import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';

class Bookmark {
  final String id;
  final String title;
  final String url;
  final String? description;
  final String? favicon;
  final List<String> tags;
  final String? folderId;
  final DateTime createdAt;
  final DateTime lastAccessed;
  final int visitCount;
  final Map<String, dynamic> metadata;
  
  const Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.favicon,
    this.tags = const [],
    this.folderId,
    required this.createdAt,
    required this.lastAccessed,
    this.visitCount = 0,
    this.metadata = const {},
  });
  
  Bookmark copyWith({
    String? id,
    String? title,
    String? url,
    String? description,
    String? favicon,
    List<String>? tags,
    String? folderId,
    DateTime? createdAt,
    DateTime? lastAccessed,
    int? visitCount,
    Map<String, dynamic>? metadata,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      favicon: favicon ?? this.favicon,
      tags: tags ?? this.tags,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      visitCount: visitCount ?? this.visitCount,
      metadata: metadata ?? this.metadata,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'favicon': favicon,
      'tags': tags,
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'visitCount': visitCount,
      'metadata': metadata,
    };
  }
  
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      favicon: json['favicon'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      folderId: json['folderId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
      visitCount: json['visitCount'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class BookmarkFolder {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  
  const BookmarkFolder({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.color = Colors.blue,
    this.icon = Icons.folder,
    required this.createdAt,
    this.metadata = const {},
  });
  
  BookmarkFolder copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return BookmarkFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentId': parentId,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  factory BookmarkFolder.fromJson(Map<String, dynamic> json) {
    return BookmarkFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
      color: Color(json['color'] as int? ?? Colors.blue.value),
      icon: IconData(json['icon'] as int? ?? Icons.folder.codePoint, fontFamily: 'MaterialIcons'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class BookmarkManagerService {
  static final Map<String, Bookmark> _bookmarks = {};
  static final Map<String, BookmarkFolder> _folders = {};
  static final StreamController<List<Bookmark>> _bookmarksController = StreamController.broadcast();
  static final StreamController<List<BookmarkFolder>> _foldersController = StreamController.broadcast();
  
  static Stream<List<Bookmark>> get bookmarksStream => _bookmarksController.stream;
  static Stream<List<BookmarkFolder>> get foldersStream => _foldersController.stream;
  
  static List<Bookmark> get bookmarks => _bookmarks.values.toList();
  static List<BookmarkFolder> get folders => _folders.values.toList();
  
  // Bookmark management
  static Future<String> addBookmark({
    required String title,
    required String url,
    String? description,
    String? favicon,
    List<String>? tags,
    String? folderId,
  }) async {
    final bookmarkId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Auto-generate description if not provided
    String? finalDescription = description;
    if (finalDescription == null || finalDescription.isEmpty) {
      try {
        // Use AI to generate description based on title and URL
        finalDescription = await _generateBookmarkDescription(title, url);
      } catch (e) {
        finalDescription = 'Bookmark for $title';
      }
    }
    
    // Auto-generate tags if not provided
    List<String> finalTags = tags ?? [];
    if (finalTags.isEmpty) {
      finalTags = await _generateBookmarkTags(title, url, finalDescription);
    }
    
    final bookmark = Bookmark(
      id: bookmarkId,
      title: title,
      url: url,
      description: finalDescription,
      favicon: favicon,
      tags: finalTags,
      folderId: folderId,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
    
    _bookmarks[bookmarkId] = bookmark;
    await _saveBookmark(bookmark);
    
    _notifyBookmarksChanged();
    
    return bookmarkId;
  }
  
  static Future<void> updateBookmark(
    String bookmarkId, {
    String? title,
    String? url,
    String? description,
    String? favicon,
    List<String>? tags,
    String? folderId,
  }) async {
    final existing = _bookmarks[bookmarkId];
    if (existing == null) return;
    
    final updated = existing.copyWith(
      title: title,
      url: url,
      description: description,
      favicon: favicon,
      tags: tags,
      folderId: folderId,
    );
    
    _bookmarks[bookmarkId] = updated;
    await _saveBookmark(updated);
    
    _notifyBookmarksChanged();
  }
  
  static Future<void> removeBookmark(String bookmarkId) async {
    _bookmarks.remove(bookmarkId);
    await StorageService.removeSetting('bookmark_$bookmarkId');
    
    _notifyBookmarksChanged();
  }
  
  static Future<void> accessBookmark(String bookmarkId) async {
    final bookmark = _bookmarks[bookmarkId];
    if (bookmark == null) return;
    
    final updated = bookmark.copyWith(
      lastAccessed: DateTime.now(),
      visitCount: bookmark.visitCount + 1,
    );
    
    _bookmarks[bookmarkId] = updated;
    await _saveBookmark(updated);
    
    _notifyBookmarksChanged();
  }
  
  // Folder management
  static Future<String> createFolder({
    required String name,
    String? description,
    String? parentId,
    Color? color,
    IconData? icon,
  }) async {
    final folderId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final folder = BookmarkFolder(
      id: folderId,
      name: name,
      description: description,
      parentId: parentId,
      color: color ?? Colors.blue,
      icon: icon ?? Icons.folder,
      createdAt: DateTime.now(),
    );
    
    _folders[folderId] = folder;
    await _saveFolder(folder);
    
    _notifyFoldersChanged();
    
    return folderId;
  }
  
  static Future<void> updateFolder(
    String folderId, {
    String? name,
    String? description,
    String? parentId,
    Color? color,
    IconData? icon,
  }) async {
    final existing = _folders[folderId];
    if (existing == null) return;
    
    final updated = existing.copyWith(
      name: name,
      description: description,
      parentId: parentId,
      color: color,
      icon: icon,
    );
    
    _folders[folderId] = updated;
    await _saveFolder(updated);
    
    _notifyFoldersChanged();
  }
  
  static Future<void> removeFolder(String folderId, {bool moveBookmarksToParent = true}) async {
    final folder = _folders[folderId];
    if (folder == null) return;
    
    // Handle bookmarks in this folder
    final bookmarksInFolder = _bookmarks.values.where((b) => b.folderId == folderId).toList();
    
    for (final bookmark in bookmarksInFolder) {
      if (moveBookmarksToParent) {
        // Move to parent folder
        await updateBookmark(bookmark.id, folderId: folder.parentId);
      } else {
        // Remove bookmarks
        await removeBookmark(bookmark.id);
      }
    }
    
    // Handle subfolders
    final subfolders = _folders.values.where((f) => f.parentId == folderId).toList();
    for (final subfolder in subfolders) {
      await updateFolder(subfolder.id, parentId: folder.parentId);
    }
    
    _folders.remove(folderId);
    await StorageService.removeSetting('folder_$folderId');
    
    _notifyFoldersChanged();
  }
  
  // Search and filtering
  static List<Bookmark> searchBookmarks(String query) {
    if (query.isEmpty) return bookmarks;
    
    final lowerQuery = query.toLowerCase();
    return bookmarks.where((bookmark) =>
        bookmark.title.toLowerCase().contains(lowerQuery) ||
        bookmark.url.toLowerCase().contains(lowerQuery) ||
        (bookmark.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        bookmark.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }
  
  static List<Bookmark> getBookmarksByFolder(String? folderId) {
    return bookmarks.where((bookmark) => bookmark.folderId == folderId).toList();
  }
  
  static List<Bookmark> getBookmarksByTag(String tag) {
    return bookmarks.where((bookmark) => bookmark.tags.contains(tag)).toList();
  }
  
  static List<Bookmark> getRecentBookmarks({int limit = 10}) {
    final sortedBookmarks = bookmarks.toList()
      ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
    
    return sortedBookmarks.take(limit).toList();
  }
  
  static List<Bookmark> getPopularBookmarks({int limit = 10}) {
    final sortedBookmarks = bookmarks.toList()
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
    
    return sortedBookmarks.take(limit).toList();
  }
  
  // Smart features
  static Future<List<Bookmark>> getSimilarBookmarks(String bookmarkId) async {
    final bookmark = _bookmarks[bookmarkId];
    if (bookmark == null) return [];
    
    final similar = <Bookmark>[];
    
    // Find bookmarks with similar tags
    for (final other in bookmarks) {
      if (other.id == bookmarkId) continue;
      
      final commonTags = bookmark.tags.where((tag) => other.tags.contains(tag)).length;
      if (commonTags > 0) {
        similar.add(other);
      }
    }
    
    // Sort by similarity (number of common tags)
    similar.sort((a, b) {
      final aCommon = bookmark.tags.where((tag) => a.tags.contains(tag)).length;
      final bCommon = bookmark.tags.where((tag) => b.tags.contains(tag)).length;
      return bCommon.compareTo(aCommon);
    });
    
    return similar.take(5).toList();
  }
  
  static Future<List<String>> suggestTags(String title, String url) async {
    return await _generateBookmarkTags(title, url, null);
  }
  
  static Future<List<Bookmark>> getSmartRecommendations() async {
    final recommendations = <Bookmark>[];
    
    // Get bookmarks that haven't been accessed recently
    final now = DateTime.now();
    final oldBookmarks = bookmarks.where((bookmark) {
      final daysSinceAccess = now.difference(bookmark.lastAccessed).inDays;
      return daysSinceAccess > 30 && bookmark.visitCount > 2;
    }).toList();
    
    // Sort by visit count and take top 5
    oldBookmarks.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    recommendations.addAll(oldBookmarks.take(5));
    
    return recommendations;
  }
  
  // Import/Export
  static Future<Map<String, dynamic>> exportBookmarks() async {
    return {
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'folders': folders.map((f) => f.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }
  
  static Future<void> importBookmarks(Map<String, dynamic> data) async {
    // Clear existing bookmarks and folders
    _bookmarks.clear();
    _folders.clear();
    
    // Import folders first
    if (data['folders'] != null) {
      final foldersData = List<Map<String, dynamic>>.from(data['folders']);
      for (final folderData in foldersData) {
        final folder = BookmarkFolder.fromJson(folderData);
        _folders[folder.id] = folder;
        await _saveFolder(folder);
      }
    }
    
    // Import bookmarks
    if (data['bookmarks'] != null) {
      final bookmarksData = List<Map<String, dynamic>>.from(data['bookmarks']);
      for (final bookmarkData in bookmarksData) {
        final bookmark = Bookmark.fromJson(bookmarkData);
        _bookmarks[bookmark.id] = bookmark;
        await _saveBookmark(bookmark);
      }
    }
    
    _notifyBookmarksChanged();
    _notifyFoldersChanged();
  }
  
  static Future<String> exportToHtml() async {
    final buffer = StringBuffer();
    
    buffer.writeln('<!DOCTYPE NETSCAPE-Bookmark-file-1>');
    buffer.writeln('<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">');
    buffer.writeln('<TITLE>Bookmarks</TITLE>');
    buffer.writeln('<H1>Bookmarks</H1>');
    buffer.writeln('<DL><p>');
    
    // Export root bookmarks
    final rootBookmarks = bookmarks.where((b) => b.folderId == null).toList();
    for (final bookmark in rootBookmarks) {
      buffer.writeln('    <DT><A HREF="${bookmark.url}">${bookmark.title}</A>');
    }
    
    // Export folders and their bookmarks
    final rootFolders = folders.where((f) => f.parentId == null).toList();
    for (final folder in rootFolders) {
      _exportFolderToHtml(buffer, folder, 1);
    }
    
    buffer.writeln('</DL><p>');
    
    return buffer.toString();
  }
  
  static void _exportFolderToHtml(StringBuffer buffer, BookmarkFolder folder, int depth) {
    final indent = '    ' * depth;
    
    buffer.writeln('$indent<DT><H3>${folder.name}</H3>');
    buffer.writeln('$indent<DL><p>');
    
    // Export bookmarks in this folder
    final folderBookmarks = bookmarks.where((b) => b.folderId == folder.id).toList();
    for (final bookmark in folderBookmarks) {
      buffer.writeln('$indent    <DT><A HREF="${bookmark.url}">${bookmark.title}</A>');
    }
    
    // Export subfolders
    final subfolders = folders.where((f) => f.parentId == folder.id).toList();
    for (final subfolder in subfolders) {
      _exportFolderToHtml(buffer, subfolder, depth + 1);
    }
    
    buffer.writeln('$indent</DL><p>');
  }
  
  // Statistics and analytics
  static Map<String, dynamic> getBookmarkStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = now.subtract(const Duration(days: 7));
    final thisMonth = DateTime(now.year, now.month, 1);
    
    return {
      'totalBookmarks': bookmarks.length,
      'totalFolders': folders.length,
      'bookmarksAddedToday': bookmarks.where((b) => b.createdAt.isAfter(today)).length,
      'bookmarksAddedThisWeek': bookmarks.where((b) => b.createdAt.isAfter(thisWeek)).length,
      'bookmarksAddedThisMonth': bookmarks.where((b) => b.createdAt.isAfter(thisMonth)).length,
      'totalVisits': bookmarks.fold(0, (sum, b) => sum + b.visitCount),
      'averageVisitsPerBookmark': bookmarks.isEmpty ? 0 : bookmarks.fold(0, (sum, b) => sum + b.visitCount) / bookmarks.length,
      'mostPopularBookmark': _getMostPopularBookmark(),
      'topTags': _getTopTags(),
      'topDomains': _getTopDomains(),
    };
  }
  
  static Map<String, dynamic>? _getMostPopularBookmark() {
    if (bookmarks.isEmpty) return null;
    
    final mostPopular = bookmarks.reduce((a, b) => a.visitCount > b.visitCount ? a : b);
    return {
      'title': mostPopular.title,
      'url': mostPopular.url,
      'visitCount': mostPopular.visitCount,
    };
  }
  
  static List<Map<String, dynamic>> _getTopTags() {
    final tagCounts = <String, int>{};
    
    for (final bookmark in bookmarks) {
      for (final tag in bookmark.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTags.take(10).map((entry) => {
      'tag': entry.key,
      'count': entry.value,
    }).toList();
  }
  
  static List<Map<String, dynamic>> _getTopDomains() {
    final domainCounts = <String, int>{};
    
    for (final bookmark in bookmarks) {
      try {
        final uri = Uri.parse(bookmark.url);
        final domain = uri.host;
        domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
      } catch (e) {
        // Invalid URL, skip
      }
    }
    
    final sortedDomains = domainCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedDomains.take(10).map((entry) => {
      'domain': entry.key,
      'count': entry.value,
    }).toList();
  }
  
  // AI-powered features
  static Future<String> _generateBookmarkDescription(String title, String url) async {
    try {
      final prompt = 'Generate a brief, descriptive summary for a bookmark with title "$title" and URL "$url". Keep it under 100 characters.';
      return await AIService.generateText(prompt);
    } catch (e) {
      return 'Bookmark for $title';
    }
  }
  
  static Future<List<String>> _generateBookmarkTags(String title, String url, String? description) async {
    try {
      final content = '$title $url ${description ?? ''}';
      final analysis = await AIService.analyzeText(content);
      final keywords = List<String>.from(analysis['keywords'] ?? []);
      
      // Add domain-based tag
      try {
        final uri = Uri.parse(url);
        keywords.add(uri.host.replaceAll('www.', ''));
      } catch (e) {
        // Invalid URL, skip
      }
      
      return keywords.take(5).toList();
    } catch (e) {
      // Fallback to simple tag generation
      final tags = <String>[];
      
      // Extract domain
      try {
        final uri = Uri.parse(url);
        tags.add(uri.host.replaceAll('www.', ''));
      } catch (e) {
        // Invalid URL, skip
      }
      
      // Add generic tags based on title
      if (title.toLowerCase().contains('news')) tags.add('news');
      if (title.toLowerCase().contains('tutorial')) tags.add('tutorial');
      if (title.toLowerCase().contains('documentation')) tags.add('docs');
      
      return tags;
    }
  }
  
  // Helper methods
  static void _notifyBookmarksChanged() {
    _bookmarksController.add(bookmarks);
  }
  
  static void _notifyFoldersChanged() {
    _foldersController.add(folders);
  }
  
  static Future<void> _saveBookmark(Bookmark bookmark) async {
    await StorageService.setSetting('bookmark_${bookmark.id}', bookmark.toJson());
  }
  
  static Future<void> _saveFolder(BookmarkFolder folder) async {
    await StorageService.setSetting('folder_${folder.id}', folder.toJson());
  }
  
  // Initialization and cleanup
  static Future<void> initialize() async {
    await _loadBookmarks();
    await _loadFolders();
  }
  
  static Future<void> _loadBookmarks() async {
    // This would load bookmarks from storage
    // For now, we'll skip this to avoid complexity
  }
  
  static Future<void> _loadFolders() async {
    // This would load folders from storage
    // For now, we'll skip this to avoid complexity
  }
  
  static void dispose() {
    _bookmarksController.close();
    _foldersController.close();
  }
}