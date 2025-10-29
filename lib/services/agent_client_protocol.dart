import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/ai_task.dart';
import '../services/ai_service.dart';
import '../services/browser_engine_service.dart';

enum AgentCapability {
  navigation,
  dataExtraction,
  formFilling,
  contentAnalysis,
  imageRecognition,
  textGeneration,
  codeExecution,
  fileManagement,
  apiIntegration,
  webScraping,
}

class AgentMessage {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final String? sessionId;
  
  AgentMessage({
    required this.id,
    required this.type,
    required this.payload,
    DateTime? timestamp,
    this.sessionId,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
    };
  }
  
  factory AgentMessage.fromJson(Map<String, dynamic> json) {
    return AgentMessage(
      id: json['id'],
      type: json['type'],
      payload: Map<String, dynamic>.from(json['payload']),
      timestamp: DateTime.parse(json['timestamp']),
      sessionId: json['sessionId'],
    );
  }
}

class AgentSession {
  final String id;
  final String agentId;
  final List<AgentCapability> capabilities;
  final Map<String, dynamic> context;
  final DateTime createdAt;
  DateTime lastActivity;
  bool isActive;
  
  AgentSession({
    required this.id,
    required this.agentId,
    required this.capabilities,
    required this.context,
    DateTime? createdAt,
    DateTime? lastActivity,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastActivity = lastActivity ?? DateTime.now();
}

class AgentClientProtocol {
  static final Map<String, WebSocketChannel> _connections = {};
  static final Map<String, AgentSession> _sessions = {};
  static final List<AgentMessage> _messageHistory = [];
  static bool _isInitialized = false;
  
  // Protocol configuration
  static const String protocolVersion = '1.0.0';
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration sessionTimeout = Duration(minutes: 30);
  
  static Future<void> init() async {
    if (_isInitialized) return;
    
    // Start cleanup timer
    _startCleanupTimer();
    _isInitialized = true;
  }
  
  static void _startCleanupTimer() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredSessions();
    });
  }
  
  static void _cleanupExpiredSessions() {
    final now = DateTime.now();
    final expiredSessions = _sessions.entries
        .where((entry) => 
            now.difference(entry.value.lastActivity) > sessionTimeout)
        .map((entry) => entry.key)
        .toList();
    
    for (final sessionId in expiredSessions) {
      disconnectAgent(sessionId);
    }
  }
  
  // Agent Connection Management
  static Future<String> connectAgent({
    required String agentId,
    required List<AgentCapability> capabilities,
    String? endpoint,
    Map<String, dynamic>? initialContext,
  }) async {
    try {
      final sessionId = _generateSessionId();
      
      // Create WebSocket connection
      final uri = Uri.parse(endpoint ?? 'ws://localhost:8080/agent');
      final channel = IOWebSocketChannel.connect(uri);
      
      _connections[sessionId] = channel;
      
      // Create session
      final session = AgentSession(
        id: sessionId,
        agentId: agentId,
        capabilities: capabilities,
        context: initialContext ?? {},
      );
      
      _sessions[sessionId] = session;
      
      // Send handshake
      await _sendHandshake(sessionId, agentId, capabilities);
      
      // Set up message handling
      _setupMessageHandling(sessionId, channel);
      
      return sessionId;
    } catch (e) {
      throw Exception('Failed to connect agent: $e');
    }
  }
  
  static Future<void> _sendHandshake(
    String sessionId,
    String agentId,
    List<AgentCapability> capabilities,
  ) async {
    final handshake = AgentMessage(
      id: _generateMessageId(),
      type: 'handshake',
      payload: {
        'protocolVersion': protocolVersion,
        'agentId': agentId,
        'capabilities': capabilities.map((c) => c.name).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      },
      sessionId: sessionId,
    );
    
    await _sendMessage(sessionId, handshake);
  }
  
  static void _setupMessageHandling(String sessionId, WebSocketChannel channel) {
    channel.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data);
          final message = AgentMessage.fromJson(json);
          _handleIncomingMessage(sessionId, message);
        } catch (e) {
          print('Failed to parse agent message: $e');
        }
      },
      onError: (error) {
        print('Agent connection error: $error');
        _handleConnectionError(sessionId, error);
      },
      onDone: () {
        print('Agent connection closed: $sessionId');
        _handleConnectionClosed(sessionId);
      },
    );
  }
  
  static void _handleIncomingMessage(String sessionId, AgentMessage message) {
    _messageHistory.add(message);
    _updateSessionActivity(sessionId);
    
    switch (message.type) {
      case 'task_request':
        _handleTaskRequest(sessionId, message);
        break;
      case 'browser_action':
        _handleBrowserAction(sessionId, message);
        break;
      case 'data_request':
        _handleDataRequest(sessionId, message);
        break;
      case 'heartbeat':
        _handleHeartbeat(sessionId, message);
        break;
      case 'error':
        _handleError(sessionId, message);
        break;
      default:
        print('Unknown message type: ${message.type}');
    }
  }
  
  static void _updateSessionActivity(String sessionId) {
    final session = _sessions[sessionId];
    if (session != null) {
      session.lastActivity = DateTime.now();
    }
  }
  
  // Message Handlers
  static Future<void> _handleTaskRequest(String sessionId, AgentMessage message) async {
    try {
      final taskType = AITaskType.values.firstWhere(
        (type) => type.name == message.payload['taskType'],
        orElse: () => AITaskType.custom,
      );
      
      final task = AITask(
        type: taskType,
        description: message.payload['description'] ?? 'Agent task',
        parameters: Map<String, dynamic>.from(message.payload['parameters'] ?? {}),
      );
      
      // Execute task
      final result = await AIService.executeWebTask(task);
      
      // Send response
      final response = AgentMessage(
        id: _generateMessageId(),
        type: 'task_response',
        payload: {
          'requestId': message.id,
          'taskId': result.id,
          'status': result.status.name,
          'result': result.result,
          'error': result.error,
        },
        sessionId: sessionId,
      );
      
      await _sendMessage(sessionId, response);
    } catch (e) {
      await _sendError(sessionId, message.id, 'Task execution failed: $e');
    }
  }
  
  static Future<void> _handleBrowserAction(String sessionId, AgentMessage message) async {
    try {
      final action = message.payload['action'];
      final parameters = message.payload['parameters'] ?? {};
      
      dynamic result;
      
      switch (action) {
        case 'navigate':
          result = await _executeBrowserNavigation(parameters);
          break;
        case 'click':
          result = await _executeBrowserClick(parameters);
          break;
        case 'type':
          result = await _executeBrowserType(parameters);
          break;
        case 'extract':
          result = await _executeBrowserExtract(parameters);
          break;
        case 'screenshot':
          result = await _executeBrowserScreenshot(parameters);
          break;
        default:
          throw Exception('Unknown browser action: $action');
      }
      
      final response = AgentMessage(
        id: _generateMessageId(),
        type: 'browser_action_response',
        payload: {
          'requestId': message.id,
          'action': action,
          'result': result,
          'success': true,
        },
        sessionId: sessionId,
      );
      
      await _sendMessage(sessionId, response);
    } catch (e) {
      await _sendError(sessionId, message.id, 'Browser action failed: $e');
    }
  }
  
  static Future<void> _handleDataRequest(String sessionId, AgentMessage message) async {
    try {
      final dataType = message.payload['dataType'];
      final parameters = message.payload['parameters'] ?? {};
      
      dynamic data;
      
      switch (dataType) {
        case 'page_content':
          data = await _getPageContent(parameters);
          break;
        case 'page_metadata':
          data = await _getPageMetadata(parameters);
          break;
        case 'browser_state':
          data = await _getBrowserState(parameters);
          break;
        case 'network_logs':
          data = await _getNetworkLogs(parameters);
          break;
        default:
          throw Exception('Unknown data type: $dataType');
      }
      
      final response = AgentMessage(
        id: _generateMessageId(),
        type: 'data_response',
        payload: {
          'requestId': message.id,
          'dataType': dataType,
          'data': data,
        },
        sessionId: sessionId,
      );
      
      await _sendMessage(sessionId, response);
    } catch (e) {
      await _sendError(sessionId, message.id, 'Data request failed: $e');
    }
  }
  
  static Future<void> _handleHeartbeat(String sessionId, AgentMessage message) async {
    final response = AgentMessage(
      id: _generateMessageId(),
      type: 'heartbeat_response',
      payload: {
        'requestId': message.id,
        'timestamp': DateTime.now().toIso8601String(),
      },
      sessionId: sessionId,
    );
    
    await _sendMessage(sessionId, response);
  }
  
  static void _handleError(String sessionId, AgentMessage message) {
    print('Agent error in session $sessionId: ${message.payload}');
  }
  
  static void _handleConnectionError(String sessionId, dynamic error) {
    print('Connection error for session $sessionId: $error');
    _sessions[sessionId]?.isActive = false;
  }
  
  static void _handleConnectionClosed(String sessionId) {
    _sessions[sessionId]?.isActive = false;
    _connections.remove(sessionId);
  }
  
  // Browser Action Implementations
  static Future<Map<String, dynamic>> _executeBrowserNavigation(Map<String, dynamic> params) async {
    final url = params['url'] as String;
    final controller = BrowserEngineService.currentController;
    
    if (controller != null) {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      return {'success': true, 'url': url};
    }
    
    throw Exception('No active browser controller');
  }
  
  static Future<Map<String, dynamic>> _executeBrowserClick(Map<String, dynamic> params) async {
    final selector = params['selector'] as String;
    final controller = BrowserEngineService.currentController;
    
    if (controller != null) {
      final result = await controller.evaluateJavascript(source: '''
        (function() {
          var element = document.querySelector('$selector');
          if (element) {
            element.click();
            return {success: true, found: true};
          }
          return {success: false, found: false};
        })();
      ''');
      
      return Map<String, dynamic>.from(result ?? {});
    }
    
    throw Exception('No active browser controller');
  }
  
  static Future<Map<String, dynamic>> _executeBrowserType(Map<String, dynamic> params) async {
    final selector = params['selector'] as String;
    final text = params['text'] as String;
    final controller = BrowserEngineService.currentController;
    
    if (controller != null) {
      final result = await controller.evaluateJavascript(source: '''
        (function() {
          var element = document.querySelector('$selector');
          if (element) {
            element.value = '$text';
            element.dispatchEvent(new Event('input', {bubbles: true}));
            element.dispatchEvent(new Event('change', {bubbles: true}));
            return {success: true, found: true, text: '$text'};
          }
          return {success: false, found: false};
        })();
      ''');
      
      return Map<String, dynamic>.from(result ?? {});
    }
    
    throw Exception('No active browser controller');
  }
  
  static Future<Map<String, dynamic>> _executeBrowserExtract(Map<String, dynamic> params) async {
    final selector = params['selector'] as String;
    final attribute = params['attribute'] as String? ?? 'textContent';
    final controller = BrowserEngineService.currentController;
    
    if (controller != null) {
      final result = await controller.evaluateJavascript(source: '''
        (function() {
          var elements = document.querySelectorAll('$selector');
          var results = [];
          for (var i = 0; i < elements.length; i++) {
            var value = elements[i].$attribute;
            if (value) results.push(value);
          }
          return {success: true, count: results.length, data: results};
        })();
      ''');
      
      return Map<String, dynamic>.from(result ?? {});
    }
    
    throw Exception('No active browser controller');
  }
  
  static Future<Map<String, dynamic>> _executeBrowserScreenshot(Map<String, dynamic> params) async {
    final controller = BrowserEngineService.currentController;
    
    if (controller != null) {
      final screenshot = await controller.takeScreenshot();
      if (screenshot != null) {
        final base64 = base64Encode(screenshot);
        return {
          'success': true,
          'format': 'png',
          'data': base64,
          'size': screenshot.length,
        };
      }
    }
    
    throw Exception('Failed to take screenshot');
  }
  
  // Data Request Implementations
  static Future<Map<String, dynamic>> _getPageContent(Map<String, dynamic> params) async {
    final controller = BrowserEngineService.currentController;
    
    if (controller != null) {
      final result = await controller.evaluateJavascript(source: '''
        (function() {
          return {
            title: document.title,
            url: window.location.href,
            html: document.documentElement.outerHTML,
            text: document.body.textContent,
            links: Array.from(document.links).map(link => ({
              href: link.href,
              text: link.textContent.trim()
            })),
            images: Array.from(document.images).map(img => ({
              src: img.src,
              alt: img.alt
            })),
            forms: Array.from(document.forms).map(form => ({
              action: form.action,
              method: form.method,
              fields: Array.from(form.elements).map(el => ({
                name: el.name,
                type: el.type,
                value: el.value
              }))
            }))
          };
        })();
      ''');
      
      return Map<String, dynamic>.from(result ?? {});
    }
    
    throw Exception('No active browser controller');
  }
  
  static Future<Map<String, dynamic>> _getPageMetadata(Map<String, dynamic> params) async {
    final controller = BrowserEngineService.currentController;
    
    if (controller != null) {
      final result = await controller.evaluateJavascript(source: '''
        (function() {
          var meta = {};
          var metaTags = document.querySelectorAll('meta');
          for (var i = 0; i < metaTags.length; i++) {
            var tag = metaTags[i];
            var name = tag.getAttribute('name') || tag.getAttribute('property');
            var content = tag.getAttribute('content');
            if (name && content) {
              meta[name] = content;
            }
          }
          
          return {
            title: document.title,
            description: meta['description'] || '',
            keywords: meta['keywords'] || '',
            author: meta['author'] || '',
            viewport: meta['viewport'] || '',
            charset: document.characterSet,
            lang: document.documentElement.lang,
            meta: meta
          };
        })();
      ''');
      
      return Map<String, dynamic>.from(result ?? {});
    }
    
    throw Exception('No active browser controller');
  }
  
  static Future<Map<String, dynamic>> _getBrowserState(Map<String, dynamic> params) async {
    // Return current browser state
    return {
      'activeConnections': _connections.length,
      'activeSessions': _sessions.length,
      'messageHistory': _messageHistory.length,
    };
  }
  
  static Future<List<Map<String, dynamic>>> _getNetworkLogs(Map<String, dynamic> params) async {
    // Return network logs - would integrate with NetworkingService
    return [];
  }
  
  // Utility Methods
  static Future<void> _sendMessage(String sessionId, AgentMessage message) async {
    final connection = _connections[sessionId];
    if (connection != null) {
      final json = jsonEncode(message.toJson());
      connection.sink.add(json);
    }
  }
  
  static Future<void> _sendError(String sessionId, String requestId, String error) async {
    final errorMessage = AgentMessage(
      id: _generateMessageId(),
      type: 'error',
      payload: {
        'requestId': requestId,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      },
      sessionId: sessionId,
    );
    
    await _sendMessage(sessionId, errorMessage);
  }
  
  static String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
  
  static String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
  
  // Public API
  static void disconnectAgent(String sessionId) {
    final connection = _connections[sessionId];
    if (connection != null) {
      connection.sink.close();
      _connections.remove(sessionId);
    }
    
    _sessions.remove(sessionId);
  }
  
  static List<AgentSession> getActiveSessions() {
    return _sessions.values.where((session) => session.isActive).toList();
  }
  
  static AgentSession? getSession(String sessionId) {
    return _sessions[sessionId];
  }
  
  static List<AgentMessage> getMessageHistory({String? sessionId}) {
    if (sessionId != null) {
      return _messageHistory.where((msg) => msg.sessionId == sessionId).toList();
    }
    return List.from(_messageHistory);
  }
  
  static void cleanup() {
    for (final connection in _connections.values) {
      connection.sink.close();
    }
    
    _connections.clear();
    _sessions.clear();
    _messageHistory.clear();
  }
}