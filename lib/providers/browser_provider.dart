import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/browser_tab.dart';
import '../models/browser_window.dart';
import '../services/storage_service.dart';
import '../services/networking_service.dart';

class BrowserState {
  final List<BrowserTab> tabs;
  final int activeTabIndex;
  final bool isLoading;
  final List<BrowserWindow> windows;
  final int activeWindowIndex;
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> recentlyClosedTabs;
  final bool incognitoMode;
  final Map<String, dynamic> networkStats;
  
  const BrowserState({
    required this.tabs,
    required this.activeTabIndex,
    this.isLoading = false,
    this.windows = const [],
    this.activeWindowIndex = 0,
    this.settings = const {},
    this.recentlyClosedTabs = const [],
    this.incognitoMode = false,
    this.networkStats = const {},
  });
  
  BrowserState copyWith({
    List<BrowserTab>? tabs,
    int? activeTabIndex,
    bool? isLoading,
    List<BrowserWindow>? windows,
    int? activeWindowIndex,
    Map<String, dynamic>? settings,
    List<Map<String, dynamic>>? recentlyClosedTabs,
    bool? incognitoMode,
    Map<String, dynamic>? networkStats,
  }) {
    return BrowserState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isLoading: isLoading ?? this.isLoading,
      windows: windows ?? this.windows,
      activeWindowIndex: activeWindowIndex ?? this.activeWindowIndex,
      settings: settings ?? this.settings,
      recentlyClosedTabs: recentlyClosedTabs ?? this.recentlyClosedTabs,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      networkStats: networkStats ?? this.networkStats,
    );
  }
  
  BrowserTab? get activeTab {
    if (activeTabIndex >= 0 && activeTabIndex < tabs.length) {
      return tabs[activeTabIndex];
    }
    return null;
  }
  
  BrowserWindow? get activeWindow {
    if (activeWindowIndex >= 0 && activeWindowIndex < windows.length) {
      return windows[activeWindowIndex];
    }
    return null;
  }
  
  List<BrowserTab> get incognitoTabs {
    return tabs.where((tab) => tab.incognito).toList();
  }
  
  List<BrowserTab> get normalTabs {
    return tabs.where((tab) => !tab.incognito).toList();
  }
  
  int get totalTabs => tabs.length;
  int get loadingTabs => tabs.where((tab) => tab.isLoading).length;
  bool get hasIncognitoTabs => incognitoTabs.isNotEmpty;
}

class BrowserNotifier extends StateNotifier<BrowserState> {
  Timer? _statsTimer;
  
  BrowserNotifier() : super(const BrowserState(tabs: [], activeTabIndex: -1)) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadTabs();
    await _loadSettings();
    _startStatsTimer();
  }
  
  Future<void> _loadTabs() async {
    try {
      final savedTabs = StorageService.loadTabs();
      if (savedTabs.isNotEmpty) {
        state = state.copyWith(
          tabs: savedTabs,
          activeTabIndex: 0,
        );
      } else {
        // Create initial tab
        addNewTab();
      }
    } catch (e) {
      // Fallback: create new tab
      addNewTab();
    }
  }
  
  Future<void> _loadSettings() async {
    try {
      final settings = StorageService.getAllSettings();
      state = state.copyWith(settings: settings);
    } catch (e) {
      // Use default settings
    }
  }
  
  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateNetworkStats();
    });
  }
  
  void _updateNetworkStats() {
    final stats = NetworkingService.getNetworkStats();
    state = state.copyWith(networkStats: stats);
  }
  
  void addNewTab({String? url, bool incognito = false}) {
    final newTab = BrowserTab(
      title: incognito ? 'Incognito' : 'New Tab',
      url: url ?? 'about:blank',
      incognito: incognito,
    );
    
    final updatedTabs = [...state.tabs, newTab];
    state = state.copyWith(
      tabs: updatedTabs,
      activeTabIndex: updatedTabs.length - 1,
    );
    
    _saveTabs();
  }
  
  void closeTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    
    final tabToClose = state.tabs[index];
    
    // Add to recently closed tabs (unless incognito)
    if (!tabToClose.incognito) {
      final recentlyClosedTab = {
        'title': tabToClose.title,
        'url': tabToClose.url,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final updatedRecentlyClosed = [recentlyClosedTab, ...state.recentlyClosedTabs];
      // Keep only last 10 recently closed tabs
      if (updatedRecentlyClosed.length > 10) {
        updatedRecentlyClosed.removeLast();
      }
      
      state = state.copyWith(recentlyClosedTabs: updatedRecentlyClosed);
    }
    
    final updatedTabs = [...state.tabs];
    updatedTabs.removeAt(index);
    
    int newActiveIndex = state.activeTabIndex;
    if (index == state.activeTabIndex) {
      if (updatedTabs.isEmpty) {
        addNewTab();
        return;
      } else if (index >= updatedTabs.length) {
        newActiveIndex = updatedTabs.length - 1;
      }
    } else if (index < state.activeTabIndex) {
      newActiveIndex = state.activeTabIndex - 1;
    }
    
    state = state.copyWith(
      tabs: updatedTabs,
      activeTabIndex: newActiveIndex,
    );
    
    _saveTabs();
  }
  
  void restoreRecentlyClosedTab() {
    if (state.recentlyClosedTabs.isEmpty) return;
    
    final recentTab = state.recentlyClosedTabs.first;
    addNewTab(url: recentTab['url']);
    
    final updatedRecentlyClosed = [...state.recentlyClosedTabs];
    updatedRecentlyClosed.removeAt(0);
    
    state = state.copyWith(recentlyClosedTabs: updatedRecentlyClosed);
  }
  
  void closeAllTabs({bool incognitoOnly = false}) {
    if (incognitoOnly) {
      final nonIncognitoTabs = state.tabs.where((tab) => !tab.incognito).toList();
      if (nonIncognitoTabs.isEmpty) {
        addNewTab(); // Ensure at least one tab exists
      } else {
        state = state.copyWith(
          tabs: nonIncognitoTabs,
          activeTabIndex: 0,
        );
      }
    } else {
      state = state.copyWith(
        tabs: [],
        activeTabIndex: -1,
      );
      addNewTab();
    }
    _saveTabs();
  }
  
  void duplicateTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    
    final originalTab = state.tabs[index];
    final duplicatedTab = BrowserTab(
      title: originalTab.title,
      url: originalTab.url,
      incognito: originalTab.incognito,
    );
    
    final updatedTabs = [...state.tabs];
    updatedTabs.insert(index + 1, duplicatedTab);
    
    state = state.copyWith(
      tabs: updatedTabs,
      activeTabIndex: index + 1,
    );
    
    _saveTabs();
  }
  
  void moveTab(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= state.tabs.length ||
        toIndex < 0 || toIndex >= state.tabs.length) return;
    
    final updatedTabs = [...state.tabs];
    final tab = updatedTabs.removeAt(fromIndex);
    updatedTabs.insert(toIndex, tab);
    
    // Update active index if needed
    int newActiveIndex = state.activeTabIndex;
    if (fromIndex == state.activeTabIndex) {
      newActiveIndex = toIndex;
    } else if (fromIndex < state.activeTabIndex && toIndex >= state.activeTabIndex) {
      newActiveIndex = state.activeTabIndex - 1;
    } else if (fromIndex > state.activeTabIndex && toIndex <= state.activeTabIndex) {
      newActiveIndex = state.activeTabIndex + 1;
    }
    
    state = state.copyWith(
      tabs: updatedTabs,
      activeTabIndex: newActiveIndex,
    );
    
    _saveTabs();
  }
  
  void switchToTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeTabIndex: index);
      _saveTabs();
    }
  }
  
  void updateTab(int index, BrowserTab updatedTab) {
    if (index < 0 || index >= state.tabs.length) return;
    
    final updatedTabs = [...state.tabs];
    updatedTabs[index] = updatedTab;
    
    state = state.copyWith(tabs: updatedTabs);
    _saveTabs();
  }
  
  void updateActiveTab(BrowserTab updatedTab) {
    if (state.activeTabIndex >= 0) {
      updateTab(state.activeTabIndex, updatedTab);
    }
  }
  
  void navigateToUrl(String url) {
    if (state.activeTab != null) {
      final updatedTab = state.activeTab!.copyWith(
        url: url,
        isLoading: true,
        lastAccessed: DateTime.now(),
      );
      updateActiveTab(updatedTab);
      
      // Add to history unless incognito
      if (!updatedTab.incognito) {
        StorageService.addToHistory(url, updatedTab.title);
      }
    }
  }
  
  void setTabLoading(bool isLoading) {
    if (state.activeTab != null) {
      final updatedTab = state.activeTab!.copyWith(isLoading: isLoading);
      updateActiveTab(updatedTab);
    }
  }
  
  void setTabTitle(String title) {
    if (state.activeTab != null) {
      final updatedTab = state.activeTab!.copyWith(title: title);
      updateActiveTab(updatedTab);
    }
  }
  
  void setTabNavigationState({bool? canGoBack, bool? canGoForward}) {
    if (state.activeTab != null) {
      final updatedTab = state.activeTab!.copyWith(
        canGoBack: canGoBack ?? state.activeTab!.canGoBack,
        canGoForward: canGoForward ?? state.activeTab!.canGoForward,
      );
      updateActiveTab(updatedTab);
    }
  }
  
  // Window management
  void createNewWindow({List<BrowserTab>? tabs}) {
    final newWindow = BrowserWindow(
      isIncognito: false,
      initialUrl: 'about:blank',
      size: const Size(1200, 800),
      tabs: tabs ?? [BrowserTab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Tab', 
        url: 'about:blank'
      )],
    );
    
    final updatedWindows = [...state.windows, newWindow];
    state = state.copyWith(
      windows: updatedWindows,
      activeWindowIndex: updatedWindows.length - 1,
    );
  }
  
  void closeWindow(int index) {
    if (index < 0 || index >= state.windows.length) return;
    
    final updatedWindows = [...state.windows];
    updatedWindows.removeAt(index);
    
    int newActiveIndex = state.activeWindowIndex;
    if (index == state.activeWindowIndex) {
      if (updatedWindows.isEmpty) {
        createNewWindow();
        return;
      } else if (index >= updatedWindows.length) {
        newActiveIndex = updatedWindows.length - 1;
      }
    } else if (index < state.activeWindowIndex) {
      newActiveIndex = state.activeWindowIndex - 1;
    }
    
    state = state.copyWith(
      windows: updatedWindows,
      activeWindowIndex: newActiveIndex,
    );
  }
  
  void switchToWindow(int index) {
    if (index >= 0 && index < state.windows.length) {
      state = state.copyWith(activeWindowIndex: index);
    }
  }
  
  // Settings management
  Future<void> updateSetting(String key, dynamic value) async {
    final settings = Map<String, dynamic>.from(state.settings);
    settings[key] = value;
    state = state.copyWith(settings: settings);
    
    await StorageService.setSetting(key, value);
  }
  
  // Incognito mode
  void toggleIncognitoMode() {
    state = state.copyWith(incognitoMode: !state.incognitoMode);
  }
  
  // Search functionality
  List<BrowserTab> searchTabs(String query) {
    if (query.trim().isEmpty) return state.tabs;
    
    final lowercaseQuery = query.toLowerCase();
    return state.tabs.where((tab) {
      return tab.title.toLowerCase().contains(lowercaseQuery) ||
             tab.url.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  // Tab groups (future feature)
  void createTabGroup(List<int> tabIndices, String groupName) {
    // Implementation for tab grouping
    // This would require extending the BrowserTab model
  }
  
  // Session management
  Future<void> saveSession(String name) async {
    final sessionData = {
      'name': name,
      'tabs': state.normalTabs.map((tab) => tab.toJson()).toList(),
      'activeTabIndex': state.activeTabIndex,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await StorageService.setCacheEntry('session_$name', sessionData);
  }
  
  Future<void> restoreSession(String name) async {
    final sessionData = StorageService.getCacheEntry('session_$name');
    if (sessionData == null) return;
    
    final tabsData = List<Map<String, dynamic>>.from(sessionData['tabs'] ?? []);
    final restoredTabs = tabsData.map((json) => BrowserTab.fromJson(json)).toList();
    
    if (restoredTabs.isNotEmpty) {
      state = state.copyWith(
        tabs: [...state.incognitoTabs, ...restoredTabs],
        activeTabIndex: sessionData['activeTabIndex'] ?? 0,
      );
      _saveTabs();
    }
  }
  
  // Statistics
  Map<String, dynamic> getBrowsingStats() {
    return {
      'total_tabs': state.totalTabs,
      'normal_tabs': state.normalTabs.length,
      'incognito_tabs': state.incognitoTabs.length,
      'loading_tabs': state.loadingTabs,
      'recently_closed_count': state.recentlyClosedTabs.length,
      'network_stats': state.networkStats,
    };
  }
  
  void _saveTabs() {
    // Do not persist incognito tabs
    final nonIncognito = state.tabs.where((t) => !t.incognito).toList();
    StorageService.saveTabs(nonIncognito);
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }
}

final browserProvider = StateNotifierProvider<BrowserNotifier, BrowserState>((ref) {
  return BrowserNotifier();
});
