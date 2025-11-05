import 'package:flutter/material.dart';
import '../models/extension.dart';
import '../services/extension_manager_service.dart';
import '../services/extension_marketplace_service.dart';
import '../widgets/extension_card.dart';
import '../widgets/extension_details_dialog.dart';

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({Key? key}) : super(key: key);

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Extension> _installedExtensions = [];
  List<MarketplaceExtension> _featuredExtensions = [];
  List<MarketplaceExtension> _trendingExtensions = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _setupExtensionListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupExtensionListener() {
    ExtensionManagerService.extensionStateStream.listen((extension) {
      setState(() {
        final index = _installedExtensions.indexWhere((e) => e.id == extension.id);
        if (index >= 0) {
          _installedExtensions[index] = extension;
        } else {
          _installedExtensions.add(extension);
        }
      });
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        Future.value(ExtensionManagerService.getInstalledExtensions()),
        ExtensionMarketplaceService.getFeaturedExtensions(),
        ExtensionMarketplaceService.getTrendingExtensions(),
        Future.value(ExtensionMarketplaceService.getCategories()),
      ]);

      setState(() {
        _installedExtensions = futures[0] as List<Extension>;
        _featuredExtensions = futures[1] as List<MarketplaceExtension>;
        _trendingExtensions = futures[2] as List<MarketplaceExtension>;
        _categories = futures[3] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load extensions: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _toggleExtension(Extension extension) async {
    try {
      if (extension.isEnabled) {
        await ExtensionManagerService.disableExtension(extension.id);
        _showSuccessSnackBar('Extension disabled');
      } else {
        await ExtensionManagerService.enableExtension(extension.id);
        _showSuccessSnackBar('Extension enabled');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to toggle extension: $e');
    }
  }

  Future<void> _uninstallExtension(Extension extension) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Extension'),
        content: Text('Are you sure you want to uninstall "${extension.manifest.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ExtensionManagerService.uninstallExtension(extension.id);
        _showSuccessSnackBar('Extension uninstalled');
      } catch (e) {
        _showErrorSnackBar('Failed to uninstall extension: $e');
      }
    }
  }

  Future<void> _installExtension(MarketplaceExtension extension) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Installing ${extension.manifest.name}...'),
            ],
          ),
        ),
      );

      await ExtensionMarketplaceService.downloadAndInstallExtension(extension.id);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessSnackBar('Extension installed successfully');
        _loadData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Failed to install extension: $e');
      }
    }
  }

  void _showExtensionDetails(dynamic extension) {
    showDialog(
      context: context,
      builder: (context) => ExtensionDetailsDialog(
        extension: extension,
        onInstall: extension is MarketplaceExtension ? () => _installExtension(extension) : null,
        onToggle: extension is Extension ? () => _toggleExtension(extension) : null,
        onUninstall: extension is Extension ? () => _uninstallExtension(extension) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extensions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Installed', icon: Icon(Icons.extension)),
            Tab(text: 'Featured', icon: Icon(Icons.star)),
            Tab(text: 'Browse', icon: Icon(Icons.explore)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInstalledTab(),
                _buildFeaturedTab(),
                _buildBrowseTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildInstalledTab() {
    final filteredExtensions = _installedExtensions.where((extension) {
      if (_searchQuery.isEmpty) return true;
      return extension.manifest.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             extension.manifest.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search installed extensions...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: filteredExtensions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.extension, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No extensions installed'
                            : 'No extensions match your search',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _tabController.animateTo(2),
                        child: const Text('Browse Extensions'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredExtensions.length,
                  itemBuilder: (context, index) {
                    final extension = filteredExtensions[index];
                    return ExtensionCard(
                      extension: extension,
                      onTap: () => _showExtensionDetails(extension),
                      onToggle: () => _toggleExtension(extension),
                      onUninstall: () => _uninstallExtension(extension),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFeaturedTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _featuredExtensions.isEmpty
          ? const Center(
              child: Text('No featured extensions available'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _featuredExtensions.length,
              itemBuilder: (context, index) {
                final extension = _featuredExtensions[index];
                return ExtensionCard(
                  extension: extension,
                  onTap: () => _showExtensionDetails(extension),
                  onInstall: () => _installExtension(extension),
                );
              },
            ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search extensions...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedCategory,
                hint: const Text('Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ..._categories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildBrowseContent(),
        ),
      ],
    );
  }

  Widget _buildBrowseContent() {
    if (_searchQuery.isNotEmpty || _selectedCategory != null) {
      return FutureBuilder<MarketplaceSearchResult>(
        future: ExtensionMarketplaceService.searchExtensions(
          _searchQuery,
          filters: MarketplaceFilters(category: _selectedCategory),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final result = snapshot.data!;
          if (result.extensions.isEmpty) {
            return const Center(
              child: Text('No extensions found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: result.extensions.length,
            itemBuilder: (context, index) {
              final extension = result.extensions[index];
              return ExtensionCard(
                extension: extension,
                onTap: () => _showExtensionDetails(extension),
                onInstall: () => _installExtension(extension),
              );
            },
          );
        },
      );
    }

    // Show trending extensions by default
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Trending Extensions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ..._trendingExtensions.map((extension) => ExtensionCard(
          extension: extension,
          onTap: () => _showExtensionDetails(extension),
          onInstall: () => _installExtension(extension),
        )),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extension Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Developer Mode'),
                  subtitle: const Text('Enable development features and unsigned extensions'),
                  value: false, // This would be bound to actual setting
                  onChanged: (value) {
                    // Update setting
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Unsigned Extensions'),
                  subtitle: const Text('Allow installation of unsigned extensions'),
                  value: false, // This would be bound to actual setting
                  onChanged: (value) {
                    // Update setting
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Clear Extension Cache'),
                  subtitle: const Text('Clear cached extension data'),
                  trailing: const Icon(Icons.clear),
                  onTap: () async {
                    await ExtensionMarketplaceService.clearCache();
                    _showSuccessSnackBar('Extension cache cleared');
                  },
                ),
                ListTile(
                  title: const Text('Extension Statistics'),
                  subtitle: const Text('View extension usage statistics'),
                  trailing: const Icon(Icons.analytics),
                  onTap: () {
                    _showExtensionStats();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showExtensionStats() {
    final stats = ExtensionManagerService.getExtensionStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extension Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Extensions', stats['totalExtensions'].toString()),
              _buildStatRow('Enabled Extensions', stats['enabledExtensions'].toString()),
              _buildStatRow('Disabled Extensions', stats['disabledExtensions'].toString()),
              _buildStatRow('Error Extensions', stats['errorExtensions'].toString()),
              const Divider(),
              const Text('Extensions by Type:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((stats['extensionsByType'] as Map<String, int>).entries.map(
                (entry) => _buildStatRow(entry.key, entry.value.toString()),
              )),
              const Divider(),
              const Text('Security Ratings:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((stats['extensionsBySecurityRating'] as Map<String, int>).entries.map(
                (entry) => _buildStatRow(entry.key, entry.value.toString()),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}