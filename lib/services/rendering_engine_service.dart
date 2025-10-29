import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum RenderingEngine {
  webkit,
  blink,
  gecko,
  custom,
}

enum RenderingMode {
  standard,
  mobile,
  desktop,
  reader,
  accessibility,
}

class RenderingSettings {
  final RenderingEngine engine;
  final RenderingMode mode;
  final double zoomLevel;
  final bool enableJavaScript;
  final bool enableImages;
  final bool enableCSS;
  final bool enableWebGL;
  final bool enableCanvas;
  final bool enableSVG;
  final bool enableFonts;
  final bool enableAnimations;
  final bool enableVideoAutoplay;
  final bool enableAudioAutoplay;
  final String userAgent;
  final Map<String, String> customCSS;
  final Color backgroundColor;
  final TextDirection textDirection;
  
  const RenderingSettings({
    this.engine = RenderingEngine.webkit,
    this.mode = RenderingMode.standard,
    this.zoomLevel = 1.0,
    this.enableJavaScript = true,
    this.enableImages = true,
    this.enableCSS = true,
    this.enableWebGL = true,
    this.enableCanvas = true,
    this.enableSVG = true,
    this.enableFonts = true,
    this.enableAnimations = true,
    this.enableVideoAutoplay = false,
    this.enableAudioAutoplay = false,
    this.userAgent = 'TitanBrowser/1.0.0',
    this.customCSS = const {},
    this.backgroundColor = Colors.white,
    this.textDirection = TextDirection.ltr,
  });
  
  RenderingSettings copyWith({
    RenderingEngine? engine,
    RenderingMode? mode,
    double? zoomLevel,
    bool? enableJavaScript,
    bool? enableImages,
    bool? enableCSS,
    bool? enableWebGL,
    bool? enableCanvas,
    bool? enableSVG,
    bool? enableFonts,
    bool? enableAnimations,
    bool? enableVideoAutoplay,
    bool? enableAudioAutoplay,
    String? userAgent,
    Map<String, String>? customCSS,
    Color? backgroundColor,
    TextDirection? textDirection,
  }) {
    return RenderingSettings(
      engine: engine ?? this.engine,
      mode: mode ?? this.mode,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      enableJavaScript: enableJavaScript ?? this.enableJavaScript,
      enableImages: enableImages ?? this.enableImages,
      enableCSS: enableCSS ?? this.enableCSS,
      enableWebGL: enableWebGL ?? this.enableWebGL,
      enableCanvas: enableCanvas ?? this.enableCanvas,
      enableSVG: enableSVG ?? this.enableSVG,
      enableFonts: enableFonts ?? this.enableFonts,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableVideoAutoplay: enableVideoAutoplay ?? this.enableVideoAutoplay,
      enableAudioAutoplay: enableAudioAutoplay ?? this.enableAudioAutoplay,
      userAgent: userAgent ?? this.userAgent,
      customCSS: customCSS ?? this.customCSS,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textDirection: textDirection ?? this.textDirection,
    );
  }
}

class RenderingEngineService {
  static final Map<String, RenderingSettings> _tabSettings = {};
  static final Map<String, InAppWebViewController> _controllers = {};
  static RenderingSettings _defaultSettings = const RenderingSettings();
  
  static void init() {
    _setupDefaultSettings();
  }
  
  static void _setupDefaultSettings() {
    // Initialize default rendering settings
  }
  
  static void setDefaultSettings(RenderingSettings settings) {
    _defaultSettings = settings;
  }
  
  static RenderingSettings getDefaultSettings() {
    return _defaultSettings;
  }
  
  // Tab-specific rendering settings
  static void setTabSettings(String tabId, RenderingSettings settings) {
    _tabSettings[tabId] = settings;
    _applySettingsToTab(tabId, settings);
  }
  
  static RenderingSettings getTabSettings(String tabId) {
    return _tabSettings[tabId] ?? _defaultSettings;
  }
  
  static void removeTabSettings(String tabId) {
    _tabSettings.remove(tabId);
    _controllers.remove(tabId);
  }
  
  static void registerController(String tabId, InAppWebViewController controller) {
    _controllers[tabId] = controller;
    final settings = getTabSettings(tabId);
    _applySettingsToController(controller, settings);
  }
  
  static void _applySettingsToTab(String tabId, RenderingSettings settings) {
    final controller = _controllers[tabId];
    if (controller != null) {
      _applySettingsToController(controller, settings);
    }
  }
  
  static Future<void> _applySettingsToController(
    InAppWebViewController controller,
    RenderingSettings settings,
  ) async {
    try {
      // Apply zoom level
      await controller.setZoomScale(zoomScale: settings.zoomLevel);
      
      // Apply custom CSS
      if (settings.customCSS.isNotEmpty) {
        await _injectCustomCSS(controller, settings.customCSS);
      }
      
      // Apply rendering mode specific settings
      await _applyRenderingMode(controller, settings.mode);
      
      // Apply accessibility settings
      if (settings.mode == RenderingMode.accessibility) {
        await _applyAccessibilitySettings(controller);
      }
      
      // Apply reader mode settings
      if (settings.mode == RenderingMode.reader) {
        await _applyReaderModeSettings(controller);
      }
    } catch (e) {
      print('Failed to apply rendering settings: $e');
    }
  }
  
  static Future<void> _injectCustomCSS(
    InAppWebViewController controller,
    Map<String, String> customCSS,
  ) async {
    final cssRules = customCSS.entries
        .map((entry) => '${entry.key} { ${entry.value} }')
        .join('\n');
    
    final script = '''
      (function() {
        var style = document.createElement('style');
        style.type = 'text/css';
        style.innerHTML = `$cssRules`;
        document.head.appendChild(style);
      })();
    ''';
    
    await controller.evaluateJavascript(source: script);
  }
  
  static Future<void> _applyRenderingMode(
    InAppWebViewController controller,
    RenderingMode mode,
  ) async {
    switch (mode) {
      case RenderingMode.mobile:
        await _applyMobileMode(controller);
        break;
      case RenderingMode.desktop:
        await _applyDesktopMode(controller);
        break;
      case RenderingMode.reader:
        await _applyReaderModeSettings(controller);
        break;
      case RenderingMode.accessibility:
        await _applyAccessibilitySettings(controller);
        break;
      case RenderingMode.standard:
      default:
        // Standard mode - no special modifications
        break;
    }
  }
  
  static Future<void> _applyMobileMode(InAppWebViewController controller) async {
    const script = '''
      (function() {
        // Set mobile viewport
        var viewport = document.querySelector('meta[name="viewport"]');
        if (!viewport) {
          viewport = document.createElement('meta');
          viewport.name = 'viewport';
          document.head.appendChild(viewport);
        }
        viewport.content = 'width=device-width, initial-scale=1.0, user-scalable=yes';
        
        // Add mobile-specific CSS
        var style = document.createElement('style');
        style.innerHTML = `
          body { 
            font-size: 16px !important;
            line-height: 1.5 !important;
            -webkit-text-size-adjust: 100% !important;
          }
          img { 
            max-width: 100% !important;
            height: auto !important;
          }
          table {
            width: 100% !important;
            overflow-x: auto !important;
          }
        `;
        document.head.appendChild(style);
      })();
    ''';
    
    await controller.evaluateJavascript(source: script);
  }
  
  static Future<void> _applyDesktopMode(InAppWebViewController controller) async {
    const script = '''
      (function() {
        // Set desktop viewport
        var viewport = document.querySelector('meta[name="viewport"]');
        if (viewport) {
          viewport.content = 'width=1024';
        }
        
        // Add desktop-specific CSS
        var style = document.createElement('style');
        style.innerHTML = `
          body { 
            min-width: 1024px !important;
          }
        `;
        document.head.appendChild(style);
      })();
    ''';
    
    await controller.evaluateJavascript(source: script);
  }
  
  static Future<void> _applyReaderModeSettings(InAppWebViewController controller) async {
    const script = '''
      (function() {
        // Reader mode implementation
        var readerCSS = `
          body {
            font-family: Georgia, 'Times New Roman', serif !important;
            font-size: 18px !important;
            line-height: 1.6 !important;
            max-width: 800px !important;
            margin: 0 auto !important;
            padding: 20px !important;
            background-color: #f9f9f9 !important;
            color: #333 !important;
          }
          
          h1, h2, h3, h4, h5, h6 {
            font-family: 'Helvetica Neue', Arial, sans-serif !important;
            color: #222 !important;
            margin-top: 30px !important;
            margin-bottom: 15px !important;
          }
          
          p {
            margin-bottom: 15px !important;
            text-align: justify !important;
          }
          
          img {
            max-width: 100% !important;
            height: auto !important;
            margin: 20px 0 !important;
            border-radius: 8px !important;
          }
          
          a {
            color: #0066cc !important;
            text-decoration: underline !important;
          }
          
          blockquote {
            border-left: 4px solid #ddd !important;
            margin: 20px 0 !important;
            padding-left: 20px !important;
            font-style: italic !important;
          }
          
          code {
            background-color: #f0f0f0 !important;
            padding: 2px 4px !important;
            border-radius: 3px !important;
            font-family: 'Courier New', monospace !important;
          }
          
          pre {
            background-color: #f0f0f0 !important;
            padding: 15px !important;
            border-radius: 5px !important;
            overflow-x: auto !important;
          }
          
          /* Hide non-content elements */
          nav, aside, footer, .sidebar, .advertisement, .social-share {
            display: none !important;
          }
        `;
        
        var style = document.createElement('style');
        style.innerHTML = readerCSS;
        document.head.appendChild(style);
        
        // Extract main content
        var content = document.querySelector('article, main, .content, .post, .entry');
        if (!content) {
          // Fallback: find the element with most text content
          var elements = document.querySelectorAll('div, section');
          var maxLength = 0;
          for (var i = 0; i < elements.length; i++) {
            var textLength = elements[i].textContent.length;
            if (textLength > maxLength) {
              maxLength = textLength;
              content = elements[i];
            }
          }
        }
        
        if (content) {
          document.body.innerHTML = '';
          document.body.appendChild(content);
        }
      })();
    ''';
    
    await controller.evaluateJavascript(source: script);
  }
  
  static Future<void> _applyAccessibilitySettings(InAppWebViewController controller) async {
    const script = '''
      (function() {
        // Accessibility enhancements
        var accessibilityCSS = `
          * {
            outline: 2px solid transparent !important;
            transition: outline 0.2s ease !important;
          }
          
          *:focus {
            outline: 2px solid #0066cc !important;
            outline-offset: 2px !important;
          }
          
          body {
            font-size: 18px !important;
            line-height: 1.8 !important;
            font-family: Arial, sans-serif !important;
          }
          
          h1, h2, h3, h4, h5, h6 {
            font-weight: bold !important;
            margin-top: 30px !important;
            margin-bottom: 15px !important;
          }
          
          a {
            text-decoration: underline !important;
            color: #0066cc !important;
          }
          
          a:hover, a:focus {
            background-color: #e6f3ff !important;
            padding: 2px !important;
          }
          
          button {
            min-height: 44px !important;
            min-width: 44px !important;
            padding: 8px 16px !important;
            border: 2px solid #333 !important;
            background-color: #f0f0f0 !important;
            cursor: pointer !important;
          }
          
          button:hover, button:focus {
            background-color: #0066cc !important;
            color: white !important;
          }
          
          input, textarea, select {
            min-height: 44px !important;
            padding: 8px !important;
            border: 2px solid #333 !important;
            font-size: 16px !important;
          }
          
          img {
            border: 1px solid #ddd !important;
          }
          
          /* High contrast mode */
          @media (prefers-contrast: high) {
            body {
              background-color: white !important;
              color: black !important;
            }
            
            a {
              color: #0000ee !important;
            }
            
            a:visited {
              color: #551a8b !important;
            }
          }
          
          /* Reduced motion */
          @media (prefers-reduced-motion: reduce) {
            *, *::before, *::after {
              animation-duration: 0.01ms !important;
              animation-iteration-count: 1 !important;
              transition-duration: 0.01ms !important;
            }
          }
        `;
        
        var style = document.createElement('style');
        style.innerHTML = accessibilityCSS;
        document.head.appendChild(style);
        
        // Add ARIA labels where missing
        var images = document.querySelectorAll('img:not([alt])');
        for (var i = 0; i < images.length; i++) {
          images[i].setAttribute('alt', 'Image');
        }
        
        // Add skip links
        var skipLink = document.createElement('a');
        skipLink.href = '#main-content';
        skipLink.textContent = 'Skip to main content';
        skipLink.style.cssText = `
          position: absolute;
          top: -40px;
          left: 6px;
          background: #000;
          color: #fff;
          padding: 8px;
          text-decoration: none;
          z-index: 1000;
        `;
        skipLink.addEventListener('focus', function() {
          this.style.top = '6px';
        });
        skipLink.addEventListener('blur', function() {
          this.style.top = '-40px';
        });
        
        document.body.insertBefore(skipLink, document.body.firstChild);
        
        // Add main content landmark if missing
        var main = document.querySelector('main');
        if (!main) {
          main = document.createElement('main');
          main.id = 'main-content';
          while (document.body.firstChild !== skipLink.nextSibling) {
            main.appendChild(document.body.firstChild.nextSibling);
          }
          document.body.appendChild(main);
        }
      })();
    ''';
    
    await controller.evaluateJavascript(source: script);
  }
  
  // Zoom controls
  static Future<void> zoomIn(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      final currentSettings = getTabSettings(tabId);
      final newZoom = (currentSettings.zoomLevel * 1.2).clamp(0.5, 3.0);
      final newSettings = currentSettings.copyWith(zoomLevel: newZoom);
      setTabSettings(tabId, newSettings);
    }
  }
  
  static Future<void> zoomOut(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      final currentSettings = getTabSettings(tabId);
      final newZoom = (currentSettings.zoomLevel / 1.2).clamp(0.5, 3.0);
      final newSettings = currentSettings.copyWith(zoomLevel: newZoom);
      setTabSettings(tabId, newSettings);
    }
  }
  
  static Future<void> resetZoom(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      final currentSettings = getTabSettings(tabId);
      final newSettings = currentSettings.copyWith(zoomLevel: 1.0);
      setTabSettings(tabId, newSettings);
    }
  }
  
  // Screenshot and printing
  static Future<Uint8List?> takeScreenshot(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        return await controller.takeScreenshot();
      } catch (e) {
        print('Failed to take screenshot: $e');
        return null;
      }
    }
    return null;
  }
  
  static Future<void> printPage(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        // Print functionality would be implemented here
        // This is platform-specific
      } catch (e) {
        print('Failed to print page: $e');
      }
    }
  }
  
  // Performance monitoring
  static Future<Map<String, dynamic>> getPerformanceMetrics(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        final result = await controller.evaluateJavascript(source: '''
          (function() {
            var performance = window.performance;
            var navigation = performance.getEntriesByType('navigation')[0];
            var paint = performance.getEntriesByType('paint');
            
            return {
              loadTime: navigation ? navigation.loadEventEnd - navigation.fetchStart : 0,
              domContentLoaded: navigation ? navigation.domContentLoadedEventEnd - navigation.fetchStart : 0,
              firstPaint: paint.find(p => p.name === 'first-paint')?.startTime || 0,
              firstContentfulPaint: paint.find(p => p.name === 'first-contentful-paint')?.startTime || 0,
              memoryUsage: performance.memory ? {
                used: performance.memory.usedJSHeapSize,
                total: performance.memory.totalJSHeapSize,
                limit: performance.memory.jsHeapSizeLimit
              } : null
            };
          })();
        ''');
        
        return Map<String, dynamic>.from(result ?? {});
      } catch (e) {
        print('Failed to get performance metrics: $e');
        return {};
      }
    }
    return {};
  }
  
  // Cleanup
  static void cleanup() {
    _tabSettings.clear();
    _controllers.clear();
  }
}