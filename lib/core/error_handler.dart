import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error handler for the application
class ErrorHandler {
  static final List<AppError> _errors = [];
  static final StreamController<AppError> _errorController = StreamController.broadcast();
  
  static Stream<AppError> get errorStream => _errorController.stream;
  static List<AppError> get errors => List.unmodifiable(_errors);
  
  /// Initialize error handling
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      final error = AppError(
        type: ErrorType.framework,
        message: details.exception.toString(),
        stackTrace: details.stack.toString(),
        timestamp: DateTime.now(),
      );
      _handleError(error);
    };
    
    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      final appError = AppError(
        type: ErrorType.async,
        message: error.toString(),
        stackTrace: stack.toString(),
        timestamp: DateTime.now(),
      );
      _handleError(appError);
      return true;
    };
  }
  
  /// Report an error
  static void reportError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorType type = ErrorType.general,
    Map<String, dynamic>? context,
  }) {
    final appError = AppError(
      type: type,
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
      context: context,
      timestamp: DateTime.now(),
    );
    _handleError(appError);
  }
  
  /// Handle error internally
  static void _handleError(AppError error) {
    _errors.add(error);
    _errorController.add(error);
    
    // Log error
    debugPrint('Error [${error.type}]: ${error.message}');
    if (error.stackTrace != null) {
      debugPrint('Stack trace: ${error.stackTrace}');
    }
    
    // Keep only last 100 errors
    if (_errors.length > 100) {
      _errors.removeAt(0);
    }
  }
  
  /// Clear all errors
  static void clearErrors() {
    _errors.clear();
  }
  
  /// Get errors by type
  static List<AppError> getErrorsByType(ErrorType type) {
    return _errors.where((error) => error.type == type).toList();
  }
  
  /// Dispose resources
  static void dispose() {
    _errorController.close();
  }
}

/// Application error types
enum ErrorType {
  framework,
  async,
  network,
  storage,
  security,
  extension,
  browser,
  ai,
  general,
}

/// Application error model
class AppError {
  final ErrorType type;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  
  AppError({
    required this.type,
    required this.message,
    this.stackTrace,
    this.context,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'message': message,
    'stackTrace': stackTrace,
    'context': context,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory AppError.fromJson(Map<String, dynamic> json) => AppError(
    type: ErrorType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => ErrorType.general,
    ),
    message: json['message'],
    stackTrace: json['stackTrace'],
    context: json['context'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}