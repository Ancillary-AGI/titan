import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/browser_tab.dart';
import '../services/storage_service.dart';
import '../services/performance_engine_service.dart';

class TabManagerService {
  static final List<BrowserTab> _tabs = [];
  static final Map<String, Timer> _tabTimers = {};
  static final Map<String, double> _tabMemoryUsage = {};
  static final StreamController<List<BrowserTab>> _tabsController = StreamController.broadcast();
  
  static Stream<List<BrowserTab>> get tabsStream => _tabsController.stream;
  static List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  
  // Tab lifecycle management
  static Future<BrowserTab> createTab({
    String? url,
    String? title,
    bool isIncognito = false,
    BrowserTab? parentTab,
  }) async {
    final tab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url ?? 'titan://newtab',
      title: title ?? 'New Tab',
      isIncognito: isIncognito,
    );
    
    _tabs.add(tab);
    _startTabTimer(tab.id);
    
    // Save tab state
    await _saveTabState(tab);
    
    // Notify listeners
    _tabsController.add(_tabs);
    
    return tab;
  }
  
  static Future<void> closeTab(String tabId) async {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return;
    
    final tab = _tabs[tabIndex];
    
    // Save tab to recently closed if not incognito
    if (!tab.isIncognito) {
      await _saveRecentlyClosed(tab);
    }
    
    // Clean up resources
    _stopTabTimer(tabId);
    _tabMemoryUsage.remove(tabId);
    
    // Remove tab
    _tabs.removeAt(tabIndex);
    
    // Notify listeners
    _tabsController.add(_tabs);
  }
  
  static Future<void> updateTab(String tabId, {
    String? url,
    String? title,
    bool? isLoading,
    String? favicon,
    double? progress,
  }) async {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return;
    
    final currentTab = _tabs[tabIndex];
    final updatedTab = BrowserTab(
      id: currentTab.id,
      url: url ?? currentTab.url,
      title: title ?? currentTab.title,
      isLoading: isLoading ?? currentTab.isLoading,
      favicon: favicon ?? currentTab.favicon,
      progress: progress ?? currentTab.progress,
      createdAt: currentTab.createdAt,
      lastAccessed: DateTime.now(),
      isIncognito: currentTab.isIncognito,
      metadata: currentTab.metadata,
    );
    
    _tabs[tabIndex] = updatedTab;
    
    // Save updated state
    await _saveTabState(updatedTab);
    
    // Notify listeners
    _tabsController.add(_tabs);
  }
  
  // Tab grouping and organization
  static Future<void> createTabGroup(String name, List<String> tabIds, {Color? color}) async {
    final group = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'color': color?.value ?? Colors.blue.value,
      'tabIds': tabIds,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    final groups = await getTabGroups();
    groups.add(group);
    
    await StorageService.setSetting('tab_groups', groups);
    
    // Update tab metadata
    for (final tabId in tabIds) {
      final tab = _tabs.firstWhere((t) => t.id == tabId, orElse: () => throw Exception('Tab not found'));
      final updatedMetadata = Map<String, dynamic>.from(tab.metadata);
      updatedMetadata['groupId'] = group['id'];
      
      await updateTab(tabId, url: tab.url); // Trigger metadata update
    }
  }
  
  static Future<List<Map<String, dynamic>>> getTabGroups() async {
    final groups = StorageService.getSetting<List>('tab_groups') ?? [];
    return groups.cast<Map<String, dynamic>>();
  }
  
  static Future<void> removeTabFromGroup(String tabId) async {
    final groups = await getTabGroups();
    
    for (final group in groups) {
      final tabIds = List<String>.from(group['tabIds'] ?? []);
      if (tabIds.remove(tabId)) {
        group['tabIds'] = tabIds;
        break;
      }
    }
    
    await StorageService.setSetting('tab_groups', groups);
  }
  
  // Tab search and filtering
  static List<BrowserTab> searchTabs(String query) {
    if (query.isEmpty) return _tabs;
    
    final lowerQuery = query.toLowerCase();
    return _tabs.where((tab) =>
        tab.title.toLowerCase().contains(lowerQuery) ||
        tab.url.toLowerCase().contains(lowerQuery)
    ).toList();
  }
  
  static List<BrowserTab> filterTabsByDomain(String domain) {
    return _tabs.where((tab) {
      try {
        final uri = Uri.parse(tab.url);
        return uri.host.contains(domain);
      } catch (e) {
        return false;
      }
    }).toList();
  }
  
  static List<BrowserTab> getTabsByGroup(String groupId) {
    return _tabs.where((tab) => tab.metadata['groupId'] == groupId).toList();
  }
  
  // Tab session management
  static Future<void> saveSession(String name) async {
    final session = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'tabs': _tabs.map((tab) => {
        'url': tab.url,
        'title': tab.title,
        'favicon': tab.favicon,
      }).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    final sessions = await getSavedSessions();
    sessions.add(session);
    
    await StorageService.setSetting('saved_sessions', sessions);
  }
  
  static Future<List<Map<String, dynamic>>> getSavedSessions() async {
    final sessions = StorageService.getSetting<List>('saved_sessions') ?? [];
    return sessions.cast<Map<String, dynamic>>();
  }
  
  static Future<void> restoreSession(String sessionId) async {
    final sessions = await getSavedSessions();
    final session = sessions.firstWhere(
      (s) => s['id'] == sessionId,
      orElse: () => throw Exception('Session not found'),
    );
    
    final sessionTabs = List<Map<String, dynamic>>.from(session['tabs'] ?? []);
    
    // Close current tabs (except pinned ones)
    final tabsToClose = _tabs.where((tab) => !tab.metadata.containsKey('pinned')).toList();
    for (final tab in tabsToClose) {
      await closeTab(tab.id);
    }
    
    // Create tabs from session
    for (final tabData in sessionTabs) {
      await createTab(
        url: tabData['url'] as String?,
        title: tabData['title'] as String?,
      );
    }
  }
  
  // Tab performance monitoring
  static void _startTabTimer(String tabId) {
    _tabTimers[tabId] = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateTabMetrics(tabId);
    });
  }
  
  static void _stopTabTimer(String tabId) {
    _tabTimers[tabId]?.cancel();
    _tabTimers.remove(tabId);
  }
  
  static void _updateTabMetrics(String tabId) {
    // Simulate memory usage tracking
    final currentUsage = _tabMemoryUsage[tabId] ?? 0.0;
    final newUsage = currentUsage + (0.1 * (1 + (DateTime.now().millisecondsSinceEpoch % 10)));
    _tabMemoryUsage[tabId] = newUsage;
    
    // Check for memory leaks
    if (newUsage > 100.0) {
      _handleMemoryLeak(tabId);
    }
  }
  
  static void _handleMemoryLeak(String tabId) {
    // Notify about potential memory leak
    print('Memory leak detected in tab $tabId');
    
    // Could trigger automatic tab reload or user notification
  }
  
  static Map<String, double> getTabMemoryUsage() {
    return Map.unmodifiable(_tabMemoryUsage);
  }
  
  // Tab automation and smart features
  static Future<void> enableAutoDiscard(bool enabled) async {
    await StorageService.setSetting('auto_discard_tabs', enabled);
    
    if (enabled) {
      _startAutoDiscardTimer();
    } else {
      _stopAutoDiscardTimer();
    }
  }
  
  static Timer? _autoDiscardTimer;
  
  static void _startAutoDiscardTimer() {
    _autoDiscardTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _discardInactiveTabs();
    });
  }
  
  static void _stopAutoDiscardTimer() {
    _autoDiscardTimer?.cancel();
    _autoDiscardTimer = null;
  }
  
  static void _discardInactiveTabs() {
    final now = DateTime.now();
    final inactiveThreshold = const Duration(minutes: 30);
    
    for (final tab in _tabs) {
      final lastAccessed = tab.lastAccessed ?? tab.createdAt;
      final inactiveDuration = now.difference(lastAccessed);
      
      if (inactiveDuration > inactiveThreshold && 
          !tab.metadata.containsKey('pinned') && 
          !tab.isLoading) {
        _discardTab(tab.id);
      }
    }
  }
  
  static void _discardTab(String tabId) {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return;
    
    final tab = _tabs[tabIndex];
    final discardedTab = BrowserTab(
      id: tab.id,
      url: tab.url,
      title: tab.title,
      isLoading: false,
      favicon: tab.favicon,
      progress: tab.progress,
      createdAt: tab.createdAt,
      lastAccessed: tab.lastAccessed,
      isIncognito: tab.isIncognito,
      metadata: {
        ...tab.metadata,
        'discarded': true,
        'discardedAt': DateTime.now().toIso8601String(),
      },
    );
    
    _tabs[tabIndex] = discardedTab;
    _tabsController.add(_tabs);
  }
  
  static Future<void> restoreDiscardedTab(String tabId) async {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return;
    
    final tab = _tabs[tabIndex];
    if (!tab.metadata.containsKey('discarded')) return;
    
    final restoredMetadata = Map<String, dynamic>.from(tab.metadata);
    restoredMetadata.remove('discarded');
    restoredMetadata.remove('discardedAt');
    
    final restoredTab = BrowserTab(
      id: tab.id,
      url: tab.url,
      title: tab.title,
      isLoading: true,
      favicon: tab.favicon,
      progress: 0.0,
      createdAt: tab.createdAt,
      lastAccessed: DateTime.now(),
      isIncognito: tab.isIncognito,
      metadata: restoredMetadata,
    );
    
    _tabs[tabIndex] = restoredTab;
    _tabsController.add(_tabs);
  }
  
  // Tab persistence
  static Future<void> _saveTabState(BrowserTab tab) async {
    if (tab.isIncognito) return; // Don't save incognito tabs
    
    final tabData = {
      'id': tab.id,
      'url': tab.url,
      'title': tab.title,
      'favicon': tab.favicon,
      'createdAt': tab.createdAt.toIso8601String(),
      'lastAccessed': tab.lastAccessed?.toIso8601String(),
      'metadata': tab.metadata,
    };
    
    await StorageService.setSetting('tab_${tab.id}', tabData);
  }
  
  static Future<void> _saveRecentlyClosed(BrowserTab tab) async {
    final recentlyClosed = await getRecentlyClosedTabs();
    
    recentlyClosed.insert(0, {
      'url': tab.url,
      'title': tab.title,
      'favicon': tab.favicon,
      'closedAt': DateTime.now().toIso8601String(),
    });
    
    // Keep only last 20 closed tabs
    if (recentlyClosed.length > 20) {
      recentlyClosed.removeRange(20, recentlyClosed.length);
    }
    
    await StorageService.setSetting('recently_closed_tabs', recentlyClosed);
  }
  
  static Future<List<Map<String, dynamic>>> getRecentlyClosedTabs() async {
    final closed = StorageService.getSetting<List>('recently_closed_tabs') ?? [];
    return closed.cast<Map<String, dynamic>>();
  }
  
  static Future<void> restoreRecentlyClosedTab(int index) async {
    final recentlyClosed = await getRecentlyClosedTabs();
    if (index >= recentlyClosed.length) return;
    
    final tabData = recentlyClosed[index];
    await createTab(
      url: tabData['url'] as String?,
      title: tabData['title'] as String?,
    );
    
    // Remove from recently closed
    recentlyClosed.removeAt(index);
    await StorageService.setSetting('recently_closed_tabs', recentlyClosed);
  }
  
  // Tab statistics and analytics
  static Future<Map<String, dynamic>> getTabStatistics() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return {
      'totalTabs': _tabs.length,
      'activeTabs': _tabs.where((tab) => !tab.metadata.containsKey('discarded')).length,
      'discardedTabs': _tabs.where((tab) => tab.metadata.containsKey('discarded')).length,
      'incognitoTabs': _tabs.where((tab) => tab.isIncognito).length,
      'loadingTabs': _tabs.where((tab) => tab.isLoading).length,
      'pinnedTabs': _tabs.where((tab) => tab.metadata.containsKey('pinned')).length,
      'tabsCreatedToday': _tabs.where((tab) => tab.createdAt.isAfter(today)).length,
      'averageTabAge': _calculateAverageTabAge(),
      'memoryUsage': _tabMemoryUsage.values.fold(0.0, (sum, usage) => sum + usage),
      'topDomains': _getTopDomains(),
    };
  }
  
  static double _calculateAverageTabAge() {
    if (_tabs.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final totalAge = _tabs.fold(0, (sum, tab) => sum + now.difference(tab.createdAt).inMinutes);
    
    return totalAge / _tabs.length;
  }
  
  static List<Map<String, dynamic>> _getTopDomains() {
    final domainCounts = <String, int>{};
    
    for (final tab in _tabs) {
      try {
        final uri = Uri.parse(tab.url);
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
  
  // Cleanup and initialization
  static Future<void> initialize() async {
    // Load saved tabs (non-incognito)
    await _loadSavedTabs();
    
    // Start auto-discard if enabled
    final autoDiscardEnabled = StorageService.getSetting<bool>('auto_discard_tabs') ?? false;
    if (autoDiscardEnabled) {
      _startAutoDiscardTimer();
    }
  }
  
  static Future<void> _loadSavedTabs() async {
    // This would load tabs from storage
    // For now, we'll skip this to avoid complexity
  }
  
  static void dispose() {
    _tabsController.close();
    _autoDiscardTimer?.cancel();
    
    for (final timer in _tabTimers.values) {
      timer.cancel();
    }
    _tabTimers.clear();
  }
}