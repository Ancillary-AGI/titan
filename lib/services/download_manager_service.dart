import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/storage_service.dart';
import '../services/browser_security_service.dart';

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadItem {
  final String id;
  final String url;
  final String filename;
  final String savePath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? error;
  final Map<String, dynamic> metadata;
  
  const DownloadItem({
    required this.id,
    required this.url,
    required this.filename,
    required this.savePath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    required this.startTime,
    this.endTime,
    this.error,
    this.metadata = const {},
  });
  
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
  
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  double get speed {
    final durationSeconds = duration.inSeconds;
    return durationSeconds > 0 ? downloadedBytes / durationSeconds : 0.0;
  }
  
  DownloadItem copyWith({
    String? id,
    String? url,
    String? filename,
    String? savePath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      savePath: savePath ?? this.savePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }
}

class DownloadManagerService {
  static final Dio _dio = Dio();
  static final Map<String, DownloadItem> _downloads = {};
  static final Map<String, CancelToken> _cancelTokens = {};
  static final StreamController<List<DownloadItem>> _downloadsController = StreamController.broadcast();
  static final StreamController<DownloadItem> _downloadUpdateController = StreamController.broadcast();
  
  static Stream<List<DownloadItem>> get downloadsStream => _downloadsController.stream;
  static Stream<DownloadItem> get downloadUpdateStream => _downloadUpdateController.stream;
  static List<DownloadItem> get downloads => _downloads.values.toList();
  
  // Download management
  static Future<String> startDownload({
    required String url,
    String? filename,
    String? savePath,
    Map<String, String>? headers,
    bool resumeIfExists = true,
  }) async {
    // Security check
    final threatLevel = await BrowserSecurityService.checkUrlSafety(url);
    if (threatLevel.index >= ThreatLevel.high.index) {
      throw Exception('Download blocked: URL flagged as potentially dangerous');
    }
    
    // Generate download ID
    final downloadId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Determine filename and save path
    final resolvedFilename = filename ?? _extractFilenameFromUrl(url);
    final resolvedSavePath = savePath ?? await _getDefaultDownloadPath(resolvedFilename);
    
    // Check if file already exists and handle accordingly
    final file = File(resolvedSavePath);
    int resumeFrom = 0;
    
    if (await file.exists() && resumeIfExists) {
      resumeFrom = await file.length();
    }
    
    // Create download item
    final downloadItem = DownloadItem(
      id: downloadId,
      url: url,
      filename: resolvedFilename,
      savePath: resolvedSavePath,
      startTime: DateTime.now(),
      downloadedBytes: resumeFrom,
      metadata: {
        'headers': headers ?? {},
        'resumeFrom': resumeFrom,
      },
    );
    
    _downloads[downloadId] = downloadItem;
    _notifyDownloadsChanged();
    
    // Start download
    _performDownload(downloadItem, headers, resumeFrom);
    
    return downloadId;
  }
  
  static Future<void> _performDownload(
    DownloadItem item,
    Map<String, String>? headers,
    int resumeFrom,
  ) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;
    
    try {
      // Update status to downloading
      _updateDownload(item.id, status: DownloadStatus.downloading);
      
      // Prepare headers for resume
      final requestHeaders = <String, dynamic>{
        ...?headers,
        if (resumeFrom > 0) 'Range': 'bytes=$resumeFrom-',
      };
      
      // Start download
      await _dio.download(
        item.url,
        item.savePath,
        cancelToken: cancelToken,
        options: Options(headers: requestHeaders),
        onReceiveProgress: (received, total) {
          final totalBytes = total > 0 ? total + resumeFrom : 0;
          final downloadedBytes = received + resumeFrom;
          
          _updateDownload(
            item.id,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
          );
        },
      );
      
      // Download completed
      _updateDownload(
        item.id,
        status: DownloadStatus.completed,
        endTime: DateTime.now(),
      );
      
      // Scan downloaded file for security
      await _scanDownloadedFile(item.id);
      
    } catch (e) {
      String errorMessage = e.toString();
      DownloadStatus status = DownloadStatus.failed;
      
      if (e is DioException) {
        if (e.type == DioExceptionType.cancel) {
          status = DownloadStatus.cancelled;
          errorMessage = 'Download cancelled by user';
        } else {
          errorMessage = 'Network error: ${e.message}';
        }
      }
      
      _updateDownload(
        item.id,
        status: status,
        error: errorMessage,
        endTime: DateTime.now(),
      );
    } finally {
      _cancelTokens.remove(item.id);
    }
  }
  
  static Future<void> pauseDownload(String downloadId) async {
    final cancelToken = _cancelTokens[downloadId];
    if (cancelToken != null) {
      cancelToken.cancel('Paused by user');
      _updateDownload(downloadId, status: DownloadStatus.paused);
    }
  }
  
  static Future<void> resumeDownload(String downloadId) async {
    final download = _downloads[downloadId];
    if (download == null || download.status != DownloadStatus.paused) return;
    
    // Restart download from current position
    final headers = Map<String, String>.from(download.metadata['headers'] ?? {});
    await _performDownload(download, headers, download.downloadedBytes);
  }
  
  static Future<void> cancelDownload(String downloadId) async {
    final cancelToken = _cancelTokens[downloadId];
    if (cancelToken != null) {
      cancelToken.cancel('Cancelled by user');
    }
    
    _updateDownload(downloadId, status: DownloadStatus.cancelled);
    
    // Optionally delete partial file
    final download = _downloads[downloadId];
    if (download != null) {
      final file = File(download.savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          print('Failed to delete partial download: $e');
        }
      }
    }
  }
  
  static Future<void> retryDownload(String downloadId) async {
    final download = _downloads[downloadId];
    if (download == null) return;
    
    // Reset download state
    final updatedDownload = download.copyWith(
      status: DownloadStatus.pending,
      downloadedBytes: 0,
      error: null,
      startTime: DateTime.now(),
      endTime: null,
    );
    
    _downloads[downloadId] = updatedDownload;
    _notifyDownloadsChanged();
    
    // Start download again
    final headers = Map<String, String>.from(download.metadata['headers'] ?? {});
    await _performDownload(updatedDownload, headers, 0);
  }
  
  static Future<void> removeDownload(String downloadId, {bool deleteFile = false}) async {
    final download = _downloads[downloadId];
    if (download == null) return;
    
    // Cancel if still downloading
    if (download.status == DownloadStatus.downloading) {
      await cancelDownload(downloadId);
    }
    
    // Delete file if requested
    if (deleteFile) {
      final file = File(download.savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          print('Failed to delete download file: $e');
        }
      }
    }
    
    // Remove from memory and storage
    _downloads.remove(downloadId);
    await StorageService.removeSetting('download_$downloadId');
    
    _notifyDownloadsChanged();
  }
  
  // Batch operations
  static Future<void> pauseAllDownloads() async {
    final activeDownloads = _downloads.values
        .where((d) => d.status == DownloadStatus.downloading)
        .toList();
    
    for (final download in activeDownloads) {
      await pauseDownload(download.id);
    }
  }
  
  static Future<void> resumeAllDownloads() async {
    final pausedDownloads = _downloads.values
        .where((d) => d.status == DownloadStatus.paused)
        .toList();
    
    for (final download in pausedDownloads) {
      await resumeDownload(download.id);
    }
  }
  
  static Future<void> clearCompletedDownloads() async {
    final completedIds = _downloads.values
        .where((d) => d.status == DownloadStatus.completed)
        .map((d) => d.id)
        .toList();
    
    for (final id in completedIds) {
      await removeDownload(id);
    }
  }
  
  // Download queue management
  static Future<void> setMaxConcurrentDownloads(int maxConcurrent) async {
    await StorageService.setSetting('max_concurrent_downloads', maxConcurrent);
    _enforceDownloadLimit();
  }
  
  static void _enforceDownloadLimit() {
    final maxConcurrent = StorageService.getSetting<int>('max_concurrent_downloads') ?? 3;
    final activeDownloads = _downloads.values
        .where((d) => d.status == DownloadStatus.downloading)
        .length;
    
    if (activeDownloads >= maxConcurrent) {
      // Pause excess downloads
      final downloadingItems = _downloads.values
          .where((d) => d.status == DownloadStatus.downloading)
          .skip(maxConcurrent)
          .toList();
      
      for (final item in downloadingItems) {
        pauseDownload(item.id);
      }
    }
  }
  
  // File management
  static String _extractFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isNotEmpty) {
        final filename = pathSegments.last;
        if (filename.contains('.')) {
          return filename;
        }
      }
      
      // Fallback to timestamp-based filename
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  static Future<String> _getDefaultDownloadPath(String filename) async {
    final downloadsDir = await getDownloadsDirectory() ?? 
                       await getApplicationDocumentsDirectory();
    
    final downloadPath = path.join(downloadsDir.path, filename);
    
    // Ensure unique filename
    return await _ensureUniqueFilename(downloadPath);
  }
  
  static Future<String> _ensureUniqueFilename(String filePath) async {
    if (!await File(filePath).exists()) {
      return filePath;
    }
    
    final dir = path.dirname(filePath);
    final name = path.basenameWithoutExtension(filePath);
    final ext = path.extension(filePath);
    
    int counter = 1;
    String newPath;
    
    do {
      newPath = path.join(dir, '${name}_$counter$ext');
      counter++;
    } while (await File(newPath).exists());
    
    return newPath;
  }
  
  // Security scanning
  static Future<void> _scanDownloadedFile(String downloadId) async {
    final download = _downloads[downloadId];
    if (download == null) return;
    
    try {
      final file = File(download.savePath);
      if (!await file.exists()) return;
      
      // Basic file type validation
      final isExecutable = _isExecutableFile(download.filename);
      if (isExecutable) {
        // Mark as potentially dangerous
        _updateDownload(
          downloadId,
          metadata: {
            ...download.metadata,
            'executable': true,
            'scanResult': 'warning',
          },
        );
      }
      
      // Check file size limits
      final fileSize = await file.length();
      final maxSize = StorageService.getSetting<int>('max_download_size') ?? (100 * 1024 * 1024); // 100MB
      
      if (fileSize > maxSize) {
        _updateDownload(
          downloadId,
          metadata: {
            ...download.metadata,
            'oversized': true,
          },
        );
      }
      
    } catch (e) {
      print('Error scanning downloaded file: $e');
    }
  }
  
  static bool _isExecutableFile(String filename) {
    final executableExtensions = ['.exe', '.msi', '.app', '.deb', '.rpm', '.dmg', '.pkg'];
    final extension = path.extension(filename).toLowerCase();
    return executableExtensions.contains(extension);
  }
  
  // Statistics and monitoring
  static Map<String, dynamic> getDownloadStatistics() {
    final allDownloads = _downloads.values.toList();
    
    return {
      'total': allDownloads.length,
      'completed': allDownloads.where((d) => d.status == DownloadStatus.completed).length,
      'downloading': allDownloads.where((d) => d.status == DownloadStatus.downloading).length,
      'paused': allDownloads.where((d) => d.status == DownloadStatus.paused).length,
      'failed': allDownloads.where((d) => d.status == DownloadStatus.failed).length,
      'totalBytes': allDownloads.fold(0, (sum, d) => sum + d.totalBytes),
      'downloadedBytes': allDownloads.fold(0, (sum, d) => sum + d.downloadedBytes),
      'averageSpeed': _calculateAverageSpeed(allDownloads),
    };
  }
  
  static double _calculateAverageSpeed(List<DownloadItem> downloads) {
    final completedDownloads = downloads
        .where((d) => d.status == DownloadStatus.completed)
        .toList();
    
    if (completedDownloads.isEmpty) return 0.0;
    
    final totalSpeed = completedDownloads.fold(0.0, (sum, d) => sum + d.speed);
    return totalSpeed / completedDownloads.length;
  }
  
  // Helper methods
  static void _updateDownload(
    String downloadId, {
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    DateTime? endTime,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    final current = _downloads[downloadId];
    if (current == null) return;
    
    final updated = current.copyWith(
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes,
      status: status,
      endTime: endTime,
      error: error,
      metadata: metadata,
    );
    
    _downloads[downloadId] = updated;
    _downloadUpdateController.add(updated);
    _notifyDownloadsChanged();
    
    // Save to storage
    _saveDownloadState(updated);
  }
  
  static void _notifyDownloadsChanged() {
    _downloadsController.add(_downloads.values.toList());
  }
  
  static Future<void> _saveDownloadState(DownloadItem download) async {
    final data = {
      'id': download.id,
      'url': download.url,
      'filename': download.filename,
      'savePath': download.savePath,
      'totalBytes': download.totalBytes,
      'downloadedBytes': download.downloadedBytes,
      'status': download.status.index,
      'startTime': download.startTime.toIso8601String(),
      'endTime': download.endTime?.toIso8601String(),
      'error': download.error,
      'metadata': download.metadata,
    };
    
    await StorageService.setSetting('download_${download.id}', data);
  }
  
  // Initialization and cleanup
  static Future<void> initialize() async {
    // Load saved downloads
    await _loadSavedDownloads();
    
    // Configure Dio
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }
  
  static Future<void> _loadSavedDownloads() async {
    // This would load downloads from storage
    // For now, we'll skip this to avoid complexity
  }
  
  static void dispose() {
    _downloadsController.close();
    _downloadUpdateController.close();
    
    // Cancel all active downloads
    for (final cancelToken in _cancelTokens.values) {
      cancelToken.cancel('App closing');
    }
    _cancelTokens.clear();
  }
}