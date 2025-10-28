import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/browser_tab.dart';
import '../services/storage_service.dart';

class BrowserEngineService {
  static late InAppWebViewController? _controller;
  static final Map<String, InAppWebViewController> _tabControllers = {};
  static final List<String> _blockedDomains = [];
  static bool _adBlockEnabled = true;
  static bool _javascriptEnabled = true;
  static bool _cookiesEnabled = true;
  
  static Future<void> init() async {
    // Load blocked domains for ad blocking
    await _loadBlockedDomains();
    
    // Set up custom user agent
    await _setupUserAgent();
  }
  
  static Future<void> _loadBlockedDomains() async {
    try {
      final String data = await rootBundle.loadString('assets/data/blocked_domains.txt');
      _blockedDomains.addAll(data.split('\n').where((line) => line.trim().isNotEmpty));
    } catch (e) {
      print('Failed to load blocked domains: $e');
    }
  }
  
  static Future<void> _setupUserAgent() async {
    // Custom user agent for Titan Browser
    const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) TitanBrowser/1.0.0 Chrome/120.0.0.0 Safari/537.36';
    // User agent will be set per WebView instance
  }
  
  static InAppWebViewSettings getWebViewSettings() {
    return InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone; geolocation",
      iframeAllowFullscreen: true,
      
      // Security settings
      allowsLinkPreview: true,
      allowsBackForwardNavigationGestures: true,
      allowsPictureInPictureMediaPlayback: true,
      
      // Performance settings
      cacheEnabled: true,
      clearCache: false,
      
      // JavaScript settings
      javaScriptEnabled: _javascriptEnabled,
      javaScriptCanOpenWindowsAutomatically: false,
      
      // Cookie settings
      thirdPartyCookiesEnabled: _cookiesEnabled,
      
      // Developer tools
      debuggingEnabled: true,
      
      // Custom user agent
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) TitanBrowser/1.0.0 Chrome/120.0.0.0 Safari/537.36',
      
      // Network settings
      networkAvailable: true,
      
      // Rendering settings
      supportZoom: true,
      builtInZoomControls: true,
      displayZoomControls: false,
      
      // Content settings
      blockNetworkImage: false,
      blockNetworkLoads: false,
      
      // Accessibility
      accessibilityIgnoresInvertColors: false,
      
      // Mixed content
      mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
    );
  }
  
  static void registerController(String tabId, InAppWebViewController controller) {
    _tabControllers[tabId] = controller;
    _controller = controller;
  }
  
  static void unregisterController(String tabId) {
    _tabControllers.remove(tabId);
  }
  
  static InAppWebViewController? getController(String tabId) {
    return _tabControllers[tabId];
  }
  
  static InAppWebViewController? get currentController => _controller;
  
  // Network request interception for ad blocking and custom handling
  static Future<WebResourceResponse?> shouldInterceptRequest(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) async {
    final url = request.url.toString();
    
    // Ad blocking
    if (_adBlockEnabled && _isBlocked(url)) {
      return WebResourceResponse(
        contentType: 'text/plain',
        data: Uint8List.fromList([]),
      );
    }
    
    // Custom protocol handling
    if (url.startsWith('titan://')) {
      return await _handleTitanProtocol(url);
    }
    
    // Log network requests for developer tools
    await _logNetworkRequest(request);
    
    return null; // Allow normal processing
  }
  
  static bool _isBlocked(String url) {
    return _blockedDomains.any((domain) => url.contains(domain));
  }
  
  static Future<WebResourceResponse?> _handleTitanProtocol(String url) async {
    final uri = Uri.parse(url);
    
    switch (uri.host) {
      case 'settings':
        return _createHtmlResponse(_generateSettingsPage());
      case 'newtab':
        return _createHtmlResponse(_generateNewTabPage());
      case 'history':
        return _createHtmlResponse(_generateHistoryPage());
      case 'bookmarks':
        return _createHtmlResponse(_generateBookmarksPage());
      default:
        return _createHtmlResponse('<h1>Titan Protocol</h1><p>Unknown page: ${uri.host}</p>');
    }
  }
  
  static WebResourceResponse _createHtmlResponse(String html) {
    return WebResourceResponse(
      contentType: 'text/html',
      data: Uint8List.fromList(utf8.encode(html)),
    );
  }
  
  static String _generateNewTabPage() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <title>New Tab - Titan Browser</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 40px 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            min-height: 100vh;
            box-sizing: border-box;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        .logo {
            font-size: 48px;
            font-weight: bold;
            margin-bottom: 20px;
        }
        .search-box {
            width: 100%;
            max-width: 600px;
            padding: 15px 20px;
            font-size: 16px;
            border: none;
            border-radius: 25px;
            margin: 20px 0;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        .shortcuts {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 20px;
            margin-top: 40px;
        }
        .shortcut {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            text-decoration: none;
            color: white;
            transition: transform 0.2s;
        }
        .shortcut:hover {
            transform: translateY(-2px);
            background: rgba(255,255,255,0.2);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀 Titan</div>
        <input type="text" class="search-box" placeholder="Search or enter URL..." 
               onkeypress="if(event.key==='Enter') window.location.href='https://www.google.com/search?q='+encodeURIComponent(this.value)">
        
        <div class="shortcuts">
            <a href="https://www.google.com" class="shortcut">
                <div>🔍</div>
                <div>Google</div>
            </a>
            <a href="https://www.youtube.com" class="shortcut">
                <div>📺</div>
                <div>YouTube</div>
            </a>
            <a href="https://www.github.com" class="shortcut">
                <div>💻</div>
                <div>GitHub</div>
            </a>
            <a href="titan://bookmarks" class="shortcut">
                <div>📚</div>
                <div>Bookmarks</div>
            </a>
            <a href="titan://history" class="shortcut">
                <div>📜</div>
                <div>History</div>
            </a>
            <a href="titan://settings" class="shortcut">
                <div>⚙️</div>
                <div>Settings</div>
            </a>
        </div>
    </div>
</body>
</html>
    ''';
  }
  
  static String _generateSettingsPage() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <title>Settings - Titan Browser</title>
    <meta charset="utf-8">
    <style>
        body { font-family: system-ui; margin: 20px; }
        .setting { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 8px; }
        .setting h3 { margin-top: 0; }
        button { padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; }
        button:hover { background: #0056b3; }
    </style>
</head>
<body>
    <h1>⚙️ Titan Browser Settings</h1>
    
    <div class="setting">
        <h3>JavaScript</h3>
        <p>Enable JavaScript execution on web pages</p>
        <button onclick="toggleJavaScript()">Toggle JavaScript</button>
    </div>
    
    <div class="setting">
        <h3>Ad Blocker</h3>
        <p>Block advertisements and trackers</p>
        <button onclick="toggleAdBlock()">Toggle Ad Blocker</button>
    </div>
    
    <div class="setting">
        <h3>Developer Tools</h3>
        <p>Enable web developer tools</p>
        <button onclick="openDevTools()">Open Developer Tools</button>
    </div>
    
    <script>
        function toggleJavaScript() {
            window.flutter_inappwebview.callHandler('toggleJavaScript');
        }
        
        function toggleAdBlock() {
            window.flutter_inappwebview.callHandler('toggleAdBlock');
        }
        
        function openDevTools() {
            window.flutter_inappwebview.callHandler('openDevTools');
        }
    </script>
</body>
</html>
    ''';
  }
  
  static String _generateHistoryPage() {
    final history = StorageService.getHistory();
    final historyItems = history.map((item) => '''
      <div class="history-item">
        <a href="${item['url']}">${item['title']}</a>
        <small>${item['timestamp']}</small>
      </div>
    ''').join('');
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <title>History - Titan Browser</title>
    <meta charset="utf-8">
    <style>
        body { font-family: system-ui; margin: 20px; }
        .history-item { margin: 10px 0; padding: 10px; border-bottom: 1px solid #eee; }
        .history-item a { text-decoration: none; color: #007bff; font-weight: 500; }
        .history-item small { display: block; color: #666; margin-top: 5px; }
    </style>
</head>
<body>
    <h1>📜 Browsing History</h1>
    $historyItems
</body>
</html>
    ''';
  }
  
  static String _generateBookmarksPage() {
    final bookmarks = StorageService.getBookmarks();
    final bookmarkItems = bookmarks.map((item) => '''
      <div class="bookmark-item">
        <a href="${item['url']}">${item['title']}</a>
        <small>${item['folder']}</small>
      </div>
    ''').join('');
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <title>Bookmarks - Titan Browser</title>
    <meta charset="utf-8">
    <style>
        body { font-family: system-ui; margin: 20px; }
        .bookmark-item { margin: 10px 0; padding: 10px; border-bottom: 1px solid #eee; }
        .bookmark-item a { text-decoration: none; color: #007bff; font-weight: 500; }
        .bookmark-item small { display: block; color: #666; margin-top: 5px; }
    </style>
</head>
<body>
    <h1>📚 Bookmarks</h1>
    $bookmarkItems
</body>
</html>
    ''';
  }
  
  static Future<void> _logNetworkRequest(WebResourceRequest request) async {
    // Log for developer tools
    final logEntry = {
      'url': request.url.toString(),
      'method': request.method,
      'headers': request.headers,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Store in developer tools logs
    await StorageService.setSetting('dev_network_logs', 
        jsonEncode([...await _getNetworkLogs(), logEntry]));
  }
  
  static Future<List<dynamic>> _getNetworkLogs() async {
    final logs = StorageService.getSetting<String>('dev_network_logs');
    if (logs != null) {
      return jsonDecode(logs);
    }
    return [];
  }
  
  // JavaScript injection for AI context
  static Future<void> injectAIContextScript(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      // Titan AI Context Script
      window.titanAI = {
        getPageContext: function() {
          return {
            title: document.title,
            url: window.location.href,
            content: document.body.innerText.substring(0, 5000),
            forms: Array.from(document.forms).map(form => ({
              action: form.action,
              method: form.method,
              fields: Array.from(form.elements).map(el => ({
                name: el.name,
                type: el.type,
                value: el.value
              }))
            })),
            links: Array.from(document.links).slice(0, 50).map(link => ({
              href: link.href,
              text: link.textContent.trim()
            })),
            images: Array.from(document.images).slice(0, 20).map(img => ({
              src: img.src,
              alt: img.alt
            }))
          };
        },
        
        highlightElement: function(selector) {
          const element = document.querySelector(selector);
          if (element) {
            element.style.outline = '3px solid #ff6b6b';
            element.style.outlineOffset = '2px';
            setTimeout(() => {
              element.style.outline = '';
              element.style.outlineOffset = '';
            }, 3000);
          }
        },
        
        clickElement: function(selector) {
          const element = document.querySelector(selector);
          if (element) {
            element.click();
            return true;
          }
          return false;
        },
        
        fillField: function(selector, value) {
          const element = document.querySelector(selector);
          if (element) {
            element.value = value;
            element.dispatchEvent(new Event('input', { bubbles: true }));
            element.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
          }
          return false;
        }
      };
      
      // Notify Flutter that AI context is ready
      window.flutter_inappwebview.callHandler('aiContextReady', window.titanAI.getPageContext());
    ''');
  }
  
  // Developer tools functionality
  static Future<void> openDeveloperTools(InAppWebViewController controller) async {
    // This would open Chrome DevTools in a separate window
    // For now, we'll inject a basic console
    await controller.evaluateJavascript(source: '''
      if (!window.titanDevTools) {
        window.titanDevTools = {
          console: {
            log: function(...args) {
              window.flutter_inappwebview.callHandler('devConsoleLog', args.join(' '));
            },
            error: function(...args) {
              window.flutter_inappwebview.callHandler('devConsoleError', args.join(' '));
            },
            warn: function(...args) {
              window.flutter_inappwebview.callHandler('devConsoleWarn', args.join(' '));
            }
          }
        };
        
        // Override console methods
        const originalLog = console.log;
        const originalError = console.error;
        const originalWarn = console.warn;
        
        console.log = function(...args) {
          originalLog.apply(console, args);
          window.titanDevTools.console.log(...args);
        };
        
        console.error = function(...args) {
          originalError.apply(console, args);
          window.titanDevTools.console.error(...args);
        };
        
        console.warn = function(...args) {
          originalWarn.apply(console, args);
          window.titanDevTools.console.warn(...args);
        };
      }
    ''');
  }
  
  static void toggleJavaScript() {
    _javascriptEnabled = !_javascriptEnabled;
    StorageService.setSetting('javascript_enabled', _javascriptEnabled);
  }
  
  static void toggleAdBlock() {
    _adBlockEnabled = !_adBlockEnabled;
    StorageService.setSetting('adblock_enabled', _adBlockEnabled);
  }
  
  static bool get isJavaScriptEnabled => _javascriptEnabled;
  static bool get isAdBlockEnabled => _adBlockEnabled;
}