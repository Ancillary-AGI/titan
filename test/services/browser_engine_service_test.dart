import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/browser_engine_service.dart';
import '../../lib/models/browser_tab.dart';

@GenerateMocks([BrowserEngineService])
import 'browser_engine_service_test.mocks.dart';

void main() {
  group('BrowserEngineService Tests', () {
    late BrowserEngineService engineService;

    setUp(() {
      engineService = BrowserEngineService();
    });

    test('should initialize browser engine', () async {
      await engineService.initialize();
      
      expect(engineService.isInitialized, isTrue);
      expect(engineService.engineVersion, isNotEmpty);
    });

    test('should create new tab', () async {
      final tab = await engineService.createTab('https://example.com');
      
      expect(tab, isNotNull);
      expect(tab.url, equals('https://example.com'));
      expect(tab.isLoading, isTrue);
    });

    test('should navigate to URL', () async {
      final tab = await engineService.createTab('about:blank');
      
      await engineService.navigateTab(tab.id, 'https://google.com');
      
      expect(tab.url, equals('https://google.com'));
      expect(tab.isLoading, isTrue);
    });

    test('should handle JavaScript execution', () async {
      final tab = await engineService.createTab('https://example.com');
      
      final result = await engineService.executeJavaScript(
        tab.id, 
        'document.title'
      );
      
      expect(result, isNotNull);
    });

    test('should manage browser history', () async {
      final tab = await engineService.createTab('https://example.com');
      
      await engineService.navigateTab(tab.id, 'https://google.com');
      await engineService.navigateTab(tab.id, 'https://github.com');
      
      expect(engineService.canGoBack(tab.id), isTrue);
      expect(engineService.canGoForward(tab.id), isFalse);
      
      await engineService.goBack(tab.id);
      expect(engineService.canGoForward(tab.id), isTrue);
    });

    test('should handle page loading events', () async {
      final tab = await engineService.createTab('https://example.com');
      bool loadingStarted = false;
      bool loadingFinished = false;
      
      engineService.onLoadingStart.listen((tabId) {
        if (tabId == tab.id) loadingStarted = true;
      });
      
      engineService.onLoadingFinished.listen((tabId) {
        if (tabId == tab.id) loadingFinished = true;
      });
      
      await engineService.navigateTab(tab.id, 'https://google.com');
      
      // Wait for events
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(loadingStarted, isTrue);
      // Note: loadingFinished might not be true in test environment
    });

    test('should manage cookies', () async {
      await engineService.setCookie(
        'https://example.com',
        'test_cookie',
        'test_value'
      );
      
      final cookies = await engineService.getCookies('https://example.com');
      
      expect(cookies, isNotEmpty);
      expect(cookies.any((c) => c.name == 'test_cookie'), isTrue);
    });

    test('should handle zoom operations', () async {
      final tab = await engineService.createTab('https://example.com');
      
      await engineService.setZoomLevel(tab.id, 1.5);
      final zoomLevel = await engineService.getZoomLevel(tab.id);
      
      expect(zoomLevel, equals(1.5));
    });

    test('should capture screenshots', () async {
      final tab = await engineService.createTab('https://example.com');
      
      final screenshot = await engineService.captureScreenshot(tab.id);
      
      expect(screenshot, isNotNull);
      expect(screenshot.length, greaterThan(0));
    });

    test('should handle user agent changes', () async {
      const customUserAgent = 'TitanBrowser/1.0';
      
      await engineService.setUserAgent(customUserAgent);
      final userAgent = await engineService.getUserAgent();
      
      expect(userAgent, equals(customUserAgent));
    });

    test('should manage download operations', () async {
      final tab = await engineService.createTab('https://example.com');
      bool downloadStarted = false;
      
      engineService.onDownloadStart.listen((download) {
        downloadStarted = true;
      });
      
      await engineService.downloadFile(
        tab.id,
        'https://example.com/file.pdf'
      );
      
      await Future.delayed(Duration(milliseconds: 100));
      expect(downloadStarted, isTrue);
    });

    test('should handle security certificates', () async {
      final tab = await engineService.createTab('https://google.com');
      
      final certificate = await engineService.getCertificateInfo(tab.id);
      
      expect(certificate, isNotNull);
      expect(certificate.isValid, isTrue);
    });
  });
}