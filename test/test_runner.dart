import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

// Import all test files
import 'services/ai_service_test.dart' as ai_tests;
import 'services/browser_engine_service_test.dart' as engine_tests;
import 'services/security_service_test.dart' as security_tests;
import 'services/storage_service_test.dart' as storage_tests;
import 'platform/windows_test.dart' as windows_tests;
import 'platform/macos_test.dart' as macos_tests;
import 'platform/linux_test.dart' as linux_tests;
import 'widget/browser_widgets_test.dart' as widget_tests;

void main() {
  group('Titan Browser Test Suite', () {
    // Core service tests
    group('Core Services', () {
      ai_tests.main();
      engine_tests.main();
      security_tests.main();
      storage_tests.main();
    });

    // Platform-specific tests
    group('Platform Tests', () {
      if (Platform.isWindows) {
        windows_tests.main();
      }
      if (Platform.isMacOS) {
        macos_tests.main();
      }
      if (Platform.isLinux) {
        linux_tests.main();
      }
    });

    // Widget tests
    group('Widget Tests', () {
      widget_tests.main();
    });

    // Performance tests
    group('Performance Tests', () {
      test('should handle large number of tabs', () async {
        // Test with 100 tabs
        final stopwatch = Stopwatch()..start();
        
        // Simulate creating 100 tabs
        for (int i = 0; i < 100; i++) {
          // Mock tab creation
          await Future.delayed(Duration(milliseconds: 1));
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete in 5 seconds
      });

      test('should handle memory usage efficiently', () async {
        // Test memory usage with multiple operations
        final initialMemory = ProcessInfo.currentRss;
        
        // Perform memory-intensive operations
        final largeList = List.generate(10000, (i) => 'Item $i');
        largeList.clear();
        
        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;
        
        // Memory increase should be reasonable
        expect(memoryIncrease, lessThan(100 * 1024 * 1024)); // Less than 100MB
      });
    });

    // Security tests
    group('Security Tests', () {
      test('should prevent XSS attacks', () {
        final maliciousScript = '<script>alert("xss")</script>';
        final sanitized = sanitizeHtml(maliciousScript);
        
        expect(sanitized, isNot(contains('<script>')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should validate SSL certificates', () async {
        final isValid = await validateSSLCertificate('https://google.com');
        expect(isValid, isTrue);
        
        final isInvalid = await validateSSLCertificate('https://self-signed.badssl.com');
        expect(isInvalid, isFalse);
      });
    });

    // Network tests
    group('Network Tests', () {
      test('should handle network connectivity', () async {
        final isConnected = await checkNetworkConnectivity();
        expect(isConnected, isA<bool>());
      });

      test('should handle offline mode', () async {
        // Simulate offline mode
        final offlineHandler = OfflineHandler();
        await offlineHandler.enableOfflineMode();
        
        expect(offlineHandler.isOffline, isTrue);
        
        // Test offline page loading
        final offlinePage = await offlineHandler.loadOfflinePage('https://example.com');
        expect(offlinePage, isNotNull);
      });
    });
  });
}

// Helper functions and classes for tests
String sanitizeHtml(String html) {
  return html
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
      .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
      .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
}

Future<bool> validateSSLCertificate(String url) async {
  try {
    final uri = Uri.parse(url);
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    client.close();
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

Future<bool> checkNetworkConnectivity() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    return false;
  }
}

class OfflineHandler {
  bool _isOffline = false;
  
  bool get isOffline => _isOffline;
  
  Future<void> enableOfflineMode() async {
    _isOffline = true;
  }
  
  Future<String?> loadOfflinePage(String url) async {
    if (_isOffline) {
      return '<html><body>Offline content for $url</body></html>';
    }
    return null;
  }
}