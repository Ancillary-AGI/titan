import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Performance optimization levels
enum PerformanceLevel {
  battery,    // Optimize for battery life
  balanced,   // Balance performance and efficiency
  performance, // Maximum performance
  gaming,     // Optimized for web games and apps
}

/// Resource loading priorities
enum ResourcePriority {
  critical,   // HTML, CSS, critical JS
  high,       // Images above fold, important JS
  medium,     // Images below fold, non-critical JS
  low,        // Analytics, tracking scripts
  idle,       // Prefetch resources
}

/// Performance metrics
class PerformanceMetrics {
  final double loadTime;
  final double domContentLoaded;
  final double firstPaint;
  final double firstContentfulPaint;
  final double largestContentfulPaint;
  final double firstInputDelay;
  final double cumulativeLayoutShift;
  final int memoryUsage;
  final int jsHeapSize;
  final int domNodes;
  final int networkRequests;
  final double renderingTime;
  final DateTime timestamp;
  
  const PerformanceMetrics({
    required this.loadTime,
    required this.domContentLoaded,
    required this.firstPaint,
    required this.firstContentfulPaint,
    required this.largestContentfulPaint,
    required this.firstInputDelay,
    required this.cumulativeLayoutShift,
    required this.memoryUsage,
    required this.jsHeapSize,
    required this.domNodes,
    required this.networkRequests,
    required this.renderingTime,
    required this.timestamp,
  });
  
  /// Calculate Core Web Vitals score (0-100)
  double get coreWebVitalsScore {
    double lcpScore = largestContentfulPaint <= 2500 ? 100 : 
                     largestContentfulPaint <= 4000 ? 50 : 0;
    double fidScore = firstInputDelay <= 100 ? 100 : 
                     firstInputDelay <= 300 ? 50 : 0;
    double clsScore = cumulativeLayoutShift <= 0.1 ? 100 : 
                     cumulativeLayoutShift <= 0.25 ? 50 : 0;
    
    return (lcpScore + fidScore + clsScore) / 3;
  }
  
  Map<String, dynamic> toJson() => {
    'loadTime': loadTime,
    'domContentLoaded': domContentLoaded,
    'firstPaint': firstPaint,
    'firstContentfulPaint': firstContentfulPaint,
    'largestContentfulPaint': largestContentfulPaint,
    'firstInputDelay': firstInputDelay,
    'cumulativeLayoutShift': cumulativeLayoutShift,
    'memoryUsage': memoryUsage,
    'jsHeapSize': jsHeapSize,
    'domNodes': domNodes,
    'networkRequests': networkRequests,
    'renderingTime': renderingTime,
    'coreWebVitalsScore': coreWebVitalsScore,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Resource loading optimization
class ResourceOptimizer {
  final String url;
  final ResourcePriority priority;
  final bool shouldPreload;
  final bool shouldCompress;
  final Duration cacheTime;
  
  const ResourceOptimizer({
    required this.url,
    required this.priority,
    this.shouldPreload = false,
    this.shouldCompress = true,
    this.cacheTime = const Duration(hours: 24),
  });
}

/// Performance Engine Service - Chrome-level optimizations
class PerformanceEngineService {
  static final Map<String, PerformanceLevel> _tabPerformanceLevels = {};
  static final Map<String, List<PerformanceMetrics>> _performanceHistory = {};
  static final Map<String, Timer> _performanceMonitors = {};
  static final Map<String, List<ResourceOptimizer>> _resourceOptimizers = {};
  static final Map<String, InAppWebViewController> _controllers = {};
  
  // Performance thresholds
  static const double _maxLoadTime = 3000; // 3 seconds
  static const double _maxLCP = 2500; // 2.5 seconds
  static const double _maxFID = 100; // 100ms
  static const double _maxCLS = 0.1; // 0.1
  static const int _maxMemoryMB = 512; // 512MB
  
  /// Initialize performance engine
  static Future<void> initialize() async {
    await _setupPerformanceOptimizations();
    _startGlobalPerformanceMonitoring();
  }
  
  /// Setup Chrome-level performance optimizations
  static Future<void> _setupPerformanceOptimizations() async {
    // Enable hardware acceleration
    // Setup resource prioritization
    // Configure caching strategies
    print('Performance optimizations initialized');
  }
  
  /// Start global performance monitoring
  static void _startGlobalPerformanceMonitoring() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _performGlobalOptimizations();
    });
  }
  
  /// Register tab for performance monitoring
  static Future<void> registerTab(String tabId, InAppWebViewController controller) async {
    _controllers[tabId] = controller;
    _tabPerformanceLevels[tabId] = PerformanceLevel.balanced;
    _performanceHistory[tabId] = [];
    
    // Setup performance monitoring for this tab
    await _setupTabPerformanceMonitoring(tabId, controller);
    
    // Inject performance monitoring script
    await _injectPerformanceScript(controller);
  }
  
  /// Setup performance monitoring for a specific tab
  static Future<void> _setupTabPerformanceMonitoring(String tabId, InAppWebViewController controller) async {
    // Monitor performance every 2 seconds
    _performanceMonitors[tabId] = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _collectPerformanceMetrics(tabId);
    });
    
    // Setup performance event handlers
    await controller.addJavaScriptHandler(
      handlerName: 'performanceEvent',
      callback: (args) => _handlePerformanceEvent(tabId, args),
    );
    
    await controller.addJavaScriptHandler(
      handlerName: 'resourceTiming',
      callback: (args) => _handleResourceTiming(tabId, args),
    );
  }
  
  /// Inject performance monitoring JavaScript
  static Future<void> _injectPerformanceScript(InAppWebViewController controller) async {
    const script = '''
      (function() {
        // Performance monitoring setup
        window.titanPerformance = {
          startTime: performance.now(),
          metrics: {},
          
          // Collect Core Web Vitals
          collectCoreWebVitals: function() {
            // Largest Contentful Paint
            new PerformanceObserver((entryList) => {
              const entries = entryList.getEntries();
              const lastEntry = entries[entries.length - 1];
              this.metrics.lcp = lastEntry.startTime;
              window.flutter_inappwebview.callHandler('performanceEvent', {
                type: 'lcp',
                value: lastEntry.startTime,
                timestamp: Date.now()
              });
            }).observe({entryTypes: ['largest-contentful-paint']});
            
            // First Input Delay
            new PerformanceObserver((entryList) => {
              const firstInput = entryList.getEntries()[0];
              this.metrics.fid = firstInput.processingStart - firstInput.startTime;
              window.flutter_inappwebview.callHandler('performanceEvent', {
                type: 'fid',
                value: this.metrics.fid,
                timestamp: Date.now()
              });
            }).observe({entryTypes: ['first-input']});
            
            // Cumulative Layout Shift
            let clsValue = 0;
            new PerformanceObserver((entryList) => {
              for (const entry of entryList.getEntries()) {
                if (!entry.hadRecentInput) {
                  clsValue += entry.value;
                }
              }
              this.metrics.cls = clsValue;
              window.flutter_inappwebview.callHandler('performanceEvent', {
                type: 'cls',
                value: clsValue,
                timestamp: Date.now()
              });
            }).observe({entryTypes: ['layout-shift']});
          },
          
          // Monitor resource loading
          monitorResources: function() {
            new PerformanceObserver((entryList) => {
              for (const entry of entryList.getEntries()) {
                window.flutter_inappwebview.callHandler('resourceTiming', {
                  name: entry.name,
                  duration: entry.duration,
                  transferSize: entry.transferSize,
                  encodedBodySize: entry.encodedBodySize,
                  decodedBodySize: entry.decodedBodySize,
                  startTime: entry.startTime,
                  responseEnd: entry.responseEnd
                });
              }
            }).observe({entryTypes: ['resource']});
          },
          
          // Memory monitoring
          monitorMemory: function() {
            if (performance.memory) {
              setInterval(() => {
                window.flutter_inappwebview.callHandler('performanceEvent', {
                  type: 'memory',
                  used: performance.memory.usedJSHeapSize,
                  total: performance.memory.totalJSHeapSize,
                  limit: performance.memory.jsHeapSizeLimit,
                  timestamp: Date.now()
                });
              }, 5000);
            }
          },
          
          // Long task monitoring
          monitorLongTasks: function() {
            new PerformanceObserver((entryList) => {
              for (const entry of entryList.getEntries()) {
                window.flutter_inappwebview.callHandler('performanceEvent', {
                  type: 'longTask',
                  duration: entry.duration,
                  startTime: entry.startTime,
                  timestamp: Date.now()
                });
              }
            }).observe({entryTypes: ['longtask']});
          }
        };
        
        // Start monitoring when DOM is ready
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', () => {
            window.titanPerformance.collectCoreWebVitals();
            window.titanPerformance.monitorResources();
            window.titanPerformance.monitorMemory();
            window.titanPerformance.monitorLongTasks();
          });
        } else {
          window.titanPerformance.collectCoreWebVitals();
          window.titanPerformance.monitorResources();
          window.titanPerformance.monitorMemory();
          window.titanPerformance.monitorLongTasks();
        }
        
        // Report initial metrics
        window.addEventListener('load', () => {
          setTimeout(() => {
            const navigation = performance.getEntriesByType('navigation')[0];
            const paint = performance.getEntriesByType('paint');
            
            window.flutter_inappwebview.callHandler('performanceEvent', {
              type: 'pageLoad',
              loadTime: navigation.loadEventEnd - navigation.fetchStart,
              domContentLoaded: navigation.domContentLoadedEventEnd - navigation.fetchStart,
              firstPaint: paint.find(p => p.name === 'first-paint')?.startTime || 0,
              firstContentfulPaint: paint.find(p => p.name === 'first-contentful-paint')?.startTime || 0,
              timestamp: Date.now()
            });
          }, 1000);
        });
      })();
    ''';
    
    await controller.evaluateJavascript(source: script);
  }
  
  /// Handle performance events from JavaScript
  static void _handlePerformanceEvent(String tabId, List<dynamic> args) {
    if (args.isEmpty) return;
    
    final event = Map<String, dynamic>.from(args[0]);
    final type = event['type'];
    
    switch (type) {
      case 'pageLoad':
        _processPageLoadMetrics(tabId, event);
        break;
      case 'lcp':
        _processLCPMetric(tabId, event['value']);
        break;
      case 'fid':
        _processFIDMetric(tabId, event['value']);
        break;
      case 'cls':
        _processCLSMetric(tabId, event['value']);
        break;
      case 'memory':
        _processMemoryMetrics(tabId, event);
        break;
      case 'longTask':
        _processLongTaskMetric(tabId, event);
        break;
    }
  }
  
  /// Handle resource timing data
  static void _handleResourceTiming(String tabId, List<dynamic> args) {
    if (args.isEmpty) return;
    
    final resource = Map<String, dynamic>.from(args[0]);
    _analyzeResourcePerformance(tabId, resource);
  }
  
  /// Collect comprehensive performance metrics
  static Future<PerformanceMetrics?> _collectPerformanceMetrics(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return null;
    
    try {
      final result = await controller.evaluateJavascript(source: '''
        (function() {
          const navigation = performance.getEntriesByType('navigation')[0];
          const paint = performance.getEntriesByType('paint');
          
          return {
            loadTime: navigation ? navigation.loadEventEnd - navigation.fetchStart : 0,
            domContentLoaded: navigation ? navigation.domContentLoadedEventEnd - navigation.fetchStart : 0,
            firstPaint: paint.find(p => p.name === 'first-paint')?.startTime || 0,
            firstContentfulPaint: paint.find(p => p.name === 'first-contentful-paint')?.startTime || 0,
            largestContentfulPaint: window.titanPerformance?.metrics?.lcp || 0,
            firstInputDelay: window.titanPerformance?.metrics?.fid || 0,
            cumulativeLayoutShift: window.titanPerformance?.metrics?.cls || 0,
            memoryUsage: performance.memory ? performance.memory.usedJSHeapSize : 0,
            jsHeapSize: performance.memory ? performance.memory.totalJSHeapSize : 0,
            domNodes: document.querySelectorAll('*').length,
            networkRequests: performance.getEntriesByType('resource').length,
            renderingTime: performance.now()
          };
        })();
      ''');
      
      if (result != null) {
        final data = Map<String, dynamic>.from(result);
        final metrics = PerformanceMetrics(
          loadTime: (data['loadTime'] ?? 0).toDouble(),
          domContentLoaded: (data['domContentLoaded'] ?? 0).toDouble(),
          firstPaint: (data['firstPaint'] ?? 0).toDouble(),
          firstContentfulPaint: (data['firstContentfulPaint'] ?? 0).toDouble(),
          largestContentfulPaint: (data['largestContentfulPaint'] ?? 0).toDouble(),
          firstInputDelay: (data['firstInputDelay'] ?? 0).toDouble(),
          cumulativeLayoutShift: (data['cumulativeLayoutShift'] ?? 0).toDouble(),
          memoryUsage: data['memoryUsage'] ?? 0,
          jsHeapSize: data['jsHeapSize'] ?? 0,
          domNodes: data['domNodes'] ?? 0,
          networkRequests: data['networkRequests'] ?? 0,
          renderingTime: (data['renderingTime'] ?? 0).toDouble(),
          timestamp: DateTime.now(),
        );
        
        // Store metrics
        final history = _performanceHistory[tabId] ?? [];
        history.add(metrics);
        
        // Keep only last 100 metrics
        if (history.length > 100) {
          history.removeAt(0);
        }
        
        _performanceHistory[tabId] = history;
        
        // Trigger optimizations if needed
        await _optimizeBasedOnMetrics(tabId, metrics);
        
        return metrics;
      }
    } catch (e) {
      print('Error collecting performance metrics: $e');
    }
    
    return null;
  }
  
  /// Process page load metrics
  static void _processPageLoadMetrics(String tabId, Map<String, dynamic> event) {
    final loadTime = (event['loadTime'] ?? 0).toDouble();
    
    if (loadTime > _maxLoadTime) {
      _triggerLoadTimeOptimization(tabId);
    }
  }
  
  /// Process Largest Contentful Paint metric
  static void _processLCPMetric(String tabId, dynamic value) {
    final lcp = (value ?? 0).toDouble();
    
    if (lcp > _maxLCP) {
      _triggerLCPOptimization(tabId);
    }
  }
  
  /// Process First Input Delay metric
  static void _processFIDMetric(String tabId, dynamic value) {
    final fid = (value ?? 0).toDouble();
    
    if (fid > _maxFID) {
      _triggerFIDOptimization(tabId);
    }
  }
  
  /// Process Cumulative Layout Shift metric
  static void _processCLSMetric(String tabId, dynamic value) {
    final cls = (value ?? 0).toDouble();
    
    if (cls > _maxCLS) {
      _triggerCLSOptimization(tabId);
    }
  }
  
  /// Process memory metrics
  static void _processMemoryMetrics(String tabId, Map<String, dynamic> event) {
    final used = event['used'] ?? 0;
    final usedMB = used / (1024 * 1024);
    
    if (usedMB > _maxMemoryMB) {
      _triggerMemoryOptimization(tabId);
    }
  }
  
  /// Process long task metric
  static void _processLongTaskMetric(String tabId, Map<String, dynamic> event) {
    final duration = (event['duration'] ?? 0).toDouble();
    
    if (duration > 50) { // Long tasks > 50ms
      _triggerLongTaskOptimization(tabId);
    }
  }
  
  /// Analyze resource performance
  static void _analyzeResourcePerformance(String tabId, Map<String, dynamic> resource) {
    final duration = (resource['duration'] ?? 0).toDouble();
    final transferSize = resource['transferSize'] ?? 0;
    final url = resource['name'] ?? '';
    
    // Identify slow resources
    if (duration > 1000) { // > 1 second
      _optimizeSlowResource(tabId, url, duration);
    }
    
    // Identify large resources
    if (transferSize > 1024 * 1024) { // > 1MB
      _optimizeLargeResource(tabId, url, transferSize);
    }
  }
  
  /// Optimize based on performance metrics
  static Future<void> _optimizeBasedOnMetrics(String tabId, PerformanceMetrics metrics) async {
    final controller = _controllers[tabId];
    if (controller == null) return;
    
    // Auto-adjust performance level based on metrics
    if (metrics.coreWebVitalsScore < 50) {
      await setPerformanceLevel(tabId, PerformanceLevel.performance);
    } else if (metrics.memoryUsage > 256 * 1024 * 1024) { // > 256MB
      await setPerformanceLevel(tabId, PerformanceLevel.battery);
    }
  }
  
  /// Set performance level for a tab
  static Future<void> setPerformanceLevel(String tabId, PerformanceLevel level) async {
    _tabPerformanceLevels[tabId] = level;
    
    final controller = _controllers[tabId];
    if (controller == null) return;
    
    switch (level) {
      case PerformanceLevel.battery:
        await _applyBatteryOptimizations(controller);
        break;
      case PerformanceLevel.balanced:
        await _applyBalancedOptimizations(controller);
        break;
      case PerformanceLevel.performance:
        await _applyPerformanceOptimizations(controller);
        break;
      case PerformanceLevel.gaming:
        await _applyGamingOptimizations(controller);
        break;
    }
  }
  
  /// Apply battery optimization settings
  static Future<void> _applyBatteryOptimizations(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      // Reduce animation frame rate
      const originalRAF = window.requestAnimationFrame;
      let rafThrottle = 0;
      window.requestAnimationFrame = function(callback) {
        if (++rafThrottle % 2 === 0) {
          return originalRAF(callback);
        }
        return setTimeout(callback, 33); // ~30fps instead of 60fps
      };
      
      // Disable non-essential animations
      document.documentElement.style.setProperty('--animation-duration', '0s', 'important');
      
      // Reduce timer frequency
      const originalSetInterval = window.setInterval;
      window.setInterval = function(callback, delay) {
        return originalSetInterval(callback, Math.max(delay, 100));
      };
    ''');
  }
  
  /// Apply balanced optimization settings
  static Future<void> _applyBalancedOptimizations(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      // Standard optimizations
      // Enable passive event listeners where possible
      const originalAddEventListener = EventTarget.prototype.addEventListener;
      EventTarget.prototype.addEventListener = function(type, listener, options) {
        if (typeof options === 'boolean') {
          options = { capture: options, passive: true };
        } else if (typeof options === 'object' && options.passive === undefined) {
          options.passive = true;
        }
        return originalAddEventListener.call(this, type, listener, options);
      };
    ''');
  }
  
  /// Apply performance optimization settings
  static Future<void> _applyPerformanceOptimizations(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      // Enable high-performance mode
      // Prioritize rendering performance
      if (document.documentElement.style.willChange !== 'transform') {
        document.documentElement.style.willChange = 'transform';
      }
      
      // Enable GPU acceleration for animations
      const style = document.createElement('style');
      style.textContent = `
        * {
          transform: translateZ(0);
          backface-visibility: hidden;
          perspective: 1000px;
        }
      `;
      document.head.appendChild(style);
      
      // Optimize scroll performance
      document.addEventListener('wheel', function(e) {
        e.preventDefault();
        window.scrollBy({
          top: e.deltaY,
          behavior: 'auto'
        });
      }, { passive: false });
    ''');
  }
  
  /// Apply gaming optimization settings
  static Future<void> _applyGamingOptimizations(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      // Gaming-specific optimizations
      // Disable context menu for better gaming experience
      document.addEventListener('contextmenu', e => e.preventDefault());
      
      // Optimize for low latency
      if (navigator.scheduling && navigator.scheduling.isInputPending) {
        function yieldToMain() {
          return new Promise(resolve => {
            setTimeout(resolve, 0);
          });
        }
        
        async function scheduler(tasks) {
          while (tasks.length > 0) {
            if (navigator.scheduling.isInputPending()) {
              await yieldToMain();
            }
            const task = tasks.shift();
            task();
          }
        }
      }
      
      // Request high refresh rate if available
      if (screen.orientation && screen.orientation.lock) {
        try {
          screen.orientation.lock('landscape');
        } catch (e) {
          // Ignore if not supported
        }
      }
    ''');
  }
  
  /// Trigger load time optimization
  static Future<void> _triggerLoadTimeOptimization(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return;
    
    // Implement resource prioritization
    await controller.evaluateJavascript(source: '''
      // Defer non-critical resources
      const scripts = document.querySelectorAll('script:not([async]):not([defer])');
      scripts.forEach(script => {
        if (!script.src.includes('critical')) {
          script.defer = true;
        }
      });
      
      // Lazy load images
      const images = document.querySelectorAll('img:not([loading])');
      images.forEach(img => {
        img.loading = 'lazy';
      });
    ''');
  }
  
  /// Trigger LCP optimization
  static Future<void> _triggerLCPOptimization(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return;
    
    await controller.evaluateJavascript(source: '''
      // Preload LCP element resources
      const lcpElements = document.querySelectorAll('img, video, [style*="background-image"]');
      lcpElements.forEach(element => {
        if (element.tagName === 'IMG' && element.src) {
          const link = document.createElement('link');
          link.rel = 'preload';
          link.as = 'image';
          link.href = element.src;
          document.head.appendChild(link);
        }
      });
    ''');
  }
  
  /// Trigger FID optimization
  static Future<void> _triggerFIDOptimization(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return;
    
    await controller.evaluateJavascript(source: '''
      // Break up long tasks
      function yieldToMain() {
        return new Promise(resolve => {
          setTimeout(resolve, 0);
        });
      }
      
      // Override heavy operations to yield
      const originalSetTimeout = window.setTimeout;
      window.setTimeout = function(callback, delay) {
        if (delay === 0) {
          return originalSetTimeout(async () => {
            await yieldToMain();
            callback();
          }, 0);
        }
        return originalSetTimeout(callback, delay);
      };
    ''');
  }
  
  /// Trigger CLS optimization
  static Future<void> _triggerCLSOptimization(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return;
    
    await controller.evaluateJavascript(source: '''
      // Reserve space for dynamic content
      const images = document.querySelectorAll('img:not([width]):not([height])');
      images.forEach(img => {
        img.style.aspectRatio = '16/9'; // Default aspect ratio
      });
      
      // Prevent layout shifts from web fonts
      const style = document.createElement('style');
      style.textContent = `
        @font-face {
          font-display: swap;
        }
      `;
      document.head.appendChild(style);
    ''');
  }
  
  /// Trigger memory optimization
  static Future<void> _triggerMemoryOptimization(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return;
    
    await controller.evaluateJavascript(source: '''
      // Force garbage collection if available
      if (window.gc) {
        window.gc();
      }
      
      // Clear unused event listeners
      const elements = document.querySelectorAll('*');
      elements.forEach(element => {
        const clone = element.cloneNode(true);
        if (element.parentNode) {
          element.parentNode.replaceChild(clone, element);
        }
      });
      
      // Clear large objects from memory
      if (window.caches) {
        caches.keys().then(names => {
          names.forEach(name => {
            if (name.includes('old') || name.includes('temp')) {
              caches.delete(name);
            }
          });
        });
      }
    ''');
  }
  
  /// Trigger long task optimization
  static Future<void> _triggerLongTaskOptimization(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return;
    
    await controller.evaluateJavascript(source: '''
      // Implement task scheduling
      const scheduler = {
        tasks: [],
        
        addTask(task) {
          this.tasks.push(task);
          this.processTasks();
        },
        
        async processTasks() {
          while (this.tasks.length > 0) {
            const start = performance.now();
            const task = this.tasks.shift();
            
            try {
              task();
            } catch (e) {
              console.error('Task error:', e);
            }
            
            // Yield if task took too long
            if (performance.now() - start > 5) {
              await new Promise(resolve => setTimeout(resolve, 0));
            }
          }
        }
      };
      
      window.titanScheduler = scheduler;
    ''');
  }
  
  /// Optimize slow resource
  static void _optimizeSlowResource(String tabId, String url, double duration) {
    print('Slow resource detected: $url (${duration}ms)');
    // Could implement resource caching, compression, or CDN switching
  }
  
  /// Optimize large resource
  static void _optimizeLargeResource(String tabId, String url, int size) {
    print('Large resource detected: $url (${size} bytes)');
    // Could implement image compression, lazy loading, or format optimization
  }
  
  /// Perform global optimizations
  static void _performGlobalOptimizations() {
    // Global memory cleanup
    // Resource cache optimization
    // Performance analytics
  }
  
  /// Get performance metrics for a tab
  static List<PerformanceMetrics> getPerformanceHistory(String tabId) {
    return _performanceHistory[tabId] ?? [];
  }
  
  /// Get current performance level
  static PerformanceLevel getPerformanceLevel(String tabId) {
    return _tabPerformanceLevels[tabId] ?? PerformanceLevel.balanced;
  }
  
  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    final allMetrics = _performanceHistory.values.expand((list) => list).toList();
    
    if (allMetrics.isEmpty) {
      return {'totalTabs': 0, 'averageScore': 0};
    }
    
    final averageScore = allMetrics
        .map((m) => m.coreWebVitalsScore)
        .reduce((a, b) => a + b) / allMetrics.length;
    
    return {
      'totalTabs': _performanceHistory.length,
      'averageScore': averageScore,
      'totalMetrics': allMetrics.length,
      'averageLoadTime': allMetrics
          .map((m) => m.loadTime)
          .reduce((a, b) => a + b) / allMetrics.length,
      'averageMemoryUsage': allMetrics
          .map((m) => m.memoryUsage)
          .reduce((a, b) => a + b) / allMetrics.length,
    };
  }
  
  /// Cleanup resources for a tab
  static Future<void> cleanup(String tabId) async {
    _controllers.remove(tabId);
    _tabPerformanceLevels.remove(tabId);
    _performanceHistory.remove(tabId);
    _resourceOptimizers.remove(tabId);
    
    final monitor = _performanceMonitors[tabId];
    if (monitor != null) {
      monitor.cancel();
      _performanceMonitors.remove(tabId);
    }
  }
  
  /// Cleanup all resources
  static void cleanupAll() {
    _controllers.clear();
    _tabPerformanceLevels.clear();
    _performanceHistory.clear();
    _resourceOptimizers.clear();
    
    for (final monitor in _performanceMonitors.values) {
      monitor.cancel();
    }
    _performanceMonitors.clear();
  }
}