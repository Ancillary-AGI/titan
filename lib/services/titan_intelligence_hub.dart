import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/ai_service.dart';
import '../services/web_intelligence_service.dart';
import '../services/ai_web_interaction_service.dart';
import '../services/performance_engine_service.dart';
import '../services/browser_security_service.dart';
import '../services/javascript_engine_service.dart';
import '../services/storage_service.dart';

/// Intelligence hub capabilities
enum IntelligenceCapability {
  webAnalysis,        // Deep web page analysis
  automation,         // Web automation and scripting
  aiInteraction,      // Natural language web interaction
  performance,        // Performance optimization
  security,           // Security analysis and protection
  accessibility,      // Accessibility improvements
  learning,           // Machine learning and adaptation
  prediction,         // Predictive browsing
  personalization,    // Personalized experience
  collaboration,      // Multi-user collaboration
}

/// Intelligence task priority
enum TaskPriority {
  critical,   // Security, performance critical
  high,       // User-requested tasks
  medium,     // Background optimization
  low,        // Learning, analytics
  idle,       // Cleanup, maintenance
}

/// Intelligence task status
enum TaskStatus {
  pending,    // Waiting to execute
  running,    // Currently executing
  completed,  // Successfully completed
  failed,     // Failed to execute
  cancelled,  // Cancelled by user
  paused,     // Temporarily paused
}

/// Unified intelligence task
class IntelligenceTask {
  final String id;
  final String name;
  final String description;
  final IntelligenceCapability capability;
  final TaskPriority priority;
  final TaskStatus status;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? estimatedDuration;
  final double progress;
  final String? error;
  final Map<String, dynamic> result;
  
  const IntelligenceTask({
    required this.id,
    required this.name,
    required this.description,
    required this.capability,
    required this.priority,
    required this.status,
    this.parameters = const {},
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.estimatedDuration,
    this.progress = 0.0,
    this.error,
    this.result = const {},
  });
  
  IntelligenceTask copyWith({
    TaskStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    double? progress,
    String? error,
    Map<String, dynamic>? result,
  }) {
    return IntelligenceTask(
      id: id,
      name: name,
      description: description,
      capability: capability,
      priority: priority,
      status: status ?? this.status,
      parameters: parameters,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedDuration: estimatedDuration,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      result: result ?? this.result,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'capability': capability.name,
    'priority': priority.name,
    'status': status.name,
    'parameters': parameters,
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'estimatedDuration': estimatedDuration?.inMilliseconds,
    'progress': progress,
    'error': error,
    'result': result,
  };
}

/// Intelligence insights and recommendations
class IntelligenceInsight {
  final String id;
  final String title;
  final String description;
  final IntelligenceCapability category;
  final double confidence;
  final Map<String, dynamic> data;
  final List<String> recommendations;
  final DateTime generatedAt;
  final bool isActionable;
  
  const IntelligenceInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.confidence,
    required this.data,
    required this.recommendations,
    required this.generatedAt,
    this.isActionable = true,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'confidence': confidence,
    'data': data,
    'recommendations': recommendations,
    'generatedAt': generatedAt.toIso8601String(),
    'isActionable': isActionable,
  };
}

/// Titan Intelligence Hub - Central AI and automation coordinator
class TitanIntelligenceHub {
  static final Map<String, InAppWebViewController> _controllers = {};
  static final Map<String, IntelligenceTask> _activeTasks = {};
  static final Map<String, Timer> _taskTimers = {};
  static final List<IntelligenceInsight> _insights = {};
  static final Map<String, StreamController<IntelligenceTask>> _taskStreams = {};
  static final StreamController<IntelligenceInsight> _insightStream = 
      StreamController<IntelligenceInsight>.broadcast();
  
  // Intelligence configuration
  static final Set<IntelligenceCapability> _enabledCapabilities = {
    IntelligenceCapability.webAnalysis,
    IntelligenceCapability.automation,
    IntelligenceCapability.aiInteraction,
    IntelligenceCapability.performance,
    IntelligenceCapability.security,
    IntelligenceCapability.accessibility,
  };
  
  static bool _autoOptimization = true;
  static bool _predictiveBrowsing = true;
  static bool _learningMode = true;
  static double _confidenceThreshold = 0.7;
  static int _maxConcurrentTasks = 5;
  
  // Performance metrics
  static int _tasksCompleted = 0;
  static int _tasksFailed = 0;
  static Duration _totalExecutionTime = Duration.zero;
  static final Map<IntelligenceCapability, int> _capabilityUsage = {};
  
  /// Initialize Titan Intelligence Hub
  static Future<void> initialize() async {
    await _initializeSubServices();
    await _loadConfiguration();
    _startIntelligenceEngine();
    _startInsightGenerator();
    print('Titan Intelligence Hub initialized');
  }
  
  /// Initialize all sub-services
  static Future<void> _initializeSubServices() async {
    await WebIntelligenceService.initialize();
    await AIWebInteractionService.initialize();
    await PerformanceEngineService.initialize();
    await BrowserSecurityService.initialize();
    await JavaScriptEngineService.initialize();
  }
  
  /// Load configuration from storage
  static Future<void> _loadConfiguration() async {
    try {
      final config = StorageService.getSetting<String>('intelligence_config');
      if (config != null) {
        final configData = jsonDecode(config);
        _autoOptimization = configData['autoOptimization'] ?? true;
        _predictiveBrowsing = configData['predictiveBrowsing'] ?? true;
        _learningMode = configData['learningMode'] ?? true;
        _confidenceThreshold = configData['confidenceThreshold'] ?? 0.7;
        _maxConcurrentTasks = configData['maxConcurrentTasks'] ?? 5;
      }
    } catch (e) {
      print('Error loading intelligence configuration: $e');
    }
  }
  
  /// Start main intelligence engine
  static void _startIntelligenceEngine() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      _processIntelligenceTasks();
    });
    
    Timer.periodic(Duration(minutes: 5), (timer) {
      _performAutoOptimization();
    });
  }
  
  /// Start insight generator
  static void _startInsightGenerator() {
    Timer.periodic(Duration(minutes: 2), (timer) {
      _generateInsights();
    });
  }
  
  /// Register tab with intelligence hub
  static Future<void> registerTab(String tabId, InAppWebViewController controller) async {
    _controllers[tabId] = controller;
    
    // Register with all sub-services
    await WebIntelligenceService.registerTab(tabId, controller);
    await AIWebInteractionService.registerTab(tabId, controller);
    await PerformanceEngineService.registerTab(tabId, controller);
    await JavaScriptEngineService.registerController(tabId, controller);
    
    // Create task stream for this tab
    _taskStreams[tabId] = StreamController<IntelligenceTask>.broadcast();
    
    // Start initial analysis
    await _performInitialAnalysis(tabId);
  }
  
  /// Perform initial analysis when tab is registered
  static Future<void> _performInitialAnalysis(String tabId) async {
    // Queue initial analysis tasks
    await queueTask(IntelligenceTask(
      id: '${tabId}_initial_analysis',
      name: 'Initial Page Analysis',
      description: 'Analyze page structure, content, and capabilities',
      capability: IntelligenceCapability.webAnalysis,
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      estimatedDuration: Duration(seconds: 5),
    ));
    
    await queueTask(IntelligenceTask(
      id: '${tabId}_security_scan',
      name: 'Security Scan',
      description: 'Scan page for security threats and vulnerabilities',
      capability: IntelligenceCapability.security,
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      estimatedDuration: Duration(seconds: 3),
    ));
    
    await queueTask(IntelligenceTask(
      id: '${tabId}_performance_analysis',
      name: 'Performance Analysis',
      description: 'Analyze page performance and optimization opportunities',
      capability: IntelligenceCapability.performance,
      priority: TaskPriority.medium,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      estimatedDuration: Duration(seconds: 2),
    ));
  }
  
  /// Queue intelligence task
  static Future<String> queueTask(IntelligenceTask task) async {
    if (!_enabledCapabilities.contains(task.capability)) {
      throw Exception('Capability ${task.capability.name} is not enabled');
    }
    
    if (_activeTasks.length >= _maxConcurrentTasks) {
      // Wait for a slot or queue for later
      await _waitForTaskSlot();
    }
    
    _activeTasks[task.id] = task;
    
    // Notify listeners
    final tabId = _extractTabIdFromTaskId(task.id);
    if (tabId != null) {
      _taskStreams[tabId]?.add(task);
    }
    
    // Schedule execution
    _scheduleTaskExecution(task);
    
    return task.id;
  }
  
  /// Wait for task execution slot
  static Future<void> _waitForTaskSlot() async {
    while (_activeTasks.length >= _maxConcurrentTasks) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
  
  /// Schedule task execution
  static void _scheduleTaskExecution(IntelligenceTask task) {
    final delay = _calculateTaskDelay(task);
    
    _taskTimers[task.id] = Timer(delay, () async {
      await _executeTask(task.id);
    });
  }
  
  /// Calculate task execution delay based on priority
  static Duration _calculateTaskDelay(IntelligenceTask task) {
    switch (task.priority) {
      case TaskPriority.critical:
        return Duration.zero;
      case TaskPriority.high:
        return Duration(milliseconds: 100);
      case TaskPriority.medium:
        return Duration(milliseconds: 500);
      case TaskPriority.low:
        return Duration(seconds: 2);
      case TaskPriority.idle:
        return Duration(seconds: 10);
    }
  }
  
  /// Execute intelligence task
  static Future<void> _executeTask(String taskId) async {
    final task = _activeTasks[taskId];
    if (task == null) return;
    
    try {
      // Update task status
      final startedTask = task.copyWith(
        status: TaskStatus.running,
        startedAt: DateTime.now(),
      );
      _activeTasks[taskId] = startedTask;
      _notifyTaskUpdate(startedTask);
      
      // Execute based on capability
      final result = await _executeTaskByCapability(startedTask);
      
      // Update task with result
      final completedTask = startedTask.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        progress: 1.0,
        result: result,
      );
      
      _activeTasks[taskId] = completedTask;
      _notifyTaskUpdate(completedTask);
      
      // Update statistics
      _tasksCompleted++;
      _totalExecutionTime += completedTask.completedAt!.difference(completedTask.startedAt!);
      _capabilityUsage[task.capability] = (_capabilityUsage[task.capability] ?? 0) + 1;
      
      // Generate insights from task result
      await _generateInsightsFromTask(completedTask);
      
    } catch (e) {
      // Handle task failure
      final failedTask = task.copyWith(
        status: TaskStatus.failed,
        completedAt: DateTime.now(),
        error: e.toString(),
      );
      
      _activeTasks[taskId] = failedTask;
      _notifyTaskUpdate(failedTask);
      _tasksFailed++;
      
      print('Task ${task.name} failed: $e');
    } finally {
      // Cleanup
      _taskTimers.remove(taskId);
      
      // Remove completed/failed tasks after delay
      Timer(Duration(minutes: 5), () {
        _activeTasks.remove(taskId);
      });
    }
  }
  
  /// Execute task based on capability
  static Future<Map<String, dynamic>> _executeTaskByCapability(IntelligenceTask task) async {
    final tabId = _extractTabIdFromTaskId(task.id);
    
    switch (task.capability) {
      case IntelligenceCapability.webAnalysis:
        return await _executeWebAnalysisTask(tabId, task);
      case IntelligenceCapability.automation:
        return await _executeAutomationTask(tabId, task);
      case IntelligenceCapability.aiInteraction:
        return await _executeAIInteractionTask(tabId, task);
      case IntelligenceCapability.performance:
        return await _executePerformanceTask(tabId, task);
      case IntelligenceCapability.security:
        return await _executeSecurityTask(tabId, task);
      case IntelligenceCapability.accessibility:
        return await _executeAccessibilityTask(tabId, task);
      case IntelligenceCapability.learning:
        return await _executeLearningTask(tabId, task);
      case IntelligenceCapability.prediction:
        return await _executePredictionTask(tabId, task);
      case IntelligenceCapability.personalization:
        return await _executePersonalizationTask(tabId, task);
      case IntelligenceCapability.collaboration:
        return await _executeCollaborationTask(tabId, task);
    }
  }
  
  /// Execute web analysis task
  static Future<Map<String, dynamic>> _executeWebAnalysisTask(String? tabId, IntelligenceTask task) async {
    if (tabId == null) return {'error': 'Invalid tab ID'};
    
    final intelligence = WebIntelligenceService.getPageIntelligence(tabId);
    if (intelligence == null) {
      return {'error': 'No page intelligence available'};
    }
    
    return {
      'pageIntelligence': intelligence.toJson(),
      'analysisComplete': true,
      'confidence': intelligence.confidenceScore,
    };
  }
  
  /// Execute automation task
  static Future<Map<String, dynamic>> _executeAutomationTask(String? tabId, IntelligenceTask task) async {
    if (tabId == null) return {'error': 'Invalid tab ID'};
    
    final instruction = task.parameters['instruction'] as String?;
    if (instruction == null) return {'error': 'No instruction provided'};
    
    final automationTask = await WebIntelligenceService.createAutomationTask(tabId, instruction);
    if (automationTask == null) return {'error': 'Failed to create automation task'};
    
    final success = await WebIntelligenceService.executeAutomationTask(tabId, automationTask.id);
    
    return {
      'automationTask': automationTask.toJson(),
      'executed': success,
      'confidence': success ? 0.9 : 0.3,
    };
  }
  
  /// Execute AI interaction task
  static Future<Map<String, dynamic>> _executeAIInteractionTask(String? tabId, IntelligenceTask task) async {
    if (tabId == null) return {'error': 'Invalid tab ID'};
    
    final instruction = task.parameters['instruction'] as String?;
    if (instruction == null) return {'error': 'No instruction provided'};
    
    final result = await AIWebInteractionService.processInstruction(tabId, instruction);
    
    return {
      'aiResult': result.toJson(),
      'confidence': result.confidence,
    };
  }
  
  /// Execute performance task
  static Future<Map<String, dynamic>> _executePerformanceTask(String? tabId, IntelligenceTask task) async {
    if (tabId == null) return {'error': 'Invalid tab ID'};
    
    final metrics = await PerformanceEngineService._collectPerformanceMetrics(tabId);
    if (metrics == null) return {'error': 'Failed to collect performance metrics'};
    
    return {
      'performanceMetrics': metrics.toJson(),
      'coreWebVitalsScore': metrics.coreWebVitalsScore,
      'confidence': 0.95,
    };
  }
  
  /// Execute security task
  static Future<Map<String, dynamic>> _executeSecurityTask(String? tabId, IntelligenceTask task) async {
    if (tabId == null) return {'error': 'Invalid tab ID'};
    
    final controller = _controllers[tabId];
    if (controller == null) return {'error': 'Controller not found'};
    
    final url = await controller.getUrl();
    if (url == null) return {'error': 'No URL available'};
    
    final threatLevel = await BrowserSecurityService.checkUrlSafety(url.toString());
    final events = BrowserSecurityService.getTabSecurityEvents(tabId);
    
    return {
      'threatLevel': threatLevel.name,
      'securityEvents': events.map((e) => e.toJson()).toList(),
      'threatScore': BrowserSecurityService.getThreatScore(tabId),
      'confidence': 0.9,
    };
  }
  
  /// Execute accessibility task
  static Future<Map<String, dynamic>> _executeAccessibilityTask(String? tabId, IntelligenceTask task) async {
    if (tabId == null) return {'error': 'Invalid tab ID'};
    
    final result = await AIWebInteractionService.improveAccessibility(tabId);
    
    return {
      'accessibilityResult': result.toJson(),
      'confidence': result.confidence,
    };
  }
  
  /// Execute learning task
  static Future<Map<String, dynamic>> _executeLearningTask(String? tabId, IntelligenceTask task) async {
    // Implement machine learning task execution
    return {
      'learningComplete': true,
      'confidence': 0.8,
    };
  }
  
  /// Execute prediction task
  static Future<Map<String, dynamic>> _executePredictionTask(String? tabId, IntelligenceTask task) async {
    // Implement predictive browsing task execution
    return {
      'predictions': [],
      'confidence': 0.7,
    };
  }
  
  /// Execute personalization task
  static Future<Map<String, dynamic>> _executePersonalizationTask(String? tabId, IntelligenceTask task) async {
    // Implement personalization task execution
    return {
      'personalizationApplied': true,
      'confidence': 0.8,
    };
  }
  
  /// Execute collaboration task
  static Future<Map<String, dynamic>> _executeCollaborationTask(String? tabId, IntelligenceTask task) async {
    // Implement collaboration task execution
    return {
      'collaborationEnabled': true,
      'confidence': 0.7,
    };
  }
  
  /// Extract tab ID from task ID
  static String? _extractTabIdFromTaskId(String taskId) {
    final parts = taskId.split('_');
    return parts.isNotEmpty ? parts[0] : null;
  }
  
  /// Notify task update
  static void _notifyTaskUpdate(IntelligenceTask task) {
    final tabId = _extractTabIdFromTaskId(task.id);
    if (tabId != null) {
      _taskStreams[tabId]?.add(task);
    }
  }
  
  /// Process intelligence tasks
  static void _processIntelligenceTasks() {
    // Check for stuck tasks
    final now = DateTime.now();
    final stuckTasks = _activeTasks.values.where((task) {
      if (task.status == TaskStatus.running && task.startedAt != null) {
        final runningTime = now.difference(task.startedAt!);
        final maxTime = task.estimatedDuration ?? Duration(minutes: 5);
        return runningTime > maxTime * 2; // 2x estimated time
      }
      return false;
    }).toList();
    
    for (final task in stuckTasks) {
      print('Cancelling stuck task: ${task.name}');
      _activeTasks[task.id] = task.copyWith(
        status: TaskStatus.cancelled,
        completedAt: now,
        error: 'Task timeout',
      );
    }
  }
  
  /// Perform automatic optimization
  static void _performAutoOptimization() {
    if (!_autoOptimization) return;
    
    for (final tabId in _controllers.keys) {
      // Queue optimization tasks
      queueTask(IntelligenceTask(
        id: '${tabId}_auto_optimization_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Auto Optimization',
        description: 'Automatic performance and security optimization',
        capability: IntelligenceCapability.performance,
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        estimatedDuration: Duration(seconds: 3),
      ));
    }
  }
  
  /// Generate insights from completed tasks
  static Future<void> _generateInsightsFromTask(IntelligenceTask task) async {
    final result = task.result;
    if (result.isEmpty) return;
    
    // Generate insights based on task type and results
    switch (task.capability) {
      case IntelligenceCapability.performance:
        await _generatePerformanceInsights(task, result);
        break;
      case IntelligenceCapability.security:
        await _generateSecurityInsights(task, result);
        break;
      case IntelligenceCapability.webAnalysis:
        await _generateWebAnalysisInsights(task, result);
        break;
      default:
        break;
    }
  }
  
  /// Generate performance insights
  static Future<void> _generatePerformanceInsights(IntelligenceTask task, Map<String, dynamic> result) async {
    final metrics = result['performanceMetrics'] as Map<String, dynamic>?;
    if (metrics == null) return;
    
    final coreWebVitalsScore = result['coreWebVitalsScore'] as double? ?? 0.0;
    
    if (coreWebVitalsScore < 0.7) {
      final insight = IntelligenceInsight(
        id: 'perf_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Performance Optimization Needed',
        description: 'Page performance is below optimal levels (${(coreWebVitalsScore * 100).toInt()}%)',
        category: IntelligenceCapability.performance,
        confidence: 0.9,
        data: {'metrics': metrics, 'score': coreWebVitalsScore},
        recommendations: [
          'Enable performance mode',
          'Optimize images and resources',
          'Reduce JavaScript execution time',
          'Improve server response time',
        ],
        generatedAt: DateTime.now(),
      );
      
      _addInsight(insight);
    }
  }
  
  /// Generate security insights
  static Future<void> _generateSecurityInsights(IntelligenceTask task, Map<String, dynamic> result) async {
    final threatLevel = result['threatLevel'] as String?;
    final threatScore = result['threatScore'] as int? ?? 0;
    
    if (threatScore > 50) {
      final insight = IntelligenceInsight(
        id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Security Threats Detected',
        description: 'Multiple security threats detected (threat score: $threatScore)',
        category: IntelligenceCapability.security,
        confidence: 0.95,
        data: {'threatLevel': threatLevel, 'threatScore': threatScore},
        recommendations: [
          'Enable strict security mode',
          'Block suspicious scripts',
          'Use HTTPS-only mode',
          'Enable tracking protection',
        ],
        generatedAt: DateTime.now(),
      );
      
      _addInsight(insight);
    }
  }
  
  /// Generate web analysis insights
  static Future<void> _generateWebAnalysisInsights(IntelligenceTask task, Map<String, dynamic> result) async {
    final intelligence = result['pageIntelligence'] as Map<String, dynamic>?;
    if (intelligence == null) return;
    
    final forms = intelligence['forms'] as List? ?? [];
    final accessibility = intelligence['accessibility'] as Map<String, dynamic>? ?? {};
    
    if (forms.isNotEmpty) {
      final insight = IntelligenceInsight(
        id: 'form_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Forms Detected',
        description: 'Found ${forms.length} form(s) that can be automated',
        category: IntelligenceCapability.automation,
        confidence: 0.8,
        data: {'forms': forms},
        recommendations: [
          'Enable smart autofill',
          'Create automation shortcuts',
          'Save form templates',
        ],
        generatedAt: DateTime.now(),
      );
      
      _addInsight(insight);
    }
    
    final accessibilityScore = accessibility['score'] as double? ?? 1.0;
    if (accessibilityScore < 0.8) {
      final insight = IntelligenceInsight(
        id: 'a11y_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Accessibility Issues Found',
        description: 'Page has accessibility issues (score: ${(accessibilityScore * 100).toInt()}%)',
        category: IntelligenceCapability.accessibility,
        confidence: 0.85,
        data: {'accessibility': accessibility},
        recommendations: [
          'Enable accessibility mode',
          'Add missing alt text',
          'Improve keyboard navigation',
          'Increase color contrast',
        ],
        generatedAt: DateTime.now(),
      );
      
      _addInsight(insight);
    }
  }
  
  /// Generate general insights
  static void _generateInsights() {
    // Generate insights based on overall usage patterns
    _generateUsageInsights();
    _generateTrendInsights();
  }
  
  /// Generate usage insights
  static void _generateUsageInsights() {
    if (_capabilityUsage.isEmpty) return;
    
    final mostUsed = _capabilityUsage.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    if (mostUsed.value > 10) {
      final insight = IntelligenceInsight(
        id: 'usage_${DateTime.now().millisecondsSinceEpoch}',
        title: 'High Usage Pattern Detected',
        description: 'You frequently use ${mostUsed.key.name} features (${mostUsed.value} times)',
        category: mostUsed.key,
        confidence: 0.8,
        data: {'usage': _capabilityUsage},
        recommendations: [
          'Create shortcuts for common tasks',
          'Enable auto-optimization for this feature',
          'Consider upgrading to premium features',
        ],
        generatedAt: DateTime.now(),
      );
      
      _addInsight(insight);
    }
  }
  
  /// Generate trend insights
  static void _generateTrendInsights() {
    final successRate = _tasksCompleted / (_tasksCompleted + _tasksFailed);
    
    if (successRate < 0.8 && _tasksCompleted > 20) {
      final insight = IntelligenceInsight(
        id: 'trend_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Task Success Rate Below Optimal',
        description: 'Task success rate is ${(successRate * 100).toInt()}% (${_tasksFailed} failures)',
        category: IntelligenceCapability.learning,
        confidence: 0.7,
        data: {
          'successRate': successRate,
          'completed': _tasksCompleted,
          'failed': _tasksFailed,
        },
        recommendations: [
          'Check network connectivity',
          'Update browser engine',
          'Reset AI models',
          'Contact support if issues persist',
        ],
        generatedAt: DateTime.now(),
      );
      
      _addInsight(insight);
    }
  }
  
  /// Add insight and notify listeners
  static void _addInsight(IntelligenceInsight insight) {
    _insights.add(insight);
    _insightStream.add(insight);
    
    // Keep only last 50 insights
    if (_insights.length > 50) {
      _insights.removeAt(0);
    }
  }
  
  /// Process natural language command
  static Future<String> processCommand(String tabId, String command) async {
    try {
      // Determine command type and create appropriate task
      final taskType = _determineCommandType(command);
      
      final task = IntelligenceTask(
        id: '${tabId}_command_${DateTime.now().millisecondsSinceEpoch}',
        name: 'User Command',
        description: command,
        capability: taskType,
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        parameters: {'instruction': command},
        createdAt: DateTime.now(),
        estimatedDuration: Duration(seconds: 10),
      );
      
      final taskId = await queueTask(task);
      
      // Wait for task completion
      await _waitForTaskCompletion(taskId);
      
      final completedTask = _activeTasks[taskId];
      if (completedTask?.status == TaskStatus.completed) {
        return 'Command executed successfully: ${completedTask?.result['message'] ?? 'Done'}';
      } else {
        return 'Command failed: ${completedTask?.error ?? 'Unknown error'}';
      }
    } catch (e) {
      return 'Error processing command: $e';
    }
  }
  
  /// Determine command type from natural language
  static IntelligenceCapability _determineCommandType(String command) {
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('click') || lowerCommand.contains('fill') || lowerCommand.contains('automate')) {
      return IntelligenceCapability.automation;
    } else if (lowerCommand.contains('analyze') || lowerCommand.contains('understand')) {
      return IntelligenceCapability.webAnalysis;
    } else if (lowerCommand.contains('optimize') || lowerCommand.contains('speed')) {
      return IntelligenceCapability.performance;
    } else if (lowerCommand.contains('secure') || lowerCommand.contains('safe')) {
      return IntelligenceCapability.security;
    } else if (lowerCommand.contains('accessible') || lowerCommand.contains('a11y')) {
      return IntelligenceCapability.accessibility;
    } else {
      return IntelligenceCapability.aiInteraction;
    }
  }
  
  /// Wait for task completion
  static Future<void> _waitForTaskCompletion(String taskId) async {
    while (true) {
      final task = _activeTasks[taskId];
      if (task == null || 
          task.status == TaskStatus.completed || 
          task.status == TaskStatus.failed || 
          task.status == TaskStatus.cancelled) {
        break;
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
  
  /// Get task stream for tab
  static Stream<IntelligenceTask>? getTaskStream(String tabId) {
    return _taskStreams[tabId]?.stream;
  }
  
  /// Get insight stream
  static Stream<IntelligenceInsight> get insightStream => _insightStream.stream;
  
  /// Get active tasks
  static List<IntelligenceTask> getActiveTasks([String? tabId]) {
    if (tabId != null) {
      return _activeTasks.values
          .where((task) => _extractTabIdFromTaskId(task.id) == tabId)
          .toList();
    }
    return _activeTasks.values.toList();
  }
  
  /// Get insights
  static List<IntelligenceInsight> getInsights([IntelligenceCapability? category]) {
    if (category != null) {
      return _insights.where((insight) => insight.category == category).toList();
    }
    return List.from(_insights);
  }
  
  /// Cancel task
  static bool cancelTask(String taskId) {
    final task = _activeTasks[taskId];
    if (task != null && task.status == TaskStatus.pending) {
      _activeTasks[taskId] = task.copyWith(
        status: TaskStatus.cancelled,
        completedAt: DateTime.now(),
      );
      
      _taskTimers[taskId]?.cancel();
      _taskTimers.remove(taskId);
      
      return true;
    }
    return false;
  }
  
  /// Enable/disable capability
  static void setCapabilityEnabled(IntelligenceCapability capability, bool enabled) {
    if (enabled) {
      _enabledCapabilities.add(capability);
    } else {
      _enabledCapabilities.remove(capability);
    }
    _saveConfiguration();
  }
  
  /// Configure intelligence settings
  static void configure({
    bool? autoOptimization,
    bool? predictiveBrowsing,
    bool? learningMode,
    double? confidenceThreshold,
    int? maxConcurrentTasks,
  }) {
    if (autoOptimization != null) _autoOptimization = autoOptimization;
    if (predictiveBrowsing != null) _predictiveBrowsing = predictiveBrowsing;
    if (learningMode != null) _learningMode = learningMode;
    if (confidenceThreshold != null) _confidenceThreshold = confidenceThreshold.clamp(0.0, 1.0);
    if (maxConcurrentTasks != null) _maxConcurrentTasks = maxConcurrentTasks.clamp(1, 20);
    
    _saveConfiguration();
  }
  
  /// Save configuration to storage
  static void _saveConfiguration() {
    final config = {
      'autoOptimization': _autoOptimization,
      'predictiveBrowsing': _predictiveBrowsing,
      'learningMode': _learningMode,
      'confidenceThreshold': _confidenceThreshold,
      'maxConcurrentTasks': _maxConcurrentTasks,
      'enabledCapabilities': _enabledCapabilities.map((c) => c.name).toList(),
    };
    
    StorageService.setSetting('intelligence_config', jsonEncode(config));
  }
  
  /// Get intelligence statistics
  static Map<String, dynamic> getIntelligenceStats() {
    return {
      'registeredTabs': _controllers.length,
      'activeTasks': _activeTasks.length,
      'completedTasks': _tasksCompleted,
      'failedTasks': _tasksFailed,
      'totalExecutionTime': _totalExecutionTime.inMilliseconds,
      'averageExecutionTime': _tasksCompleted > 0 
          ? _totalExecutionTime.inMilliseconds / _tasksCompleted 
          : 0,
      'successRate': _tasksCompleted / (_tasksCompleted + _tasksFailed),
      'capabilityUsage': _capabilityUsage,
      'enabledCapabilities': _enabledCapabilities.map((c) => c.name).toList(),
      'insights': _insights.length,
      'configuration': {
        'autoOptimization': _autoOptimization,
        'predictiveBrowsing': _predictiveBrowsing,
        'learningMode': _learningMode,
        'confidenceThreshold': _confidenceThreshold,
        'maxConcurrentTasks': _maxConcurrentTasks,
      },
    };
  }
  
  /// Cleanup resources for tab
  static Future<void> cleanup(String tabId) async {
    _controllers.remove(tabId);
    
    // Cancel all tasks for this tab
    final tabTasks = _activeTasks.values
        .where((task) => _extractTabIdFromTaskId(task.id) == tabId)
        .toList();
    
    for (final task in tabTasks) {
      cancelTask(task.id);
    }
    
    // Close task stream
    await _taskStreams[tabId]?.close();
    _taskStreams.remove(tabId);
    
    // Cleanup sub-services
    WebIntelligenceService.cleanup(tabId);
    AIWebInteractionService.cleanup(tabId);
    PerformanceEngineService.cleanup(tabId);
    JavaScriptEngineService.cleanup(tabId);
  }
  
  /// Cleanup all resources
  static Future<void> cleanupAll() async {
    // Cancel all tasks
    for (final taskId in _activeTasks.keys.toList()) {
      cancelTask(taskId);
    }
    
    // Cancel all timers
    for (final timer in _taskTimers.values) {
      timer.cancel();
    }
    _taskTimers.clear();
    
    // Close all streams
    for (final stream in _taskStreams.values) {
      await stream.close();
    }
    _taskStreams.clear();
    
    await _insightStream.close();
    
    // Clear data
    _controllers.clear();
    _activeTasks.clear();
    _insights.clear();
    
    // Cleanup sub-services
    WebIntelligenceService.cleanupAll();
    AIWebInteractionService.cleanupAll();
    PerformanceEngineService.cleanupAll();
  }
}