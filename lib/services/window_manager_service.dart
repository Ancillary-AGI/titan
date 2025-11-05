import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import '../models/browser_window.dart';
import '../screens/browser_window_screen.dart';
import '../services/storage_service.dart';
import '../services/system_integration_service.dart';

/// Window types for different use cases
enum WindowType {
  main,           // Main browser window
  popup,          // Popup window
  incognito,      // Incognito window
  devtools,       // Developer tools window
  picture,        // Picture-in-picture window
  overlay,        // Overlay window
  kiosk,          // Kiosk mode window
}

/// Window state for session management
class WindowState {
  final String id;
  final WindowType type;
  final Size size;
  final Offset position;
  final bool isMaximized;
  final bool isMinimized;
  final bool isFullScreen;
  final bool isAlwaysOnTop;
  final List<String> tabUrls;
  final int activeTabIndex;
  final DateTime lastActive;
  
  const WindowState({
    required this.id,
    required this.type,
    required this.size,
    required this.position,
    this.isMaximized = false,
    this.isMinimized = false,
    this.isFullScreen = false,
    this.isAlwaysOnTop = false,
    this.tabUrls = const [],
    this.activeTabIndex = 0,
    required this.lastActive,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'size': {'width': size.width, 'height': size.height},
    'position': {'x': position.dx, 'y': position.dy},
    'isMaximized': isMaximized,
    'isMinimized': isMinimized,
    'isFullScreen': isFullScreen,
    'isAlwaysOnTop': isAlwaysOnTop,
    'tabUrls': tabUrls,
    'activeTabIndex': activeTabIndex,
    'lastActive': lastActive.toIso8601String(),
  };
  
  factory WindowState.fromJson(Map<String, dynamic> json) {
    return WindowState(
      id: json['id'],
      type: WindowType.values.firstWhere((t) => t.name == json['type']),
      size: Size(json['size']['width'], json['size']['height']),
      position: Offset(json['position']['x'], json['position']['y']),
      isMaximized: json['isMaximized'] ?? false,
      isMinimized: json['isMinimized'] ?? false,
      isFullScreen: json['isFullScreen'] ?? false,
      isAlwaysOnTop: json['isAlwaysOnTop'] ?? false,
      tabUrls: List<String>.from(json['tabUrls'] ?? []),
      activeTabIndex: json['activeTabIndex'] ?? 0,
      lastActive: DateTime.parse(json['lastActive']),
    );
  }
}

/// Advanced multi-window manager with desktop and mobile integration
class WindowManagerService {
  static final Map<String, BrowserWindow> _windows = {};
  static final Map<String, Webview> _desktopWebviews = {};
  static final List<String> _windowOrder = [];
  static String? _activeWindowId;
  static final StreamController<WindowState> _windowStateStream = 
      StreamController<WindowState>.broadcast();
  
  // Window management settings
  static bool _enableMultiWindow = true;
  static bool _enableWindowSnapping = true;
  static bool _enableWindowGroups = true;
  static bool _enablePictureInPicture = true;
  static int _maxWindows = 20;
  static Size _defaultWindowSize = const Size(1200, 800);
  static Size _minWindowSize = const Size(400, 300);
  
  /// Initialize window manager with platform-specific features
  static Future<void> init() async {
    await _loadWindowSettings();
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _initializeDesktop();
    } else {
      await _initializeMobile();
    }
    
    await _setupWindowEventHandlers();
    await _restoreSession();
  }
  
  /// Initialize desktop window management
  static Future<void> _initializeDesktop() async {
    await windowManager.ensureInitialized();
    
    // Configure main window
    await windowManager.setTitle('Titan Browser');
    await windowManager.setSize(_defaultWindowSize);
    await windowManager.setMinimumSize(_minWindowSize);
    await windowManager.center();
    
    // Enable window features
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setBackgroundColor(Colors.transparent);
    
    // Setup window event listeners
    windowManager.addListener(_DesktopWindowListener());
    
    print('Desktop window manager initialized');
  }
  
  /// Initialize mobile system integration
  static Future<void> _initializeMobile() async {
    await SystemIntegrationService.initialize();
    
    // Setup deep linking
    await _setupDeepLinking();
    
    // Setup share target
    await _setupShareTarget();
    
    // Setup custom URL schemes
    await _setupCustomSchemes();
    
    print('Mobile system integration initialized');
  }
  
  /// Setup window event handlers
  static Future<void> _setupWindowEventHandlers() async {
    // Listen for system events
    SystemChannels.lifecycle.setMessageHandler((message) async {
      switch (message) {
        case 'AppLifecycleState.paused':
          await _saveSession();
          break;
        case 'AppLifecycleState.resumed':
          await _restoreSession();
          break;
      }
      return null;
    });
  }
  
  /// Load window settings from storage
  static Future<void> _loadWindowSettings() async {
    try {
      final settings = StorageService.getSetting<String>('window_settings');
      if (settings != null) {
        final data = jsonDecode(settings);
        _enableMultiWindow = data['enableMultiWindow'] ?? true;
        _enableWindowSnapping = data['enableWindowSnapping'] ?? true;
        _enableWindowGroups = data['enableWindowGroups'] ?? true;
        _enablePictureInPicture = data['enablePictureInPicture'] ?? true;
        _maxWindows = data['maxWindows'] ?? 20;
        
        final defaultSize = data['defaultWindowSize'];
        if (defaultSize != null) {
          _defaultWindowSize = Size(defaultSize['width'], defaultSize['height']);
        }
      }
    } catch (e) {
      print('Error loading window settings: $e');
    }
  }
  
  /// Create new window with advanced options
  static Future<String> createNewWindow({
    WindowType type = WindowType.main,
    bool isIncognito = false,
    String? initialUrl,
    Size? size,
    Offset? position,
    String? parentWindowId,
    Map<String, dynamic>? options,
  }) async {
    if (!_enableMultiWindow && _windows.isNotEmpty && type != WindowType.popup) {
      throw Exception('Multi-window is disabled');
    }
    
    if (_windows.length >= _maxWindows) {
      throw Exception('Maximum window limit reached');
    }
    
    final window = BrowserWindow(
      isIncognito: isIncognito,
      initialUrl: initialUrl ?? 'titan://newtab',
      size: size ?? _defaultWindowSize,
      position: position,
    );
    
    _windows[window.id] = window;
    _windowOrder.add(window.id);
    _activeWindowId = window.id;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _createDesktopWindow(window, type, options);
    } else {
      await _createMobileWindow(window, type, options);
    }
    
    // Notify window state change
    _notifyWindowStateChange(window.id);
    
    return window.id;
  }
  
  /// Create popup window
  static Future<String> createPopupWindow({
    required String url,
    Size? size,
    Offset? position,
    String? parentWindowId,
  }) async {
    return await createNewWindow(
      type: WindowType.popup,
      initialUrl: url,
      size: size ?? const Size(800, 600),
      position: position,
      parentWindowId: parentWindowId,
      options: {'popup': true},
    );
  }
  
  /// Create incognito window
  static Future<String> createIncognitoWindow({
    String? initialUrl,
    Size? size,
    Offset? position,
  }) async {
    return await createNewWindow(
      type: WindowType.incognito,
      isIncognito: true,
      initialUrl: initialUrl,
      size: size,
      position: position,
    );
  }
  
  /// Create developer tools window
  static Future<String> createDevToolsWindow({
    required String targetTabId,
    Size? size,
    Offset? position,
  }) async {
    return await createNewWindow(
      type: WindowType.devtools,
      initialUrl: 'titan://devtools?tab=$targetTabId',
      size: size ?? const Size(1000, 700),
      position: position,
      options: {'devtools': true, 'targetTab': targetTabId},
    );
  }
  
  /// Create picture-in-picture window
  static Future<String> createPictureInPictureWindow({
    required String mediaUrl,
    Size? size,
    Offset? position,
  }) async {
    if (!_enablePictureInPicture) {
      throw Exception('Picture-in-picture is disabled');
    }
    
    return await createNewWindow(
      type: WindowType.picture,
      initialUrl: mediaUrl,
      size: size ?? const Size(400, 300),
      position: position,
      options: {'pip': true, 'alwaysOnTop': true},
    );
  }
  
  /// Create kiosk mode window
  static Future<String> createKioskWindow({
    required String url,
  }) async {
    return await createNewWindow(
      type: WindowType.kiosk,
      initialUrl: url,
      options: {'kiosk': true, 'fullscreen': true},
    );
  }
  
  /// Create desktop window with native webview
  static Future<void> _createDesktopWindow(
    BrowserWindow window,
    WindowType type,
    Map<String, dynamic>? options,
  ) async {
    try {
      // Create native webview window
      final webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          windowWidth: window.size.width.toInt(),
          windowHeight: window.size.height.toInt(),
          title: _getWindowTitle(type, window.isIncognito),
          titleBarTopPadding: Platform.isMacOS ? 28 : 0,
        ),
      );
      
      _desktopWebviews[window.id] = webview;
      
      // Configure window based on type
      await _configureDesktopWindow(webview, type, options);
      
      // Load initial URL
      await webview.launch(window.initialUrl);
      
      // Setup window event handlers
      _setupDesktopWindowHandlers(window.id, webview);
      
    } catch (e) {
      print('Error creating desktop window: $e');
      // Fallback to main window navigation
      await _createMainWindowTab(window);
    }
  }
  
  /// Configure desktop window based on type
  static Future<void> _configureDesktopWindow(
    Webview webview,
    WindowType type,
    Map<String, dynamic>? options,
  ) async {
    switch (type) {
      case WindowType.popup:
        await webview.setApplicationNameForUserAgent('Titan Browser Popup');
        break;
      case WindowType.incognito:
        await webview.setApplicationNameForUserAgent('Titan Browser Incognito');
        break;
      case WindowType.devtools:
        await webview.setApplicationNameForUserAgent('Titan Developer Tools');
        break;
      case WindowType.picture:
        await webview.setApplicationNameForUserAgent('Titan PiP');
        // Configure always on top for PiP
        break;
      case WindowType.kiosk:
        await webview.setApplicationNameForUserAgent('Titan Kiosk');
        // Configure fullscreen for kiosk
        break;
      default:
        await webview.setApplicationNameForUserAgent('Titan Browser');
    }
    
    // Apply additional options
    if (options != null) {
      if (options['alwaysOnTop'] == true) {
        // Set always on top (platform-specific implementation needed)
      }
      if (options['fullscreen'] == true) {
        // Set fullscreen (platform-specific implementation needed)
      }
    }
  }
  
  /// Setup desktop window event handlers
  static void _setupDesktopWindowHandlers(String windowId, Webview webview) {
    webview.onClose.listen((_) {
      closeWindow(windowId);
    });
    
    // Add more event handlers as needed
  }
  
  /// Create mobile window (tab-based approach with system integration)
  static Future<void> _createMobileWindow(
    BrowserWindow window,
    WindowType type,
    Map<String, dynamic>? options,
  ) async {
    // On mobile, we use a tab-based approach with system integration
    switch (type) {
      case WindowType.popup:
        await _createMobilePopup(window, options);
        break;
      case WindowType.incognito:
        await _createMobileIncognito(window);
        break;
      case WindowType.picture:
        await _createMobilePictureInPicture(window, options);
        break;
      default:
        await _createMobileTab(window);
    }
  }
  
  /// Create mobile popup (overlay or new activity)
  static Future<void> _createMobilePopup(
    BrowserWindow window,
    Map<String, dynamic>? options,
  ) async {
    // Use platform channels to create native popup
    try {
      await SystemIntegrationService.createPopupWindow(
        url: window.initialUrl,
        width: window.size.width.toInt(),
        height: window.size.height.toInt(),
      );
    } catch (e) {
      print('Error creating mobile popup: $e');
      // Fallback to in-app overlay
      await _createMobileTab(window);
    }
  }
  
  /// Create mobile incognito session
  static Future<void> _createMobileIncognito(BrowserWindow window) async {
    // Create incognito tab with enhanced privacy
    await _createMobileTab(window);
    
    // Enable additional privacy features
    await SystemIntegrationService.enableIncognitoMode(window.id);
  }
  
  /// Create mobile picture-in-picture
  static Future<void> _createMobilePictureInPicture(
    BrowserWindow window,
    Map<String, dynamic>? options,
  ) async {
    if (!_enablePictureInPicture) return;
    
    try {
      await SystemIntegrationService.enterPictureInPictureMode(
        url: window.initialUrl,
        aspectRatio: window.size.aspectRatio,
      );
    } catch (e) {
      print('Error creating mobile PiP: $e');
    }
  }
  
  /// Create mobile tab
  static Future<void> _createMobileTab(BrowserWindow window) async {
    // This would integrate with the main mobile UI
    // Implementation depends on the mobile app architecture
  }
  
  /// Fallback to main window tab creation
  static Future<void> _createMainWindowTab(BrowserWindow window) async {
    // Create new tab in main window instead of new window
    // This is a fallback when native window creation fails
  }
  
  /// Get window title based on type
  static String _getWindowTitle(WindowType type, bool isIncognito) {
    final incognitoSuffix = isIncognito ? ' (Incognito)' : '';
    
    switch (type) {
      case WindowType.popup:
        return 'Titan Browser - Popup$incognitoSuffix';
      case WindowType.incognito:
        return 'Titan Browser - Incognito';
      case WindowType.devtools:
        return 'Titan Developer Tools';
      case WindowType.picture:
        return 'Titan PiP';
      case WindowType.overlay:
        return 'Titan Overlay';
      case WindowType.kiosk:
        return 'Titan Kiosk';
      default:
        return 'Titan Browser$incognitoSuffix';
    }
  }
  
  static Future<void> closeWindow(String windowId) async {
    final window = _windows[windowId];
    if (window == null) return;
    
    // Save window state before closing
    await _saveWindowState(window);
    
    _windows.remove(windowId);
    _windowOrder.remove(windowId);
    
    if (_activeWindowId == windowId) {
      _activeWindowId = _windowOrder.isNotEmpty ? _windowOrder.last : null;
    }
    
    if (_windows.isEmpty) {
      // Close application if no windows remain
      await windowManager.close();
    }
  }
  
  static Future<void> _saveWindowState(BrowserWindow window) async {
    // Save window state for session restoration
    // Implementation would save to storage
  }
  
  static void focusWindow(String windowId) {
    if (_windows.containsKey(windowId)) {
      _activeWindowId = windowId;
      _windowOrder.remove(windowId);
      _windowOrder.add(windowId);
    }
  }
  
  static BrowserWindow? getWindow(String windowId) {
    return _windows[windowId];
  }
  
  static BrowserWindow? get activeWindow {
    return _activeWindowId != null ? _windows[_activeWindowId] : null;
  }
  
  static List<BrowserWindow> get allWindows {
    return _windowOrder.map((id) => _windows[id]!).toList();
  }
  
  static int get windowCount => _windows.length;
  
  static Future<void> minimizeWindow(String windowId) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.minimize();
    }
  }
  
  static Future<void> maximizeWindow(String windowId) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final isMaximized = await windowManager.isMaximized();
      if (isMaximized) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    }
  }
  
  static Future<void> setWindowAlwaysOnTop(String windowId, bool alwaysOnTop) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    }
  }
  
  static Future<void> setWindowFullScreen(String windowId, bool fullScreen) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setFullScreen(fullScreen);
    }
  }
  
  /// Setup deep linking for mobile integration
  static Future<void> _setupDeepLinking() async {
    // Register URL schemes: titan://, https://titan.browser/
    await SystemIntegrationService.registerUrlSchemes([
      'titan',
      'https://titan.browser',
    ]);
    
    // Handle incoming deep links
    SystemIntegrationService.onDeepLink.listen((url) {
      _handleDeepLink(url);
    });
  }
  
  /// Setup share target for receiving shared content
  static Future<void> _setupShareTarget() async {
    await SystemIntegrationService.registerShareTarget([
      'text/plain',
      'text/html',
      'image/*',
      'application/pdf',
    ]);
    
    // Handle shared content
    SystemIntegrationService.onSharedContent.listen((content) {
      _handleSharedContent(content);
    });
  }
  
  /// Setup custom URL schemes
  static Future<void> _setupCustomSchemes() async {
    await SystemIntegrationService.registerCustomSchemes({
      'titan-search': _handleSearchScheme,
      'titan-bookmark': _handleBookmarkScheme,
      'titan-translate': _handleTranslateScheme,
      'titan-ai': _handleAIScheme,
    });
  }
  
  /// Handle deep link navigation
  static Future<void> _handleDeepLink(String url) async {
    final uri = Uri.parse(url);
    
    switch (uri.scheme) {
      case 'titan':
        await _handleTitanScheme(uri);
        break;
      case 'https':
        if (uri.host == 'titan.browser') {
          await _handleTitanWebScheme(uri);
        } else {
          await _openUrlInNewWindow(url);
        }
        break;
      default:
        await _openUrlInNewWindow(url);
    }
  }
  
  /// Handle titan:// scheme
  static Future<void> _handleTitanScheme(Uri uri) async {
    switch (uri.host) {
      case 'newtab':
        await createNewWindow(initialUrl: 'titan://newtab');
        break;
      case 'incognito':
        await createIncognitoWindow();
        break;
      case 'search':
        final query = uri.queryParameters['q'] ?? '';
        await createNewWindow(initialUrl: 'https://www.google.com/search?q=${Uri.encodeComponent(query)}');
        break;
      case 'bookmark':
        final bookmarkId = uri.queryParameters['id'];
        if (bookmarkId != null) {
          await _openBookmark(bookmarkId);
        }
        break;
      case 'ai':
        final command = uri.queryParameters['cmd'] ?? '';
        await _executeAICommand(command);
        break;
      default:
        await createNewWindow(initialUrl: uri.toString());
    }
  }
  
  /// Handle titan.browser web scheme
  static Future<void> _handleTitanWebScheme(Uri uri) async {
    switch (uri.path) {
      case '/open':
        final url = uri.queryParameters['url'];
        if (url != null) {
          await _openUrlInNewWindow(url);
        }
        break;
      case '/search':
        final query = uri.queryParameters['q'] ?? '';
        await createNewWindow(initialUrl: 'https://www.google.com/search?q=${Uri.encodeComponent(query)}');
        break;
      case '/translate':
        final url = uri.queryParameters['url'];
        final lang = uri.queryParameters['lang'] ?? 'en';
        if (url != null) {
          await _openUrlWithTranslation(url, lang);
        }
        break;
      default:
        await createNewWindow();
    }
  }
  
  /// Handle shared content from other apps
  static Future<void> _handleSharedContent(Map<String, dynamic> content) async {
    final type = content['type'] as String?;
    final data = content['data'];
    
    switch (type) {
      case 'text/plain':
        final text = data as String;
        if (Uri.tryParse(text) != null) {
          // Shared URL
          await _openUrlInNewWindow(text);
        } else {
          // Shared text - search for it
          await createNewWindow(initialUrl: 'https://www.google.com/search?q=${Uri.encodeComponent(text)}');
        }
        break;
      case 'text/html':
        // Create new window with HTML content
        await _createWindowWithHtmlContent(data as String);
        break;
      case 'image':
        // Open image in new window
        await _openImageInNewWindow(data as String);
        break;
      default:
        await createNewWindow();
    }
  }
  
  /// Handle custom scheme callbacks
  static Future<void> _handleSearchScheme(String url) async {
    final uri = Uri.parse(url);
    final query = uri.queryParameters['q'] ?? '';
    await createNewWindow(initialUrl: 'https://www.google.com/search?q=${Uri.encodeComponent(query)}');
  }
  
  static Future<void> _handleBookmarkScheme(String url) async {
    final uri = Uri.parse(url);
    final bookmarkId = uri.queryParameters['id'];
    if (bookmarkId != null) {
      await _openBookmark(bookmarkId);
    }
  }
  
  static Future<void> _handleTranslateScheme(String url) async {
    final uri = Uri.parse(url);
    final targetUrl = uri.queryParameters['url'];
    final lang = uri.queryParameters['lang'] ?? 'en';
    if (targetUrl != null) {
      await _openUrlWithTranslation(targetUrl, lang);
    }
  }
  
  static Future<void> _handleAIScheme(String url) async {
    final uri = Uri.parse(url);
    final command = uri.queryParameters['cmd'] ?? '';
    await _executeAICommand(command);
  }
  
  /// Open URL in new window
  static Future<void> _openUrlInNewWindow(String url) async {
    await createNewWindow(initialUrl: url);
  }
  
  /// Open bookmark by ID
  static Future<void> _openBookmark(String bookmarkId) async {
    // Load bookmark from storage and open
    try {
      final bookmarks = StorageService.getBookmarks();
      final bookmark = bookmarks.firstWhere((b) => b['id'] == bookmarkId);
      await createNewWindow(initialUrl: bookmark['url']);
    } catch (e) {
      print('Error opening bookmark: $e');
    }
  }
  
  /// Open URL with translation
  static Future<void> _openUrlWithTranslation(String url, String targetLang) async {
    final translateUrl = 'https://translate.google.com/translate?sl=auto&tl=$targetLang&u=${Uri.encodeComponent(url)}';
    await createNewWindow(initialUrl: translateUrl);
  }
  
  /// Execute AI command
  static Future<void> _executeAICommand(String command) async {
    // Create new window and execute AI command
    final windowId = await createNewWindow();
    // Execute AI command in the new window
    // This would integrate with the AI services
  }
  
  /// Create window with HTML content
  static Future<void> _createWindowWithHtmlContent(String html) async {
    final dataUrl = 'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';
    await createNewWindow(initialUrl: dataUrl);
  }
  
  /// Open image in new window
  static Future<void> _openImageInNewWindow(String imagePath) async {
    final imageUrl = 'file://$imagePath';
    await createNewWindow(initialUrl: imageUrl);
  }
  
  /// Window snapping and management
  static Future<void> snapWindowToEdge(String windowId, String edge) async {
    if (!_enableWindowSnapping) return;
    
    final window = _windows[windowId];
    if (window == null) return;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Get screen dimensions
      final screenSize = await windowManager.getSize();
      Size newSize;
      Offset newPosition;
      
      switch (edge) {
        case 'left':
          newSize = Size(screenSize.width / 2, screenSize.height);
          newPosition = const Offset(0, 0);
          break;
        case 'right':
          newSize = Size(screenSize.width / 2, screenSize.height);
          newPosition = Offset(screenSize.width / 2, 0);
          break;
        case 'top':
          newSize = Size(screenSize.width, screenSize.height / 2);
          newPosition = const Offset(0, 0);
          break;
        case 'bottom':
          newSize = Size(screenSize.width, screenSize.height / 2);
          newPosition = Offset(0, screenSize.height / 2);
          break;
        default:
          return;
      }
      
      await windowManager.setSize(newSize);
      await windowManager.setPosition(newPosition);
    }
  }
  
  /// Window grouping
  static Future<void> createWindowGroup(List<String> windowIds, String groupName) async {
    if (!_enableWindowGroups) return;
    
    // Save window group to storage
    final groups = StorageService.getSetting<String>('window_groups') ?? '{}';
    final groupsMap = Map<String, dynamic>.from(jsonDecode(groups));
    groupsMap[groupName] = windowIds;
    
    await StorageService.setSetting('window_groups', jsonEncode(groupsMap));
  }
  
  /// Restore window group
  static Future<void> restoreWindowGroup(String groupName) async {
    try {
      final groups = StorageService.getSetting<String>('window_groups') ?? '{}';
      final groupsMap = Map<String, dynamic>.from(jsonDecode(groups));
      final windowIds = List<String>.from(groupsMap[groupName] ?? []);
      
      for (final windowId in windowIds) {
        final state = await _loadWindowState(windowId);
        if (state != null) {
          await _restoreWindowFromState(state);
        }
      }
    } catch (e) {
      print('Error restoring window group: $e');
    }
  }
  
  /// Notify window state change
  static void _notifyWindowStateChange(String windowId) {
    final window = _windows[windowId];
    if (window == null) return;
    
    final state = WindowState(
      id: windowId,
      type: WindowType.main, // This would be determined from window properties
      size: window.size,
      position: window.position ?? Offset.zero,
      lastActive: DateTime.now(),
    );
    
    _windowStateStream.add(state);
  }
  
  /// Get window state stream
  static Stream<WindowState> get windowStateStream => _windowStateStream.stream;
  
  /// Save window state
  static Future<void> _saveWindowState(BrowserWindow window) async {
    final state = WindowState(
      id: window.id,
      type: WindowType.main,
      size: window.size,
      position: window.position ?? Offset.zero,
      lastActive: DateTime.now(),
    );
    
    await StorageService.setSetting('window_state_${window.id}', jsonEncode(state.toJson()));
  }
  
  /// Load window state
  static Future<WindowState?> _loadWindowState(String windowId) async {
    try {
      final stateJson = StorageService.getSetting<String>('window_state_$windowId');
      if (stateJson != null) {
        return WindowState.fromJson(jsonDecode(stateJson));
      }
    } catch (e) {
      print('Error loading window state: $e');
    }
    return null;
  }
  
  /// Restore window from state
  static Future<void> _restoreWindowFromState(WindowState state) async {
    await createNewWindow(
      initialUrl: state.tabUrls.isNotEmpty ? state.tabUrls[state.activeTabIndex] : null,
      size: state.size,
      position: state.position,
    );
  }
  
  /// Restore session
  static Future<void> _restoreSession() async {
    try {
      final sessionJson = StorageService.getSetting<String>('browser_session');
      if (sessionJson != null) {
        final session = Map<String, dynamic>.from(jsonDecode(sessionJson));
        final windowStates = List<Map<String, dynamic>>.from(session['windows'] ?? []);
        
        for (final stateData in windowStates) {
          final state = WindowState.fromJson(stateData);
          await _restoreWindowFromState(state);
        }
      }
    } catch (e) {
      print('Error restoring session: $e');
      // Create default window if session restore fails
      if (_windows.isEmpty) {
        await createNewWindow();
      }
    }
  }
  
  /// Save session
  static Future<void> _saveSession() async {
    try {
      final windowStates = <Map<String, dynamic>>[];
      
      for (final window in _windows.values) {
        final state = WindowState(
          id: window.id,
          type: WindowType.main,
          size: window.size,
          position: window.position ?? Offset.zero,
          lastActive: DateTime.now(),
        );
        windowStates.add(state.toJson());
      }
      
      final session = {
        'windows': windowStates,
        'activeWindow': _activeWindowId,
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      await StorageService.setSetting('browser_session', jsonEncode(session));
    } catch (e) {
      print('Error saving session: $e');
    }
  }
  
  /// Configure window settings
  static Future<void> configureWindowSettings({
    bool? enableMultiWindow,
    bool? enableWindowSnapping,
    bool? enableWindowGroups,
    bool? enablePictureInPicture,
    int? maxWindows,
    Size? defaultWindowSize,
  }) async {
    if (enableMultiWindow != null) _enableMultiWindow = enableMultiWindow;
    if (enableWindowSnapping != null) _enableWindowSnapping = enableWindowSnapping;
    if (enableWindowGroups != null) _enableWindowGroups = enableWindowGroups;
    if (enablePictureInPicture != null) _enablePictureInPicture = enablePictureInPicture;
    if (maxWindows != null) _maxWindows = maxWindows;
    if (defaultWindowSize != null) _defaultWindowSize = defaultWindowSize;
    
    // Save settings
    final settings = {
      'enableMultiWindow': _enableMultiWindow,
      'enableWindowSnapping': _enableWindowSnapping,
      'enableWindowGroups': _enableWindowGroups,
      'enablePictureInPicture': _enablePictureInPicture,
      'maxWindows': _maxWindows,
      'defaultWindowSize': {
        'width': _defaultWindowSize.width,
        'height': _defaultWindowSize.height,
      },
    };
    
    await StorageService.setSetting('window_settings', jsonEncode(settings));
  }
  
  /// Get window management statistics
  static Map<String, dynamic> getWindowStats() {
    return {
      'totalWindows': _windows.length,
      'activeWindow': _activeWindowId,
      'windowOrder': _windowOrder,
      'desktopWebviews': _desktopWebviews.length,
      'settings': {
        'enableMultiWindow': _enableMultiWindow,
        'enableWindowSnapping': _enableWindowSnapping,
        'enableWindowGroups': _enableWindowGroups,
        'enablePictureInPicture': _enablePictureInPicture,
        'maxWindows': _maxWindows,
      },
    };
  }
  
  /// Cleanup all windows
  static Future<void> cleanup() async {
    await _saveSession();
    
    // Close all desktop webviews
    for (final webview in _desktopWebviews.values) {
      await webview.close();
    }
    _desktopWebviews.clear();
    
    // Clear window data
    _windows.clear();
    _windowOrder.clear();
    _activeWindowId = null;
    
    // Close streams
    await _windowStateStream.close();
  }
}

/// Desktop window event listener
class _DesktopWindowListener extends WindowListener {
  @override
  void onWindowClose() {
    WindowManagerService._saveSession();
  }
  
  @override
  void onWindowFocus() {
    // Handle window focus events
  }
  
  @override
  void onWindowBlur() {
    // Handle window blur events
  }
  
  @override
  void onWindowResize() {
    // Handle window resize events
  }
  
  @override
  void onWindowMove() {
    // Handle window move events
  }
}