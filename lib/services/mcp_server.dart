import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/ai_task.dart';
import '../services/ai_service.dart';
import '../providers/browser_provider.dart';
import '../services/browser_bridge.dart';
import '../services/sidecar_client.dart';

class MCPServer {
  static HttpServer? _server;
  static int _port = 8080;
  static bool _isRunning = false;
  static final List<WebSocketChannel> _clients = [];
  
  static Future<void> start({int port = 8080}) async {
    if (_isRunning) return;
    
    _port = port;
    final router = Router();
    
    // MCP Protocol endpoints
    router.get('/mcp/capabilities', _handleCapabilities);
    router.post('/mcp/tools/list', _handleToolsList);
    router.post('/mcp/tools/call', _handleToolCall);
    router.post('/mcp/resources/list', _handleResourcesList);
    router.post('/mcp/resources/read', _handleResourceRead);
    
    // WebSocket for real-time communication
    router.get('/ws', webSocketHandler(_handleWebSocket));
    
    // Health check
    router.get('/health', (Request request) {
      return Response.ok(jsonEncode({
        'status': 'healthy',
        'server': 'Titan Browser MCP Server',
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
      }));
    });
    
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
.addHandler(router.call);
    
    try {
      _server = await shelf_io.serve(handler, 'localhost', _port);
      _isRunning = true;
      print('MCP Server running on http://localhost:$_port');
    } catch (e) {
      print('Failed to start MCP server: $e');
rethrow;
    }
  }
  
  static Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _isRunning = false;
      _clients.clear();
      print('MCP Server stopped');
    }
  }
  
  static bool get isRunning => _isRunning;
  static int get port => _port;
  
  // MCP Protocol Handlers
  static Response _handleCapabilities(Request request) {
    final capabilities = {
      'capabilities': {
        'tools': {
          'listChanged': true,
        },
        'resources': {
          'subscribe': true,
          'listChanged': true,
        },
        'prompts': {
          'listChanged': true,
        },
        'logging': {},
      },
      'serverInfo': {
        'name': 'titan-browser',
        'version': '1.0.0',
      },
      'protocolVersion': '2024-11-05',
    };
    
    return Response.ok(
      jsonEncode(capabilities),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  static Response _handleToolsList(Request request) {
    final tools = [
      {
        'name': 'navigate_to_url',
        'description': 'Navigate the browser to a specific URL',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'url': {
              'type': 'string',
              'description': 'The URL to navigate to',
            },
          },
          'required': ['url'],
        },
      },
      {
        'name': 'click_element',
        'description': 'Click on a web page element',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'selector': {
              'type': 'string',
              'description': 'CSS selector for the element to click',
            },
          },
          'required': ['selector'],
        },
      },
      {
        'name': 'extract_text',
        'description': 'Extract text content from web page elements',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'selector': {
              'type': 'string',
              'description': 'CSS selector for elements to extract text from',
            },
          },
          'required': ['selector'],
        },
      },
      {
        'name': 'fill_form',
        'description': 'Fill out form fields on the current page',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'fields': {
              'type': 'object',
              'description': 'Key-value pairs of field selectors and values',
            },
          },
          'required': ['fields'],
        },
      },
      {
        'name': 'take_screenshot',
        'description': 'Take a screenshot of the current page',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'fullPage': {
              'type': 'boolean',
              'description': 'Whether to capture the full page or just viewport',
              'default': false,
            },
          },
        },
      },
      {
        'name': 'get_page_content',
        'description': 'Get the HTML content of the current page',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'search_web',
        'description': 'Perform a web search using the default search engine',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'The search query',
            },
          },
          'required': ['query'],
        },
      },
    ];
    
    return Response.ok(
      jsonEncode({'tools': tools}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  static Future<Response> _handleToolCall(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final toolName = data['params']['name'];
      final arguments = data['params']['arguments'] ?? {};
      
      final result = await _executeTool(toolName, arguments);
      
      return Response.ok(
        jsonEncode({
          'content': [
            {
              'type': 'text',
              'text': result,
            }
          ],
          'isError': false,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.ok(
        jsonEncode({
          'content': [
            {
              'type': 'text',
              'text': 'Error executing tool: $e',
            }
          ],
          'isError': true,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  static Response _handleResourcesList(Request request) {
    final resources = [
      {
        'uri': 'browser://current-page',
        'name': 'Current Page',
        'description': 'The currently active browser page',
        'mimeType': 'text/html',
      },
      {
        'uri': 'browser://tabs',
        'name': 'Open Tabs',
        'description': 'List of all open browser tabs',
        'mimeType': 'application/json',
      },
      {
        'uri': 'browser://history',
        'name': 'Browser History',
        'description': 'Browser browsing history',
        'mimeType': 'application/json',
      },
      {
        'uri': 'browser://bookmarks',
        'name': 'Bookmarks',
        'description': 'User bookmarks',
        'mimeType': 'application/json',
      },
    ];
    
    return Response.ok(
      jsonEncode({'resources': resources}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  static Future<Response> _handleResourceRead(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final uri = data['params']['uri'];
      
      String content;
      String mimeType;
      
      switch (uri) {
        case 'browser://current-page':
          content = await _getCurrentPageContent();
          mimeType = 'text/html';
          break;
        case 'browser://tabs':
          content = jsonEncode(await _getTabsInfo());
          mimeType = 'application/json';
          break;
        case 'browser://history':
          content = jsonEncode(await _getHistoryInfo());
          mimeType = 'application/json';
          break;
        case 'browser://bookmarks':
          content = jsonEncode(await _getBookmarksInfo());
          mimeType = 'application/json';
          break;
        default:
          throw Exception('Unknown resource URI: $uri');
      }
      
      return Response.ok(
        jsonEncode({
          'contents': [
            {
              'uri': uri,
              'mimeType': mimeType,
              'text': content,
            }
          ],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to read resource: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  static void _handleWebSocket(WebSocketChannel webSocket) {
    _clients.add(webSocket);
    
    webSocket.stream.listen(
      (message) {
        // Handle incoming WebSocket messages
        _handleWebSocketMessage(webSocket, message);
      },
      onDone: () {
        _clients.remove(webSocket);
      },
      onError: (error) {
        print('WebSocket error: $error');
        _clients.remove(webSocket);
      },
    );
  }
  
  static void _handleWebSocketMessage(WebSocketChannel webSocket, dynamic message) {
    try {
      final data = jsonDecode(message);
      // Handle real-time MCP messages
      print('Received WebSocket message: $data');
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }
  
  static Future<String> _executeTool(String toolName, Map<String, dynamic> arguments) async {
    switch (toolName) {
      case 'navigate_to_url':
        return await _navigateToUrl(arguments['url']);
      case 'click_element':
        return await _clickElement(arguments['selector']);
      case 'extract_text':
        return await _extractText(arguments['selector']);
      case 'fill_form':
        return await _fillForm(arguments['fields']);
      case 'take_screenshot':
        return await _takeScreenshot(arguments['fullPage'] ?? false);
      case 'get_page_content':
        return await _getCurrentPageContent();
      case 'search_web':
        return await _searchWeb(arguments['query']);
      default:
        throw Exception('Unknown tool: $toolName');
    }
  }
  
  // Tool implementations
  static Future<String> _navigateToUrl(String url) async {
    if (SidecarClient.enabled) {
      return await SidecarClient.navigate(url);
    }
    if (BrowserBridge.navigateToUrl == null) throw Exception('Browser not ready');
    return await BrowserBridge.navigateToUrl!(url);
  }
  
  static Future<String> _clickElement(String selector) async {
    if (SidecarClient.enabled) {
      return await SidecarClient.click(selector);
    }
    if (BrowserBridge.clickElement == null) throw Exception('Browser not ready');
    return await BrowserBridge.clickElement!(selector);
  }
  
  static Future<String> _extractText(String selector) async {
    if (SidecarClient.enabled) {
      return await SidecarClient.extract(selector);
    }
    if (BrowserBridge.extract == null) throw Exception('Browser not ready');
    return await BrowserBridge.extract!(selector);
  }
  
  static Future<String> _fillForm(Map<String, dynamic> fields) async {
    if (BrowserBridge.fillForm == null) throw Exception('Browser not ready');
    return await BrowserBridge.fillForm!(fields);
  }
  
  static Future<String> _takeScreenshot(bool fullPage) async {
    // Not yet implemented in BrowserBridge
    return 'Screenshot not implemented (fullPage: $fullPage)';
  }
  
  static Future<String> _getCurrentPageContent() async {
    if (SidecarClient.enabled) {
      return await SidecarClient.content();
    }
    if (BrowserBridge.getPageContent == null) throw Exception('Browser not ready');
    return await BrowserBridge.getPageContent!();
  }
  
  static Future<String> _searchWeb(String query) async {
    // Naive search using default engine by navigating
    if (BrowserBridge.navigateToUrl == null) throw Exception('Browser not ready');
    await BrowserBridge.navigateToUrl!(query);
    return 'Searched for: $query';
  }
  
  static Future<List<Map<String, dynamic>>> _getTabsInfo() async {
    if (BrowserBridge.getTabsInfo == null) return [];
    return await BrowserBridge.getTabsInfo!();
  }
  
  static Future<List<Map<String, dynamic>>> _getHistoryInfo() async {
    // Implementation would get history from storage
    return [];
  }
  
  static Future<List<Map<String, dynamic>>> _getBookmarksInfo() async {
    // Implementation would get bookmarks from storage
    return [];
  }
  
  static Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }
  
  static final Map<String, String> _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
  
  static void broadcastToClients(Map<String, dynamic> message) {
    final messageStr = jsonEncode(message);
    for (final client in _clients) {
      try {
        client.sink.add(messageStr);
      } catch (e) {
        print('Error broadcasting to client: $e');
      }
    }
  }
}