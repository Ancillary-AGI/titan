import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

/// Bridge to communicate with the Rust Titan Engine
class RustEngineBridge {
  static RustEngineBridge? _instance;
  late DynamicLibrary _lib;
  bool _initialized = false;

  // Function signatures
  late int Function() _titanEngineInit;
  late int Function() _titanEngineShutdown;
  late Pointer<Utf8> Function(Pointer<Utf8>) _titanEngineLoadPage;
  late Pointer<Utf8> Function(Pointer<Utf8>) _titanEngineExecuteJavaScript;
  late Pointer<Utf8> Function(Pointer<Utf8>) _titanEngineGetAiAnalysis;
  late int Function(Pointer<Utf8>) _titanEngineValidateUrlSecurity;
  late Pointer<Utf8> Function() _titanEngineGetNetworkMetrics;
  late int Function(int, int, int, int, int, int) _titanEngineSetConfig;
  late Pointer<Utf8> Function() _titanEngineGetPerformanceMetrics;
  late void Function(Pointer<Utf8>) _titanEngineFreeString;
  late Pointer<Utf8> Function() _titanEngineGetVersion;
  late int Function() _titanEngineIsInitialized;
  late int Function(Pointer<Utf8>) _titanEngineMediaPlay;
  late int Function(Pointer<Utf8>) _titanEngineMediaPause;
  late int Function(Pointer<Utf8>, double) _titanEngineMediaSetVolume;
  late int Function(Pointer<Utf8>, Pointer<Utf8>) _titanEngineStorageSet;
  late Pointer<Utf8> Function(Pointer<Utf8>) _titanEngineStorageGet;

  // Callback types
  typedef ProgressCallbackNative = Void Function(Double progress);
  typedef EventCallbackNative = Void Function(Pointer<Utf8> eventType, Pointer<Utf8> eventData);
  typedef ErrorCallbackNative = Void Function(Pointer<Utf8> errorMessage);

  typedef ProgressCallbackDart = void Function(double progress);
  typedef EventCallbackDart = void Function(String eventType, String eventData);
  typedef ErrorCallbackDart = void Function(String errorMessage);

  late void Function(Pointer<NativeFunction<ProgressCallbackNative>>) _titanEngineSetProgressCallback;
  late void Function(Pointer<NativeFunction<EventCallbackNative>>) _titanEngineSetEventCallback;
  late void Function(Pointer<NativeFunction<ErrorCallbackNative>>) _titanEngineSetErrorCallback;

  // Callback handlers
  ProgressCallbackDart? _progressCallback;
  EventCallbackDart? _eventCallback;
  ErrorCallbackDart? _errorCallback;

  RustEngineBridge._();

  static RustEngineBridge get instance {
    _instance ??= RustEngineBridge._();
    return _instance!;
  }

  /// Initialize the Rust engine bridge
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Load the dynamic library
      if (Platform.isWindows) {
        _lib = DynamicLibrary.open('titan_engine.dll');
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('libtitan_engine.dylib');
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libtitan_engine.so');
      } else {
        throw UnsupportedError('Platform not supported');
      }

      // Load function pointers
      _loadFunctions();

      // Initialize the Rust engine
      final result = _titanEngineInit();
      if (result == 1) {
        _initialized = true;
        _setupCallbacks();
        return true;
      }
    } catch (e) {
      print('Failed to initialize Rust engine: $e');
    }

    return false;
  }

  void _loadFunctions() {
    _titanEngineInit = _lib.lookupFunction<Int32 Function(), int Function()>('titan_engine_init');
    _titanEngineShutdown = _lib.lookupFunction<Int32 Function(), int Function()>('titan_engine_shutdown');
    _titanEngineLoadPage = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('titan_engine_load_page');
    _titanEngineExecuteJavaScript = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('titan_engine_execute_javascript');
    _titanEngineGetAiAnalysis = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('titan_engine_get_ai_analysis');
    _titanEngineValidateUrlSecurity = _lib.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('titan_engine_validate_url_security');
    _titanEngineGetNetworkMetrics = _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('titan_engine_get_network_metrics');
    _titanEngineSetConfig = _lib.lookupFunction<Int32 Function(Int32, Int32, Int32, Int32, Int32, Int32), int Function(int, int, int, int, int, int)>('titan_engine_set_config');
    _titanEngineGetPerformanceMetrics = _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('titan_engine_get_performance_metrics');
    _titanEngineFreeString = _lib.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>('titan_engine_free_string');
    _titanEngineGetVersion = _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('titan_engine_get_version');
    _titanEngineIsInitialized = _lib.lookupFunction<Int32 Function(), int Function()>('titan_engine_is_initialized');
    _titanEngineMediaPlay = _lib.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('titan_engine_media_play');
    _titanEngineMediaPause = _lib.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('titan_engine_media_pause');
    _titanEngineMediaSetVolume = _lib.lookupFunction<Int32 Function(Pointer<Utf8>, Double), int Function(Pointer<Utf8>, double)>('titan_engine_media_set_volume');
    _titanEngineStorageSet = _lib.lookupFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>), int Function(Pointer<Utf8>, Pointer<Utf8>)>('titan_engine_storage_set');
    _titanEngineStorageGet = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('titan_engine_storage_get');

    // Callback setters
    _titanEngineSetProgressCallback = _lib.lookupFunction<Void Function(Pointer<NativeFunction<ProgressCallbackNative>>), void Function(Pointer<NativeFunction<ProgressCallbackNative>>)>('titan_engine_set_progress_callback');
    _titanEngineSetEventCallback = _lib.lookupFunction<Void Function(Pointer<NativeFunction<EventCallbackNative>>), void Function(Pointer<NativeFunction<EventCallbackNative>>)>('titan_engine_set_event_callback');
    _titanEngineSetErrorCallback = _lib.lookupFunction<Void Function(Pointer<NativeFunction<ErrorCallbackNative>>), void Function(Pointer<NativeFunction<ErrorCallbackNative>>)>('titan_engine_set_error_callback');
  }

  void _setupCallbacks() {
    // Progress callback
    final progressCallback = Pointer.fromFunction<ProgressCallbackNative>(_onProgress);
    _titanEngineSetProgressCallback(progressCallback);

    // Event callback
    final eventCallback = Pointer.fromFunction<EventCallbackNative>(_onEvent);
    _titanEngineSetEventCallback(eventCallback);

    // Error callback
    final errorCallback = Pointer.fromFunction<ErrorCallbackNative>(_onError);
    _titanEngineSetErrorCallback(errorCallback);
  }

  static void _onProgress(double progress) {
    final instance = RustEngineBridge.instance;
    instance._progressCallback?.call(progress);
  }

  static void _onEvent(Pointer<Utf8> eventType, Pointer<Utf8> eventData) {
    final instance = RustEngineBridge.instance;
    final eventTypeStr = eventType.toDartString();
    final eventDataStr = eventData.toDartString();
    instance._eventCallback?.call(eventTypeStr, eventDataStr);
  }

  static void _onError(Pointer<Utf8> errorMessage) {
    final instance = RustEngineBridge.instance;
    final errorStr = errorMessage.toDartString();
    instance._errorCallback?.call(errorStr);
  }

  /// Set callback handlers
  void setProgressCallback(ProgressCallbackDart callback) {
    _progressCallback = callback;
  }

  void setEventCallback(EventCallbackDart callback) {
    _eventCallback = callback;
  }

  void setErrorCallback(ErrorCallbackDart callback) {
    _errorCallback = callback;
  }

  /// Load a web page
  Future<Map<String, dynamic>> loadPage(String url) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final urlPtr = url.toNativeUtf8();
    try {
      final resultPtr = _titanEngineLoadPage(urlPtr);
      if (resultPtr.address == 0) {
        return {'success': false, 'error': 'Failed to load page'};
      }

      final resultStr = resultPtr.toDartString();
      _titanEngineFreeString(resultPtr);

      return jsonDecode(resultStr) as Map<String, dynamic>;
    } finally {
      malloc.free(urlPtr);
    }
  }

  /// Execute JavaScript code
  Future<Map<String, dynamic>> executeJavaScript(String code) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final codePtr = code.toNativeUtf8();
    try {
      final resultPtr = _titanEngineExecuteJavaScript(codePtr);
      if (resultPtr.address == 0) {
        return {'success': false, 'error': 'Failed to execute JavaScript'};
      }

      final resultStr = resultPtr.toDartString();
      _titanEngineFreeString(resultPtr);

      return jsonDecode(resultStr) as Map<String, dynamic>;
    } finally {
      malloc.free(codePtr);
    }
  }

  /// Get AI analysis for a page
  Future<Map<String, dynamic>> getAiAnalysis(String url) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final urlPtr = url.toNativeUtf8();
    try {
      final resultPtr = _titanEngineGetAiAnalysis(urlPtr);
      if (resultPtr.address == 0) {
        return {'error': 'Failed to get AI analysis'};
      }

      final resultStr = resultPtr.toDartString();
      _titanEngineFreeString(resultPtr);

      return jsonDecode(resultStr) as Map<String, dynamic>;
    } finally {
      malloc.free(urlPtr);
    }
  }

  /// Validate URL security
  Future<bool> validateUrlSecurity(String url) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final urlPtr = url.toNativeUtf8();
    try {
      final result = _titanEngineValidateUrlSecurity(urlPtr);
      return result == 1;
    } finally {
      malloc.free(urlPtr);
    }
  }

  /// Get network metrics
  Future<Map<String, dynamic>> getNetworkMetrics() async {
    if (!_initialized) throw StateError('Engine not initialized');

    final resultPtr = _titanEngineGetNetworkMetrics();
    if (resultPtr.address == 0) {
      return {'error': 'Failed to get network metrics'};
    }

    final resultStr = resultPtr.toDartString();
    _titanEngineFreeString(resultPtr);

    return jsonDecode(resultStr) as Map<String, dynamic>;
  }

  /// Set engine configuration
  Future<bool> setConfig({
    required bool javascriptEnabled,
    required bool webglEnabled,
    required bool mediaEnabled,
    required bool aiEnabled,
    required int securityLevel,
    required int maxMemoryMb,
  }) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final result = _titanEngineSetConfig(
      javascriptEnabled ? 1 : 0,
      webglEnabled ? 1 : 0,
      mediaEnabled ? 1 : 0,
      aiEnabled ? 1 : 0,
      securityLevel,
      maxMemoryMb,
    );

    return result == 1;
  }

  /// Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    if (!_initialized) throw StateError('Engine not initialized');

    final resultPtr = _titanEngineGetPerformanceMetrics();
    if (resultPtr.address == 0) {
      return {'error': 'Failed to get performance metrics'};
    }

    final resultStr = resultPtr.toDartString();
    _titanEngineFreeString(resultPtr);

    return jsonDecode(resultStr) as Map<String, dynamic>;
  }

  /// Get engine version
  String getVersion() {
    if (!_initialized) return 'Unknown';

    final versionPtr = _titanEngineGetVersion();
    if (versionPtr.address == 0) return 'Unknown';

    final version = versionPtr.toDartString();
    _titanEngineFreeString(versionPtr);

    return version;
  }

  /// Check if engine is initialized
  bool get isInitialized {
    if (!_initialized) return false;
    return _titanEngineIsInitialized() == 1;
  }

  /// Media control methods
  Future<bool> mediaPlay(String elementId) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final elementIdPtr = elementId.toNativeUtf8();
    try {
      final result = _titanEngineMediaPlay(elementIdPtr);
      return result == 1;
    } finally {
      malloc.free(elementIdPtr);
    }
  }

  Future<bool> mediaPause(String elementId) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final elementIdPtr = elementId.toNativeUtf8();
    try {
      final result = _titanEngineMediaPause(elementIdPtr);
      return result == 1;
    } finally {
      malloc.free(elementIdPtr);
    }
  }

  Future<bool> mediaSetVolume(String elementId, double volume) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final elementIdPtr = elementId.toNativeUtf8();
    try {
      final result = _titanEngineMediaSetVolume(elementIdPtr, volume);
      return result == 1;
    } finally {
      malloc.free(elementIdPtr);
    }
  }

  /// Storage methods
  Future<bool> storageSet(String key, String value) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final keyPtr = key.toNativeUtf8();
    final valuePtr = value.toNativeUtf8();
    try {
      final result = _titanEngineStorageSet(keyPtr, valuePtr);
      return result == 1;
    } finally {
      malloc.free(keyPtr);
      malloc.free(valuePtr);
    }
  }

  Future<String?> storageGet(String key) async {
    if (!_initialized) throw StateError('Engine not initialized');

    final keyPtr = key.toNativeUtf8();
    try {
      final resultPtr = _titanEngineStorageGet(keyPtr);
      if (resultPtr.address == 0) return null;

      final result = resultPtr.toDartString();
      _titanEngineFreeString(resultPtr);

      return result;
    } finally {
      malloc.free(keyPtr);
    }
  }

  /// Shutdown the engine
  Future<void> shutdown() async {
    if (!_initialized) return;

    _titanEngineShutdown();
    _initialized = false;
  }
}

/// Engine configuration class
class EngineConfig {
  final bool javascriptEnabled;
  final bool webglEnabled;
  final bool mediaEnabled;
  final bool aiEnabled;
  final int securityLevel;
  final int maxMemoryMb;

  const EngineConfig({
    this.javascriptEnabled = true,
    this.webglEnabled = true,
    this.mediaEnabled = true,
    this.aiEnabled = true,
    this.securityLevel = 2,
    this.maxMemoryMb = 2048,
  });
}

/// Performance metrics class
class PerformanceMetrics {
  final double memoryUsageMb;
  final double cpuUsagePercent;
  final double gpuUsagePercent;
  final double renderFps;
  final int javascriptExecutionTimeMs;
  final int layoutTimeMs;
  final int paintTimeMs;

  const PerformanceMetrics({
    required this.memoryUsageMb,
    required this.cpuUsagePercent,
    required this.gpuUsagePercent,
    required this.renderFps,
    required this.javascriptExecutionTimeMs,
    required this.layoutTimeMs,
    required this.paintTimeMs,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      memoryUsageMb: (json['memory_usage_mb'] as num).toDouble(),
      cpuUsagePercent: (json['cpu_usage_percent'] as num).toDouble(),
      gpuUsagePercent: (json['gpu_usage_percent'] as num).toDouble(),
      renderFps: (json['render_fps'] as num).toDouble(),
      javascriptExecutionTimeMs: json['javascript_execution_time_ms'] as int,
      layoutTimeMs: json['layout_time_ms'] as int,
      paintTimeMs: json['paint_time_ms'] as int,
    );
  }
}

/// Network metrics class
class NetworkMetrics {
  final int totalRequests;
  final int failedRequests;
  final int totalBytesReceived;
  final double cacheHitRatio;
  final int averageLoadTimeMs;

  const NetworkMetrics({
    required this.totalRequests,
    required this.failedRequests,
    required this.totalBytesReceived,
    required this.cacheHitRatio,
    required this.averageLoadTimeMs,
  });

  factory NetworkMetrics.fromJson(Map<String, dynamic> json) {
    return NetworkMetrics(
      totalRequests: json['total_requests'] as int,
      failedRequests: json['failed_requests'] as int,
      totalBytesReceived: json['total_bytes_received'] as int,
      cacheHitRatio: (json['cache_hit_ratio'] as num).toDouble(),
      averageLoadTimeMs: json['average_load_time_ms'] as int,
    );
  }
}

/// AI analysis result class
class AIAnalysisResult {
  final String url;
  final List<AIInsight> insights;
  final double sentiment;
  final String language;

  const AIAnalysisResult({
    required this.url,
    required this.insights,
    required this.sentiment,
    required this.language,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    final insightsJson = json['insights'] as List<dynamic>;
    final insights = insightsJson
        .map((insight) => AIInsight.fromJson(insight as Map<String, dynamic>))
        .toList();

    return AIAnalysisResult(
      url: json['url'] as String,
      insights: insights,
      sentiment: (json['sentiment'] as num).toDouble(),
      language: json['language'] as String,
    );
  }
}

/// AI insight class
class AIInsight {
  final String type;
  final String title;
  final String description;
  final double confidence;

  const AIInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}