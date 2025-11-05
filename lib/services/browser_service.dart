import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/browser_tab.dart';
import '../models/browser_window.dart';
import '../core/service_locator.dart';
import 'storage_service.dart';
import 'security_service.dart';

/// Consolidated browser service handling all browser operations
class BrowserService extends ChangeNotifier {
  final Map<String, InAppWebViewController> _controllers = {};
  final Map<String, BrowserTab> _tabs = {};
  final Map<String, BrowserWindow> _windows = {};
  final List<String> _tabOrder = [];
  
  String? _activeTabId;
  bool _isInitialized = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  List<BrowserTab> get tabs => _tabOrder.map((id) => _tabs[id]!).toList();
  BrowserTab? get activeTab => _activeTabId != null ? _tabs[_activeTabId] : null;
  int get tabCount => _tabs.length;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize WebView platform
      if (kIsWeb) {
        // Web platform initialization
      } else {
        await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize BrowserService: $e');
      rethrow;
    }
  }
  
  /// Create a new browser tab
  Future<BrowserTab> createTab({
    String? url,
    bool isIncognito = false,
    String? windowId,
  }) async {
    final tab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url ?? 'about:blank',
      title: 'New Tab',
      isIncognito: isIncognito,
      windowId: windowId,
    );
    
    _tabs[tab.id] = tab;
    _tabOrder.add(tab.id);
    
    if (_activeTabId == null) {
      _activeTabId = tab.id;
    }
    
    // Save to storage
    await ServiceLocator.get<StorageService>().saveTabs(_tabs.values.toList());
    
    notifyListeners();
    return tab;
  }
  
  /// Close a tab
  Future<void> closeTab(String tabId) async {
    if (!_tabs.containsKey(tabId)) return;
    
    // Clean up controller
    _controllers[tabId]?.dispose();
    _controllers.remove(tabId);
    
    // Remove tab
    _tabs.remove(tabId);
    _tabOrder.remove(tabId);
    
    // Update active tab
    if (_activeTabId == tabId) {
      _activeTabId = _tabOrder.isNotEmpty ? _tabOrder.last : null;
    }
    
    await ServiceLocator.get<StorageService>().saveTabs(_tabs.values.toList());
    notifyListeners();
  }
  
  /// Navigate tab to URL
  Future<void> navigateTab(String tabId, String url) async {
    final tab = _tabs[tabId];
    if (tab == null) return;
    
    // Security check
    final securityService = ServiceLocator.get<SecurityService>();
    final isSecure = await securityService.validateUrl(url);
    
    if (!isSecure.isSafe && isSecure.riskLevel == RiskLevel.high) {
      throw SecurityException('URL blocked by security policy: $url');
    }
    
    // Update tab
    tab.url = url;
    tab.isLoading = true;
    tab.hasError = false;
    
    // Navigate controller
    final controller = _controllers[tabId];
    if (controller != null) {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
    
    notifyListeners();
  }
  
  /// Set active tab
  void setActiveTab(String tabId) {
    if (_tabs.containsKey(tabId)) {
      _activeTabId = tabId;
      notifyListeners();
    }
  }
  
  /// Register WebView controller for tab
  void registerController(String tabId, InAppWebViewController controller) {
    _controllers[tabId] = controller;
    
    // Set up event listeners
    controller.addJavaScriptHandler(
      handlerName: 'titanBridge',
      callback: (args) => _handleJavaScriptMessage(tabId, args),
    );
  }
  
  /// Execute JavaScript in tab
  Future<dynamic> executeJavaScript(String tabId, String code) async {
    final controller = _controllers[tabId];
    if (controller == null) return null;
    
    try {
      return await controller.evaluateJavascript(source: code);
    } catch (e) {
      debugPrint('JavaScript execution error: $e');
      return null;
    }
  }
  
  /// Go back in tab history
  Future<void> goBack(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
    }
  }
  
  /// Go forward in tab history
  Future<void> goForward(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null && await controller.canGoForward()) {
      await controller.goForward();
    }
  }
  
  /// Reload tab
  Future<void> reloadTab(String tabId) async {
    final controller = _controllers[tabId];
    await controller?.reload();
  }
  
  /// Capture screenshot of tab
  Future<Uint8List?> captureScreenshot(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return null;
    
    try {
      return await controller.takeScreenshot();
    } catch (e) {
      debugPrint('Screenshot capture error: $e');
      return null;
    }
  }
  
  /// Handle JavaScript messages from web content
  void _handleJavaScriptMessage(String tabId, List<dynamic> args) {
    // Handle messages from web content
    debugPrint('JavaScript message from tab $tabId: $args');
  }
  
  /// Update tab loading state
  void updateTabLoading(String tabId, bool isLoading) {
    final tab = _tabs[tabId];
    if (tab != null) {
      tab.isLoading = isLoading;
      notifyListeners();
    }
  }
  
  /// Update tab title
  void updateTabTitle(String tabId, String title) {
    final tab = _tabs[tabId];
    if (tab != null) {
      tab.title = title;
      notifyListeners();
    }
  }
  
  /// Update tab URL
  void updateTabUrl(String tabId, String url) {
    final tab = _tabs[tabId];
    if (tab != null) {
      tab.url = url;
      notifyListeners();
    }
  }
  
  /// Set tab error state
  void setTabError(String tabId, String error) {
    final tab = _tabs[tabId];
    if (tab != null) {
      tab.hasError = true;
      tab.errorMessage = error;
      tab.isLoading = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}