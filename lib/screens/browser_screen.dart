import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

import '../providers/browser_provider.dart';
import '../providers/ai_provider.dart';
import '../widgets/browser_app_bar.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/ai_assistant_toggle.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/developer_tools_panel.dart';
import '../services/storage_service.dart';
import '../services/browser_engine_service.dart';
import '../services/incognito_service.dart';
import '../services/autofill_service.dart';
import '../services/sandboxing_service.dart';
import '../services/rendering_engine_service.dart';
import '../services/networking_service.dart';
import '../services/browser_bridge.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  final String? windowId;
  final bool isIncognito;
  
  const BrowserScreen({
    super.key,
    this.windowId,
    this.isIncognito = false,
  });

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  InAppWebViewController? _webViewController;
  bool _showAIPanel = false;
  bool _showDevTools = false;
  final TextEditingController _urlController = TextEditingController();
  Map<String, dynamic>? _currentPageContext;
  final GlobalKey<DeveloperToolsPanelState> _devToolsKey = GlobalKey<DeveloperToolsPanelState>();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  void _initializeServices() async {
    await BrowserEngineService.init();
    await NetworkingService.init();
    await AutofillService.init();
    SandboxingService.init();
    RenderingEngineService.init();
  }

  void _updateNavigationState() async {
    if (_webViewController == null) return;
    
    final canGoBack = await _webViewController!.canGoBack();
    final canGoForward = await _webViewController!.canGoForward();
    
    ref.read(browserProvider.notifier).setTabNavigationState(
      canGoBack: canGoBack,
      canGoForward: canGoForward,
    );
  }

  void _updatePageTitle() async {
    if (_webViewController == null) return;
    
    final title = await _webViewController!.getTitle();
    if (title != null) {
      ref.read(browserProvider.notifier).setTabTitle(title);
    }
  }

  void _updatePageContext() async {
    if (_webViewController == null) return;
    
    try {
      final result = await _webViewController!.evaluateJavascript(
        source: 'window.titanAI ? window.titanAI.getPageContext() : null'
      );
      
      if (result != null && result is Map) {
        setState(() {
          _currentPageContext = Map<String, dynamic>.from(result);
        });
      }
    } catch (e) {
      print('Failed to get page context: $e');
    }
  }

  void _navigateToUrl(String url) {
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('titan://')) {
      if (url.contains('.') && !url.contains(' ')) {
        formattedUrl = 'https://$url';
      } else {
        formattedUrl = '${StorageService.defaultSearchEngine}$url';
      }
    }
    
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(formattedUrl)));
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final activeTab = browserState.activeTab;

    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, browserState, activeTab),
      tablet: _buildTabletLayout(context, browserState, activeTab),
      desktop: _buildDesktopLayout(context, browserState, activeTab),
    );
  }

  Widget _buildMobileLayout(BuildContext context, browserState, activeTab) {
    return Scaffold(
      body: Column(
        children: [
          // Browser App Bar
          BrowserAppBar(
            urlController: _urlController,
            onNavigate: _navigateToUrl,
            onRefresh: () => _webViewController?.reload(),
            onBack: () => _webViewController?.goBack(),
            onForward: () => _webViewController?.goForward(),
            onToggleAI: () => _showMobileAIPanel(context),
            onSettings: () => context.go('/settings'),
            onToggleDevTools: () => _showMobileDevTools(context),
          ),
          
          // Tab Bar
          TabBarWidget(
            tabs: browserState.tabs,
            activeIndex: browserState.activeTabIndex,
            onTabSelected: _handleTabSelected,
            onTabClosed: (index) => ref.read(browserProvider.notifier).closeTab(index),
            onNewTab: () => ref.read(browserProvider.notifier).addNewTab(),
          ),
          
          // Web View
          Expanded(
            child: _buildWebView(context, activeTab),
          ),
        ],
      ),
      
      // Bottom navigation for mobile
      bottomNavigationBar: _buildMobileBottomNav(context),
    );
  }

  Widget _buildTabletLayout(BuildContext context, browserState, activeTab) {
    return Scaffold(
      body: Column(
        children: [
          // Browser App Bar
          BrowserAppBar(
            urlController: _urlController,
            onNavigate: _navigateToUrl,
            onRefresh: () => _webViewController?.reload(),
            onBack: () => _webViewController?.goBack(),
            onForward: () => _webViewController?.goForward(),
            onToggleAI: () => setState(() => _showAIPanel = !_showAIPanel),
            onSettings: () => context.go('/settings'),
            onToggleDevTools: () => setState(() => _showDevTools = !_showDevTools),
          ),
          
          // Tab Bar
          TabBarWidget(
            tabs: browserState.tabs,
            activeIndex: browserState.activeTabIndex,
            onTabSelected: _handleTabSelected,
            onTabClosed: (index) => ref.read(browserProvider.notifier).closeTab(index),
            onNewTab: () => ref.read(browserProvider.notifier).addNewTab(),
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Web View and AI Panel Row
                Expanded(
                  child: Row(
                    children: [
                      // Web View
                      Expanded(
                        flex: _showAIPanel ? 2 : 1,
                        child: _buildWebView(context, activeTab),
                      ),
                      
                      // AI Panel
                      if (_showAIPanel)
                        SizedBox(
                          width: 400,
                          child: AIAssistantPanel(
                            pageContext: _currentPageContext,
                            isVisible: _showAIPanel,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Developer Tools Panel
                if (_showDevTools)
                  DeveloperToolsPanel(key: _devToolsKey),
              ],
            ),
          ),
        ],
      ),
      
      // Floating action buttons for tablet
      floatingActionButton: _buildTabletFABs(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, browserState, activeTab) {
    return Scaffold(
      body: Column(
        children: [
          // Browser App Bar
          BrowserAppBar(
            urlController: _urlController,
            onNavigate: _navigateToUrl,
            onRefresh: () => _webViewController?.reload(),
            onBack: () => _webViewController?.goBack(),
            onForward: () => _webViewController?.goForward(),
            onToggleAI: () => setState(() => _showAIPanel = !_showAIPanel),
            onSettings: () => context.go('/settings'),
            onToggleDevTools: () => setState(() => _showDevTools = !_showDevTools),
          ),
          
          // Tab Bar
          TabBarWidget(
            tabs: browserState.tabs,
            activeIndex: browserState.activeTabIndex,
            onTabSelected: _handleTabSelected,
            onTabClosed: (index) => ref.read(browserProvider.notifier).closeTab(index),
            onNewTab: () => ref.read(browserProvider.notifier).addNewTab(),
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Web View and AI Panel Row
                Expanded(
                  child: Row(
                    children: [
                      // Web View
                      Expanded(
                        flex: _showAIPanel ? 3 : 1,
                        child: _buildWebView(context, activeTab),
                      ),
                      
                      // AI Panel
                      if (_showAIPanel)
                        SizedBox(
                          width: 350,
                          child: AIAssistantPanel(
                            pageContext: _currentPageContext,
                            isVisible: _showAIPanel,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Developer Tools Panel
                if (_showDevTools)
                  DeveloperToolsPanel(key: _devToolsKey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(BuildContext context, activeTab) {
    if (activeTab == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppTheme.spaceMd),
            Text(
              'No active tab',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: AppTheme.spaceSm),
            ElevatedButton.icon(
              onPressed: () => ref.read(browserProvider.notifier).addNewTab(),
              icon: const Icon(Icons.add),
              label: const Text('New Tab'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(activeTab.url == 'about:blank' 
                ? 'titan://newtab' 
                : activeTab.url),
          ),
          initialSettings: BrowserEngineService.getWebViewSettings(),
          onWebViewCreated: (controller) => _setupWebViewController(controller, activeTab),
          onLoadStart: (controller, url) => _handleLoadStart(controller, url),
          onLoadStop: (controller, url) => _handleLoadStop(controller, url),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            return NavigationActionPolicy.ALLOW;
          },
          shouldInterceptRequest: (controller, request) => _handleInterceptRequest(controller, request),
        ),
        
        if (activeTab.isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => context.go('/bookmarks'),
                icon: const Icon(Icons.bookmark),
                tooltip: 'Bookmarks',
              ),
              IconButton(
                onPressed: () => context.go('/history'),
                icon: const Icon(Icons.history),
                tooltip: 'History',
              ),
              IconButton(
                onPressed: () => _showMobileAIPanel(context),
                icon: const Icon(Icons.smart_toy),
                tooltip: 'AI Assistant',
              ),
              IconButton(
                onPressed: () => _showMobileDevTools(context),
                icon: const Icon(Icons.developer_mode),
                tooltip: 'Developer Tools',
              ),
              IconButton(
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletFABs(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "devtools",
          mini: true,
          onPressed: () => setState(() => _showDevTools = !_showDevTools),
          child: Icon(_showDevTools ? Icons.close : Icons.developer_mode),
        ),
        SizedBox(height: AppTheme.spaceSm),
        FloatingActionButton(
          heroTag: "ai",
          onPressed: () => setState(() => _showAIPanel = !_showAIPanel),
          child: Icon(_showAIPanel ? Icons.close : Icons.smart_toy),
        ),
      ],
    );
  }

  void _handleTabSelected(int index) {
    ref.read(browserProvider.notifier).switchToTab(index);
    final browserState = ref.read(browserProvider);
    if (index < browserState.tabs.length) {
      final tab = browserState.tabs[index];
      _urlController.text = tab.url;
      if (tab.url != 'about:blank') {
        _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(tab.url)));
      }
    }
  }

  void _setupWebViewController(InAppWebViewController controller, activeTab) {
    _webViewController = controller;
    BrowserEngineService.registerController(activeTab.id, controller);

    // Wire BrowserBridge so MCP/tools can drive the browser
    BrowserBridge.navigateToUrl = (String url) async {
      _navigateToUrl(url);
      return 'Navigated to: $url';
    };
    
    BrowserBridge.clickElement = (String selector) async {
      final js = "(() => { const el = document.querySelector('${selector.replaceAll("'", "\\'")}'); if (el) { el.click(); return 'ok'; } return 'not_found'; })()";
      await _webViewController?.evaluateJavascript(source: js);
      return 'Clicked: $selector';
    };
    
    BrowserBridge.extract = (String selector, {String? attribute}) async {
      final attr = attribute ?? 'textContent';
      final js = "(() => { const el = document.querySelector('${selector.replaceAll("'", "\\'")}'); if (!el) return ''; const v = el['$attr']; return (v || '').toString(); })()";
      final res = await _webViewController?.evaluateJavascript(source: js);
      return res?.toString() ?? '';
    };
    
    BrowserBridge.fillForm = (Map<String, dynamic> fields) async {
      final entries = fields.entries.map((e) => "{sel: '${e.key.replaceAll("'", "\\'")}', val: '${(e.value?.toString() ?? '').replaceAll("'", "\\'")}'}").join(',');
      final js = "(() => { const fields = [$entries]; fields.forEach(f => { const el = document.querySelector(f.sel); if (el) { el.value = f.val; el.dispatchEvent(new Event('input', {bubbles:true})); } }); return 'ok'; })()";
      await _webViewController?.evaluateJavascript(source: js);
      return 'Form filled';
    };
    
    BrowserBridge.getPageContent = () async {
      final js = "document.documentElement.outerHTML";
      final res = await _webViewController?.evaluateJavascript(source: js);
      return res?.toString() ?? '';
    };
    
    BrowserBridge.getTabsInfo = () async {
      final tabs = ref.read(browserProvider).tabs;
      return tabs.map((t) => {
        'id': t.id,
        'title': t.title,
        'url': t.url,
        'isLoading': t.isLoading,
        'canGoBack': t.canGoBack,
        'canGoForward': t.canGoForward,
        'incognito': t.incognito,
        'lastAccessed': t.lastAccessed.toIso8601String(),
      }).toList();
    };
    
    BrowserBridge.getCurrentTab = () async {
      final t = ref.read(browserProvider).activeTab;
      if (t == null) return null;
      return {
        'id': t.id,
        'title': t.title,
        'url': t.url,
        'isLoading': t.isLoading,
        'canGoBack': t.canGoBack,
        'canGoForward': t.canGoForward,
        'incognito': t.incognito,
        'lastAccessed': t.lastAccessed.toIso8601String(),
      };
    };

    // Add JavaScript handlers
    controller.addJavaScriptHandler(
      handlerName: 'aiContextReady',
      callback: (args) {
        if (args.isNotEmpty) {
          setState(() {
            _currentPageContext = Map<String, dynamic>.from(args[0]);
          });
        }
      },
    );
    
    // Dev console handlers: forward to DevTools panel
    controller.addJavaScriptHandler(
      handlerName: 'devConsoleLog',
      callback: (args) {
        if (args.isNotEmpty) {
          _devToolsKey.currentState?.addConsoleLog('log', args[0].toString());
        }
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'devConsoleError',
      callback: (args) {
        if (args.isNotEmpty) {
          _devToolsKey.currentState?.addConsoleLog('error', args[0].toString());
        }
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'devConsoleWarn',
      callback: (args) {
        if (args.isNotEmpty) {
          _devToolsKey.currentState?.addConsoleLog('warn', args[0].toString());
        }
      },
    );
  }

  void _handleLoadStart(InAppWebViewController controller, WebUri? url) {
    ref.read(browserProvider.notifier).setTabLoading(true);
    if (url != null) {
      _urlController.text = url.toString();
    }
  }

  Future<void> _handleLoadStop(InAppWebViewController controller, WebUri? url) async {
    ref.read(browserProvider.notifier).setTabLoading(false);
    _updateNavigationState();
    _updatePageTitle();
    
    // Inject AI context script
    await BrowserEngineService.injectAIContextScript(controller);
    _updatePageContext();
    
    // Add to history (skip internal schemes and incognito)
    if (url != null && !url.toString().startsWith('titan://')) {
      final current = ref.read(browserProvider).activeTab;
      if (current == null || !current.incognito) {
        final title = await controller.getTitle() ?? 'Untitled';
        StorageService.addToHistory(url.toString(), title);
      }
    }
  }

  Future<WebResourceResponse?> _handleInterceptRequest(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) async {
    final activeTab = ref.read(browserProvider).activeTab;
    final response = await BrowserEngineService.shouldInterceptRequest(
      controller, 
      request, 
      activeTab?.id ?? 'unknown'
    );
    
    // Log network request for developer tools
    _devToolsKey.currentState?.addNetworkLog({
      'url': request.url.toString(),
      'method': request.method,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 200,
    });
    return response;
  }

  void _showMobileAIPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
        ),
        child: AIAssistantPanel(
          pageContext: _currentPageContext,
          isVisible: true,
        ),
      ),
    );
  }

  void _showMobileDevTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeveloperToolsPanel(key: _devToolsKey),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}