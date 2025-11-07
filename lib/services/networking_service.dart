import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

enum NetworkProtocol {
  http,
  https,
  websocket,
  ftp,
  custom,
}

class NetworkRequest {
  final String id;
  final String url;
  final String method;
  final Map<String, String> headers;
  final dynamic body;
  final DateTime timestamp;
  final NetworkProtocol protocol;
  final String? tabId;
  
  NetworkRequest({
    required this.id,
    required this.url,
    required this.method,
    required this.headers,
    this.body,
    DateTime? timestamp,
    required this.protocol,
    this.tabId,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'method': method,
      'headers': headers,
      'body': body?.toString(),
      'timestamp': timestamp.toIso8601String(),
      'protocol': protocol.name,
      'tabId': tabId,
    };
  }
}

class NetworkResponse {
  final String requestId;
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
  final int contentLength;
  final Duration responseTime;
  final DateTime timestamp;
  
  NetworkResponse({
    required this.requestId,
    required this.statusCode,
    required this.headers,
    this.body,
    required this.contentLength,
    required this.responseTime,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'statusCode': statusCode,
      'headers': headers,
      'body': body?.toString(),
      'contentLength': contentLength,
      'responseTime': responseTime.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class NetworkingService {
  static late Dio _dio;
  static final Map<String, NetworkRequest> _activeRequests = {};
  static final List<NetworkRequest> _requestHistory = [];
  static final List<NetworkResponse> _responseHistory = [];
  static final Map<String, WebSocket> _webSockets = {};
  static bool _isInitialized = false;
  
  // Network settings
  static int _maxConcurrentRequests = 10;
  static Duration _requestTimeout = const Duration(seconds: 30);
  static bool _followRedirects = true;
  static int _maxRedirects = 5;
  static bool _enableHttp2 = true;
  static bool _enableCompression = true;
  
  static Future<void> init() async {
    if (_isInitialized) return;
    
    _dio = Dio(BaseOptions(
      connectTimeout: _requestTimeout,
      receiveTimeout: _requestTimeout,
      sendTimeout: _requestTimeout,
      followRedirects: _followRedirects,
      maxRedirects: _maxRedirects,
      headers: {
        'User-Agent': 'TitanBrowser/1.0.0 (Cross-Platform AI Browser)',
        'Accept': '*/*',
        'Accept-Encoding': _enableCompression ? 'gzip, deflate, br' : 'identity',
        'Connection': 'keep-alive',
      },
    ));
    
    _setupInterceptors();
    _isInitialized = true;
  }
  
  static void _setupInterceptors() {
    // Request interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final request = NetworkRequest(
          id: _generateRequestId(),
          url: options.uri.toString(),
          method: options.method,
          headers: Map<String, String>.from(options.headers),
          body: options.data,
          protocol: options.uri.scheme == 'https' 
              ? NetworkProtocol.https 
              : NetworkProtocol.http,
        );
        
        _activeRequests[request.id] = request;
        _requestHistory.add(request);
        
        // Limit history size
        if (_requestHistory.length > 1000) {
          _requestHistory.removeAt(0);
        }
        
        options.extra['requestId'] = request.id;
        options.extra['startTime'] = DateTime.now();
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        final requestId = response.requestOptions.extra['requestId'] as String;
        final startTime = response.requestOptions.extra['startTime'] as DateTime;
        final responseTime = DateTime.now().difference(startTime);
        
        final networkResponse = NetworkResponse(
          requestId: requestId,
          statusCode: response.statusCode ?? 0,
          headers: Map<String, String>.from(response.headers.map),
          body: response.data,
          contentLength: _getContentLength(response),
          responseTime: responseTime,
        );
        
        _responseHistory.add(networkResponse);
        _activeRequests.remove(requestId);
        
        // Limit history size
        if (_responseHistory.length > 1000) {
          _responseHistory.removeAt(0);
        }
        
        handler.next(response);
      },
      onError: (error, handler) {
        final requestId = error.requestOptions.extra['requestId'] as String?;
        if (requestId != null) {
          _activeRequests.remove(requestId);
        }
        
        handler.next(error);
      },
    ));
  }
  
  static String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode;
    return '$timestamp-$random';
  }
  
  static int _getContentLength(Response response) {
    final contentLength = response.headers.value('content-length');
    if (contentLength != null) {
      return int.tryParse(contentLength) ?? 0;
    }
    
    if (response.data is String) {
      return utf8.encode(response.data).length;
    } else if (response.data is List<int>) {
      return response.data.length;
    }
    
    return 0;
  }
  
  // HTTP Methods
  static Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? tabId,
  }) async {
    return await _dio.get(
      url,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        extra: {'tabId': tabId},
      ),
    );
  }
  
  static Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? tabId,
  }) async {
    return await _dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        extra: {'tabId': tabId},
      ),
    );
  }
  
  static Future<Response> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? tabId,
  }) async {
    return await _dio.put(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        extra: {'tabId': tabId},
      ),
    );
  }
  
  static Future<Response> delete(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? tabId,
  }) async {
    return await _dio.delete(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        extra: {'tabId': tabId},
      ),
    );
  }
  
  // WebSocket Support
  static Future<WebSocket> connectWebSocket(
    String url, {
    Map<String, String>? headers,
    String? tabId,
  }) async {
    try {
      final webSocket = await WebSocket.connect(
        url,
        headers: headers,
      );
      
      final socketId = _generateRequestId();
      _webSockets[socketId] = webSocket;
      
      // Log WebSocket connection
      final request = NetworkRequest(
        id: socketId,
        url: url,
        method: 'WEBSOCKET',
        headers: headers ?? {},
        protocol: NetworkProtocol.websocket,
        tabId: tabId,
      );
      
      _requestHistory.add(request);
      
      return webSocket;
    } catch (e) {
      throw Exception('Failed to connect WebSocket: $e');
    }
  }
  
  static void closeWebSocket(String socketId) {
    final webSocket = _webSockets[socketId];
    if (webSocket != null) {
      webSocket.close();
      _webSockets.remove(socketId);
    }
  }
  
  // DNS Resolution
  static Future<List<InternetAddress>> resolveDNS(String hostname) async {
    try {
      return await InternetAddress.lookup(hostname);
    } catch (e) {
      throw Exception('DNS resolution failed for $hostname: $e');
    }
  }
  
  // DNS over HTTPS
  static Future<Map<String, dynamic>?> resolveDoH(
    String hostname, {
    String dohServer = 'https://cloudflare-dns.com/dns-query',
  }) async {
    try {
      final response = await _dio.get(
        dohServer,
        queryParameters: {
          'name': hostname,
          'type': 'A',
        },
        options: Options(
          headers: {
            'Accept': 'application/dns-json',
          },
        ),
      );
      
      return response.data;
    } catch (e) {
      print('DoH resolution failed: $e');
      return null;
    }
  }
  
  // Network Monitoring
  static List<NetworkRequest> getRequestHistory({String? tabId}) {
    if (tabId != null) {
      return _requestHistory.where((req) => req.tabId == tabId).toList();
    }
    return List.from(_requestHistory);
  }
  
  static List<NetworkResponse> getResponseHistory() {
    return List.from(_responseHistory);
  }
  
  static Map<String, NetworkRequest> getActiveRequests() {
    return Map.from(_activeRequests);
  }
  
  static int get activeRequestCount => _activeRequests.length;
  
  // Network Statistics
  static Map<String, dynamic> getNetworkStats() {
    final totalRequests = _requestHistory.length;
    final totalResponses = _responseHistory.length;
    final activeRequests = _activeRequests.length;
    
    final successfulRequests = _responseHistory
        .where((res) => res.statusCode >= 200 && res.statusCode < 300)
        .length;
    
    final failedRequests = _responseHistory
        .where((res) => res.statusCode >= 400)
        .length;
    
    final totalBytes = _responseHistory
        .fold<int>(0, (sum, res) => sum + res.contentLength);
    
    final averageResponseTime = _responseHistory.isNotEmpty
        ? _responseHistory
            .map((res) => res.responseTime.inMilliseconds)
            .reduce((a, b) => a + b) / _responseHistory.length
        : 0.0;
    
    return {
      'totalRequests': totalRequests,
      'totalResponses': totalResponses,
      'activeRequests': activeRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'totalBytes': totalBytes,
      'averageResponseTime': averageResponseTime,
      'successRate': totalResponses > 0 ? successfulRequests / totalResponses : 0.0,
    };
  }
  
  // Caching
  static final Map<String, CacheEntry> _cache = {};
  
  static void setCacheEntry(String url, dynamic data, Duration ttl) {
    _cache[url] = CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl),
    );
  }
  
  static dynamic getCacheEntry(String url) {
    final entry = _cache[url];
    if (entry != null && DateTime.now().isBefore(entry.expiresAt)) {
      return entry.data;
    }
    
    _cache.remove(url);
    return null;
  }
  
  static void clearCache() {
    _cache.clear();
  }
  
  // Request Throttling
  static final Map<String, DateTime> _lastRequestTime = {};
  static const Duration _throttleDelay = Duration(milliseconds: 100);
  
  static bool shouldThrottleRequest(String domain) {
    final lastTime = _lastRequestTime[domain];
    if (lastTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastTime);
      return timeSinceLastRequest < _throttleDelay;
    }
    return false;
  }
  
  static void recordRequestTime(String domain) {
    _lastRequestTime[domain] = DateTime.now();
  }
  
  // Network Settings
  static void setRequestTimeout(Duration timeout) {
    _requestTimeout = timeout;
    _dio.options.connectTimeout = timeout;
    _dio.options.receiveTimeout = timeout;
    _dio.options.sendTimeout = timeout;
  }
  
  static void setMaxConcurrentRequests(int max) {
    _maxConcurrentRequests = max;
  }
  
  static void setFollowRedirects(bool follow) {
    _followRedirects = follow;
    _dio.options.followRedirects = follow;
  }
  
  static void setMaxRedirects(int max) {
    _maxRedirects = max;
    _dio.options.maxRedirects = max;
  }
  
  static void enableHttp2(bool enable) {
    _enableHttp2 = enable;
    // HTTP/2 support would be configured here
  }
  
  static void enableCompression(bool enable) {
    _enableCompression = enable;
    final encoding = enable ? 'gzip, deflate, br' : 'identity';
    _dio.options.headers['Accept-Encoding'] = encoding;
  }
  
  // Cleanup
  static void cleanup() {
    for (final webSocket in _webSockets.values) {
      webSocket.close();
    }
    _webSockets.clear();
    _activeRequests.clear();
    _requestHistory.clear();
    _responseHistory.clear();
    _cache.clear();
    _lastRequestTime.clear();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  
  CacheEntry({
    required this.data,
    required this.expiresAt,
  });
}