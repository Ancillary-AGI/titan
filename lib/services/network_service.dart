import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Consolidated network service
class NetworkService {
  late Dio _dio;
  final Map<String, CancelToken> _activeRequests = {};
  bool _isInitialized = false;
  bool _isOnline = true;
  
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    
    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add custom headers
        options.headers['User-Agent'] = 'TitanBrowser/1.0';
        handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('Network error: ${error.message}');
        handler.next(error);
      },
    ));
    
    // Start connectivity monitoring
    _startConnectivityMonitoring();
    
    _isInitialized = true;
  }
  
  /// Make HTTP GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    _activeRequests[path] = token;
    
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: token,
      );
      return response;
    } finally {
      _activeRequests.remove(path);
    }
  }
  
  /// Make HTTP POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    _activeRequests[path] = token;
    
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: token,
      );
      return response;
    } finally {
      _activeRequests.remove(path);
    }
  }
  
  /// Download file
  Future<void> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    _activeRequests[url] = token;
    
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: token,
      );
    } finally {
      _activeRequests.remove(url);
    }
  }
  
  /// Cancel request
  void cancelRequest(String path) {
    final token = _activeRequests[path];
    if (token != null && !token.isCancelled) {
      token.cancel('Request cancelled by user');
    }
  }
  
  /// Cancel all active requests
  void cancelAllRequests() {
    for (final token in _activeRequests.values) {
      if (!token.isCancelled) {
        token.cancel('All requests cancelled');
      }
    }
    _activeRequests.clear();
  }
  
  /// Check internet connectivity
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Start monitoring connectivity
  void _startConnectivityMonitoring() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final wasOnline = _isOnline;
      _isOnline = await checkConnectivity();
      
      if (wasOnline != _isOnline) {
        debugPrint('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      }
    });
  }
  
  /// Get active request count
  int get activeRequestCount => _activeRequests.length;
  
  /// Dispose resources
  void dispose() {
    cancelAllRequests();
    _dio.close();
  }
}