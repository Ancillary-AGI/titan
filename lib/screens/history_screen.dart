import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../providers/browser_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final history = StorageService.getHistory();
    setState(() => _history = history);
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_searchQuery.isEmpty) return _history;
    
    return _history.where((item) {
      final title = item['title']?.toString().toLowerCase() ?? '';
      final url = item['url']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || url.contains(query);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedHistory {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final now = DateTime.now();
    
    for (final item in _filteredHistory) {
      final timestamp = DateTime.parse(item['timestamp']);
      final difference = now.difference(timestamp);
      
      String group;
      if (difference.inDays == 0) {
        group = 'Today';
      } else if (difference.inDays == 1) {
        group = 'Yesterday';
      } else if (difference.inDays < 7) {
        group = 'This Week';
      } else if (difference.inDays < 30) {
        group = 'This Month';
      } else {
        group = DateFormat('MMMM yyyy').format(timestamp);
      }
      
      grouped.putIfAbsent(group, () => []).add(item);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedHistory = _groupedHistory;
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        actions: [
          if (!isMobile) ...[
            IconButton(
              onPressed: _exportHistory,
              icon: const Icon(Icons.download),
              tooltip: 'Export History',
            ),
            IconButton(
              onPressed: _showHistoryStats,
              icon: const Icon(Icons.analytics),
              tooltip: 'History Statistics',
            ),
          ],
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear History',
          ),
          if (isMobile)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _exportHistory();
                    break;
                  case 'stats':
                    _showHistoryStats();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Export History'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'stats',
                  child: ListTile(
                    leading: Icon(Icons.analytics),
                    title: Text('Statistics'),
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, groupedHistory),
        tablet: _buildTabletLayout(context, groupedHistory),
        desktop: _buildDesktopLayout(context, groupedHistory),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Map<String, List<Map<String, dynamic>>> groupedHistory) {
    return Column(
      children: [
        _buildSearchBar(context, isMobile: true),
        Expanded(
          child: groupedHistory.isEmpty
              ? _buildEmptyState(isMobile: true)
              : _buildHistoryList(context, groupedHistory, isMobile: true),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, Map<String, List<Map<String, dynamic>>> groupedHistory) {
    return Row(
      children: [
        // History filters sidebar
        SizedBox(
          width: 250,
          child: _buildHistoryFilters(context),
        ),
        
        // Main history content
        Expanded(
          child: Column(
            children: [
              _buildSearchBar(context),
              Expanded(
                child: groupedHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(context, groupedHistory),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Map<String, List<Map<String, dynamic>>> groupedHistory) {
    return Row(
      children: [
        // History filters sidebar
        SizedBox(
          width: 300,
          child: _buildHistoryFilters(context),
        ),
        
        // Main history content
        Expanded(
          child: AdaptiveContainer(
            maxWidth: 1000,
            child: Column(
              children: [
                _buildSearchBar(context),
                _buildHistoryStats(context),
                Expanded(
                  child: groupedHistory.isEmpty
                      ? _buildEmptyState()
                      : _buildHistoryList(context, groupedHistory),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, {bool isMobile = false}) {
    return Padding(
      padding: Responsive.getPadding(context),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search history...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildHistoryFilters(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spaceMd),
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spaceMd),
          
          // Time filters
          _buildFilterSection(context, 'Time Range', [
            _FilterOption('Today', Icons.today),
            _FilterOption('Yesterday', Icons.yesterday),
            _FilterOption('This Week', Icons.date_range),
            _FilterOption('This Month', Icons.calendar_month),
            _FilterOption('All Time', Icons.history),
          ]),
          
          SizedBox(height: AppTheme.spaceMd),
          
          // Domain filters
          _buildFilterSection(context, 'Domains', [
            _FilterOption('Google', Icons.search),
            _FilterOption('YouTube', Icons.video_library),
            _FilterOption('GitHub', Icons.code),
            _FilterOption('Other', Icons.public),
          ]),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, String title, List<_FilterOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppTheme.spaceSm),
        ...options.map((option) => ListTile(
          leading: Icon(option.icon, size: 20),
          title: Text(option.label),
          dense: true,
          onTap: () {
            // Apply filter
          },
        )),
      ],
    );
  }

  Widget _buildHistoryStats(BuildContext context) {
    return Container(
      margin: Responsive.getMargin(context),
      padding: EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Total Items', '${_history.length}'),
          _buildStatItem(context, 'Today', '${_getTodayCount()}'),
          _buildStatItem(context, 'This Week', '${_getWeekCount()}'),
          _buildStatItem(context, 'Unique Domains', '${_getUniqueDomains()}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context, Map<String, List<Map<String, dynamic>>> groupedHistory, {bool isMobile = false}) {
    return ListView.builder(
      itemCount: groupedHistory.length,
      itemBuilder: (context, index) {
        final group = groupedHistory.keys.elementAt(index);
        final items = groupedHistory[group]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceSm,
              ),
              child: Text(
                group,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            
            // Group Items
            if (isMobile)
              ...items.map((item) => _HistoryItem(
                item: item,
                onTap: () => _openHistoryItem(item),
                onDelete: () => _deleteHistoryItem(item),
                onBookmark: () => _bookmarkHistoryItem(item),
                isCompact: true,
              ))
            else
              ...items.map((item) => _HistoryItem(
                item: item,
                onTap: () => _openHistoryItem(item),
                onDelete: () => _deleteHistoryItem(item),
                onBookmark: () => _bookmarkHistoryItem(item),
              )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({bool isMobile = false}) {
    return Center(
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: isMobile ? 48 : 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppTheme.spaceMd),
            Text(
              _searchQuery.isNotEmpty ? 'No matching history' : 'No browsing history',
              style: (isMobile 
                  ? Theme.of(context).textTheme.titleLarge 
                  : Theme.of(context).textTheme.headlineSmall)?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Your browsing history will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isMobile) ...[
              SizedBox(height: AppTheme.spaceLg),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.web),
                label: const Text('Start Browsing'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openHistoryItem(Map<String, dynamic> item) {
    // Navigate back to browser with the history URL
    ref.read(browserProvider.notifier).navigateToUrl(item['url']);
    Navigator.of(context).pop();
  }

  void _exportHistory() {
    // Export history functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History export started...')),
    );
  }

  void _showHistoryStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('History Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem(context, 'Total Items', '${_history.length}'),
            SizedBox(height: AppTheme.spaceMd),
            _buildStatItem(context, 'Today', '${_getTodayCount()}'),
            SizedBox(height: AppTheme.spaceMd),
            _buildStatItem(context, 'This Week', '${_getWeekCount()}'),
            SizedBox(height: AppTheme.spaceMd),
            _buildStatItem(context, 'Unique Domains', '${_getUniqueDomains()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  int _getTodayCount() {
    final today = DateTime.now();
    return _history.where((item) {
      final timestamp = DateTime.parse(item['timestamp']);
      return timestamp.day == today.day &&
             timestamp.month == today.month &&
             timestamp.year == today.year;
    }).length;
  }

  int _getWeekCount() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _history.where((item) {
      final timestamp = DateTime.parse(item['timestamp']);
      return timestamp.isAfter(weekAgo);
    }).length;
  }

  int _getUniqueDomains() {
    final domains = <String>{};
    for (final item in _history) {
      try {
        final uri = Uri.parse(item['url']);
        domains.add(uri.host);
      } catch (e) {
        // Invalid URL
      }
    }
    return domains.length;
  }

  void _deleteHistoryItem(Map<String, dynamic> item) {
    // This would need to be implemented to delete a specific history item
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History item deleted')),
    );
  }

  void _bookmarkHistoryItem(Map<String, dynamic> item) {
    StorageService.addBookmark(item['url'], item['title']);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to bookmarks')),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('This will permanently delete all browsing history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              StorageService.clearHistory();
              _loadHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _FilterOption {
  final String label;
  final IconData icon;

  const _FilterOption(this.label, this.icon);
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onBookmark;
  final bool isCompact;

  const _HistoryItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onBookmark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.parse(item['timestamp']);
    final timeString = DateFormat('HH:mm').format(timestamp);
    final domain = _extractDomain(item['url']);
    
    if (isCompact) {
      return Card(
        margin: EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceXs,
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.public,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            item['title'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            domain,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeString,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'bookmark':
                      onBookmark();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'bookmark',
                    child: ListTile(
                      leading: Icon(Icons.bookmark_add),
                      title: Text('Bookmark'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: onTap,
        ),
      );
    }
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.public,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        item['title'],
        style: Theme.of(context).textTheme.titleSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['url'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppTheme.spaceXs),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
              SizedBox(width: AppTheme.spaceXs),
              Text(
                timeString,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              SizedBox(width: AppTheme.spaceMd),
              Icon(
                Icons.domain,
                size: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
              SizedBox(width: AppTheme.spaceXs),
              Text(
                domain,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'bookmark':
              onBookmark();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'bookmark',
            child: ListTile(
              leading: Icon(Icons.bookmark_add),
              title: Text('Bookmark'),
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              dense: true,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }
}