import 'package:uuid/uuid.dart';

enum AITaskType {
  webSearch,
  dataExtraction,
  formFilling,
  navigation,
  contentSummary,
  translation,
  custom,
}

enum AITaskStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

class AITask {
  final String id;
  final AITaskType type;
  final String description;
  final Map<String, dynamic> parameters;
  AITaskStatus status;
  String? result;
  String? error;
  DateTime createdAt;
  DateTime? completedAt;
  double progress;
  
  AITask({
    String? id,
    required this.type,
    required this.description,
    required this.parameters,
    this.status = AITaskStatus.pending,
    this.result,
    this.error,
    DateTime? createdAt,
    this.completedAt,
    this.progress = 0.0,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  
  AITask copyWith({
    AITaskType? type,
    String? description,
    Map<String, dynamic>? parameters,
    AITaskStatus? status,
    String? result,
    String? error,
    DateTime? completedAt,
    double? progress,
  }) {
    return AITask(
      id: id,
      type: type ?? this.type,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'parameters': parameters,
      'status': status.name,
      'result': result,
      'error': error,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'progress': progress,
    };
  }
  
  factory AITask.fromJson(Map<String, dynamic> json) {
    return AITask(
      id: json['id'],
      type: AITaskType.values.firstWhere((e) => e.name == json['type']),
      description: json['description'],
      parameters: json['parameters'],
      status: AITaskStatus.values.firstWhere((e) => e.name == json['status']),
      result: json['result'],
      error: json['error'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      progress: json['progress']?.toDouble() ?? 0.0,
    );
  }
}