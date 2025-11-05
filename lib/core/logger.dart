import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Application logger with file and console output
class Logger {
  static Logger? _instance;
  static Logger get instance => _instance ??= Logger._();
  
  Logger._();
  
  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logController = StreamController.broadcast();
  File? _logFile;
  bool _isInitialized = false;
  
  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  bool get isInitialized => _isInitialized;
  
  /// Initialize logger
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final logsDir = Directory('${appDir.path}/logs');
        if (!await logsDir.exists()) {
          await logsDir.create(recursive: true);
        }
        
        final now = DateTime.now();
        final fileName = 'titan_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.log';
        _logFile = File('${logsDir.path}/$fileName');
      }
      
      _isInitialized = true;
      info('Logger initialized');
    } catch (e) {
      debugPrint('Failed to initialize logger: $e');
    }
  }
  
  /// Log debug message
  void debug(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.debug, message, context: context);
  }
  
  /// Log info message
  void info(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.info, message, context: context);
  }
  
  /// Log warning message
  void warning(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.warning, message, context: context);
  }
  
  /// Log error message
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }
  
  /// Log critical message
  void critical(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _log(
      LogLevel.critical,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }
  
  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final entry = LogEntry(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      timestamp: DateTime.now(),
    );
    
    _logs.add(entry);
    _logController.add(entry);
    
    // Console output
    _printToConsole(entry);
    
    // File output
    _writeToFile(entry);
    
    // Keep only last 1000 logs in memory
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
  }
  
  /// Print log to console
  void _printToConsole(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String();
    final levelStr = entry.level.toString().split('.').last.toUpperCase();
    final message = '[$timestamp] [$levelStr] ${entry.message}';
    
    switch (entry.level) {
      case LogLevel.debug:
        if (kDebugMode) debugPrint(message);
        break;
      case LogLevel.info:
        debugPrint(message);
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $message');
        break;
      case LogLevel.error:
        debugPrint('❌ $message');
        if (entry.error != null) {
          debugPrint('Error: ${entry.error}');
        }
        if (entry.stackTrace != null) {
          debugPrint('Stack trace: ${entry.stackTrace}');
        }
        break;
      case LogLevel.critical:
        debugPrint('🚨 $message');
        if (entry.error != null) {
          debugPrint('Error: ${entry.error}');
        }
        if (entry.stackTrace != null) {
          debugPrint('Stack trace: ${entry.stackTrace}');
        }
        break;
    }
  }
  
  /// Write log to file
  void _writeToFile(LogEntry entry) {
    if (_logFile == null || kIsWeb) return;
    
    try {
      final logLine = jsonEncode(entry.toJson()) + '\n';
      _logFile!.writeAsStringSync(logLine, mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write log to file: $e');
    }
  }
  
  /// Get logs by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }
  
  /// Clear all logs
  void clearLogs() {
    _logs.clear();
  }
  
  /// Export logs to file
  Future<File?> exportLogs() async {
    if (kIsWeb) return null;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final exportFile = File('${appDir.path}/titan_logs_export.json');
      
      final logsJson = _logs.map((log) => log.toJson()).toList();
      await exportFile.writeAsString(jsonEncode(logsJson));
      
      return exportFile;
    } catch (e) {
      error('Failed to export logs', error: e);
      return null;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _logController.close();
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Log entry model
class LogEntry {
  final LogLevel level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  
  LogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'level': level.toString(),
    'message': message,
    'error': error?.toString(),
    'stackTrace': stackTrace?.toString(),
    'context': context,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    level: LogLevel.values.firstWhere(
      (e) => e.toString() == json['level'],
      orElse: () => LogLevel.info,
    ),
    message: json['message'],
    error: json['error'],
    stackTrace: json['stackTrace'] != null 
        ? StackTrace.fromString(json['stackTrace'])
        : null,
    context: json['context'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}