import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_task.dart';

class AIService {
  static const String _openAIBaseUrl = 'https://api.openai.com/v1';
  static const String _anthropicBaseUrl = 'https://api.anthropic.com/v1';
  
  static String? _openAIKey;
  static String? _anthropicKey;
  
  static Future<void> init() async {
    // Initialize AI service - keys should be set via settings
  }
  
  static void setOpenAIKey(String key) {
    _openAIKey = key;
  }
  
  static void setAnthropicKey(String key) {
    _anthropicKey = key;
  }
  
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
  
  static Future<AITask> executeWebTask(AITask task) async {
    try {
      task = task.copyWith(status: AITaskStatus.running);
      
      String prompt = _buildTaskPrompt(task);
      String response = await generateResponse(prompt);
      
      // Parse and execute the AI response
      Map<String, dynamic> actionPlan = _parseAIResponse(response);
      String result = await _executeActionPlan(actionPlan, task);
      
      return task.copyWith(
        status: AITaskStatus.completed,
        result: result,
        completedAt: DateTime.now(),
        progress: 1.0,
      );
    } catch (e) {
      return task.copyWith(
        status: AITaskStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }
  
  static String _buildTaskPrompt(AITask task) {
    switch (task.type) {
      case AITaskType.webSearch:
        return '''
You are an AI browser agent. Execute this web search task:
Task: ${task.description}
Parameters: ${jsonEncode(task.parameters)}

Provide a step-by-step action plan in JSON format with these actions:
- navigate: {url: "URL"}
- click: {selector: "CSS_SELECTOR"}
- type: {selector: "CSS_SELECTOR", text: "TEXT"}
- extract: {selector: "CSS_SELECTOR", attribute: "ATTRIBUTE"}
- wait: {milliseconds: NUMBER}

Return only valid JSON.
        ''';
      case AITaskType.dataExtraction:
        return '''
Extract data from the current webpage:
Task: ${task.description}
Parameters: ${jsonEncode(task.parameters)}

Provide extraction instructions in JSON format.
        ''';
      case AITaskType.formFilling:
        return '''
Fill out a web form:
Task: ${task.description}
Form data: ${jsonEncode(task.parameters)}

Provide form filling steps in JSON format.
        ''';
      default:
        return '''
Execute this browser task:
Task: ${task.description}
Parameters: ${jsonEncode(task.parameters)}

Provide action plan in JSON format.
        ''';
    }
  }
  
  static Map<String, dynamic> _parseAIResponse(String response) {
    try {
      return jsonDecode(response);
    } catch (e) {
      // Fallback parsing if response isn't pure JSON
      return {'actions': [{'type': 'error', 'message': 'Failed to parse AI response'}]};
    }
  }
  
  static Future<String> _executeActionPlan(Map<String, dynamic> plan, AITask task) async {
    // This would integrate with the browser engine to execute actions
    // For now, return a mock result
    return 'Task executed successfully: ${task.description}';
  }
  
  static Future<String> summarizeContent(String content) async {
    String prompt = '''
Summarize the following web content in a clear, concise manner:

$content

Provide a summary that captures the key points and main ideas.
    ''';
    
    return await generateResponse(prompt);
  }
  
  static Future<String> translateContent(String content, String targetLanguage) async {
    String prompt = '''
Translate the following content to $targetLanguage:

$content

Provide an accurate translation while maintaining the original meaning and context.
    ''';
    
    return await generateResponse(prompt);
  }
  
  static Future<List<String>> generateSearchSuggestions(String query) async {
    String prompt = '''
Generate 5 relevant search suggestions for the query: "$query"

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
}