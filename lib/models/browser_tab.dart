import 'package:uuid/uuid.dart';

class BrowserTab {
  final String id;
  String title;
  String url;
  bool isLoading;
  bool canGoBack;
  bool canGoForward;
  DateTime lastAccessed;
  String? favicon;
  bool incognito;
  
  BrowserTab({
    String? id,
    required this.title,
    required this.url,
    this.isLoading = false,
    this.canGoBack = false,
    this.canGoForward = false,
    DateTime? lastAccessed,
    this.favicon,
    this.incognito = false,
  }) : id = id ?? const Uuid().v4(),
       lastAccessed = lastAccessed ?? DateTime.now();
  
  BrowserTab copyWith({
    String? title,
    String? url,
    bool? isLoading,
    bool? canGoBack,
    bool? canGoForward,
    DateTime? lastAccessed,
    String? favicon,
    bool? incognito,
  }) {
    return BrowserTab(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      isLoading: isLoading ?? this.isLoading,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      favicon: favicon ?? this.favicon,
      incognito: incognito ?? this.incognito,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'isLoading': isLoading,
      'canGoBack': canGoBack,
      'canGoForward': canGoForward,
      'lastAccessed': lastAccessed.toIso8601String(),
      'favicon': favicon,
      'incognito': incognito,
    };
  }
  
  factory BrowserTab.fromJson(Map<String, dynamic> json) {
    return BrowserTab(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      isLoading: json['isLoading'] ?? false,
      canGoBack: json['canGoBack'] ?? false,
      canGoForward: json['canGoForward'] ?? false,
      lastAccessed: DateTime.parse(json['lastAccessed']),
      favicon: json['favicon'],
      incognito: json['incognito'] ?? false,
    );
  }
}
