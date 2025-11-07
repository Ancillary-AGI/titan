import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/ai_task.dart';
import '../services/browser_bridge.dart';
import '../services/storage_service.dart';

class AIService {
  static const String _openAIBaseUrl = 'https://api.openai.com/v1';
  
  static String? _openAIKey;
  static String? _anthropicKey;
  static String _defaultModel = 'gpt-4';
  static double _defaultTemperature = 0.7;
  static int _maxTokens = 4000;
  static bool _isInitialized = false;
  
  // Task execution tracking
  static final Map<String, StreamController<AITask>> _taskStreams = {};
  static final Map<String, Timer> _taskTimers = {};
  
  static Future<void> init() async {
    if (_isInitialized) return;
    
    // Load API keys from storage
    _openAIKey = await StorageService.getString('openai_api_key');
    _anthropicKey = await StorageService.getString('anthropic_api_key');
    _defaultModel = await StorageService.getString('ai_default_model') ?? 'gpt-4';
    _defaultTemperature = await StorageService.getDouble('ai_temperature') ?? 0.7;
    _maxTokens = await StorageService.getInt('ai_max_tokens') ?? 4000;
    
    _isInitialized = true;
  }
  
  Future<void> initialize() async {
    await init();
  }
  
  static Future<void> setOpenAIKey(String key) async {
    _openAIKey = key;
    await StorageService.setString('openai_api_key', key);
  }
  
  static Future<void> setAnthropicKey(String key) async {
    _anthropicKey = key;
    await StorageService.setString('anthropic_api_key', key);
  }
  
  static Future<void> setDefaultModel(String model) async {
    _defaultModel = model;
    await StorageService.setString('ai_default_model', model);
  }
  
  static Future<void> setTemperature(double temperature) async {
    _defaultTemperature = temperature;
    await StorageService.setDouble('ai_temperature', temperature);
  }
  
  static Future<void> setMaxTokens(int tokens) async {
    _maxTokens = tokens;
    await StorageService.setInt('ai_max_tokens', tokens);
  }
  
  static bool get isConfigured => _openAIKey != null || _anthropicKey != null;
  static String get defaultModel => _defaultModel;
  static double get temperature => _defaultTemperature;
  static int get maxTokens => _maxTokens;
  
  static Future<String> generateResponse(String prompt, {
    String model = 'gpt-4',
    double temperature = 0.7,
  }) async {
    if (_openAIKey == null) {
      throw Exception('OpenAI API key not set');
    }
    
    final response = await http.post(
      Uri.parse('$_openAIBaseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openAIKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': temperature,
        'max_tokens': 2000,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate response: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> _makeOpenAIRequest(String model, List<Map<String, String>> messages, {double? temperature, int? maxTokens}) async {
    if (_openAIKey == null) {
      throw Exception('OpenAI API key not set');
    }
    final resp = await http.post(
      Uri.parse('$_openAIBaseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openAIKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature ?? _defaultTemperature,
        'max_tokens': maxTokens ?? _maxTokens,
      }),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('OpenAI request failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<String> generateText(String prompt, {String? model}) async {
    final data = await _makeOpenAIRequest(model ?? _defaultModel, [
      {'role': 'user', 'content': prompt},
    ]);
    return (data['choices']?[0]?['message']?['content'] as String?) ?? '';
  }
  
  static Stream<AITask> executeWebTaskStream(AITask task) async* {
    final controller = StreamController<AITask>();
    _taskStreams[task.id] = controller;
    
    try {
      // Start task
      task = task.copyWith(status: AITaskStatus.running, progress: 0.1);
      yield task;
      
      // Get current page context
      final pageContent = await _getCurrentPageContent();
      final pageContext = await _getCurrentPageContext();
      
      task = task.copyWith(progress: 0.2);
      yield task;
      
      // Build enhanced prompt with context
      String prompt = _buildEnhancedTaskPrompt(task, pageContent, pageContext);
      
      task = task.copyWith(progress: 0.3);
      yield task;
      
      // Generate AI response
      String response = await generateResponse(prompt, model: _defaultModel);
      
      task = task.copyWith(progress: 0.5);
      yield task;
      
      // Parse and validate action plan
      Map<String, dynamic> actionPlan = _parseAIResponse(response);
      
      task = task.copyWith(progress: 0.6);
      yield task;
      
      // Execute action plan with progress updates
      String result = await _executeActionPlanWithProgress(
        actionPlan, 
        task,
        (progress) {
          task = task.copyWith(progress: 0.6 + (progress * 0.4));
          controller.add(task);
        },
      );
      
      // Complete task
      task = task.copyWith(
        status: AITaskStatus.completed,
        result: result,
        completedAt: DateTime.now(),
        progress: 1.0,
      );
      yield task;
      
    } catch (e) {
      task = task.copyWith(
        status: AITaskStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
      yield task;
    } finally {
      _taskStreams.remove(task.id);
      controller.close();
    }
  }

  static Future<AITask> executeWebTask(AITask task) async {
    AITask? lastTask;
    await for (final updatedTask in executeWebTaskStream(task)) {
      lastTask = updatedTask;
    }
    return lastTask ?? task;
  }
  
  static String _buildEnhancedTaskPrompt(
      AITask task, String pageContent, Map<String, dynamic>? pageContext) {
    final sb = StringBuffer();
    if (pageContext != null) {
      sb.writeln('Current Page Context:');
      sb.writeln('- Title: ${pageContext['title'] ?? 'Unknown'}');
      sb.writeln('- URL: ${pageContext['url'] ?? 'Unknown'}');
      sb.writeln('- Description: ${pageContext['description'] ?? 'No description'}');
      sb.writeln();
    }

    sb.writeln('You are Titan AI, an advanced browser automation agent.');
    sb.writeln('You can interact with web pages through these actions:');
    sb.writeln('1. navigate(url)');
    sb.writeln('2. click(selector)');
    sb.writeln('3. type(selector, text)');
    sb.writeln('4. extract(selector, attribute?)');
    sb.writeln('5. scroll(direction, amount?)');
    sb.writeln('6. wait(milliseconds)');
    sb.writeln('7. screenshot()');
    sb.writeln('8. evaluate(javascript)');
    sb.writeln();

    final snippet = pageContent.length > 2000
        ? '${pageContent.substring(0, 2000)}...'
        : pageContent;
    sb.writeln('CURRENT PAGE CONTENT (first 2000 chars):');
    sb.writeln(snippet);
    sb.writeln();

    sb.writeln('TASK TO EXECUTE:');
    sb.writeln(task.description);
    sb.writeln();

    sb.writeln('PARAMETERS:');
    sb.writeln(jsonEncode(task.parameters));
    sb.writeln();

    sb.writeln('INSTRUCTIONS:');
    sb.writeln('1. Analyze the current page content and context');
    sb.writeln('2. Plan the necessary steps to complete the task');
    sb.writeln('3. Return a JSON action plan with structure:');
    sb.writeln('{"reasoning":"...","actions":[{"type":"...","parameters":{...}}],"expected_outcome":"..."}');
    sb.writeln('IMPORTANT: Use precise selectors, handle errors, return ONLY valid JSON');
    sb.writeln();

    switch (task.type) {
      case AITaskType.webSearch:
        sb.writeln('SEARCH TASK SPECIFICS:');
        sb.writeln('- If not on a search engine, navigate to one first');
        sb.writeln('- Use the search query from parameters');
        sb.writeln('- Extract relevant results');
        sb.writeln('- Summarize findings');
        break;
      case AITaskType.dataExtraction:
        sb.writeln('DATA EXTRACTION SPECIFICS:');
        sb.writeln('- Identify the data elements to extract');
        sb.writeln('- Use appropriate selectors');
        sb.writeln('- Handle pagination if needed');
        sb.writeln('- Return structured data');
        break;
      case AITaskType.formFilling:
        sb.writeln('FORM FILLING SPECIFICS:');
        sb.writeln('- Locate form fields by labels or placeholders');
        sb.writeln('- Fill fields with provided data');
        sb.writeln('- Handle dropdowns, checkboxes, radio buttons');
        sb.writeln('- Submit form if requested');
        break;
      case AITaskType.pageSummary:
        sb.writeln('PAGE SUMMARY SPECIFICS:');
        sb.writeln('- Read and analyze the main content');
        sb.writeln('- Identify key points and themes');
        sb.writeln('- Create a concise summary');
        sb.writeln('- Highlight important information');
        break;
      case AITaskType.translation:
        final target = task.parameters['targetLanguage'] ?? 'English';
        sb.writeln('TRANSLATION SPECIFICS:');
        sb.writeln('- Extract text content from the page');
        sb.writeln('- Translate to target language: $target');
        sb.writeln('- Maintain formatting and structure');
        sb.writeln('- Handle special characters properly');
        break;
      default:
        break;
    }

    return sb.toString();
  }
  
  static Map<String, dynamic> _parseAIResponse(String response) {
    try {
      return jsonDecode(response);
    } catch (e) {
      // Fallback parsing if response isn't pure JSON
      return {'actions': [{'type': 'error', 'message': 'Failed to parse AI response'}]};
    }
  }
  
  static Future<String> _executeActionPlanWithProgress(
    Map<String, dynamic> plan, 
    AITask task,
    Function(double) onProgress,
  ) async {
    final actions = plan['actions'] as List<dynamic>? ?? [];
    final results = <String>[];
    
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i] as Map<String, dynamic>;
      final progress = (i + 1) / actions.length;
      
      try {
        final result = await _executeAction(action);
        results.add(result);
        onProgress(progress);
        
        // Small delay between actions for stability
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        results.add('Error in action ${i + 1}: $e');
        onProgress(progress);
      }
    }
    
    return results.join('\n');
  }

  static Future<String> _executeAction(Map<String, dynamic> action) async {
    final type = action['type'] as String;
    final parameters = action['parameters'] as Map<String, dynamic>? ?? {};
    
    switch (type) {
      case 'navigate':
        final url = parameters['url'] as String;
        if (BrowserBridge.navigateToUrl != null) {
          return await BrowserBridge.navigateToUrl!(url);
        }
        return 'Navigation not available';
        
      case 'click':
        final selector = parameters['selector'] as String;
        if (BrowserBridge.clickElement != null) {
          return await BrowserBridge.clickElement!(selector);
        }
        return 'Click not available';
        
      case 'type':
        final selector = parameters['selector'] as String;
        final text = parameters['text'] as String;
        if (BrowserBridge.fillForm != null) {
          return await BrowserBridge.fillForm!({selector: text});
        }
        return 'Type not available';
        
      case 'extract':
        final selector = parameters['selector'] as String;
        final attribute = parameters['attribute'] as String?;
        if (BrowserBridge.extract != null) {
          return await BrowserBridge.extract!(selector, attribute: attribute);
        }
        return 'Extract not available';
        
      case 'wait':
        final milliseconds = parameters['milliseconds'] as int? ?? 1000;
        await Future.delayed(Duration(milliseconds: milliseconds));
        return 'Waited ${milliseconds}ms';
        
      case 'evaluate':
// This would need to be implemented in BrowserBridge
        return 'JavaScript evaluation not implemented';
        
      default:
        return 'Unknown action type: $type';
    }
  }

  static Future<String> _getCurrentPageContent() async {
    if (BrowserBridge.getPageContent != null) {
      return await BrowserBridge.getPageContent!();
    }
    return '';
  }

  static Future<Map<String, dynamic>?> _getCurrentPageContext() async {
    if (BrowserBridge.getCurrentTab != null) {
      return await BrowserBridge.getCurrentTab!();
    }
    return null;
  }
  
  static Future<String> summarizeCurrentPage() async {
    final content = await _getCurrentPageContent();
    final context = await _getCurrentPageContext();
    
    if (content.isEmpty) {
      throw Exception('No page content available to summarize');
    }
    
    String prompt = '''
Analyze and summarize the following web page content:

Page Title: ${context?['title'] ?? 'Unknown'}
Page URL: ${context?['url'] ?? 'Unknown'}

Content:
${content.length > 4000 ? '${content.substring(0, 4000)}...' : content}

Provide a comprehensive summary that includes:
1. Main topic and purpose
2. Key points and important information
3. Notable features or sections
4. Overall assessment or conclusion

Keep the summary concise but informative (200-400 words).
    ''';
    
    return await generateResponse(prompt);
  }

  static Future<String> summarizeContent(String content) async {
    String prompt = '''
Summarize the following web content in a clear, concise manner:

$content

Provide a summary that captures the key points and main ideas.
    ''';
    
    return await generateResponse(prompt);
  }
  
  static Future<String> translateCurrentPage(String targetLanguage) async {
    final content = await _getCurrentPageContent();
    
    if (content.isEmpty) {
      throw Exception('No page content available to translate');
    }
    
    return await translateContent(content, targetLanguage);
  }
  
  static Future<String> translateContent(String content, String targetLanguage) async {
    String prompt = '''
Translate the following content to $targetLanguage:

$content

Provide an accurate translation while maintaining the original meaning and context.
Preserve any HTML structure if present.
    ''';
    
    return await generateResponse(prompt);
  }
  
  static Future<List<String>> generateSearchSuggestions(String query) async {
    String prompt = '''
Generate 5 relevant search suggestions for the query: "$query"

Consider:
- Related topics and variations
- Common search patterns
- Trending or popular searches
- Specific and general alternatives

Return only a JSON array of strings, no additional text.
    ''';
    
    try {
      String response = await generateResponse(prompt);
      List<dynamic> suggestions = jsonDecode(response);
      return suggestions.cast<String>();
    } catch (e) {
      return [query]; // Fallback to original query
    }
  }

  static Future<Map<String, dynamic>> analyzePageForAccessibility() async {
    final content = await _getCurrentPageContent();
    
    String prompt = '''
Analyze the following HTML content for accessibility issues:

$content

Provide a JSON response with:
{
  "score": 0-100,
  "issues": [
    {"type": "issue_type", "severity": "low|medium|high", "description": "description", "suggestion": "how to fix"}
  ],
  "strengths": ["list of accessibility strengths"],
  "recommendations": ["list of improvement recommendations"]
}
    ''';
    
    try {
      String response = await generateResponse(prompt);
      return jsonDecode(response);
    } catch (e) {
      return {
        'score': 0,
        'issues': [{'type': 'analysis_error', 'severity': 'high', 'description': 'Failed to analyze accessibility', 'suggestion': 'Manual review required'}],
        'strengths': [],
        'recommendations': ['Perform manual accessibility audit']
      };
    }
  }

  static Future<List<Map<String, dynamic>>> extractStructuredData() async {
    final content = await _getCurrentPageContent();
    
    String prompt = '''
Extract structured data from this HTML content:

$content

Look for:
- Contact information (emails, phones, addresses)
- Product information (names, prices, descriptions)
- Article metadata (author, date, categories)
- Social media links
- Important links and navigation
- Forms and their fields

Return a JSON array of objects with:
{
  "type": "data_type",
  "label": "human_readable_label", 
  "value": "extracted_value",
  "selector": "css_selector_if_applicable"
}
    ''';
    
    try {
      String response = await generateResponse(prompt);
      List<dynamic> data = jsonDecode(response);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<String> generatePageInsights() async {
    final content = await _getCurrentPageContent();
    final context = await _getCurrentPageContext();

    final contentSnippet =
        content.length > 3000 ? '${content.substring(0, 3000)}...' : content;

    String prompt = '''
Analyze this web page and provide insights:

Page: ${context?['title'] ?? 'Unknown'}
URL: ${context?['url'] ?? 'Unknown'}

Content:
$contentSnippet

Provide insights about:
1. Page purpose and target audience
2. Content quality and readability
3. User experience observations
4. Technical aspects (performance, SEO, accessibility)
5. Suggestions for improvement
6. Notable features or innovations

Format as a structured analysis with clear sections.
    ''';

    return await generateResponse(prompt);
  }

  static Future<void> cancelTask(String taskId) async {
    final timer = _taskTimers[taskId];
    if (timer != null) {
      timer.cancel();
      _taskTimers.remove(taskId);
    }
    
    final stream = _taskStreams[taskId];
    if (stream != null) {
      stream.close();
      _taskStreams.remove(taskId);
    }
  }

  static void cleanup() {
    for (final timer in _taskTimers.values) {
      timer.cancel();
    }
    _taskTimers.clear();
    
    for (final stream in _taskStreams.values) {
      stream.close();
    }
    _taskStreams.clear();
}
  static Future<Map<String, dynamic>> analyzeText(String text) async {
    try {
await _makeOpenAIRequest('gpt-3.5-turbo', [
        {
          'role': 'system',
          'content': 'Analyze the provided text and return insights about sentiment, keywords, and readability.'
        },
        {
          'role': 'user',
          'content': text
        }
      ]);
      
      return {
        'sentiment': _extractSentiment(text),
        'keywords': _extractKeywords(text),
        'summary': await _generateSummary(text),
        'language': _detectLanguage(text),
        'readability': _calculateReadability(text),
        'wordCount': text.split(' ').length,
        'characterCount': text.length,
        'estimatedReadingTime': (text.split(' ').length / 200).ceil(), // minutes
      };
    } catch (e) {
      return {
        'sentiment': 'neutral',
        'keywords': _extractKeywords(text),
        'summary': text.length > 200 ? '${text.substring(0, 200)}...' : text,
        'language': 'en',
        'readability': 0.7,
        'error': e.toString(),
      };
    }
  }
  
  static String _extractSentiment(String text) {
    final positiveWords = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic'];
    final negativeWords = ['bad', 'terrible', 'awful', 'horrible', 'disappointing'];
    
    final words = text.toLowerCase().split(' ');
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in words) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }
  
  static List<String> _extractKeywords(String text) {
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.length > 3)
        .toList();
    
    final wordCount = <String, int>{};
    for (final word in words) {
      wordCount[word] = (wordCount[word] ?? 0) + 1;
    }
    
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords.take(10).map((e) => e.key).toList();
  }
  
  static Future<String> _generateSummary(String text) async {
    if (text.length <= 200) return text;
    
    final sentences = text.split(RegExp(r'[.!?]+'));
    if (sentences.length <= 3) return text;
    
    // Simple extractive summarization - take first and most important sentences
    final summary = sentences.take(3).join('. ');
    return summary.length > 200 ? '${summary.substring(0, 200)}...' : summary;
  }
  
  static String _detectLanguage(String text) {
    // Simple language detection based on common words
    final englishWords = ['the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of'];
    final spanishWords = ['el', 'la', 'y', 'o', 'pero', 'en', 'de', 'para', 'con', 'por'];
    final frenchWords = ['le', 'la', 'et', 'ou', 'mais', 'dans', 'de', 'pour', 'avec', 'par'];
    
    final words = text.toLowerCase().split(' ');
    int englishCount = 0;
    int spanishCount = 0;
    int frenchCount = 0;
    
    for (final word in words) {
      if (englishWords.contains(word)) englishCount++;
      if (spanishWords.contains(word)) spanishCount++;
      if (frenchWords.contains(word)) frenchCount++;
    }
    
    if (englishCount >= spanishCount && englishCount >= frenchCount) return 'en';
    if (spanishCount >= frenchCount) return 'es';
    return 'fr';
  }
  
  static double _calculateReadability(String text) {
    final sentences = text.split(RegExp(r'[.!?]+'));
    final words = text.split(' ');
    final syllables = words.map(_countSyllables).reduce((a, b) => a + b);
    
    if (sentences.isEmpty || words.isEmpty) return 0.5;
    
    // Flesch Reading Ease Score (simplified)
    final avgSentenceLength = words.length / sentences.length;
    final avgSyllablesPerWord = syllables / words.length;
    
    final score = 206.835 - (1.015 * avgSentenceLength) - (84.6 * avgSyllablesPerWord);
    return (score / 100).clamp(0.0, 1.0);
  }
  
  static int _countSyllables(String word) {
    word = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (word.isEmpty) return 0;
    
    int count = 0;
    bool previousWasVowel = false;
    
    for (int i = 0; i < word.length; i++) {
      final isVowel = 'aeiou'.contains(word[i]);
      if (isVowel && !previousWasVowel) count++;
      previousWasVowel = isVowel;
    }
    
    if (word.endsWith('e')) count--;
    return count < 1 ? 1 : count;
  }
  
  // Enhanced text summarization
  static Future<String> summarizeText(String text, {int maxLength = 200}) async {
    try {
      final response = await _makeOpenAIRequest('gpt-3.5-turbo', [
        {
          'role': 'system',
          'content': 'Summarize the following text in approximately $maxLength characters. Be concise and capture the main points.'
        },
        {
          'role': 'user',
          'content': text
        }
      ]);
      
      return response['choices'][0]['message']['content'] ?? await _generateSummary(text);
    } catch (e) {
      return await _generateSummary(text);
    }
  }
  
  // Text translation
  static Future<String> translateText(String text, String targetLanguage) async {
    try {
      final response = await _makeOpenAIRequest('gpt-3.5-turbo', [
        {
          'role': 'system',
          'content': 'Translate the following text to $targetLanguage. Only return the translation.'
        },
        {
          'role': 'user',
          'content': text
        }
      ]);
      
      return response['choices'][0]['message']['content'] ?? text;
    } catch (e) {
      return 'Translation failed: ${e.toString()}';
    }
  }
  
  // Smart form filling
  static Future<Map<String, String>> smartFormFill(Map<String, dynamic> formData, Map<String, String> userProfile) async {
    final suggestions = <String, String>{};
    
    for (final entry in formData.entries) {
      final fieldName = entry.key.toLowerCase();
// final fieldType = entry.value['type'] as String? ?? 'text';
      
      if (fieldName.contains('email')) {
        suggestions[entry.key] = userProfile['email'] ?? '';
      } else if (fieldName.contains('name')) {
        if (fieldName.contains('first')) {
          suggestions[entry.key] = userProfile['firstName'] ?? '';
        } else if (fieldName.contains('last')) {
          suggestions[entry.key] = userProfile['lastName'] ?? '';
        } else {
          suggestions[entry.key] = '${userProfile['firstName'] ?? ''} ${userProfile['lastName'] ?? ''}'.trim();
        }
      } else if (fieldName.contains('phone')) {
        suggestions[entry.key] = userProfile['phone'] ?? '';
      } else if (fieldName.contains('address')) {
        suggestions[entry.key] = userProfile['address'] ?? '';
      } else if (fieldName.contains('city')) {
        suggestions[entry.key] = userProfile['city'] ?? '';
      } else if (fieldName.contains('zip') || fieldName.contains('postal')) {
        suggestions[entry.key] = userProfile['zipCode'] ?? '';
      }
    }
    
    return suggestions;
  }
  
  // Content extraction and structuring
  static Future<Map<String, dynamic>> parseStructuredDataFromHtml(String html) async {
    final data = <String, dynamic>{};
    
    // Extract common structured data
    data['title'] = _extractBetween(html, '<title>', '</title>');
    data['description'] = _extractMetaContent(html, 'description');
    data['keywords'] = _extractMetaContent(html, 'keywords');
    data['author'] = _extractMetaContent(html, 'author');
    
    // Extract headings
    data['headings'] = _extractHeadings(html);
    
    // Extract links
    data['links'] = _extractLinks(html);
    
    // Extract images
    data['images'] = _extractImages(html);
    
    // Extract contact information
    data['emails'] = _extractEmails(html);
    data['phones'] = _extractPhones(html);
    
    return data;
  }
  
  static String? _extractBetween(String text, String start, String end) {
    final startIndex = text.indexOf(start);
    if (startIndex == -1) return null;
    
    final contentStart = startIndex + start.length;
    final endIndex = text.indexOf(end, contentStart);
    if (endIndex == -1) return null;
    
    return text.substring(contentStart, endIndex).trim();
  }
  
  static String? _extractMetaContent(String html, String name) {
    final pattern = RegExp('<meta[^>]*name=["\']$name["\'][^>]*content=["\']([^"\']*)["\']', caseSensitive: false);
    final match = pattern.firstMatch(html);
    return match?.group(1);
  }
  
  static List<String> _extractHeadings(String html) {
    final headings = <String>[];
    final pattern = RegExp(r'<h[1-6][^>]*>(.*?)</h[1-6]>', caseSensitive: false);
    final matches = pattern.allMatches(html);
    
    for (final match in matches) {
      final heading = match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (heading != null && heading.isNotEmpty) {
        headings.add(heading);
      }
    }
    
    return headings;
  }
  
  static List<Map<String, String>> _extractLinks(String html) {
    final links = <Map<String, String>>[];
    final pattern = RegExp('<a[^>]*href=["\']([^"\']*)["\'][^>]*>(.*?)</a>', caseSensitive: false);
    final matches = pattern.allMatches(html);
    
    for (final match in matches) {
      final url = match.group(1);
      final text = match.group(2)?.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      
      if (url != null && text != null && text.isNotEmpty) {
        links.add({'url': url, 'text': text});
      }
    }
    
    return links;
  }
  
  static List<Map<String, String>> _extractImages(String html) {
    final images = <Map<String, String>>[];
    final pattern = RegExp('<img[^>]*src=["\']([^"\']*)["\'][^>]*(?:alt=["\']([^"\']*)["\'])?[^>]*>', caseSensitive: false);
    final matches = pattern.allMatches(html);
    
    for (final match in matches) {
      final src = match.group(1);
      final alt = match.group(2) ?? '';
      
      if (src != null) {
        images.add({'src': src, 'alt': alt});
      }
    }
    
    return images;
  }
  
  static List<String> _extractEmails(String text) {
    final pattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final matches = pattern.allMatches(text);
    return matches.map((match) => match.group(0)!).toSet().toList();
  }
  
  static List<String> _extractPhones(String text) {
    final patterns = [
      RegExp(r'\b\d{3}-\d{3}-\d{4}\b'), // 123-456-7890
      RegExp(r'\b\(\d{3}\)\s*\d{3}-\d{4}\b'), // (123) 456-7890
      RegExp(r'\b\d{3}\.\d{3}\.\d{4}\b'), // 123.456.7890
      RegExp(r'\b\d{10}\b'), // 1234567890
    ];
    
    final phones = <String>[];
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      phones.addAll(matches.map((match) => match.group(0)!));
    }
    
    return phones.toSet().toList();
  }
}