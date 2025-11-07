import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/browser_tab.dart';
import '../models/ai_task.dart';

class StorageService {
  static late Box<Map> _tabsBox;
  static late Box<Map> _historyBox;
  static late Box<Map> _bookmarksBox;
  static late Box<Map> _tasksBox;
  static late Box<Map> _settingsBox;
  static late Box<Map> _cacheBox;
  static late Box<Map> _cookiesBox;
  static late Box<Map> _downloadsBox;
  static late SharedPreferences _prefs;
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    _tabsBox = await Hive.openBox<Map>('browser_tabs');
    _historyBox = await Hive.openBox<Map>('browser_history');
    _bookmarksBox = await Hive.openBox<Map>('bookmarks');
    _tasksBox = await Hive.openBox<Map>('ai_tasks');
    _settingsBox = await Hive.openBox<Map>('settings');
    _cacheBox = await Hive.openBox<Map>('cache');
    _cookiesBox = await Hive.openBox<Map>('cookies');
    _downloadsBox = await Hive.openBox<Map>('downloads');
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize default settings
    await _initializeDefaultSettings();
  }
  
  static Future<void> _initializeDefaultSettings() async {
    final defaults = {
      'search_engine': 'https://www.google.com/search?q=',
      'home_page': 'titan://newtab',
      'ai_assistant_enabled': true,
      'javascript_enabled': true,
      'cookies_enabled': true,
      'adblock_enabled': true,
      'dark_mode': false,
      'auto_save_tabs': true,
      'clear_history_on_exit': false,
      'download_location': '',
      'user_agent': 'TitanBrowser/1.0.0',
      'zoom_level': 1.0,
      'font_size': 16,
      'privacy_mode': false,
      'sync_enabled': false,
    };
    
    for (final entry in defaults.entries) {
      if (!_settingsBox.containsKey(entry.key)) {
        await _settingsBox.put(entry.key, {'value': entry.value});
      }
    }
  }
  
  // Browser Tabs
  static Future<void> saveTabs(List<BrowserTab> tabs) async {
    final tabsData = tabs.map((tab) => tab.toJson()).toList();
    await _tabsBox.put('current_tabs', {'tabs': tabsData});
  }
  
  static List<BrowserTab> loadTabs() {
    final data = _tabsBox.get('current_tabs');
    if (data == null) return [];
    
    final tabsData = List<Map<String, dynamic>>.from(data['tabs'] ?? []);
    return tabsData.map((json) => BrowserTab.fromJson(json)).toList();
  }
  
  // Browser History
  static Future<void> addToHistory(String url, String title) async {
    final historyItem = {
      'url': url,
      'title': title,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await _historyBox.put(key, historyItem);
  }
  
  static List<Map<String, dynamic>> getHistory({int limit = 100}) {
    final history = _historyBox.values.toList();
    history.sort((a, b) => DateTime.parse(b['timestamp'])
        .compareTo(DateTime.parse(a['timestamp'])));
    return history.take(limit).cast<Map<String, dynamic>>().toList();
  }
  
  static Future<void> clearHistory() async {
    await _historyBox.clear();
  }
  
  // Bookmarks
  static Future<void> addBookmark(String url, String title, {String? folder}) async {
    final bookmark = {
      'url': url,
      'title': title,
      'folder': folder ?? 'default',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final key = url.hashCode.toString();
    await _bookmarksBox.put(key, bookmark);
  }
  
  static Future<void> removeBookmark(String url) async {
    final key = url.hashCode.toString();
    await _bookmarksBox.delete(key);
  }
  
  static List<Map<String, dynamic>> getBookmarks({String? folder}) {
    final bookmarks = _bookmarksBox.values.where((bookmark) {
      if (folder != null) {
        return bookmark['folder'] == folder;
      }
      return true;
    }).toList();
    
    bookmarks.sort((a, b) => DateTime.parse(b['timestamp'])
        .compareTo(DateTime.parse(a['timestamp'])));
    return bookmarks.cast<Map<String, dynamic>>().toList();
  }
  
  static bool isBookmarked(String url) {
    final key = url.hashCode.toString();
    return _bookmarksBox.containsKey(key);
  }
  
  // AI Tasks
  static Future<void> saveTask(AITask task) async {
    await _tasksBox.put(task.id, task.toJson());
  }
  
  static List<AITask> getTasks() {
    final tasks = _tasksBox.values
        .map((json) => AITask.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }
  
  static AITask? getTask(String id) {
    final data = _tasksBox.get(id);
    if (data == null) return null;
    return AITask.fromJson(Map<String, dynamic>.from(data));
  }
  
  static Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }
  
  // Enhanced Settings Management
  static Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, {'value': value, 'updated': DateTime.now().toIso8601String()});
    
    // Also store in SharedPreferences for quick access
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }
  }
  
  static T? getSetting<T>(String key) {
    final data = _settingsBox.get(key);
    if (data != null) {
      return data['value'] as T?;
    }
    return _prefs.get(key) as T?;
  }
  
  static Map<String, dynamic> getAllSettings() {
    final settings = <String, dynamic>{};
    for (final key in _settingsBox.keys) {
      final data = _settingsBox.get(key);
      if (data != null) {
        settings[key] = data['value'];
      }
    }
    return settings;
  }
  
  static Future<void> resetSettings() async {
    await _settingsBox.clear();
    await _initializeDefaultSettings();
  }
  
  // Convenience getters for common settings
  static String get defaultSearchEngine => 
      getSetting<String>('search_engine') ?? 'https://www.google.com/search?q=';
  
  static String get defaultHomePage => 
      getSetting<String>('home_page') ?? 'titan://newtab';
  
  static bool get aiAssistantEnabled => 
      getSetting<bool>('ai_assistant_enabled') ?? true;
  
  static bool get javascriptEnabled => 
      getSetting<bool>('javascript_enabled') ?? true;
  
  static bool get cookiesEnabled => 
      getSetting<bool>('cookies_enabled') ?? true;
  
  static bool get adBlockEnabled => 
      getSetting<bool>('adblock_enabled') ?? true;
  
  static bool get darkMode => 
      getSetting<bool>('dark_mode') ?? false;
  
  static double get zoomLevel => 
      getSetting<double>('zoom_level') ?? 1.0;
  
  static int get fontSize => 
      getSetting<int>('font_size') ?? 16;
  
  static String get userAgent => 
      getSetting<String>('user_agent') ?? 'TitanBrowser/1.0.0';
  
  // Secure storage for API keys
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  static Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }
  
  static Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }
  
  static Future<double?> getDouble(String key) async {
    return _prefs.getDouble(key);
  }
  
  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }
  
  static Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }
  
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  static Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }
  
  // Cache Management
  static Future<void> setCacheEntry(String key, Map<String, dynamic> data, {Duration? ttl}) async {
    final entry = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'ttl': ttl?.inMilliseconds,
    };
    await _cacheBox.put(key, entry);
  }
  
  static Map<String, dynamic>? getCacheEntry(String key) {
    final entry = _cacheBox.get(key);
    if (entry == null) return null;
    
    final timestamp = DateTime.parse(entry['timestamp']);
    final ttl = entry['ttl'] as int?;
    
    if (ttl != null) {
      final expiry = timestamp.add(Duration(milliseconds: ttl));
      if (DateTime.now().isAfter(expiry)) {
        _cacheBox.delete(key);
        return null;
      }
    }
    
    return Map<String, dynamic>.from(entry['data']);
  }
  
  static Future<void> clearCache() async {
    await _cacheBox.clear();
  }
  
  // Cookie Management
  static Future<void> setCookie(String domain, String name, String value, {DateTime? expires}) async {
    final cookieKey = '$domain:$name';
    final cookie = {
      'domain': domain,
      'name': name,
      'value': value,
      'expires': expires?.toIso8601String(),
      'created': DateTime.now().toIso8601String(),
    };
    await _cookiesBox.put(cookieKey, cookie);
  }
  
  static String? getCookie(String domain, String name) {
    final cookieKey = '$domain:$name';
    final cookie = _cookiesBox.get(cookieKey);
    if (cookie == null) return null;
    
    final expires = cookie['expires'] as String?;
    if (expires != null) {
      final expiryDate = DateTime.parse(expires);
      if (DateTime.now().isAfter(expiryDate)) {
        _cookiesBox.delete(cookieKey);
        return null;
      }
    }
    
    return cookie['value'] as String?;
  }
  
  static List<Map<String, dynamic>> getCookiesForDomain(String domain) {
    return _cookiesBox.values
        .where((cookie) => cookie['domain'] == domain)
        .cast<Map<String, dynamic>>()
        .toList();
  }
  
  static Future<void> clearCookies({String? domain}) async {
    if (domain != null) {
      final keysToDelete = _cookiesBox.keys
          .where((key) => key.toString().startsWith('$domain:'))
          .toList();
      for (final key in keysToDelete) {
        await _cookiesBox.delete(key);
      }
    } else {
      await _cookiesBox.clear();
    }
  }
  
  // Download Management
  static Future<void> addDownload(String url, String filename, String path) async {
    final download = {
      'url': url,
      'filename': filename,
      'path': path,
      'status': 'pending',
      'progress': 0.0,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await _downloadsBox.put(key, download);
  }
  
  static Future<void> updateDownloadProgress(String key, double progress, {String? status}) async {
    final download = _downloadsBox.get(key);
    if (download != null) {
      download['progress'] = progress;
      if (status != null) {
        download['status'] = status;
      }
      await _downloadsBox.put(key, download);
    }
  }
  
  static List<Map<String, dynamic>> getDownloads() {
    final downloads = _downloadsBox.values.toList();
    downloads.sort((a, b) => DateTime.parse(b['timestamp'])
        .compareTo(DateTime.parse(a['timestamp'])));
    return downloads.cast<Map<String, dynamic>>().toList();
  }
  
  static Future<void> clearDownloads() async {
    await _downloadsBox.clear();
  }
  
  // Data Export/Import
  static Future<Map<String, dynamic>> exportData() async {
    return {
      'bookmarks': _bookmarksBox.values.toList(),
      'history': _historyBox.values.toList(),
      'settings': getAllSettings(),
      'tasks': _tasksBox.values.toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }
  
  static Future<void> importData(Map<String, dynamic> data) async {
    // Import bookmarks
    if (data['bookmarks'] != null) {
      await _bookmarksBox.clear();
      final bookmarks = data['bookmarks'] as List;
      for (int i = 0; i < bookmarks.length; i++) {
        await _bookmarksBox.put(i.toString(), bookmarks[i]);
      }
    }
    
    // Import history
    if (data['history'] != null) {
      await _historyBox.clear();
      final history = data['history'] as List;
      for (int i = 0; i < history.length; i++) {
        await _historyBox.put(i.toString(), history[i]);
      }
    }
    
    // Import settings
    if (data['settings'] != null) {
      final settings = data['settings'] as Map<String, dynamic>;
      for (final entry in settings.entries) {
        await setSetting(entry.key, entry.value);
      }
    }
  }
  
  // Storage Statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = '${directory.path}/hive';
    
    int totalSize = 0;
    if (await Directory(dbPath).exists()) {
      final files = await Directory(dbPath).list().toList();
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
    }
    
    return {
      'total_size_bytes': totalSize,
      'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'tabs_count': _tabsBox.length,
      'history_count': _historyBox.length,
      'bookmarks_count': _bookmarksBox.length,
      'tasks_count': _tasksBox.length,
      'cache_count': _cacheBox.length,
      'cookies_count': _cookiesBox.length,
      'downloads_count': _downloadsBox.length,
    };
  }
  
  // Cleanup and Maintenance
  static Future<void> cleanup() async {
    // Remove expired cache entries
    final expiredKeys = <String>[];
    for (final key in _cacheBox.keys) {
      final entry = _cacheBox.get(key);
      if (entry != null) {
        final timestamp = DateTime.parse(entry['timestamp']);
        final ttl = entry['ttl'] as int?;
        if (ttl != null) {
          final expiry = timestamp.add(Duration(milliseconds: ttl));
          if (DateTime.now().isAfter(expiry)) {
            expiredKeys.add(key);
          }
        }
      }
    }
    
    for (final key in expiredKeys) {
      await _cacheBox.delete(key);
    }
    
    // Remove expired cookies
    final expiredCookieKeys = <String>[];
    for (final key in _cookiesBox.keys) {
      final cookie = _cookiesBox.get(key);
      if (cookie != null) {
        final expires = cookie['expires'] as String?;
        if (expires != null) {
          final expiryDate = DateTime.parse(expires);
          if (DateTime.now().isAfter(expiryDate)) {
            expiredCookieKeys.add(key);
          }
        }
      }
    }
    
    for (final key in expiredCookieKeys) {
      await _cookiesBox.delete(key);
    }
    
    // Compact databases
    await _tabsBox.compact();
    await _historyBox.compact();
    await _bookmarksBox.compact();
    await _tasksBox.compact();
    await _cacheBox.compact();
    await _cookiesBox.compact();
  }
  
  static Future<void> clearAllData() async {
    await _tabsBox.clear();
    await _historyBox.clear();
    await _bookmarksBox.clear();
    await _tasksBox.clear();
    await _cacheBox.clear();
    await _cookiesBox.clear();
    await _downloadsBox.clear();
    await _settingsBox.clear();
    await _prefs.clear();
    await _initializeDefaultSettings();
  }
  
  // API Key Management
  static String? get openAIKey => _prefs.getString('openai_key');
  static String? get anthropicKey => _prefs.getString('anthropic_key');
  
  static Future<void> setOpenAIKey(String key) async {
    await _prefs.setString('openai_key', key);
  }
  
  static Future<void> setAnthropicKey(String key) async {
    await _prefs.setString('anthropic_key', key);
  }
  
  // Remove setting method
  static Future<void> removeSetting(String key) async {
    await _settingsBox.delete(key);
  }
  
  // Extension management methods
  static Future<List<Map<String, dynamic>>> getExtensions() async {
    final extensionsData = _settingsBox.get('installed_extensions');
    if (extensionsData == null) return [];
    return List<Map<String, dynamic>>.from(extensionsData['extensions'] ?? []);
  }
  
  static Future<void> saveExtensions(List<Map<String, dynamic>> extensions) async {
    await _settingsBox.put('installed_extensions', {'extensions': extensions});
  }
}