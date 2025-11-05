import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_task.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class AIState {
  final List<AITask> tasks;
  final bool isProcessing;
  final String? currentTaskId;
  final bool isConfigured;
  final String? error;
  final Map<String, dynamic> settings;
  final List<String> suggestions;
  final Map<String, StreamSubscription> activeStreams;
  
  const AIState({
    required this.tasks,
    this.isProcessing = false,
    this.currentTaskId,
    this.isConfigured = false,
    this.error,
    this.settings = const {},
    this.suggestions = const [],
    this.activeStreams = const {},
  });
  
  AIState copyWith({
    List<AITask>? tasks,
    bool? isProcessing,
    String? currentTaskId,
    bool? isConfigured,
    String? error,
    Map<String, dynamic>? settings,
    List<String>? suggestions,
    Map<String, StreamSubscription>? activeStreams,
  }) {
    return AIState(
      tasks: tasks ?? this.tasks,
      isProcessing: isProcessing ?? this.isProcessing,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      isConfigured: isConfigured ?? this.isConfigured,
      error: error,
      settings: settings ?? this.settings,
      suggestions: suggestions ?? this.suggestions,
      activeStreams: activeStreams ?? this.activeStreams,
    );
  }
  
  AITask? get currentTask {
    if (currentTaskId != null) {
      try {
        return tasks.firstWhere((task) => task.id == currentTaskId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  List<AITask> get runningTasks {
    return tasks.where((task) => task.status == AITaskStatus.running).toList();
  }
  
  List<AITask> get completedTasks {
    return tasks.where((task) => task.status == AITaskStatus.completed).toList();
  }
  
  List<AITask> get failedTasks {
    return tasks.where((task) => task.status == AITaskStatus.failed).toList();
  }
  
  int get totalTasks => tasks.length;
  int get successfulTasks => completedTasks.length;
  int get failedTasksCount => failedTasks.length;
  double get successRate => totalTasks > 0 ? successfulTasks / totalTasks : 0.0;
}

class AINotifier extends StateNotifier<AIState> {
  Timer? _cleanupTimer;
  
  AINotifier() : super(const AIState(tasks: [])) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadTasks();
    await _loadSettings();
    _checkConfiguration();
    _startCleanupTimer();
  }
  
  Future<void> _loadTasks() async {
    try {
      final savedTasks = StorageService.getTasks();
      state = state.copyWith(tasks: savedTasks);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load tasks: $e');
    }
  }
  
  Future<void> _loadSettings() async {
    try {
      final settings = {
        'model': await StorageService.getString('ai_default_model') ?? 'gpt-4',
        'temperature': await StorageService.getDouble('ai_temperature') ?? 0.7,
        'maxTokens': await StorageService.getInt('ai_max_tokens') ?? 4000,
        'autoExecute': await StorageService.getBool('ai_auto_execute') ?? false,
        'saveHistory': await StorageService.getBool('ai_save_history') ?? true,
      };
      state = state.copyWith(settings: settings);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load AI settings: $e');
    }
  }
  
  void _checkConfiguration() {
    final isConfigured = AIService.isConfigured;
    state = state.copyWith(isConfigured: isConfigured);
  }
  
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupCompletedTasks();
    });
  }
  
  Future<void> createTask({
    required AITaskType type,
    required String description,
    required Map<String, dynamic> parameters,
  }) async {
    final task = AITask(
      type: type,
      description: description,
      parameters: parameters,
    );
    
    final updatedTasks = [task, ...state.tasks];
    state = state.copyWith(
      tasks: updatedTasks,
      currentTaskId: task.id,
    );
    
    await StorageService.saveTask(task);
    await executeTask(task.id);
  }
  
  Future<void> executeTask(String taskId) async {
    final taskIndex = state.tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    
    if (!state.isConfigured) {
      state = state.copyWith(error: 'AI service not configured. Please add API keys in settings.');
      return;
    }
    
    state = state.copyWith(
      isProcessing: true,
      currentTaskId: taskId,
      error: null,
    );
    
    try {
      final task = state.tasks[taskIndex];
      
      // Use streaming execution for real-time updates
      final subscription = AIService.executeWebTaskStream(task).listen(
        (updatedTask) {
          final updatedTasks = [...state.tasks];
          updatedTasks[taskIndex] = updatedTask;
          
          state = state.copyWith(
            tasks: updatedTasks,
            isProcessing: updatedTask.status == AITaskStatus.running,
          );
          
          // Save task progress
          StorageService.saveTask(updatedTask);
        },
        onError: (error) {
          final failedTask = task.copyWith(
            status: AITaskStatus.failed,
            error: error.toString(),
            completedAt: DateTime.now(),
          );
          
          final updatedTasks = [...state.tasks];
          updatedTasks[taskIndex] = failedTask;
          
          state = state.copyWith(
            tasks: updatedTasks,
            isProcessing: false,
            error: error.toString(),
          );
          
          StorageService.saveTask(failedTask);
        },
        onDone: () {
          final activeStreams = Map<String, StreamSubscription>.from(state.activeStreams);
          activeStreams.remove(taskId);
          state = state.copyWith(activeStreams: activeStreams);
        },
      );
      
      // Track active stream
      final activeStreams = Map<String, StreamSubscription>.from(state.activeStreams);
      activeStreams[taskId] = subscription;
      state = state.copyWith(activeStreams: activeStreams);
      
    } catch (e) {
      final task = state.tasks[taskIndex];
      final failedTask = task.copyWith(
        status: AITaskStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
      
      final updatedTasks = [...state.tasks];
      updatedTasks[taskIndex] = failedTask;
      
      state = state.copyWith(
        tasks: updatedTasks,
        isProcessing: false,
        error: e.toString(),
      );
      
      await StorageService.saveTask(failedTask);
    }
  }
  
  Future<void> cancelTask(String taskId) async {
    final taskIndex = state.tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    
    // Cancel the stream subscription
    final subscription = state.activeStreams[taskId];
    if (subscription != null) {
      await subscription.cancel();
    }
    
    // Cancel in AI service
    await AIService.cancelTask(taskId);
    
    final task = state.tasks[taskIndex];
    final cancelledTask = task.copyWith(
      status: AITaskStatus.cancelled,
      completedAt: DateTime.now(),
    );
    
    final updatedTasks = [...state.tasks];
    updatedTasks[taskIndex] = cancelledTask;
    
    final activeStreams = Map<String, StreamSubscription>.from(state.activeStreams);
    activeStreams.remove(taskId);
    
    state = state.copyWith(
      tasks: updatedTasks,
      isProcessing: state.runningTasks.length > 1, // Still processing if other tasks running
      activeStreams: activeStreams,
    );
    
    await StorageService.saveTask(cancelledTask);
  }
  
  Future<void> deleteTask(String taskId) async {
    final updatedTasks = state.tasks.where((task) => task.id != taskId).toList();
    state = state.copyWith(tasks: updatedTasks);
    await StorageService.deleteTask(taskId);
  }
  
  Future<void> retryTask(String taskId) async {
    final taskIndex = state.tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    
    final task = state.tasks[taskIndex];
    final retryTask = task.copyWith(
      status: AITaskStatus.pending,
      error: null,
      result: null,
      progress: 0.0,
    );
    
    final updatedTasks = [...state.tasks];
    updatedTasks[taskIndex] = retryTask;
    
    state = state.copyWith(tasks: updatedTasks);
    await StorageService.saveTask(retryTask);
    await executeTask(taskId);
  }
  
  // Quick task creation methods
  Future<void> searchWeb(String query) async {
    await createTask(
      type: AITaskType.webSearch,
      description: 'Search the web for: $query',
      parameters: {'query': query},
    );
  }
  
  Future<void> extractData(String selector, {String? attribute}) async {
    await createTask(
      type: AITaskType.dataExtraction,
      description: 'Extract data from current page',
      parameters: {
        'selector': selector,
        'attribute': attribute ?? 'textContent',
      },
    );
  }
  
  Future<void> fillForm(Map<String, String> formData) async {
    await createTask(
      type: AITaskType.formFilling,
      description: 'Fill out form with provided data',
      parameters: {'formData': formData},
    );
  }
  
  Future<void> summarizePage() async {
    await createTask(
      type: AITaskType.pageSummary,
      description: 'Summarize the current page content',
      parameters: {},
    );
  }
  
  Future<void> translatePage(String targetLanguage) async {
    await createTask(
      type: AITaskType.translation,
      description: 'Translate page to $targetLanguage',
      parameters: {'targetLanguage': targetLanguage},
    );
  }
  
  Future<void> analyzeAccessibility() async {
    await createTask(
      type: AITaskType.custom,
      description: 'Analyze page accessibility',
      parameters: {'action': 'accessibility_analysis'},
    );
  }
  
  Future<void> extractStructuredData() async {
    await createTask(
      type: AITaskType.dataExtraction,
      description: 'Extract structured data from page',
      parameters: {'action': 'structured_data'},
    );
  }
  
  Future<void> generatePageInsights() async {
    await createTask(
      type: AITaskType.custom,
      description: 'Generate insights about this page',
      parameters: {'action': 'page_insights'},
    );
  }
  
  // Settings management
  Future<void> updateSetting(String key, dynamic value) async {
    final settings = Map<String, dynamic>.from(state.settings);
    settings[key] = value;
    state = state.copyWith(settings: settings);
    
    // Save to storage
    switch (key) {
      case 'model':
        await AIService.setDefaultModel(value);
        break;
      case 'temperature':
        await AIService.setTemperature(value);
        break;
      case 'maxTokens':
        await AIService.setMaxTokens(value);
        break;
      default:
        await StorageService.setBool('ai_$key', value);
    }
  }
  
  Future<void> setApiKey(String provider, String key) async {
    switch (provider.toLowerCase()) {
      case 'openai':
        await AIService.setOpenAIKey(key);
        break;
      case 'anthropic':
        await AIService.setAnthropicKey(key);
        break;
    }
    _checkConfiguration();
  }
  
  // Search suggestions
  Future<void> generateSuggestions(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }
    
    try {
      final suggestions = await AIService.generateSearchSuggestions(query);
      state = state.copyWith(suggestions: suggestions);
    } catch (e) {
      state = state.copyWith(suggestions: [query]);
    }
  }
  
  // Task management
  void _cleanupCompletedTasks() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final filteredTasks = state.tasks.where((task) {
      if (task.status == AITaskStatus.completed || task.status == AITaskStatus.failed) {
        return task.completedAt?.isAfter(cutoffDate) ?? true;
      }
      return true;
    }).toList();
    
    if (filteredTasks.length != state.tasks.length) {
      state = state.copyWith(tasks: filteredTasks);
    }
  }
  
  Future<void> clearAllTasks() async {
    // Cancel all active streams
    for (final subscription in state.activeStreams.values) {
      await subscription.cancel();
    }
    
    // Clear from storage
    for (final task in state.tasks) {
      await StorageService.deleteTask(task.id);
    }
    
    state = state.copyWith(
      tasks: [],
      activeStreams: {},
      isProcessing: false,
      currentTaskId: null,
    );
  }
  
  Future<void> exportTasks() async {
    final export = {
      'tasks': state.tasks.map((task) => task.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
    await StorageService.setSetting('ai_tasks_export', export);
  }
  
  Map<String, dynamic> getStatistics() {
    return {
      'total_tasks': state.totalTasks,
      'successful_tasks': state.successfulTasks,
      'failed_tasks': state.failedTasksCount,
      'success_rate': state.successRate,
      'running_tasks': state.runningTasks.length,
      'average_completion_time': _calculateAverageCompletionTime(),
    };
  }
  
  double _calculateAverageCompletionTime() {
    final completedTasks = state.completedTasks;
    if (completedTasks.isEmpty) return 0.0;
    
    final totalTime = completedTasks.fold<int>(0, (sum, task) {
      if (task.completedAt != null) {
        return sum + task.completedAt!.difference(task.createdAt).inMilliseconds;
      }
      return sum;
    });
    
    return totalTime / completedTasks.length / 1000; // Return in seconds
  }
  
  @override
  void dispose() {
    _cleanupTimer?.cancel();
    
    // Cancel all active streams
    for (final subscription in state.activeStreams.values) {
      subscription.cancel();
    }
    
    AIService.cleanup();
    super.dispose();
  }
}

final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier();
});