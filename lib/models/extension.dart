import 'dart:typed_data';

/// Extension types supported by Titan Browser
enum ExtensionType {
  browserAction, // Toolbar button extensions
  pageAction, // Page-specific actions
  contentScript, // Content modification scripts
  background, // Background service extensions
  theme, // Visual themes
  devtools, // Developer tools extensions
  webRequest, // Network request modification
  contextMenu, // Context menu additions
  omnibox, // Address bar extensions
  bookmarks, // Bookmark management
  history, // History management
  tabs, // Tab management
  windows, // Window management
  storage, // Data storage extensions
  notifications, // Notification extensions
  ai, // AI-powered extensions
}

/// Extension permission levels
enum ExtensionPermission {
  // Basic permissions
  activeTab, // Access to active tab
  tabs, // Access to tab information
  storage, // Local storage access
  notifications, // Show notifications
  contextMenus, // Add context menu items

  // Advanced permissions
  allUrls, // Access to all websites
  webRequest, // Intercept network requests
  webRequestBlocking, // Block network requests
  cookies, // Access to cookies
  history, // Access to browsing history
  bookmarks, // Access to bookmarks
  downloads, // Access to downloads

  // Sensitive permissions
  nativeMessaging, // Communicate with native apps
  debugger, // Debugging API access
  desktopCapture, // Screen capture
  system, // System information access
  management, // Extension management

  // AI permissions
  aiAnalysis, // AI page analysis
  aiAutomation, // AI automation features
  aiLearning, // AI learning from user behavior
}

/// Extension manifest structure
class ExtensionManifest {
  final String name;
  final String version;
  final String description;
  final String? author;
  final String? homepage;
  final List<ExtensionPermission> permissions;
  final ExtensionType type;
  final Map<String, dynamic> browserAction;
  final Map<String, dynamic> pageAction;
  final List<String> contentScripts;
  final Map<String, String> background;
  final Map<String, dynamic> webRequest;
  final List<String> matches;
  final Map<String, dynamic> icons;
  final String? updateUrl;
  final int manifestVersion;
  final Map<String, dynamic> options;

  const ExtensionManifest({
    required this.name,
    required this.version,
    required this.description,
    this.author,
    this.homepage,
    this.permissions = const [],
    required this.type,
    this.browserAction = const {},
    this.pageAction = const {},
    this.contentScripts = const [],
    this.background = const {},
    this.webRequest = const {},
    this.matches = const [],
    this.icons = const {},
    this.updateUrl,
    this.manifestVersion = 3,
    this.options = const {},
  });

  factory ExtensionManifest.fromJson(Map<String, dynamic> json) {
    return ExtensionManifest(
      name: json['name'] ?? '',
      version: json['version'] ?? '1.0.0',
      description: json['description'] ?? '',
      author: json['author'],
      homepage: json['homepage'],
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((p) => ExtensionPermission.values.firstWhere(
                    (perm) => perm.name == p,
                    orElse: () => ExtensionPermission.activeTab,
                  ))
              .toList() ??
          [],
      type: ExtensionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ExtensionType.browserAction,
      ),
      browserAction: Map<String, dynamic>.from(json['browser_action'] ?? {}),
      pageAction: Map<String, dynamic>.from(json['page_action'] ?? {}),
      contentScripts: List<String>.from(json['content_scripts'] ?? []),
      background: Map<String, String>.from(json['background'] ?? {}),
      webRequest: Map<String, dynamic>.from(json['web_request'] ?? {}),
      matches: List<String>.from(json['matches'] ?? []),
      icons: Map<String, dynamic>.from(json['icons'] ?? {}),
      updateUrl: json['update_url'],
      manifestVersion: json['manifest_version'] ?? 3,
      options: Map<String, dynamic>.from(json['options'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'description': description,
        'author': author,
        'homepage': homepage,
        'permissions': permissions.map((p) => p.name).toList(),
        'type': type.name,
        'browser_action': browserAction,
        'page_action': pageAction,
        'content_scripts': contentScripts,
        'background': background,
        'web_request': webRequest,
        'matches': matches,
        'icons': icons,
        'update_url': updateUrl,
        'manifest_version': manifestVersion,
        'options': options,
      };
}

/// Extension installation status
enum ExtensionStatus {
  installed,
  enabled,
  disabled,
  updating,
  error,
  pending,
}

/// Extension security rating
enum SecurityRating {
  safe, // Verified safe by Titan team
  trusted, // From trusted developers
  reviewed, // Community reviewed
  unverified, // Not yet reviewed
  warning, // Has potential issues
  dangerous, // Known security issues
}

/// Extension model
class Extension {
  final String id;
  final ExtensionManifest manifest;
  final ExtensionStatus status;
  final SecurityRating securityRating;
  final DateTime installedAt;
  final DateTime? lastUpdated;
  final String installPath;
  final Map<String, dynamic> settings;
  final List<String> errors;
  final Map<String, dynamic> runtime;
  final int downloadCount;
  final double rating;
  final int reviewCount;
  final List<String> screenshots;
  final String? iconUrl;
  final bool isOfficial;
  final bool isPremium;
  final double? price;

  const Extension({
    required this.id,
    required this.manifest,
    required this.status,
    required this.securityRating,
    required this.installedAt,
    this.lastUpdated,
    required this.installPath,
    this.settings = const {},
    this.errors = const [],
    this.runtime = const {},
    this.downloadCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.screenshots = const [],
    this.iconUrl,
    this.isOfficial = false,
    this.isPremium = false,
    this.price,
  });

  factory Extension.fromJson(Map<String, dynamic> json) {
    return Extension(
      id: json['id'] ?? '',
      manifest: ExtensionManifest.fromJson(json['manifest'] ?? {}),
      status: ExtensionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ExtensionStatus.installed,
      ),
      securityRating: SecurityRating.values.firstWhere(
        (r) => r.name == json['security_rating'],
        orElse: () => SecurityRating.unverified,
      ),
      installedAt: DateTime.parse(
          json['installed_at'] ?? DateTime.now().toIso8601String()),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
      installPath: json['install_path'] ?? '',
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      errors: List<String>.from(json['errors'] ?? []),
      runtime: Map<String, dynamic>.from(json['runtime'] ?? {}),
      downloadCount: json['download_count'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      screenshots: List<String>.from(json['screenshots'] ?? []),
      iconUrl: json['icon_url'],
      isOfficial: json['is_official'] ?? false,
      isPremium: json['is_premium'] ?? false,
      price: json['price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'manifest': manifest.toJson(),
        'status': status.name,
        'security_rating': securityRating.name,
        'installed_at': installedAt.toIso8601String(),
        'last_updated': lastUpdated?.toIso8601String(),
        'install_path': installPath,
        'settings': settings,
        'errors': errors,
        'runtime': runtime,
        'download_count': downloadCount,
        'rating': rating,
        'review_count': reviewCount,
        'screenshots': screenshots,
        'icon_url': iconUrl,
        'is_official': isOfficial,
        'is_premium': isPremium,
        'price': price,
      };

  /// Check if extension has specific permission
  bool hasPermission(ExtensionPermission permission) {
    return manifest.permissions.contains(permission);
  }

  /// Check if extension is enabled
  bool get isEnabled => status == ExtensionStatus.enabled;

  /// Check if extension is safe to use
  bool get isSafe => securityRating.index <= SecurityRating.reviewed.index;

  /// Get extension icon
  String? getIcon(int size) {
    final icons = manifest.icons;
    final sizeStr = size.toString();

    if (icons.containsKey(sizeStr)) {
      return icons[sizeStr];
    }

    // Find closest size
    final availableSizes = icons.keys
        .map((k) => int.tryParse(k))
        .where((s) => s != null)
        .cast<int>()
        .toList()
      ..sort();

    if (availableSizes.isEmpty) return iconUrl;

    // Find closest size
    int closestSize = availableSizes.first;
    for (final availableSize in availableSizes) {
      if ((availableSize - size).abs() < (closestSize - size).abs()) {
        closestSize = availableSize;
      }
    }

    return icons[closestSize.toString()] ?? iconUrl;
  }

  /// Create copy with updated status
  Extension copyWith({
    ExtensionStatus? status,
    SecurityRating? securityRating,
    DateTime? lastUpdated,
    Map<String, dynamic>? settings,
    List<String>? errors,
    Map<String, dynamic>? runtime,
  }) {
    return Extension(
      id: id,
      manifest: manifest,
      status: status ?? this.status,
      securityRating: securityRating ?? this.securityRating,
      installedAt: installedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      installPath: installPath,
      settings: settings ?? this.settings,
      errors: errors ?? this.errors,
      runtime: runtime ?? this.runtime,
      downloadCount: downloadCount,
      rating: rating,
      reviewCount: reviewCount,
      screenshots: screenshots,
      iconUrl: iconUrl,
      isOfficial: isOfficial,
      isPremium: isPremium,
      price: price,
    );
  }
}

/// Extension marketplace entry
class MarketplaceExtension {
  final String id;
  final ExtensionManifest manifest;
  final SecurityRating securityRating;
  final int downloadCount;
  final double rating;
  final int reviewCount;
  final List<String> screenshots;
  final String? iconUrl;
  final bool isOfficial;
  final bool isPremium;
  final double? price;
  final DateTime publishedAt;
  final DateTime lastUpdated;
  final String category;
  final List<String> tags;
  final String? changelogUrl;
  final String? supportUrl;
  final List<String> compatibleVersions;
  final Map<String, dynamic> metadata;

  const MarketplaceExtension({
    required this.id,
    required this.manifest,
    required this.securityRating,
    this.downloadCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.screenshots = const [],
    this.iconUrl,
    this.isOfficial = false,
    this.isPremium = false,
    this.price,
    required this.publishedAt,
    required this.lastUpdated,
    required this.category,
    this.tags = const [],
    this.changelogUrl,
    this.supportUrl,
    this.compatibleVersions = const [],
    this.metadata = const {},
  });

  factory MarketplaceExtension.fromJson(Map<String, dynamic> json) {
    return MarketplaceExtension(
      id: json['id'] ?? '',
      manifest: ExtensionManifest.fromJson(json['manifest'] ?? {}),
      securityRating: SecurityRating.values.firstWhere(
        (r) => r.name == json['security_rating'],
        orElse: () => SecurityRating.unverified,
      ),
      downloadCount: json['download_count'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      screenshots: List<String>.from(json['screenshots'] ?? []),
      iconUrl: json['icon_url'],
      isOfficial: json['is_official'] ?? false,
      isPremium: json['is_premium'] ?? false,
      price: json['price']?.toDouble(),
      publishedAt: DateTime.parse(
          json['published_at'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(
          json['last_updated'] ?? DateTime.now().toIso8601String()),
      category: json['category'] ?? 'Other',
      tags: List<String>.from(json['tags'] ?? []),
      changelogUrl: json['changelog_url'],
      supportUrl: json['support_url'],
      compatibleVersions: List<String>.from(json['compatible_versions'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'manifest': manifest.toJson(),
        'security_rating': securityRating.name,
        'download_count': downloadCount,
        'rating': rating,
        'review_count': reviewCount,
        'screenshots': screenshots,
        'icon_url': iconUrl,
        'is_official': isOfficial,
        'is_premium': isPremium,
        'price': price,
        'published_at': publishedAt.toIso8601String(),
        'last_updated': lastUpdated.toIso8601String(),
        'category': category,
        'tags': tags,
        'changelog_url': changelogUrl,
        'support_url': supportUrl,
        'compatible_versions': compatibleVersions,
        'metadata': metadata,
      };
}

/// Extension review
class ExtensionReview {
  final String id;
  final String extensionId;
  final String userId;
  final String userName;
  final double rating;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final int helpfulCount;
  final List<String> tags;

  const ExtensionReview({
    required this.id,
    required this.extensionId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.helpfulCount = 0,
    this.tags = const [],
  });

  factory ExtensionReview.fromJson(Map<String, dynamic> json) {
    return ExtensionReview(
      id: json['id'] ?? '',
      extensionId: json['extension_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isVerified: json['is_verified'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'extension_id': extensionId,
        'user_id': userId,
        'user_name': userName,
        'rating': rating,
        'title': title,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_verified': isVerified,
        'helpful_count': helpfulCount,
        'tags': tags,
      };
}
