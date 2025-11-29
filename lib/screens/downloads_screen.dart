import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/download_manager_service.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../core/localization/app_localizations.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  List<DownloadItem> _downloads = [];
  StreamSubscription<List<DownloadItem>>? _downloadsSubscription;
  String _filter = 'all'; // all, active, completed, failed

  @override
  void initState() {
    super.initState();
    _loadDownloads();
    _subscribeToChanges();
  }

  void _loadDownloads() {
    setState(() {
      _downloads = DownloadManagerService.downloads;
    });
  }

  void _subscribeToChanges() {
    _downloadsSubscription = DownloadManagerService.downloadsStream.listen((downloads) {
      if (mounted) {
        setState(() => _downloads = downloads);
      }
    });
  }

  List<DownloadItem> get _filteredDownloads {
    switch (_filter) {
      case 'active':
        return _downloads.where((d) => 
          d.status == DownloadStatus.downloading || 
          d.status == DownloadStatus.paused
        ).toList();
      case 'completed':
        return _downloads.where((d) => d.status == DownloadStatus.completed).toList();
      case 'failed':
        return _downloads.where((d) => d.status == DownloadStatus.failed).toList();
      default:
        return _downloads;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isMobile = Responsive.isMobile(context);
    final stats = DownloadManagerService.getDownloadStatistics();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloads),
        elevation: 0,
        actions: [
          if (!isMobile) ...[
            IconButton(
              onPressed: _pauseAllDownloads,
              icon: const Icon(Icons.pause),
              tooltip: 'Pause All',
            ),
            IconButton(
              onPressed: _resumeAllDownloads,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Resume All',
            ),
            IconButton(
              onPressed: _clearCompleted,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear Completed',
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'pause_all':
                  _pauseAllDownloads();
                  break;
                case 'resume_all':
                  _resumeAllDownloads();
                  break;
                case 'clear_completed':
                  _clearCompleted();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pause_all',
                child: ListTile(
                  leading: Icon(Icons.pause),
                  title: Text('Pause All'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'resume_all',
                child: ListTile(
                  leading: Icon(Icons.play_arrow),
                  title: Text('Resume All'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_completed',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Clear Completed'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, l10n, stats),
        tablet: _buildTabletLayout(context, l10n, stats),
        desktop: _buildDesktopLayout(context, l10n, stats),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppLocalizations l10n, Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildFilterChips(context, isMobile: true),
        _buildStatsBar(context, stats, isMobile: true),
        Expanded(
          child: _filteredDownloads.isEmpty
              ? _buildEmptyState(context, l10n, isMobile: true)
              : _buildDownloadsList(context, isMobile: true),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, AppLocalizations l10n, Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildFilterChips(context),
        _buildStatsBar(context, stats),
        Expanded(
          child: _filteredDownloads.isEmpty
              ? _buildEmptyState(context, l10n)
              : _buildDownloadsList(context),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppLocalizations l10n, Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildFilterChips(context),
        _buildStatsBar(context, stats),
        Expanded(
          child: AdaptiveContainer(
            maxWidth: 1200,
            child: _filteredDownloads.isEmpty
                ? _buildEmptyState(context, l10n)
                : _buildDownloadsList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              selected: _filter == 'all',
              onSelected: () => setState(() => _filter = 'all'),
              isCompact: isMobile,
            ),
            SizedBox(width: AppTheme.spaceSm),
            _FilterChip(
              label: 'Active',
              selected: _filter == 'active',
              onSelected: () => setState(() => _filter = 'active'),
              isCompact: isMobile,
            ),
            SizedBox(width: AppTheme.spaceSm),
            _FilterChip(
              label: 'Completed',
              selected: _filter == 'completed',
              onSelected: () => setState(() => _filter = 'completed'),
              isCompact: isMobile,
            ),
            SizedBox(width: AppTheme.spaceSm),
            _FilterChip(
              label: 'Failed',
              selected: _filter == 'failed',
              onSelected: () => setState(() => _filter = 'failed'),
              isCompact: isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, Map<String, dynamic> stats, {bool isMobile = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
      padding: EdgeInsets.all(isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Total', '${stats['total']}', isMobile: isMobile),
          _buildStatItem(context, 'Active', '${stats['downloading']}', isMobile: isMobile),
          _buildStatItem(context, 'Completed', '${stats['completed']}', isMobile: isMobile),
          _buildStatItem(context, 'Failed', '${stats['failed']}', isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, {bool isMobile = false}) {
    return Column(
      children: [
        Text(
          value,
          style: (isMobile 
              ? Theme.of(context).textTheme.titleMedium 
              : Theme.of(context).textTheme.titleLarge)?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: (isMobile 
              ? Theme.of(context).textTheme.bodySmall 
              : Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildDownloadsList(BuildContext context, {bool isMobile = false}) {
    return ListView.builder(
      padding: Responsive.getPadding(context),
      itemCount: _filteredDownloads.length,
      itemBuilder: (context, index) {
        final download = _filteredDownloads[index];
        return _DownloadCard(
          download: download,
          onPause: () => DownloadManagerService.pauseDownload(download.id),
          onResume: () => DownloadManagerService.resumeDownload(download.id),
          onCancel: () => DownloadManagerService.cancelDownload(download.id),
          onRetry: () => DownloadManagerService.retryDownload(download.id),
          onOpen: () => _openDownload(download),
          onShowInFolder: () => _showInFolder(download),
          onDelete: () => DownloadManagerService.removeDownload(download.id, deleteFile: true),
          isCompact: isMobile,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, {bool isMobile = false}) {
    return Center(
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download,
              size: isMobile ? 48 : 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppTheme.spaceMd),
            Text(
              l10n.noDownloads,
              style: (isMobile 
                  ? Theme.of(context).textTheme.titleLarge 
                  : Theme.of(context).textTheme.headlineSmall)?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              'Your downloads will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDownload(DownloadItem download) async {
    if (download.status == DownloadStatus.completed) {
      try {
        // TODO: Implement file opening with open_file package
        // await OpenFile.open(download.savePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File opening feature coming soon')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open file: $e')),
          );
        }
      }
    }
  }

  Future<void> _showInFolder(DownloadItem download) async {
    if (download.status == DownloadStatus.completed) {
      try {
        // TODO: Implement show in folder with open_file package
        // final file = File(download.savePath);
        // final directory = file.parent;
        // await OpenFile.open(directory.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Show in folder feature coming soon')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to show in folder: $e')),
          );
        }
      }
    }
  }

  Future<void> _pauseAllDownloads() async {
    await DownloadManagerService.pauseAllDownloads();
  }

  Future<void> _resumeAllDownloads() async {
    await DownloadManagerService.resumeAllDownloads();
  }

  Future<void> _clearCompleted() async {
    await DownloadManagerService.clearCompletedDownloads();
  }

  @override
  void dispose() {
    _downloadsSubscription?.cancel();
    super.dispose();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool isCompact;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(fontSize: isCompact ? 12 : 14),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadItem download;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onOpen;
  final VoidCallback onShowInFolder;
  final VoidCallback onDelete;
  final bool isCompact;

  const _DownloadCard({
    required this.download,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
    required this.onOpen,
    required this.onShowInFolder,
    required this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppTheme.spaceSm : AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  size: isCompact ? 20 : 24,
                  color: _getStatusColor(),
                ),
                SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.filename,
                        style: (isCompact 
                            ? Theme.of(context).textTheme.bodyMedium 
                            : Theme.of(context).textTheme.titleSmall)?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isCompact) ...[
                        SizedBox(height: AppTheme.spaceXs),
                        Text(
                          download.url,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'open':
                        onOpen();
                        break;
                      case 'show_in_folder':
                        onShowInFolder();
                        break;
                      case 'pause':
                        onPause();
                        break;
                      case 'resume':
                        onResume();
                        break;
                      case 'retry':
                        onRetry();
                        break;
                      case 'cancel':
                        onCancel();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[];
                    
                    if (download.status == DownloadStatus.completed) {
                      items.addAll([
                        const PopupMenuItem(
                          value: 'open',
                          child: ListTile(
                            leading: Icon(Icons.open_in_new),
                            title: Text('Open'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'show_in_folder',
                          child: ListTile(
                            leading: Icon(Icons.folder),
                            title: Text('Show in Folder'),
                            dense: true,
                          ),
                        ),
                      ]);
                    }
                    
                    if (download.status == DownloadStatus.downloading) {
                      items.add(const PopupMenuItem(
                        value: 'pause',
                        child: ListTile(
                          leading: Icon(Icons.pause),
                          title: Text('Pause'),
                          dense: true,
                        ),
                      ));
                    }
                    
                    if (download.status == DownloadStatus.paused) {
                      items.add(const PopupMenuItem(
                        value: 'resume',
                        child: ListTile(
                          leading: Icon(Icons.play_arrow),
                          title: Text('Resume'),
                          dense: true,
                        ),
                      ));
                    }
                    
                    if (download.status == DownloadStatus.failed) {
                      items.add(const PopupMenuItem(
                        value: 'retry',
                        child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Retry'),
                          dense: true,
                        ),
                      ));
                    }
                    
                    if (download.status == DownloadStatus.downloading || 
                        download.status == DownloadStatus.paused) {
                      items.add(const PopupMenuItem(
                        value: 'cancel',
                        child: ListTile(
                          leading: Icon(Icons.cancel),
                          title: Text('Cancel'),
                          dense: true,
                        ),
                      ));
                    }
                    
                    items.add(const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete'),
                        dense: true,
                      ),
                    ));
                    
                    return items;
                  },
                ),
              ],
            ),
            
            if (download.status == DownloadStatus.downloading || 
                download.status == DownloadStatus.paused) ...[
              SizedBox(height: AppTheme.spaceSm),
              LinearProgressIndicator(
                value: download.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              SizedBox(height: AppTheme.spaceXs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(download.progress * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${_formatBytes(download.downloadedBytes)} / ${_formatBytes(download.totalBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (download.status == DownloadStatus.downloading)
                    Text(
                      '${_formatSpeed(download.speed)}/s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
            
            if (download.error != null) ...[
              SizedBox(height: AppTheme.spaceSm),
              Container(
                padding: EdgeInsets.all(AppTheme.spaceSm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      size: 16,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: Text(
                        download.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (download.status) {
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.downloading:
        return Icons.download;
      case DownloadStatus.paused:
        return Icons.pause_circle;
      case DownloadStatus.failed:
        return Icons.error;
      case DownloadStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  Color _getStatusColor() {
    switch (download.status) {
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatSpeed(double bytesPerSecond) {
    return _formatBytes(bytesPerSecond.toInt());
  }
}

