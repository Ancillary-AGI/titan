import 'package:uuid/uuid.dart';

enum AITaskType {
  webSearch,
  dataExtraction,
  formFilling,
  navigation,
  pageSummary,
  contentSummary,
  translation,
  accessibility,
  performance,
  seo,
  security,
  automation,
  testing,
  monitoring,
  custom,
}

enum AITaskStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
  paused,
}

enum AITaskPriority {
  low,
  normal,
  high,
  urgent,
}

enum AITaskCategory {
  browsing,
  analysis,
  automation,
  extraction,
  testing,
  monitoring,
  utility,
}

class AITask {
  final String id;
  final AITaskType type;
  final String description;
  final Map<String, dynamic> parameters;
  final AITaskPriority priority;
  final AITaskCategory category;
  final String? parentTaskId;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  AITaskStatus status;
  String? result;
  String? error;
  DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;
  DateTime? lastUpdated;
  double progress;
  int retryCount;
  int maxRetries;
  Duration? estimatedDuration;
  Duration? actualDuration;
  
  AITask({
    String? id,
    required this.type,
    required this.description,
    required this.parameters,
    this.priority = AITaskPriority.normal,
    this.category = AITaskCategory.browsing,
    this.parentTaskId,
    this.tags = const [],
    this.metadata = const {},
    this.status = AITaskStatus.pending,
    this.result,
    this.error,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.lastUpdated,
    this.progress = 0.0,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.estimatedDuration,
    this.actualDuration,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  
  AITask copyWith({
    AITaskType? type,
    String? description,
    Map<String, dynamic>? parameters,
    AITaskPriority? priority,
    AITaskCategory? category,
    String? parentTaskId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    AITaskStatus? status,
    String? result,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastUpdated,
    double? progress,
    int? retryCount,
    int? maxRetries,
    Duration? estimatedDuration,
    Duration? actualDuration,
  }) {
    return AITask(
      id: id,
      type: type ?? this.type,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      progress: progress ?? this.progress,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'parameters': parameters,
      'priority': priority.name,
      'category': category.name,
      'parentTaskId': parentTaskId,
      'tags': tags,
      'metadata': metadata,
      'status': status.name,
      'result': result,
      'error': error,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'progress': progress,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'estimatedDuration': estimatedDuration?.inMilliseconds,
      'actualDuration': actualDuration?.inMilliseconds,
    };
  }
  
  factory AITask.fromJson(Map<String, dynamic> json) {
    return AITask(
      id: json['id'],
      type: AITaskType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AITaskType.custom,
      ),
      description: json['description'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      priority: AITaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => AITaskPriority.normal,
      ),
      category: AITaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AITaskCategory.browsing,
      ),
      parentTaskId: json['parentTaskId'],
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      status: AITaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AITaskStatus.pending,
      ),
      result: json['result'],
      error: json['error'],
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
      progress: json['progress']?.toDouble() ?? 0.0,
      retryCount: json['retryCount'] ?? 0,
      maxRetries: json['maxRetries'] ?? 3,
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(milliseconds: json['estimatedDuration'])
          : null,
      actualDuration: json['actualDuration'] != null
          ? Duration(milliseconds: json['actualDuration'])
          : null,
    );
  }
  
  // Utility methods
  bool get isRunning => status == AITaskStatus.running;
  bool get isCompleted => status == AITaskStatus.completed;
  bool get isFailed => status == AITaskStatus.failed;
  bool get isCancelled => status == AITaskStatus.cancelled;
  bool get isPending => status == AITaskStatus.pending;
  bool get isPaused => status == AITaskStatus.paused;
  
  bool get canRetry => isFailed && retryCount < maxRetries;
  bool get canCancel => isRunning || isPending || isPaused;
  bool get canPause => isRunning;
  bool get canResume => isPaused;
  
  Duration? get elapsedTime {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }
  
  Duration? get remainingTime {
    if (estimatedDuration == null || startedAt == null || progress <= 0) {
      return null;
    }
    
    final elapsed = elapsedTime!;
    final totalEstimated = Duration(
      milliseconds: (elapsed.inMilliseconds / progress).round(),
    );
    
    return totalEstimated - elapsed;
  }
  
  String get statusDisplayName {
    switch (status) {
      case AITaskStatus.pending:
        return 'Pending';
      case AITaskStatus.running:
        return 'Running';
      case AITaskStatus.completed:
        return 'Completed';
      case AITaskStatus.failed:
        return 'Failed';
      case AITaskStatus.cancelled:
        return 'Cancelled';
      case AITaskStatus.paused:
        return 'Paused';
    }
  }
  
  String get typeDisplayName {
    switch (type) {
      case AITaskType.webSearch:
        return 'Web Search';
      case AITaskType.dataExtraction:
        return 'Data Extraction';
      case AITaskType.formFilling:
        return 'Form Filling';
      case AITaskType.navigation:
        return 'Navigation';
      case AITaskType.pageSummary:
        return 'Page Summary';
      case AITaskType.contentSummary:
        return 'Content Summary';
      case AITaskType.translation:
        return 'Translation';
      case AITaskType.accessibility:
        return 'Accessibility Analysis';
      case AITaskType.performance:
        return 'Performance Analysis';
      case AITaskType.seo:
        return 'SEO Analysis';
      case AITaskType.security:
        return 'Security Analysis';
      case AITaskType.automation:
        return 'Automation';
      case AITaskType.testing:
        return 'Testing';
      case AITaskType.monitoring:
        return 'Monitoring';
      case AITaskType.custom:
        return 'Custom Task';
    }
  }
  
  String get priorityDisplayName {
    switch (priority) {
      case AITaskPriority.low:
        return 'Low';
      case AITaskPriority.normal:
        return 'Normal';
      case AITaskPriority.high:
        return 'High';
      case AITaskPriority.urgent:
        return 'Urgent';
    }
  }
  
  String get categoryDisplayName {
    switch (category) {
      case AITaskCategory.browsing:
        return 'Browsing';
      case AITaskCategory.analysis:
        return 'Analysis';
      case AITaskCategory.automation:
        return 'Automation';
      case AITaskCategory.extraction:
        return 'Extraction';
      case AITaskCategory.testing:
        return 'Testing';
      case AITaskCategory.monitoring:
        return 'Monitoring';
      case AITaskCategory.utility:
        return 'Utility';
    }
  }
  
  @override
  String toString() {
    return 'AITask(id: $id, type: $type, status: $status, progress: $progress)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AITask && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}