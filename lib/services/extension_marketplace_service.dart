import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/extension.dart';
import '../services/storage_service.dart';
import '../services/extension_manager_service.dart';

/// Marketplace search filters
class MarketplaceFilters {
  final String? category;
  final List<String> tags;
  final SecurityRating? minSecurityRating;
  final bool? isPremium;
  final double? minRating;
  final String? sortBy; // 'popularity', 'rating', 'recent', 'name'
  final bool ascending;
  final int limit;
  final int offset;
  
  const MarketplaceFilters({
    this.category,
    this.tags = const [],
    this.minSecurityRating,
    this.isPremium,
    this.minRating,
    this.sortBy = 'popularity',
    this.ascending = false,
    this.limit = 20,
    this.offset = 0,
  });
  
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (category != null) params['category'] = category;
    if (tags.isNotEmpty) params['tags'] = tags.join(',');
    if (minSecurityRating != null) params['min_security_rating'] = minSecurityRating!.name;
    if (isPremium != null) params['is_premium'] = isPremium.toString();
    if (minRating != null) params['min_rating'] = minRating.toString();
    if (sortBy != null) params['sort_by'] = sortBy;
    params['ascending'] = ascending.toString();
    params['limit'] = limit.toString();
    params['offset'] = offset.toString();
    
    return params;
  }
}

/// Marketplace search result
class MarketplaceSearchResult {
  final List<MarketplaceExtension> extensions;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  
  const MarketplaceSearchResult({
    required this.extensions,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });
  
  factory MarketplaceSearchResult.fromJson(Map<String, dynamic> json) {
    return MarketplaceSearchResult(
      extensions: (json['extensions'] as List<dynamic>)
          .map((e) => MarketplaceExtension.fromJson(e))
          .toList(),
      totalCount: json['total_count'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      hasMore: json['has_more'] ?? false,
    );
  }
}

/// Extension download progress
class DownloadProgress {
  final String extensionId;
  final int bytesDownloaded;
  final int totalBytes;
  final double progress;
  final String status;
  
  const DownloadProgress({
    required this.extensionId,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.progress,
    required this.status,
  });
}

/// Extension Marketplace Service
class ExtensionMarketplaceService {
  static const String _baseUrl = 'https://marketplace.titan-browser.com/api/v1';
  static final http.Client _httpClient = http.Client();
  
  // Cache
  static final Map<String, MarketplaceExtension> _extensionCache = {};
  static final Map<String, List<MarketplaceExtension>> _categoryCache = {};
  static final Map<String, List<ExtensionReview>> _reviewCache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  // Download tracking
  static final Map<String, StreamController<DownloadProgress>> _downloadStreams = {};
  static final Map<String, http.StreamedResponse> _activeDownloads = {};
  
  // Featured and trending
  static List<MarketplaceExtension> _featuredExtensions = [];
  static List<MarketplaceExtension> _trendingExtensions = [];
  static List<String> _categories = [];
  
  /// Initialize marketplace service
  static Future<void> initialize() async {
    await _loadCachedData();
    await _refreshMarketplaceData();
    _startPeriodicRefresh();
  }
  
  /// Load cached marketplace data
  static Future<void> _loadCachedData() async {
    try {
      final cachedData = StorageService.getSetting<String>('marketplace_cache');
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        
        _featuredExtensions = (data['featured'] as List<dynamic>?)
            ?.map((e) => MarketplaceExtension.fromJson(e))
            .toList() ?? [];
        
        _trendingExtensions = (data['trending'] as List<dynamic>?)
            ?.map((e) => MarketplaceExtension.fromJson(e))
            .toList() ?? [];
        
        _categories = List<String>.from(data['categories'] ?? []);
        
        if (data['cache_time'] != null) {
          _lastCacheUpdate = DateTime.parse(data['cache_time']);
        }
      }
    } catch (e) {
      print('Error loading cached marketplace data: $e');
    }
  }
  
  /// Refresh marketplace data from server
  static Future<void> _refreshMarketplaceData() async {
    try {
      // Fetch featured extensions
      _featuredExtensions = await _fetchFeaturedExtensions();
      
      // Fetch trending extensions
      _trendingExtensions = await _fetchTrendingExtensions();
      
      // Fetch categories
      _categories = await _fetchCategories();
      
      // Update cache timestamp
      _lastCacheUpdate = DateTime.now();
      
      // Save to cache
      await _saveCacheData();
      
    } catch (e) {
      print('Error refreshing marketplace data: $e');
    }
  }
  
  /// Start periodic refresh of marketplace data
  static void _startPeriodicRefresh() {
    Timer.periodic(Duration(hours: 1), (timer) {
      _refreshMarketplaceData();
    });
  }
  
  /// Save marketplace data to cache
  static Future<void> _saveCacheData() async {
    try {
      final cacheData = {
        'featured': _featuredExtensions.map((e) => e.toJson()).toList(),
        'trending': _trendingExtensions.map((e) => e.toJson()).toList(),
        'categories': _categories,
        'cache_time': _lastCacheUpdate?.toIso8601String(),
      };
      
      await StorageService.setSetting('marketplace_cache', jsonEncode(cacheData));
    } catch (e) {
      print('Error saving marketplace cache: $e');
    }
  }
  
  /// Fetch featured extensions
  static Future<List<MarketplaceExtension>> _fetchFeaturedExtensions() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/extensions/featured'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['extensions'] as List<dynamic>)
            .map((e) => MarketplaceExtension.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error fetching featured extensions: $e');
    }
    
    return [];
  }
  
  /// Fetch trending extensions
  static Future<List<MarketplaceExtension>> _fetchTrendingExtensions() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/extensions/trending'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['extensions'] as List<dynamic>)
            .map((e) => MarketplaceExtension.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error fetching trending extensions: $e');
    }
    
    return [];
  }
  
  /// Fetch categories
  static Future<List<String>> _fetchCategories() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/categories'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['categories'] ?? []);
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    
    return [];
  }
  
  /// Search extensions in marketplace
  static Future<MarketplaceSearchResult> searchExtensions(
    String query, {
    MarketplaceFilters? filters,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/extensions/search').replace(
        queryParameters: {
          'q': query,
          ...?filters?.toQueryParams(),
        },
      );
      
      final response = await _httpClient.get(uri, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MarketplaceSearchResult.fromJson(data);
      }
    } catch (e) {
      print('Error searching extensions: $e');
    }
    
    return const MarketplaceSearchResult(
      extensions: [],
      totalCount: 0,
      currentPage: 1,
      totalPages: 1,
      hasMore: false,
    );
  }
  
  /// Get extension details
  static Future<MarketplaceExtension?> getExtensionDetails(String extensionId) async {
    // Check cache first
    if (_extensionCache.containsKey(extensionId)) {
      return _extensionCache[extensionId];
    }
    
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/extensions/$extensionId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final extension = MarketplaceExtension.fromJson(data);
        
        // Cache the result
        _extensionCache[extensionId] = extension;
        
        return extension;
      }
    } catch (e) {
      print('Error fetching extension details: $e');
    }
    
    return null;
  }
  
  /// Get extension reviews
  static Future<List<ExtensionReview>> getExtensionReviews(
    String extensionId, {
    int limit = 20,
    int offset = 0,
  }) async {
    // Check cache first
    final cacheKey = '${extensionId}_${offset}_$limit';
    if (_reviewCache.containsKey(cacheKey)) {
      return _reviewCache[cacheKey]!;
    }
    
    try {
      final uri = Uri.parse('$_baseUrl/extensions/$extensionId/reviews').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      
      final response = await _httpClient.get(uri, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reviews = (data['reviews'] as List<dynamic>)
            .map((r) => ExtensionReview.fromJson(r))
            .toList();
        
        // Cache the result
        _reviewCache[cacheKey] = reviews;
        
        return reviews;
      }
    } catch (e) {
      print('Error fetching extension reviews: $e');
    }
    
    return [];
  }
  
  /// Download and install extension
  static Future<String> downloadAndInstallExtension(String extensionId) async {
    try {
      // Get extension details
      final extension = await getExtensionDetails(extensionId);
      if (extension == null) {
        throw Exception('Extension not found');
      }
      
      // Check if premium extension requires payment
      if (extension.isPremium && extension.price != null) {
        final hasPurchased = await _checkPurchaseStatus(extensionId);
        if (!hasPurchased) {
          throw Exception('Extension requires purchase');
        }
      }
      
      // Start download
      final downloadUrl = '$_baseUrl/extensions/$extensionId/download';
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers.addAll(_getHeaders());
      
      final streamedResponse = await _httpClient.send(request);
      _activeDownloads[extensionId] = streamedResponse;
      
      if (streamedResponse.statusCode != 200) {
        throw Exception('Download failed: ${streamedResponse.statusCode}');
      }
      
      // Track download progress
      final downloadStream = StreamController<DownloadProgress>();
      _downloadStreams[extensionId] = downloadStream;
      
      final contentLength = streamedResponse.contentLength ?? 0;
      int bytesDownloaded = 0;
      final chunks = <List<int>>[];
      
      await for (final chunk in streamedResponse.stream) {
        chunks.add(chunk);
        bytesDownloaded += chunk.length;
        
        final progress = contentLength > 0 ? bytesDownloaded / contentLength : 0.0;
        
        downloadStream.add(DownloadProgress(
          extensionId: extensionId,
          bytesDownloaded: bytesDownloaded,
          totalBytes: contentLength,
          progress: progress,
          status: 'downloading',
        ));
      }
      
      // Combine chunks
      final bytes = Uint8List.fromList(chunks.expand((chunk) => chunk).toList());
      
      // Update progress to installing
      downloadStream.add(DownloadProgress(
        extensionId: extensionId,
        bytesDownloaded: bytesDownloaded,
        totalBytes: contentLength,
        progress: 1.0,
        status: 'installing',
      ));
      
      // Install extension
      final installedExtensionId = await ExtensionManagerService.installExtensionFromBytes(bytes);
      
      // Update progress to completed
      downloadStream.add(DownloadProgress(
        extensionId: extensionId,
        bytesDownloaded: bytesDownloaded,
        totalBytes: contentLength,
        progress: 1.0,
        status: 'completed',
      ));
      
      // Cleanup
      await downloadStream.close();
      _downloadStreams.remove(extensionId);
      _activeDownloads.remove(extensionId);
      
      // Record installation
      await _recordInstallation(extensionId);
      
      return installedExtensionId;
      
    } catch (e) {
      // Cleanup on error
      _downloadStreams[extensionId]?.close();
      _downloadStreams.remove(extensionId);
      _activeDownloads.remove(extensionId);
      
      throw Exception('Failed to download and install extension: $e');
    }
  }
  
  /// Cancel extension download
  static Future<void> cancelDownload(String extensionId) async {
    final download = _activeDownloads[extensionId];
    if (download != null) {
      // Cancel the download stream
      // Note: http.StreamedResponse doesn't have a direct cancel method
      // In a real implementation, you'd use a more sophisticated HTTP client
      
      _activeDownloads.remove(extensionId);
      
      final downloadStream = _downloadStreams[extensionId];
      if (downloadStream != null) {
        downloadStream.add(DownloadProgress(
          extensionId: extensionId,
          bytesDownloaded: 0,
          totalBytes: 0,
          progress: 0.0,
          status: 'cancelled',
        ));
        
        await downloadStream.close();
        _downloadStreams.remove(extensionId);
      }
    }
  }
  
  /// Get download progress stream
  static Stream<DownloadProgress>? getDownloadProgress(String extensionId) {
    return _downloadStreams[extensionId]?.stream;
  }
  
  /// Check if extension is purchased (for premium extensions)
  static Future<bool> _checkPurchaseStatus(String extensionId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/extensions/$extensionId/purchase-status'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['purchased'] ?? false;
      }
    } catch (e) {
      print('Error checking purchase status: $e');
    }
    
    return false;
  }
  
  /// Record extension installation
  static Future<void> _recordInstallation(String extensionId) async {
    try {
      await _httpClient.post(
        Uri.parse('$_baseUrl/extensions/$extensionId/install'),
        headers: _getHeaders(),
        body: jsonEncode({'timestamp': DateTime.now().toIso8601String()}),
      );
    } catch (e) {
      print('Error recording installation: $e');
    }
  }
  
  /// Submit extension review
  static Future<void> submitReview(
    String extensionId,
    double rating,
    String title,
    String content, {
    List<String> tags = const [],
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/extensions/$extensionId/reviews'),
        headers: _getHeaders(),
        body: jsonEncode({
          'rating': rating,
          'title': title,
          'content': content,
          'tags': tags,
        }),
      );
      
      if (response.statusCode == 201) {
        // Clear review cache for this extension
        _reviewCache.removeWhere((key, value) => key.startsWith(extensionId));
      }
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }
  
  /// Report extension
  static Future<void> reportExtension(
    String extensionId,
    String reason,
    String description,
  ) async {
    try {
      await _httpClient.post(
        Uri.parse('$_baseUrl/extensions/$extensionId/report'),
        headers: _getHeaders(),
        body: jsonEncode({
          'reason': reason,
          'description': description,
        }),
      );
    } catch (e) {
      throw Exception('Failed to report extension: $e');
    }
  }
  
  /// Get extensions by category
  static Future<List<MarketplaceExtension>> getExtensionsByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
  }) async {
    // Check cache first
    final cacheKey = '${category}_${offset}_$limit';
    if (_categoryCache.containsKey(cacheKey)) {
      return _categoryCache[cacheKey]!;
    }
    
    try {
      final uri = Uri.parse('$_baseUrl/extensions/category/$category').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      
      final response = await _httpClient.get(uri, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final extensions = (data['extensions'] as List<dynamic>)
            .map((e) => MarketplaceExtension.fromJson(e))
            .toList();
        
        // Cache the result
        _categoryCache[cacheKey] = extensions;
        
        return extensions;
      }
    } catch (e) {
      print('Error fetching extensions by category: $e');
    }
    
    return [];
  }
  
  /// Get developer extensions
  static Future<List<MarketplaceExtension>> getDeveloperExtensions(
    String developerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/developers/$developerId/extensions').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      
      final response = await _httpClient.get(uri, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['extensions'] as List<dynamic>)
            .map((e) => MarketplaceExtension.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error fetching developer extensions: $e');
    }
    
    return [];
  }
  
  /// Get user's purchased extensions
  static Future<List<MarketplaceExtension>> getPurchasedExtensions() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/user/purchased-extensions'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['extensions'] as List<dynamic>)
            .map((e) => MarketplaceExtension.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error fetching purchased extensions: $e');
    }
    
    return [];
  }
  
  /// Get recommended extensions based on installed extensions
  static Future<List<MarketplaceExtension>> getRecommendedExtensions({
    int limit = 10,
  }) async {
    try {
      final installedExtensions = ExtensionManagerService.getInstalledExtensions();
      final installedIds = installedExtensions.map((e) => e.id).toList();
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/extensions/recommendations'),
        headers: _getHeaders(),
        body: jsonEncode({
          'installed_extensions': installedIds,
          'limit': limit,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['extensions'] as List<dynamic>)
            .map((e) => MarketplaceExtension.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error fetching recommended extensions: $e');
    }
    
    return [];
  }
  
  /// Get HTTP headers for API requests
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'Titan Browser Extension Manager',
      'Accept': 'application/json',
      // Add authentication headers if needed
    };
  }
  
  /// Get featured extensions
  static List<MarketplaceExtension> getFeaturedExtensions() {
    return List.from(_featuredExtensions);
  }
  
  /// Get trending extensions
  static List<MarketplaceExtension> getTrendingExtensions() {
    return List.from(_trendingExtensions);
  }
  
  /// Get available categories
  static List<String> getCategories() {
    return List.from(_categories);
  }
  
  /// Check if cache is expired
  static bool get isCacheExpired {
    if (_lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheExpiry;
  }
  
  /// Clear marketplace cache
  static Future<void> clearCache() async {
    _extensionCache.clear();
    _categoryCache.clear();
    _reviewCache.clear();
    _featuredExtensions.clear();
    _trendingExtensions.clear();
    _categories.clear();
    _lastCacheUpdate = null;
    
    await StorageService.removeSetting('marketplace_cache');
  }
  
  /// Get marketplace statistics
  static Map<String, dynamic> getMarketplaceStats() {
    return {
      'cachedExtensions': _extensionCache.length,
      'cachedCategories': _categoryCache.length,
      'cachedReviews': _reviewCache.length,
      'featuredExtensions': _featuredExtensions.length,
      'trendingExtensions': _trendingExtensions.length,
      'categories': _categories.length,
      'activeDownloads': _activeDownloads.length,
      'lastCacheUpdate': _lastCacheUpdate?.toIso8601String(),
      'cacheExpired': isCacheExpired,
    };
  }
  
  /// Cleanup marketplace service
  static Future<void> cleanup() async {
    // Cancel all active downloads
    for (final extensionId in _activeDownloads.keys.toList()) {
      await cancelDownload(extensionId);
    }
    
    // Close all download streams
    for (final stream in _downloadStreams.values) {
      await stream.close();
    }
    _downloadStreams.clear();
    
    // Close HTTP client
    _httpClient.close();
  }
}