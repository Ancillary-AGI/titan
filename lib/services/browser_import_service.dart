import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';

enum BrowserType {
  chrome,
  firefox,
  safari,
  edge,
  opera,
  brave,
}

class BrowserImportService {
  static Future<List<BrowserType>> getAvailableBrowsers() async {
    final availableBrowsers = <BrowserType>[];
    
    if (Platform.isWindows) {
      if (await _checkWindowsBrowser('Chrome')) availableBrowsers.add(BrowserType.chrome);
      if (await _checkWindowsBrowser('Firefox')) availableBrowsers.add(BrowserType.firefox);
      if (await _checkWindowsBrowser('Edge')) availableBrowsers.add(BrowserType.edge);
      if (await _checkWindowsBrowser('Opera')) availableBrowsers.add(BrowserType.opera);
      if (await _checkWindowsBrowser('Brave')) availableBrowsers.add(BrowserType.brave);
    } else if (Platform.isMacOS) {
      if (await _checkMacOSBrowser('Chrome')) availableBrowsers.add(BrowserType.chrome);
      if (await _checkMacOSBrowser('Firefox')) availableBrowsers.add(BrowserType.firefox);
      if (await _checkMacOSBrowser('Safari')) availableBrowsers.add(BrowserType.safari);
      if (await _checkMacOSBrowser('Edge')) availableBrowsers.add(BrowserType.edge);
      if (await _checkMacOSBrowser('Opera')) availableBrowsers.add(BrowserType.opera);
      if (await _checkMacOSBrowser('Brave')) availableBrowsers.add(BrowserType.brave);
    } else if (Platform.isLinux) {
      if (await _checkLinuxBrowser('Chrome')) availableBrowsers.add(BrowserType.chrome);
      if (await _checkLinuxBrowser('Firefox')) availableBrowsers.add(BrowserType.firefox);
      if (await _checkLinuxBrowser('Opera')) availableBrowsers.add(BrowserType.opera);
      if (await _checkLinuxBrowser('Brave')) availableBrowsers.add(BrowserType.brave);
    }
    
    return availableBrowsers;
  }
  
  static Future<Map<String, dynamic>> importFromBrowser(BrowserType browser) async {
    switch (browser) {
      case BrowserType.chrome:
        return await _importFromChrome();
      case BrowserType.firefox:
        return await _importFromFirefox();
      case BrowserType.safari:
        return await _importFromSafari();
      case BrowserType.edge:
        return await _importFromEdge();
      case BrowserType.opera:
        return await _importFromOpera();
      case BrowserType.brave:
        return await _importFromBrave();
    }
  }
  
  static Future<void> importBookmarksFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['html', 'json'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        if (result.files.single.extension == 'html') {
          await _parseNetscapeBookmarks(content);
        } else if (result.files.single.extension == 'json') {
          await _parseJsonBookmarks(content);
        }
      }
    } catch (e) {
      throw Exception('Failed to import bookmarks: $e');
    }
  }
  
  // Chrome Import
  static Future<Map<String, dynamic>> _importFromChrome() async {
    final bookmarksPath = await _getChromeBookmarksPath();
    final historyPath = await _getChromeHistoryPath();
    
    final bookmarks = await _importChromeBookmarks(bookmarksPath);
    final history = await _importChromeHistory(historyPath);
    
    return {
      'bookmarks': bookmarks,
      'history': history,
      'browser': 'Chrome',
    };
  }
  
  static Future<String> _getChromeBookmarksPath() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'];
      return '$appData\\Google\\Chrome\\User Data\\Default\\Bookmarks';
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      return '$home/Library/Application Support/Google/Chrome/Default/Bookmarks';
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      return '$home/.config/google-chrome/Default/Bookmarks';
    }
    throw Exception('Unsupported platform for Chrome import');
  }
  
  static Future<String> _getChromeHistoryPath() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'];
      return '$appData\\Google\\Chrome\\User Data\\Default\\History';
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      return '$home/Library/Application Support/Google/Chrome/Default/History';
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      return '$home/.config/google-chrome/Default/History';
    }
    throw Exception('Unsupported platform for Chrome import');
  }
  
  static Future<List<Map<String, dynamic>>> _importChromeBookmarks(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return [];
      
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      final bookmarks = <Map<String, dynamic>>[];
      _extractChromeBookmarks(data['roots'], bookmarks);
      
      return bookmarks;
    } catch (e) {
      print('Failed to import Chrome bookmarks: $e');
      return [];
    }
  }
  
  static void _extractChromeBookmarks(Map<String, dynamic> node, List<Map<String, dynamic>> bookmarks, [String folder = 'default']) {
    if (node['children'] != null) {
      for (final child in node['children']) {
        if (child['type'] == 'url') {
          bookmarks.add({
            'title': child['name'],
            'url': child['url'],
            'folder': folder,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else if (child['type'] == 'folder') {
          _extractChromeBookmarks(child, bookmarks, child['name']);
        }
      }
    }
  }
  
  static Future<List<Map<String, dynamic>>> _importChromeHistory(String path) async {
    // Note: Chrome history is in SQLite format, would need sqlite3 package
    // For now, return empty list
    return [];
  }
  
  // Firefox Import
  static Future<Map<String, dynamic>> _importFromFirefox() async {
    // Firefox uses SQLite for bookmarks and history
    // Implementation would require sqlite3 package
    return {
      'bookmarks': <Map<String, dynamic>>[],
      'history': <Map<String, dynamic>>[],
      'browser': 'Firefox',
    };
  }
  
  // Safari Import (macOS only)
  static Future<Map<String, dynamic>> _importFromSafari() async {
    if (!Platform.isMacOS) {
      throw Exception('Safari import only available on macOS');
    }
    
    // Safari uses plist files
    return {
      'bookmarks': <Map<String, dynamic>>[],
      'history': <Map<String, dynamic>>[],
      'browser': 'Safari',
    };
  }
  
  // Edge Import
  static Future<Map<String, dynamic>> _importFromEdge() async {
    // Edge uses similar format to Chrome
    return {
      'bookmarks': <Map<String, dynamic>>[],
      'history': <Map<String, dynamic>>[],
      'browser': 'Edge',
    };
  }
  
  // Opera Import
  static Future<Map<String, dynamic>> _importFromOpera() async {
    return {
      'bookmarks': <Map<String, dynamic>>[],
      'history': <Map<String, dynamic>>[],
      'browser': 'Opera',
    };
  }
  
  // Brave Import
  static Future<Map<String, dynamic>> _importFromBrave() async {
    // Brave uses similar format to Chrome
    return {
      'bookmarks': <Map<String, dynamic>>[],
      'history': <Map<String, dynamic>>[],
      'browser': 'Brave',
    };
  }
  
  // File format parsers
  static Future<void> _parseNetscapeBookmarks(String content) async {
    // Parse Netscape bookmark format (HTML)
    final lines = content.split('\n');
    String? currentFolder;
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.startsWith('<H3')) {
        // Folder
        final match = RegExp(r'>([^<]+)<').firstMatch(trimmed);
        if (match != null) {
          currentFolder = match.group(1);
        }
      } else if (trimmed.startsWith('<A HREF=')) {
        // Bookmark
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(trimmed);
        final titleMatch = RegExp(r'>([^<]+)<').firstMatch(trimmed);
        
        if (urlMatch != null && titleMatch != null) {
          await StorageService.addBookmark(
            urlMatch.group(1)!,
            titleMatch.group(1)!,
            folder: currentFolder ?? 'Imported',
          );
        }
      }
    }
  }
  
  static Future<void> _parseJsonBookmarks(String content) async {
    try {
      final data = jsonDecode(content);
      
      if (data is List) {
        for (final bookmark in data) {
          if (bookmark['url'] != null && bookmark['title'] != null) {
            await StorageService.addBookmark(
              bookmark['url'],
              bookmark['title'],
              folder: bookmark['folder'] ?? 'Imported',
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Invalid JSON bookmark format: $e');
    }
  }
  
  // Browser detection helpers
  static Future<bool> _checkWindowsBrowser(String browser) async {
    try {
      final result = await Process.run(
        'reg',
        ['query', 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall', '/s', '/f', browser],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> _checkMacOSBrowser(String browser) async {
    try {
      final result = await Process.run('mdfind', ['kMDItemDisplayName == "$browser"']);
      return result.stdout.toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> _checkLinuxBrowser(String browser) async {
    try {
      final result = await Process.run('which', [browser.toLowerCase()]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  static String getBrowserDisplayName(BrowserType browser) {
    switch (browser) {
      case BrowserType.chrome:
        return 'Google Chrome';
      case BrowserType.firefox:
        return 'Mozilla Firefox';
      case BrowserType.safari:
        return 'Safari';
      case BrowserType.edge:
        return 'Microsoft Edge';
      case BrowserType.opera:
        return 'Opera';
      case BrowserType.brave:
        return 'Brave Browser';
    }
  }
}