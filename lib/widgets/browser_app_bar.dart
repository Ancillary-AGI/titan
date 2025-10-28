import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/browser_provider.dart';
import '../services/system_integration_service.dart';

class BrowserAppBar extends ConsumerWidget {
  final TextEditingController urlController;
  final Function(String) onNavigate;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onToggleAI;
  final VoidCallback onSettings;
  final VoidCallback onToggleDevTools;

  const BrowserAppBar({
    super.key,
    required this.urlController,
    required this.onNavigate,
    required this.onRefresh,
    required this.onBack,
    required this.onForward,
    required this.onToggleAI,
    required this.onSettings,
    required this.onToggleDevTools,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(browserProvider);
    final activeTab = browserState.activeTab;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Navigation buttons
          IconButton(
            onPressed: activeTab?.canGoBack == true ? onBack : null,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          IconButton(
            onPressed: activeTab?.canGoForward == true ? onForward : null,
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Forward',
          ),
          IconButton(
            onPressed: onRefresh,
            icon: activeTab?.isLoading == true
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          
          const SizedBox(width: 8),
          
          // URL bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: urlController,
                decoration: InputDecoration(
                  hintText: 'Search or enter URL',
                  prefixIcon: Icon(
                    _getSecurityIcon(activeTab?.url),
                    size: 16,
                    color: _getSecurityColor(activeTab?.url, context),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (urlController.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            urlController.clear();
                          },
                          icon: const Icon(Icons.clear, size: 16),
                        ),
                      IconButton(
                        onPressed: () => onNavigate(urlController.text),
                        icon: const Icon(Icons.search, size: 16),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: onNavigate,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Action buttons
          IconButton(
            onPressed: onToggleDevTools,
            icon: const Icon(Icons.developer_mode),
            tooltip: 'Developer Tools',
          ),
          
          IconButton(
            onPressed: onToggleAI,
            icon: const Icon(Icons.smart_toy),
            tooltip: 'AI Assistant',
          ),
          
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'bookmarks':
                  // Navigate to bookmarks
                  break;
                case 'history':
                  // Navigate to history
                  break;
                case 'account':
                  // Navigate to account
                  break;
                case 'settings':
                  onSettings();
                  break;
                case 'pin_taskbar':
                  _pinToTaskbar();
                  break;
                case 'dev_tools':
                  onToggleDevTools();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bookmarks',
                child: Row(
                  children: [
                    Icon(Icons.bookmark),
                    SizedBox(width: 8),
                    Text('Bookmarks'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'account',
                child: Row(
                  children: [
                    Icon(Icons.account_circle),
                    SizedBox(width: 8),
                    Text('Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'dev_tools',
                child: Row(
                  children: [
                    Icon(Icons.developer_mode),
                    SizedBox(width: 8),
                    Text('Developer Tools'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pin_taskbar',
                child: Row(
                  children: [
                    Icon(Icons.push_pin),
                    SizedBox(width: 8),
                    Text('Pin to Taskbar'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  IconData _getSecurityIcon(String? url) {
    if (url == null) return Icons.search;
    if (url.startsWith('https://')) return Icons.lock;
    if (url.startsWith('http://')) return Icons.info_outline;
    return Icons.search;
  }

  Color _getSecurityColor(String? url, BuildContext context) {
    if (url == null) return Theme.of(context).colorScheme.onSurface;
    if (url.startsWith('https://')) return Colors.green;
    if (url.startsWith('http://')) return Colors.orange;
    return Theme.of(context).colorScheme.onSurface;
  }
  
  void _pinToTaskbar() async {
    try {
      await SystemIntegrationService.pinToTaskbar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titan has been pinned to taskbar')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pin to taskbar: $e')),
      );
    }
  }
}