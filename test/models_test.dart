import 'package:flutter_test/flutter_test.dart';
import 'package:titan_browser/models/browser_tab.dart';
import 'package:titan_browser/models/ai_task.dart';

void main() {
  group('BrowserTab', () {
    test('toJson/fromJson roundtrip including incognito', () {
      final tab = BrowserTab(
        title: 'Test',
        url: 'https://example.com',
        isLoading: true,
        canGoBack: true,
        canGoForward: false,
        favicon: 'icon.png',
        incognito: true,
      );
      final json = tab.toJson();
      final parsed = BrowserTab.fromJson(json);
      expect(parsed.title, equals('Test'));
      expect(parsed.url, equals('https://example.com'));
      expect(parsed.isLoading, isTrue);
      expect(parsed.canGoBack, isTrue);
      expect(parsed.canGoForward, isFalse);
      expect(parsed.favicon, equals('icon.png'));
      expect(parsed.incognito, isTrue);
    });
  });

  group('AITask', () {
    test('toJson/fromJson roundtrip', () {
      final task = AITask(
        type: AITaskType.webSearch,
        description: 'Search for Flutter',
        parameters: {'query': 'Flutter'},
      );
      final json = task.toJson();
      final parsed = AITask.fromJson(json);
      expect(parsed.id, equals(task.id));
      expect(parsed.type, equals(AITaskType.webSearch));
      expect(parsed.description, equals('Search for Flutter'));
      expect(parsed.parameters['query'], equals('Flutter'));
      expect(parsed.status, equals(AITaskStatus.pending));
    });
  });
}
