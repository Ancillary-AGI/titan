import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/browser_tab.dart';
import '../models/ai_task.dart';

class StorageService {
  static late Box<Map> _tabsBox;
  static late Box<Map> _historyBox;
  static late Box<Map> _bookmarksBox;
  static late Box<Map> _tasksBox;
  static late SharedPreferences _prefs;
  
  static Future<void> init() async {
    _tabsBox = await Hive.openBox<Map>('browser_tabs');
    _historyBox = await Hive.openBox<Map>('browser_history');
    _bookmarksBox = await Hive.openBox<Map>('bookmarks');
    _tasksBox = await Hive.openBox<Map>('ai_tasks');
    _prefs = await SharedPreferences.getInstance();
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
  
  // Settings
  static Future<void> setSetting(String key, dynamic value) async {
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
    return _prefs.get(key) as T?;
  }
  
  static String get defaultSearchEngine => 
      getSetting<String>('search_engine') ?? 'https://www.google.com/search?q=';
  
  static String get defaultHomePage => 
      getSetting<String>('home_page') ?? 'https://www.google.com';
  
  static bool get aiAssistantEnabled => 
      getSetting<bool>('ai_assistant_enabled') ?? true;
  
  static String? get openAIKey => getSetting<String>('openai_key');
  static String? get anthropicKey => getSetting<String>('anthropic_key');
}