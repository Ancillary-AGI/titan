import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/browser_tab.dart';
import '../services/storage_service.dart';

class BrowserState {
  final List<BrowserTab> tabs;
  final int activeTabIndex;
  final bool isLoading;
  
  const BrowserState({
    required this.tabs,
    required this.activeTabIndex,
    this.isLoading = false,
  });
  
  BrowserState copyWith({
    List<BrowserTab>? tabs,
    int? activeTabIndex,
    bool? isLoading,
  }) {
    return BrowserState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  BrowserTab? get activeTab {
    if (activeTabIndex >= 0 && activeTabIndex < tabs.length) {
      return tabs[activeTabIndex];
    }
    return null;
  }
}

class BrowserNotifier extends StateNotifier<BrowserState> {
  BrowserNotifier() : super(const BrowserState(tabs: [], activeTabIndex: -1)) {
    _loadTabs();
  }
  
  void _loadTabs() {
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
  
  void _saveTabs() {
    // Do not persist incognito tabs
    final nonIncognito = state.tabs.where((t) => !t.incognito).toList();
    StorageService.saveTabs(nonIncognito);
  }
}

final browserProvider = StateNotifierProvider<BrowserNotifier, BrowserState>((ref) {
  return BrowserNotifier();
});