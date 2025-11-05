import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/storage_service.dart';

@GenerateMocks([StorageService])
import 'storage_service_test.mocks.dart';

void main() {
  group('StorageService Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
    });

    test('should initialize storage service', () async {
      await storageService.initialize();
      
      expect(storageService.isInitialized, isTrue);
    });

    test('should store and retrieve data', () async {
      const key = 'test_key';
      const value = 'test_value';
      
      await storageService.store(key, value);
      final retrieved = await storageService.retrieve(key);
      
      expect(retrieved, equals(value));
    });

    test('should handle complex data types', () async {
      final complexData = {
        'string': 'value',
        'number': 42,
        'boolean': true,
        'list': [1, 2, 3],
        'map': {'nested': 'data'}
      };
      
      await storageService.storeJson('complex', complexData);
      final retrieved = await storageService.retrieveJson('complex');
      
      expect(retrieved, equals(complexData));
    });

    test('should manage browser history', () async {
      final historyEntry = HistoryEntry(
        url: 'https://example.com',
        title: 'Example Site',
        visitTime: DateTime.now(),
      );
      
      await storageService.addHistoryEntry(historyEntry);
      final history = await storageService.getHistory();
      
      expect(history, contains(historyEntry));
    });

    test('should handle bookmarks', () async {
      final bookmark = Bookmark(
        id: '1',
        title: 'Example',
        url: 'https://example.com',
        folder: 'General',
        createdAt: DateTime.now(),
      );
      
      await storageService.addBookmark(bookmark);
      final bookmarks = await storageService.getBookmarks();
      
      expect(bookmarks, contains(bookmark));
    });

    test('should manage cookies', () async {
      final cookie = Cookie(
        name: 'session',
        value: 'abc123',
        domain: 'example.com',
        path: '/',
        expiryDate: DateTime.now().add(Duration(days: 1)),
      );
      
      await storageService.storeCookie(cookie);
      final cookies = await storageService.getCookies('example.com');
      
      expect(cookies, contains(cookie));
    });

    test('should handle cache management', () async {
      const url = 'https://example.com/image.jpg';
      final imageData = List.generate(1000, (i) => i % 256);
      
      await storageService.cacheResource(url, imageData);
      final cached = await storageService.getCachedResource(url);
      
      expect(cached, equals(imageData));
    });

    test('should manage storage quotas', () async {
      final quota = await storageService.getStorageQuota();
      final usage = await storageService.getStorageUsage();
      
      expect(quota, greaterThan(0));
      expect(usage, greaterThanOrEqualTo(0));
      expect(usage, lessThanOrEqualTo(quota));
    });

    test('should handle data encryption', () async {
      const sensitiveData = 'password123';
      
      await storageService.storeEncrypted('password', sensitiveData);
      final decrypted = await storageService.retrieveEncrypted('password');
      
      expect(decrypted, equals(sensitiveData));
    });

    test('should support data export/import', () async {
      final testData = {
        'bookmarks': [
          {'title': 'Test', 'url': 'https://test.com'}
        ],
        'history': [
          {'url': 'https://example.com', 'title': 'Example'}
        ]
      };
      
      await storageService.importData(testData);
      final exported = await storageService.exportData();
      
      expect(exported['bookmarks'], isNotEmpty);
      expect(exported['history'], isNotEmpty);
    });

    test('should handle storage cleanup', () async {
      // Add some test data
      await storageService.store('temp1', 'data1');
      await storageService.store('temp2', 'data2');
      
      final sizeBefore = await storageService.getStorageUsage();
      
      await storageService.cleanup();
      
      final sizeAfter = await storageService.getStorageUsage();
      expect(sizeAfter, lessThanOrEqualTo(sizeBefore));
    });

    test('should manage offline storage', () async {
      const url = 'https://example.com/page.html';
      const content = '<html><body>Offline content</body></html>';
      
      await storageService.storeOfflinePage(url, content);
      final offlineContent = await storageService.getOfflinePage(url);
      
      expect(offlineContent, equals(content));
    });

    test('should handle concurrent operations', () async {
      final futures = List.generate(10, (i) => 
        storageService.store('key$i', 'value$i')
      );
      
      await Future.wait(futures);
      
      for (int i = 0; i < 10; i++) {
        final value = await storageService.retrieve('key$i');
        expect(value, equals('value$i'));
      }
    });

    test('should support data migration', () async {
      const oldVersion = 1;
      const newVersion = 2;
      
      await storageService.setDataVersion(oldVersion);
      
      final migrationNeeded = await storageService.needsMigration(newVersion);
      expect(migrationNeeded, isTrue);
      
      await storageService.migrateData(oldVersion, newVersion);
      
      final currentVersion = await storageService.getDataVersion();
      expect(currentVersion, equals(newVersion));
    });
  });
}