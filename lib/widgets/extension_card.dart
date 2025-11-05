import 'package:flutter/material.dart';
import '../models/extension.dart';

class ExtensionCard extends StatelessWidget {
  final dynamic extension; // Can be Extension or MarketplaceExtension
  final VoidCallback? onTap;
  final VoidCallback? onInstall;
  final VoidCallback? onToggle;
  final VoidCallback? onUninstall;

  const ExtensionCard({
    super.key,
    required this.extension,
    this.onTap,
    this.onInstall,
    this.onToggle,
    this.onUninstall,
  });

  bool get isInstalled => extension is Extension;
  bool get isEnabled => isInstalled && (extension as Extension).isEnabled;
  ExtensionManifest get manifest => isInstalled 
      ? (extension as Extension).manifest 
      : (extension as MarketplaceExtension).manifest;
  SecurityRating get securityRating => isInstalled
      ? (extension as Extension).securityRating
      : (extension as MarketplaceExtension).securityRating;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                manifest.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildSecurityBadge(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v${manifest.version}${manifest.author != null ? ' • ${manifest.author}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                manifest.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip(),
                  const SizedBox(width: 8),
                  if (!isInstalled) ...[
                    _buildRatingChip(),
                    const SizedBox(width: 8),
                    _buildDownloadChip(),
                  ],
                  const Spacer(),
                  if (isInstalled) _buildStatusChip(),
                ],
              ),
              if (isInstalled && (extension as Extension).errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildErrorChip(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconUrl = isInstalled 
        ? (extension as Extension).getIcon(48)
        : (extension as MarketplaceExtension).iconUrl;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: iconUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                iconUrl,
                width: 48,
                height: 48,
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
      size: 24,
      color: Colors.grey[600],
    );
  }

  Widget _buildSecurityBadge() {
    Color color;
    IconData icon;
    
    switch (securityRating) {
      case SecurityRating.safe:
        color = Colors.green;
        icon = Icons.verified;
        break;
      case SecurityRating.trusted:
        color = Colors.blue;
        icon = Icons.shield;
        break;
      case SecurityRating.reviewed:
        color = Colors.orange;
        icon = Icons.check_circle;
        break;
      case SecurityRating.unverified:
        color = Colors.grey;
        icon = Icons.help;
        break;
      case SecurityRating.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case SecurityRating.dangerous:
        color = Colors.red;
        icon = Icons.dangerous;
        break;
    }

    return Tooltip(
      message: 'Security: ${securityRating.name}',
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildActionButton() {
    if (isInstalled) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'toggle':
              onToggle?.call();
              break;
            case 'uninstall':
              onUninstall?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(isEnabled ? Icons.pause : Icons.play_arrow),
                const SizedBox(width: 8),
                Text(isEnabled ? 'Disable' : 'Enable'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'uninstall',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Uninstall', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: onInstall,
        child: const Text('Install'),
      );
    }
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
      final marketplaceExt = extension as MarketplaceExtension;
      if (marketplaceExt.rating > 0) {
        return Chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                marketplaceExt.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.amber[50],
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildDownloadChip() {
    if (!isInstalled) {
      final marketplaceExt = extension as MarketplaceExtension;
      if (marketplaceExt.downloadCount > 0) {
        return Chip(
          label: Text(
            _formatDownloadCount(marketplaceExt.downloadCount),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.grey[100],
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusChip() {
    final ext = extension as Extension;
    Color color;
    String text;
    
    switch (ext.status) {
      case ExtensionStatus.enabled:
        color = Colors.green;
        text = 'Enabled';
        break;
      case ExtensionStatus.disabled:
        color = Colors.grey;
        text = 'Disabled';
        break;
      case ExtensionStatus.error:
        color = Colors.red;
        text = 'Error';
        break;
      case ExtensionStatus.updating:
        color = Colors.blue;
        text = 'Updating';
        break;
      default:
        color = Colors.grey;
        text = ext.status.name;
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildErrorChip() {
    final ext = extension as Extension;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, size: 16, color: Colors.red[700]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              ext.errors.first,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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