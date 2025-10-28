import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_task.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class AIState {
  final List<AITask> tasks;
  final bool isProcessing;
  final String? currentTaskId;
  
  const AIState({
    required this.tasks,
    this.isProcessing = false,
    this.currentTaskId,
  });
  
  AIState copyWith({
    List<AITask>? tasks,
    bool? isProcessing,
    String? currentTaskId,
  }) {
    return AIState(
      tasks: tasks ?? this.tasks,
      isProcessing: isProcessing ?? this.isProcessing,
      currentTaskId: currentTaskId ?? this.currentTaskId,
    );
  }
  
  AITask? get currentTask {
    if (currentTaskId != null) {
      return tasks.firstWhere(
        (task) => task.id == currentTaskId,
        orElse: () => tasks.first,
      );
    }
    return null;
  }
}

class AINotifier extends StateNotifier<AIState> {
  AINotifier() : super(const AIState(tasks: [])) {
    _loadTasks();
  }
  
  void _loadTasks() {
    final savedTasks = StorageService.getTasks();
    state = state.copyWith(tasks: savedTasks);
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
    
    state = state.copyWith(
      isProcessing: true,
      currentTaskId: taskId,
    );
    
    try {
      final task = state.tasks[taskIndex];
      final updatedTask = await AIService.executeWebTask(task);
      
      final updatedTasks = [...state.tasks];
      updatedTasks[taskIndex] = updatedTask;
      
      state = state.copyWith(
        tasks: updatedTasks,
        isProcessing: false,
      );
      
      await StorageService.saveTask(updatedTask);
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
      );
      
      await StorageService.saveTask(failedTask);
    }
  }
  
  Future<void> cancelTask(String taskId) async {
    final taskIndex = state.tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    
    final task = state.tasks[taskIndex];
    final cancelledTask = task.copyWith(
      status: AITaskStatus.cancelled,
      completedAt: DateTime.now(),
    );
    
    final updatedTasks = [...state.tasks];
    updatedTasks[taskIndex] = cancelledTask;
    
    state = state.copyWith(
      tasks: updatedTasks,
      isProcessing: false,
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
      type: AITaskType.contentSummary,
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
}

final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier();
});