import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class SidecarClient {
  static const String _base = 'http://127.0.0.1:9224';

  static bool get enabled => StorageService.getSetting<bool>('external_engine_enabled') ?? false;

  static Future<bool> health() async {
    final res = await http.get(Uri.parse('$_base/health'));
    return res.statusCode == 200;
  }

  static Future<String> navigate(String url) async {
    final res = await http.post(Uri.parse('$_base/navigate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return 'ok';
    throw Exception('navigate failed: ${res.statusCode} ${res.body}');
  }

  static Future<String> click(String selector) async {
    final res = await http.post(Uri.parse('$_base/click'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'selector': selector}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return 'ok';
    throw Exception('click failed: ${res.statusCode} ${res.body}');
  }

  static Future<String> extract(String selector, {String? attribute}) async {
    final res = await http.post(Uri.parse('$_base/extract'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'selector': selector, 'attribute': attribute}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['value']?.toString() ?? '';
    }
    throw Exception('extract failed: ${res.statusCode} ${res.body}');
  }

  static Future<String> content() async {
    final res = await http.get(Uri.parse('$_base/content'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['html']?.toString() ?? '';
    }
    throw Exception('content failed: ${res.statusCode} ${res.body}');
  }
}
