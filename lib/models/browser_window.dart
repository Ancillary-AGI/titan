import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'browser_tab.dart';

class BrowserWindow {
  final String id;
  final bool isIncognito;
  final String initialUrl;
  final Size size;
  final Offset? position;
  final List<BrowserTab> tabs;
  int activeTabIndex;
  DateTime createdAt;
  DateTime lastAccessed;
  bool isMinimized;
  bool isMaximized;
  bool isFullScreen;
  bool isAlwaysOnTop;
  
  BrowserWindow({
    String? id,
    required this.isIncognito,
    required this.initialUrl,
    required this.size,
    this.position,
    List<BrowserTab>? tabs,
    this.activeTabIndex = 0,
    DateTime? createdAt,
    DateTime? lastAccessed,
    this.isMinimized = false,
    this.isMaximized = false,
    this.isFullScreen = false,
    this.isAlwaysOnTop = false,
  }) : id = id ?? const Uuid().v4(),
       tabs = tabs ?? [BrowserTab(title: 'New Tab', url: initialUrl)],
       createdAt = createdAt ?? DateTime.now(),
       lastAccessed = lastAccessed ?? DateTime.now();
  
  BrowserWindow copyWith({
    bool? isIncognito,
    String? initialUrl,
    Size? size,
    Offset? position,
    List<BrowserTab>? tabs,
    int? activeTabIndex,
    DateTime? lastAccessed,
    bool? isMinimized,
    bool? isMaximized,
    bool? isFullScreen,
    bool? isAlwaysOnTop,
  }) {
    return BrowserWindow(
      id: id,
      isIncognito: isIncognito ?? this.isIncognito,
      initialUrl: initialUrl ?? this.initialUrl,
      size: size ?? this.size,
      position: position ?? this.position,
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      createdAt: createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isMinimized: isMinimized ?? this.isMinimized,
      isMaximized: isMaximized ?? this.isMaximized,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
    );
  }
  
  BrowserTab? get activeTab {
    if (activeTabIndex >= 0 && activeTabIndex < tabs.length) {
      return tabs[activeTabIndex];
    }
    return null;
  }
  
  void addTab(BrowserTab tab) {
    tabs.add(tab);
    activeTabIndex = tabs.length - 1;
    lastAccessed = DateTime.now();
  }
  
  void removeTab(int index) {
    if (index >= 0 && index < tabs.length) {
      tabs.removeAt(index);
      if (activeTabIndex >= tabs.length) {
        activeTabIndex = tabs.length - 1;
      }
      if (activeTabIndex < 0 && tabs.isNotEmpty) {
        activeTabIndex = 0;
      }
      lastAccessed = DateTime.now();
    }
  }
  
  void switchToTab(int index) {
    if (index >= 0 && index < tabs.length) {
      activeTabIndex = index;
      lastAccessed = DateTime.now();
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isIncognito': isIncognito,
      'initialUrl': initialUrl,
      'size': {'width': size.width, 'height': size.height},
      'position': position != null 
          ? {'x': position!.dx, 'y': position!.dy} 
          : null,
      'tabs': tabs.map((tab) => tab.toJson()).toList(),
      'activeTabIndex': activeTabIndex,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'isMinimized': isMinimized,
      'isMaximized': isMaximized,
      'isFullScreen': isFullScreen,
      'isAlwaysOnTop': isAlwaysOnTop,
    };
  }
  
  factory BrowserWindow.fromJson(Map<String, dynamic> json) {
    return BrowserWindow(
      id: json['id'],
      isIncognito: json['isIncognito'] ?? false,
      initialUrl: json['initialUrl'] ?? 'titan://newtab',
      size: Size(
        json['size']['width']?.toDouble() ?? 1200.0,
        json['size']['height']?.toDouble() ?? 800.0,
      ),
      position: json['position'] != null
          ? Offset(
              json['position']['x']?.toDouble() ?? 0.0,
              json['position']['y']?.toDouble() ?? 0.0,
            )
          : null,
      tabs: (json['tabs'] as List?)
          ?.map((tabJson) => BrowserTab.fromJson(tabJson))
          .toList() ?? [],
      activeTabIndex: json['activeTabIndex'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessed: DateTime.parse(json['lastAccessed']),
      isMinimized: json['isMinimized'] ?? false,
      isMaximized: json['isMaximized'] ?? false,
      isFullScreen: json['isFullScreen'] ?? false,
      isAlwaysOnTop: json['isAlwaysOnTop'] ?? false,
    );
  }
}