import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
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
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // History List
          Expanded(
            child: groupedHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: groupedHistory.length,
                    itemBuilder: (context, index) {
                      final group = groupedHistory.keys.elementAt(index);
                      final items = groupedHistory[group]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              group,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          
                          // Group Items
                          ...items.map((item) => _HistoryItem(
                            item: item,
                            onTap: () => _openHistoryItem(item),
                            onDelete: () => _deleteHistoryItem(item),
                            onBookmark: () => _bookmarkHistoryItem(item),
                          )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No matching history' : 'No browsing history',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Your browsing history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openHistoryItem(Map<String, dynamic> item) {
    // Navigate back to browser with the history URL
    Navigator.of(context).pop();
    // This would need to be implemented to navigate to the URL
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

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onBookmark;

  const _HistoryItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.parse(item['timestamp']);
    final timeString = DateFormat('HH:mm').format(timestamp);
    
    return ListTile(
      leading: const Icon(Icons.public),
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
          const SizedBox(height: 2),
          Text(
            timeString,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
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
            child: Row(
              children: [
                Icon(Icons.bookmark_add),
                SizedBox(width: 8),
                Text('Bookmark'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}