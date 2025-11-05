import 'package:flutter/material.dart';
import '../models/extension.dart';
import '../services/extension_marketplace_service.dart';

class ExtensionDetailsDialog extends StatefulWidget {
  final dynamic extension; // Can be Extension or MarketplaceExtension
  final VoidCallback? onInstall;
  final VoidCallback? onToggle;
  final VoidCallback? onUninstall;

  const ExtensionDetailsDialog({
    super.key,
    required this.extension,
    this.onInstall,
    this.onToggle,
    this.onUninstall,
  });

  @override
  State<ExtensionDetailsDialog> createState() => _ExtensionDetailsDialogState();
}

class _ExtensionDetailsDialogState extends State<ExtensionDetailsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<ExtensionReview> _reviews = [];
  bool _loadingReviews = false;

  bool get isInstalled => widget.extension is Extension;
  bool get isEnabled => isInstalled && (widget.extension as Extension).isEnabled;
  ExtensionManifest get manifest => isInstalled 
      ? (widget.extension as Extension).manifest 
      : (widget.extension as MarketplaceExtension).manifest;
  SecurityRating get securityRating => isInstalled
      ? (widget.extension as Extension).securityRating
      : (widget.extension as MarketplaceExtension).securityRating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: isInstalled ? 3 : 4, vsync: this);
    if (!isInstalled) {
      _loadReviews();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    if (isInstalled) return;
    
    setState(() => _loadingReviews = true);
    
    try {
      final reviews = await ExtensionMarketplaceService.getExtensionReviews(
        (widget.extension as MarketplaceExtension).id,
      );
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;
      });
    } catch (e) {
      setState(() => _loadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildPermissionsTab(),
                  if (!isInstalled) _buildReviewsTab(),
                  _buildDetailsTab(),
                ],
              ),
            ),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manifest.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v${manifest.version}${manifest.author != null ? ' by ${manifest.author}' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSecurityBadge(),
                        const SizedBox(width: 8),
                        _buildTypeChip(),
                        if (!isInstalled) ...[
                          const SizedBox(width: 8),
                          _buildRatingChip(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              const Tab(text: 'Overview'),
              const Tab(text: 'Permissions'),
              if (!isInstalled) const Tab(text: 'Reviews'),
              const Tab(text: 'Details'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final iconUrl = isInstalled 
        ? (widget.extension as Extension).getIcon(64)
        : (widget.extension as MarketplaceExtension).iconUrl;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: iconUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                iconUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      Icons.extension,
      size: 32,
      color: Colors.grey[600],
    );
  }

  Widget _buildSecurityBadge() {
    Color color;
    IconData icon;
    String label;
    
    switch (securityRating) {
      case SecurityRating.safe:
        color = Colors.green;
        icon = Icons.verified;
        label = 'Safe';
        break;
      case SecurityRating.trusted:
        color = Colors.blue;
        icon = Icons.shield;
        label = 'Trusted';
        break;
      case SecurityRating.reviewed:
        color = Colors.orange;
        icon = Icons.check_circle;
        label = 'Reviewed';
        break;
      case SecurityRating.unverified:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Unverified';
        break;
      case SecurityRating.warning:
        color = Colors.orange;
        icon = Icons.warning;
        label = 'Warning';
        break;
      case SecurityRating.dangerous:
        color = Colors.red;
        icon = Icons.dangerous;
        label = 'Dangerous';
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildTypeChip() {
    return Chip(
      label: Text(
        manifest.type.name,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue[50],
      labelStyle: TextStyle(color: Colors.blue[700]),
    );
  }

  Widget _buildRatingChip() {
    if (!isInstalled) {
      final marketplaceExt = widget.extension as MarketplaceExtension;
      if (marketplaceExt.rating > 0) {
        return Chip(
          avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
          label: Text(
            '${marketplaceExt.rating.toStringAsFixed(1)} (${marketplaceExt.reviewCount})',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.amber[50],
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            manifest.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (!isInstalled && (widget.extension as MarketplaceExtension).screenshots.isNotEmpty) ...[
            Text(
              'Screenshots',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (widget.extension as MarketplaceExtension).screenshots.length,
                itemBuilder: (context, index) {
                  final screenshot = (widget.extension as MarketplaceExtension).screenshots[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        screenshot,
                        width: 300,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (manifest.homepage != null) ...[
            Text(
              'Homepage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // Open homepage URL
              },
              child: Text(
                manifest.homepage!,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (isInstalled) ...[
            Text(
              'Installation Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Installed', _formatDate((widget.extension as Extension).installedAt)),
            if ((widget.extension as Extension).lastUpdated != null)
              _buildInfoRow('Last Updated', _formatDate((widget.extension as Extension).lastUpdated!)),
            _buildInfoRow('Status', (widget.extension as Extension).status.name),
            if ((widget.extension as Extension).errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Errors',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...(widget.extension as Extension).errors.map((error) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    error,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ),
            ],
          ] else ...[
            Text(
              'Marketplace Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Downloads', _formatDownloadCount((widget.extension as MarketplaceExtension).downloadCount)),
            _buildInfoRow('Published', _formatDate((widget.extension as MarketplaceExtension).publishedAt)),
            _buildInfoRow('Last Updated', _formatDate((widget.extension as MarketplaceExtension).lastUpdated)),
            _buildInfoRow('Category', (widget.extension as MarketplaceExtension).category),
            if ((widget.extension as MarketplaceExtension).isPremium) ...[
              _buildInfoRow('Price', '\$${(widget.extension as MarketplaceExtension).price?.toStringAsFixed(2) ?? '0.00'}'),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Permissions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (manifest.permissions.isEmpty)
            const Text('This extension does not require any special permissions.')
          else
            ...manifest.permissions.map((permission) => _buildPermissionItem(permission)),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(ExtensionPermission permission) {
    IconData icon;
    String title;
    String description;
    Color color;

    switch (permission) {
      case ExtensionPermission.activeTab:
        icon = Icons.tab;
        title = 'Active Tab';
        description = 'Access information about the currently active tab';
        color = Colors.blue;
        break;
      case ExtensionPermission.tabs:
        icon = Icons.tab;
        title = 'All Tabs';
        description = 'Access information about all open tabs';
        color = Colors.orange;
        break;
      case ExtensionPermission.allUrls:
        icon = Icons.public;
        title = 'All Websites';
        description = 'Access data on all websites you visit';
        color = Colors.red;
        break;
      case ExtensionPermission.storage:
        icon = Icons.storage;
        title = 'Local Storage';
        description = 'Store and retrieve data locally';
        color = Colors.green;
        break;
      case ExtensionPermission.notifications:
        icon = Icons.notifications;
        title = 'Notifications';
        description = 'Display notifications';
        color = Colors.blue;
        break;
      case ExtensionPermission.contextMenus:
        icon = Icons.menu;
        title = 'Context Menus';
        description = 'Add items to context menus';
        color = Colors.purple;
        break;
      case ExtensionPermission.webRequest:
        icon = Icons.network_check;
        title = 'Web Requests';
        description = 'Monitor and modify network requests';
        color = Colors.orange;
        break;
      case ExtensionPermission.webRequestBlocking:
        icon = Icons.block;
        title = 'Block Web Requests';
        description = 'Block or modify network requests';
        color = Colors.red;
        break;
      case ExtensionPermission.cookies:
        icon = Icons.cookie;
        title = 'Cookies';
        description = 'Access and modify cookies';
        color = Colors.brown;
        break;
      case ExtensionPermission.history:
        icon = Icons.history;
        title = 'Browsing History';
        description = 'Access your browsing history';
        color = Colors.orange;
        break;
      case ExtensionPermission.bookmarks:
        icon = Icons.bookmark;
        title = 'Bookmarks';
        description = 'Access and modify bookmarks';
        color = Colors.blue;
        break;
      case ExtensionPermission.downloads:
        icon = Icons.download;
        title = 'Downloads';
        description = 'Access and manage downloads';
        color = Colors.green;
        break;
      case ExtensionPermission.nativeMessaging:
        icon = Icons.message;
        title = 'Native Messaging';
        description = 'Communicate with native applications';
        color = Colors.red;
        break;
      case ExtensionPermission.debugger:
        icon = Icons.bug_report;
        title = 'Debugger';
        description = 'Access debugging APIs';
        color = Colors.red;
        break;
      case ExtensionPermission.desktopCapture:
        icon = Icons.screen_share;
        title = 'Screen Capture';
        description = 'Capture screen content';
        color = Colors.red;
        break;
      case ExtensionPermission.system:
        icon = Icons.computer;
        title = 'System Information';
        description = 'Access system information';
        color = Colors.red;
        break;
      case ExtensionPermission.management:
        icon = Icons.settings;
        title = 'Extension Management';
        description = 'Manage other extensions';
        color = Colors.red;
        break;
      case ExtensionPermission.aiAnalysis:
        icon = Icons.psychology;
        title = 'AI Analysis';
        description = 'Use AI to analyze web pages';
        color = Colors.purple;
        break;
      case ExtensionPermission.aiAutomation:
        icon = Icons.smart_toy;
        title = 'AI Automation';
        description = 'Use AI for web automation';
        color = Colors.purple;
        break;
      case ExtensionPermission.aiLearning:
        icon = Icons.school;
        title = 'AI Learning';
        description = 'Learn from your browsing behavior';
        color = Colors.purple;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_loadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviews.isEmpty) {
      return const Center(
        child: Text('No reviews available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        Icons.star,
                        size: 16,
                        color: i < review.rating ? Colors.amber : Colors.grey[300],
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (review.title.isNotEmpty) ...[
                  Text(
                    review.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(review.content),
                const SizedBox(height: 8),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Technical Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Extension ID', isInstalled ? (widget.extension as Extension).id : (widget.extension as MarketplaceExtension).id),
          _buildInfoRow('Version', manifest.version),
          _buildInfoRow('Manifest Version', manifest.manifestVersion.toString()),
          _buildInfoRow('Type', manifest.type.name),
          if (manifest.updateUrl != null)
            _buildInfoRow('Update URL', manifest.updateUrl!),
          const SizedBox(height: 24),
          if (manifest.matches.isNotEmpty) ...[
            Text(
              'URL Patterns',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...manifest.matches.map((pattern) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                pattern,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (manifest.contentScripts.isNotEmpty) ...[
            Text(
              'Content Scripts',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...manifest.contentScripts.map((script) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                script,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          if (isInstalled) ...[
            ElevatedButton.icon(
              onPressed: widget.onToggle,
              icon: Icon(isEnabled ? Icons.pause : Icons.play_arrow),
              label: Text(isEnabled ? 'Disable' : 'Enable'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: widget.onUninstall,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Uninstall', style: TextStyle(color: Colors.red)),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: widget.onInstall,
              icon: const Icon(Icons.download),
              label: const Text('Install'),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDownloadCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}