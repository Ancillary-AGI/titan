import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bookmark_manager_service.dart';
import '../providers/browser_provider.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../core/localization/app_localizations.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  List<Bookmark> _bookmarks = [];
  List<BookmarkFolder> _folders = [];
  String? _selectedFolderId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<Bookmark>>? _bookmarksSubscription;
  StreamSubscription<List<BookmarkFolder>>? _foldersSubscription;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _subscribeToChanges();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarks = BookmarkManagerService.bookmarks;
      _folders = BookmarkManagerService.folders;
    });
  }

  void _subscribeToChanges() {
    _bookmarksSubscription = BookmarkManagerService.bookmarksStream.listen((bookmarks) {
      if (mounted) {
        setState(() => _bookmarks = bookmarks);
      }
    });

    _foldersSubscription = BookmarkManagerService.foldersStream.listen((folders) {
      if (mounted) {
        setState(() => _folders = folders);
      }
    });
  }

  List<Bookmark> get _filteredBookmarks {
    var filtered = _bookmarks;

    // Filter by folder
    if (_selectedFolderId != null) {
      filtered = filtered.where((b) => b.folderId == _selectedFolderId).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((bookmark) {
        return bookmark.title.toLowerCase().contains(query) ||
               bookmark.url.toLowerCase().contains(query) ||
               (bookmark.description?.toLowerCase().contains(query) ?? false) ||
               bookmark.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookmarks),
        elevation: 0,
        actions: [
          if (!isMobile) ...[
            IconButton(
              onPressed: _showImportDialog,
              icon: const Icon(Icons.upload),
              tooltip: 'Import Bookmarks',
            ),
            IconButton(
              onPressed: _showExportDialog,
              icon: const Icon(Icons.download),
              tooltip: 'Export Bookmarks',
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _showImportDialog();
                  break;
                case 'export':
                  _showExportDialog();
                  break;
                case 'create_folder':
                  _showCreateFolderDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_folder',
                child: ListTile(
                  leading: Icon(Icons.create_new_folder),
                  title: Text('Create Folder'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Import Bookmarks'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Bookmarks'),
                  dense: true,
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, l10n),
        tablet: _buildTabletLayout(context, l10n),
        desktop: _buildDesktopLayout(context, l10n),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookmarkDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildSearchBar(context, isMobile: true),
        Expanded(
          child: _filteredBookmarks.isEmpty
              ? _buildEmptyState(context, l10n, isMobile: true)
              : _buildBookmarksList(context, isMobile: true),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: _buildFoldersSidebar(context),
        ),
        Expanded(
          child: Column(
            children: [
              _buildSearchBar(context),
              Expanded(
                child: _filteredBookmarks.isEmpty
                    ? _buildEmptyState(context, l10n)
                    : _buildBookmarksList(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: _buildFoldersSidebar(context),
        ),
        Expanded(
          child: AdaptiveContainer(
            maxWidth: 1000,
            child: Column(
              children: [
                _buildSearchBar(context),
                _buildBookmarkStats(context),
                Expanded(
                  child: _filteredBookmarks.isEmpty
                      ? _buildEmptyState(context, l10n)
                      : _buildBookmarksList(context),
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
          hintText: 'Search bookmarks...',
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

  Widget _buildFoldersSidebar(BuildContext context) {
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
            'Folders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spaceMd),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('All Bookmarks'),
            selected: _selectedFolderId == null,
            onTap: () => setState(() => _selectedFolderId = null),
          ),
          const Divider(),
          ..._folders.map((folder) => ListTile(
            leading: Icon(folder.icon, color: folder.color),
            title: Text(folder.name),
            selected: _selectedFolderId == folder.id,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditFolderDialog(folder);
                    break;
                  case 'delete':
                    _showDeleteFolderDialog(folder);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
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
            onTap: () => setState(() => _selectedFolderId = folder.id),
          )),
        ],
      ),
    );
  }

  Widget _buildBookmarkStats(BuildContext context) {
    final stats = BookmarkManagerService.getBookmarkStatistics();
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
          _buildStatItem(context, 'Total', '${stats['totalBookmarks']}'),
          _buildStatItem(context, 'Folders', '${stats['totalFolders']}'),
          _buildStatItem(context, 'This Week', '${stats['bookmarksAddedThisWeek']}'),
          _buildStatItem(context, 'Total Visits', '${stats['totalVisits']}'),
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

  Widget _buildBookmarksList(BuildContext context, {bool isMobile = false}) {
    return ListView.builder(
      padding: Responsive.getPadding(context),
      itemCount: _filteredBookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = _filteredBookmarks[index];
        return _BookmarkCard(
          bookmark: bookmark,
          onTap: () => _openBookmark(bookmark),
          onEdit: () => _showEditBookmarkDialog(bookmark),
          onDelete: () => _showDeleteBookmarkDialog(bookmark),
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
              Icons.bookmark_border,
              size: isMobile ? 48 : 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppTheme.spaceMd),
            Text(
              _searchQuery.isNotEmpty ? 'No matching bookmarks' : l10n.noBookmarks,
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
                  : 'Bookmark your favorite pages to access them quickly',
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

  void _openBookmark(Bookmark bookmark) {
    BookmarkManagerService.accessBookmark(bookmark.id);
    ref.read(browserProvider.notifier).navigateToUrl(bookmark.url);
    Navigator.of(context).pop();
  }

  void _showAddBookmarkDialog() {
    showDialog(
      context: context,
      builder: (context) => _BookmarkDialog(
        onSave: (title, url, folderId) async {
          await BookmarkManagerService.addBookmark(
            title: title,
            url: url,
            folderId: folderId,
          );
        },
        folders: _folders,
      ),
    );
  }

  void _showEditBookmarkDialog(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => _BookmarkDialog(
        bookmark: bookmark,
        onSave: (title, url, folderId) async {
          await BookmarkManagerService.updateBookmark(
            bookmark.id,
            title: title,
            url: url,
            folderId: folderId,
          );
        },
        folders: _folders,
      ),
    );
  }

  void _showDeleteBookmarkDialog(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: Text('Are you sure you want to delete "${bookmark.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              BookmarkManagerService.removeBookmark(bookmark.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => _FolderDialog(
        onSave: (name, description) async {
          await BookmarkManagerService.createFolder(
            name: name,
            description: description,
          );
        },
      ),
    );
  }

  void _showEditFolderDialog(BookmarkFolder folder) {
    showDialog(
      context: context,
      builder: (context) => _FolderDialog(
        folder: folder,
        onSave: (name, description) async {
          await BookmarkManagerService.updateFolder(
            folder.id,
            name: name,
            description: description,
          );
        },
      ),
    );
  }

  void _showDeleteFolderDialog(BookmarkFolder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}"? All bookmarks in this folder will be moved to the parent folder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              BookmarkManagerService.removeFolder(folder.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    // TODO: Implement bookmark import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark import coming soon')),
    );
  }

  void _showExportDialog() async {
    try {
      final html = await BookmarkManagerService.exportToHtml();
      // TODO: Save to file or share
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmarks exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bookmarksSubscription?.cancel();
    _foldersSubscription?.cancel();
    super.dispose();
  }
}

class _BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isCompact;

  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
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
              Icons.bookmark,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            bookmark.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookmark.url,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (bookmark.tags.isNotEmpty) ...[
                SizedBox(height: AppTheme.spaceXs),
                Wrap(
                  spacing: AppTheme.spaceXs,
                  children: bookmark.tags.take(3).map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],
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
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
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
        ),
      );
    }

    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.bookmark,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          bookmark.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookmark.url,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (bookmark.description != null) ...[
              SizedBox(height: AppTheme.spaceXs),
              Text(
                bookmark.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (bookmark.tags.isNotEmpty) ...[
              SizedBox(height: AppTheme.spaceXs),
              Wrap(
                spacing: AppTheme.spaceXs,
                children: bookmark.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
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
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
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
      ),
    );
  }
}

class _BookmarkDialog extends StatefulWidget {
  final Bookmark? bookmark;
  final Function(String title, String url, String? folderId) onSave;
  final List<BookmarkFolder> folders;

  const _BookmarkDialog({
    this.bookmark,
    required this.onSave,
    required this.folders,
  });

  @override
  State<_BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<_BookmarkDialog> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookmark?.title ?? '');
    _urlController = TextEditingController(text: widget.bookmark?.url ?? '');
    _descriptionController = TextEditingController(text: widget.bookmark?.description ?? '');
    _selectedFolderId = widget.bookmark?.folderId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.bookmark == null ? 'Add Bookmark' : 'Edit Bookmark'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: AppTheme.spaceMd),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: AppTheme.spaceMd),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: AppTheme.spaceMd),
            DropdownButtonFormField<String>(
              value: _selectedFolderId,
              decoration: const InputDecoration(
                labelText: 'Folder',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None'),
                ),
                ...widget.folders.map((folder) => DropdownMenuItem(
                  value: folder.id,
                  child: Text(folder.name),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedFolderId = value);
              },
            ),
          ],
        ),
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
                _selectedFolderId,
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
    _descriptionController.dispose();
    super.dispose();
  }
}

class _FolderDialog extends StatefulWidget {
  final BookmarkFolder? folder;
  final Function(String name, String? description) onSave;

  const _FolderDialog({
    this.folder,
    required this.onSave,
  });

  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder?.name ?? '');
    _descriptionController = TextEditingController(text: widget.folder?.description ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.folder == null ? 'Create Folder' : 'Edit Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: AppTheme.spaceMd),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
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
            if (_nameController.text.isNotEmpty) {
              widget.onSave(
                _nameController.text,
                _descriptionController.text.isEmpty ? null : _descriptionController.text,
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
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
