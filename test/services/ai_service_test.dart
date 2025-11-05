import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/ai_service.dart';
import '../../lib/models/ai_task.dart';
import '../../lib/core/service_locator.dart';

// Generate mocks
@GenerateMocks([AIService])
import 'ai_service_test.mocks.dart';

void main() {
  group('AIService Tests', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('should initialize AI service correctly', () {
      expect(aiService, isNotNull);
      expect(aiService.isInitialized, isFalse);
    });

    test('should process text analysis task', () async {
      const testText = 'This is a test text for analysis';
      
      final result = await aiService.analyzeText(testText);
      
      expect(result, isNotNull);
      expect(result.confidence, greaterThan(0.0));
      expect(result.confidence, lessThanOrEqualTo(1.0));
    });

    test('should handle web content summarization', () async {
      const testContent = '''
        This is a long article about artificial intelligence.
        It discusses various aspects of AI including machine learning,
        natural language processing, and computer vision.
        The article provides insights into current trends and future possibilities.
      ''';
      
      final summary = await aiService.summarizeContent(testContent);
      
      expect(summary, isNotNull);
      expect(summary.length, lessThan(testContent.length));
      expect(summary, isNotEmpty);
    });

    test('should detect language correctly', () async {
      const englishText = 'Hello, how are you today?';
      const spanishText = 'Hola, ¿cómo estás hoy?';
      
      final englishResult = await aiService.detectLanguage(englishText);
      final spanishResult = await aiService.detectLanguage(spanishText);
      
      expect(englishResult.language, equals('en'));
      expect(spanishResult.language, equals('es'));
      expect(englishResult.confidence, greaterThan(0.8));
      expect(spanishResult.confidence, greaterThan(0.8));
    });

    test('should handle AI task queue', () async {
      final task1 = AITask(
        id: '1',
        type: AITaskType.textAnalysis,
        data: {'text': 'Test 1'},
        priority: TaskPriority.high,
      );
      
      final task2 = AITask(
        id: '2',
        type: AITaskType.contentSummarization,
        data: {'content': 'Test 2'},
        priority: TaskPriority.low,
      );
      
      aiService.addTask(task1);
      aiService.addTask(task2);
      
      expect(aiService.queueLength, equals(2));
      
      final nextTask = aiService.getNextTask();
      expect(nextTask?.id, equals('1')); // High priority first
    });

    test('should handle errors gracefully', () async {
      expect(
        () async => await aiService.analyzeText(''),
        throwsA(isA<ArgumentError>()),
      );
      
      expect(
        () async => await aiService.summarizeContent(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should manage AI model loading', () async {
      expect(aiService.isModelLoaded, isFalse);
      
      await aiService.loadModel('gpt-3.5-turbo');
      
      expect(aiService.isModelLoaded, isTrue);
      expect(aiService.currentModel, equals('gpt-3.5-turbo'));
    });

    test('should handle concurrent requests', () async {
      final futures = List.generate(5, (index) => 
        aiService.analyzeText('Test text $index')
      );
      
      final results = await Future.wait(futures);
      
      expect(results.length, equals(5));
      for (final result in results) {
        expect(result, isNotNull);
        expect(result.confidence, greaterThan(0.0));
      }
    });
  });
}