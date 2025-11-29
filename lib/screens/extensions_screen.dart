import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/extension_service.dart';
import '../models/extension.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/service_locator.dart';

class ExtensionsScreen extends ConsumerStatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  ConsumerState<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends ConsumerState<ExtensionsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final extensionService = ServiceLocator.get<ExtensionService>();
    final extensions = extensionService.installedExtensions;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.extensions),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showInstallDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Install Extension',
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, extensions, l10n),
        tablet: _buildTabletLayout(context, extensions, l10n),
        desktop: _buildDesktopLayout(context, extensions, l10n),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, List<Extension> extensions, AppLocalizations l10n) {
    return extensions.isEmpty
        ? _buildEmptyState(context, l10n, isMobile: true)
        : ListView.builder(
            padding: Responsive.getPadding(context),
            itemCount: extensions.length,
            itemBuilder: (context, index) => _ExtensionCard(
              extension: extensions[index],
              isCompact: true,
            ),
          );
  }

  Widget _buildTabletLayout(BuildContext context, List<Extension> extensions, AppLocalizations l10n) {
    return extensions.isEmpty
        ? _buildEmptyState(context, l10n)
        : GridView.builder(
            padding: Responsive.getPadding(context),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: extensions.length,
            itemBuilder: (context, index) => _ExtensionCard(
              extension: extensions[index],
            ),
          );
  }

  Widget _buildDesktopLayout(BuildContext context, List<Extension> extensions, AppLocalizations l10n) {
    return extensions.isEmpty
        ? _buildEmptyState(context, l10n)
        : GridView.builder(
            padding: Responsive.getPadding(context),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: extensions.length,
            itemBuilder: (context, index) => _ExtensionCard(
              extension: extensions[index],
            ),
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
              Icons.extension,
              size: isMobile ? 48 : 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppTheme.spaceMd),
            Text(
              'No extensions installed',
              style: (isMobile 
                  ? Theme.of(context).textTheme.titleLarge 
                  : Theme.of(context).textTheme.headlineSmall)?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              'Install extensions to enhance your browsing experience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spaceLg),
            ElevatedButton.icon(
              onPressed: _showInstallDialog,
              icon: const Icon(Icons.add),
              label: const Text('Install Extension'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install Extension'),
        content: const Text('Extension installation from file or marketplace coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ExtensionCard extends ConsumerWidget {
  final Extension extension;
  final bool isCompact;

  const _ExtensionCard({
    required this.extension,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extensionService = ServiceLocator.get<ExtensionService>();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppTheme.spaceSm : AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.extension,
                  size: isCompact ? 24 : 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        extension.manifest.name,
                        style: (isCompact 
                            ? Theme.of(context).textTheme.titleSmall 
                            : Theme.of(context).textTheme.titleMedium)?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'v${extension.manifest.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: extension.isEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await extensionService.enableExtension(extension.id);
                    } else {
                      await extensionService.disableExtension(extension.id);
                    }
                  },
                ),
              ],
            ),
            if (!isCompact && extension.manifest.description.isNotEmpty) ...[
              SizedBox(height: AppTheme.spaceSm),
              Text(
                extension.manifest.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: AppTheme.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(status: extension.status),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'disable':
                        extensionService.disableExtension(extension.id);
                        break;
                      case 'uninstall':
                        _showUninstallDialog(context, extension);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: extension.isEnabled ? 'disable' : 'enable',
                      child: ListTile(
                        leading: Icon(extension.isEnabled ? Icons.toggle_off : Icons.toggle_on),
                        title: Text(extension.isEnabled ? 'Disable' : 'Enable'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'uninstall',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Uninstall'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUninstallDialog(BuildContext context, Extension extension) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Extension'),
        content: Text('Are you sure you want to uninstall "${extension.manifest.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ServiceLocator.get<ExtensionService>().uninstallExtension(extension.id);
              Navigator.of(context).pop();
            },
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ExtensionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case ExtensionStatus.enabled:
        color = Colors.green;
        label = 'Enabled';
        break;
      case ExtensionStatus.disabled:
        color = Colors.grey;
        label = 'Disabled';
        break;
      case ExtensionStatus.installed:
        color = Colors.blue;
        label = 'Installed';
        break;
      case ExtensionStatus.error:
        color = Colors.red;
        label = 'Error';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
