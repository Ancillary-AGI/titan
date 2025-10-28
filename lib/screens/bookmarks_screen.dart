import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  List<Map<String, dynamic>> _bookmarks = [];
  String _selectedFolder = 'all';
  final Set<String> _folders = {'all', 'default'};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    final bookmarks = StorageService.getBookmarks();
    setState(() {
      _bookmarks = bookmarks;
      _folders.addAll(bookmarks.map((b) => b['folder'] as String));
    });
  }

  List<Map<String, dynamic>> get _filteredBookmarks {
    if (_selectedFolder == 'all') {
      return _bookmarks;
    }
    return _bookmarks.where((b) => b['folder'] == _selectedFolder).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (folder) {
              setState(() => _selectedFolder = folder);
            },
            itemBuilder: (context) => _folders.map((folder) {
              return PopupMenuItem(
                value: folder,
                child: Row(
                  children: [
                    Icon(
                      folder == 'all' ? Icons.all_inclusive : Icons.folder,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(folder == 'all' ? 'All Bookmarks' : folder),
                    if (folder == _selectedFolder)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 16),
                      ),
                  ],
                ),
              );
            }).toList(),
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _filteredBookmarks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredBookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = _filteredBookmarks[index];
                return _BookmarkCard(
                  bookmark: bookmark,
                  onTap: () => _openBookmark(bookmark),
                  onEdit: () => _editBookmark(bookmark),
                  onDelete: () => _deleteBookmark(bookmark),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBookmark,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Bookmark your favorite pages to access them quickly',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openBookmark(Map<String, dynamic> bookmark) {
    // Navigate back to browser with the bookmark URL
    Navigator.of(context).pop();
    // This would need to be implemented to navigate to the URL
  }

  void _editBookmark(Map<String, dynamic> bookmark) {
    showDialog(
      context: context,
      builder: (context) => _BookmarkDialog(
        bookmark: bookmark,
        onSave: (title, url, folder) {
          StorageService.removeBookmark(bookmark['url']);
          StorageService.addBookmark(url, title, folder: folder);
          _loadBookmarks();
        },
      ),
    );
  }

  void _deleteBookmark(Map<String, dynamic> bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: Text('Are you sure you want to delete "${bookmark['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              StorageService.removeBookmark(bookmark['url']);
              _loadBookmarks();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addBookmark() {
    showDialog(
      context: context,
      builder: (context) => _BookmarkDialog(
        onSave: (title, url, folder) {
          StorageService.addBookmark(url, title, folder: folder);
          _loadBookmarks();
        },
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Map<String, dynamic> bookmark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.bookmark),
        title: Text(
          bookmark['title'],
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookmark['url'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  bookmark['folder'],
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
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
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
      ),
    );
  }
}

class _BookmarkDialog extends StatefulWidget {
  final Map<String, dynamic>? bookmark;
  final Function(String title, String url, String folder) onSave;

  const _BookmarkDialog({
    this.bookmark,
    required this.onSave,
  });

  @override
  State<_BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<_BookmarkDialog> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _folderController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookmark?['title'] ?? '');
    _urlController = TextEditingController(text: widget.bookmark?['url'] ?? '');
    _folderController = TextEditingController(text: widget.bookmark?['folder'] ?? 'default');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.bookmark == null ? 'Add Bookmark' : 'Edit Bookmark'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _folderController,
            decoration: const InputDecoration(
              labelText: 'Folder',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _urlController.text.isNotEmpty) {
              widget.onSave(
                _titleController.text,
                _urlController.text,
                _folderController.text.isEmpty ? 'default' : _folderController.text,
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _folderController.dispose();
    super.dispose();
  }
}