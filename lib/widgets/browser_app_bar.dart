import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/browser_provider.dart';
import '../services/system_integration_service.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

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

    return ResponsiveLayout(
      mobile: _buildMobileAppBar(context, ref, activeTab),
      tablet: _buildTabletAppBar(context, ref, activeTab),
      desktop: _buildDesktopAppBar(context, ref, activeTab),
    );
  }

  Widget _buildMobileAppBar(BuildContext context, WidgetRef ref, activeTab) {
    return Container(
      padding: EdgeInsets.all(TitanTheme.spaceSm),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top row with navigation and menu
          Row(
            children: [
              // Navigation buttons (compact)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: activeTab?.canGoBack == true ? onBack : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    tooltip: 'Back',
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  IconButton(
                    onPressed: activeTab?.canGoForward == true ? onForward : null,
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    tooltip: 'Forward',
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Action buttons
              IconButton(
                onPressed: onRefresh,
                icon: activeTab?.isLoading == true
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
              ),
              
              IconButton(
                onPressed: onToggleAI,
                icon: const Icon(Icons.smart_toy, size: 20),
                tooltip: 'AI Assistant',
              ),
              
              _buildMobileMenu(context, ref),
            ],
          ),
          
          SizedBox(height: TitanTheme.spaceSm),
          
          // URL bar (full width)
          _buildUrlBar(context, isMobile: true),
        ],
      ),
    );
  }

  Widget _buildTabletAppBar(BuildContext context, WidgetRef ref, activeTab) {
    return Container(
      padding: EdgeInsets.all(TitanTheme.spaceMd),
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
          _buildNavigationButtons(context, activeTab),
          
          SizedBox(width: TitanTheme.spaceMd),
          
          // URL bar
          Expanded(child: _buildUrlBar(context)),
          
          SizedBox(width: TitanTheme.spaceMd),
          
          // Action buttons
          _buildActionButtons(context, ref, showLabels: false),
        ],
      ),
    );
  }

  Widget _buildDesktopAppBar(BuildContext context, WidgetRef ref, activeTab) {
    return Container(
      padding: EdgeInsets.all(TitanTheme.spaceMd),
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
          _buildNavigationButtons(context, activeTab),
          
          SizedBox(width: TitanTheme.spaceLg),
          
          // URL bar
          Expanded(child: _buildUrlBar(context)),
          
          SizedBox(width: TitanTheme.spaceLg),
          
          // Action buttons with labels
          _buildActionButtons(context, ref, showLabels: true),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, activeTab) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildUrlBar(BuildContext context, {bool isMobile = false}) {
    return Consumer(
      builder: (context, ref, child) {
        final activeTab = ref.watch(browserProvider).activeTab;
    
    return Container(
      height: isMobile ? 48 : 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isMobile ? TitanTheme.radiusMd : TitanTheme.radiusXl),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: urlController,
        decoration: InputDecoration(
          hintText: 'Search or enter URL',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(TitanTheme.spaceSm),
            child: Icon(
              _getSecurityIcon(activeTab?.url),
              size: isMobile ? 20 : 18,
              color: _getSecurityColor(activeTab?.url, context),
            ),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (urlController.text.isNotEmpty)
                IconButton(
                  onPressed: () => urlController.clear(),
                  icon: Icon(Icons.clear, size: isMobile ? 20 : 18),
                  constraints: BoxConstraints(
                    minWidth: isMobile ? 44 : 40,
                    minHeight: isMobile ? 44 : 40,
                  ),
                ),
              IconButton(
                onPressed: () => onNavigate(urlController.text),
                icon: Icon(Icons.search, size: isMobile ? 20 : 18),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 44 : 40,
                  minHeight: isMobile ? 44 : 40,
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: TitanTheme.spaceMd,
            vertical: TitanTheme.spaceSm,
          ),
        ),
        onSubmitted: onNavigate,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, {bool showLabels = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels) ...[
          TextButton.icon(
            onPressed: onToggleDevTools,
            icon: const Icon(Icons.developer_mode),
            label: const Text('Dev Tools'),
          ),
          SizedBox(width: TitanTheme.spaceSm),
          TextButton.icon(
            onPressed: onToggleAI,
            icon: const Icon(Icons.smart_toy),
            label: const Text('AI Assistant'),
          ),
        ] else ...[
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
        ],
        
        SizedBox(width: TitanTheme.spaceSm),
        _buildDesktopMenu(context, ref),
      ],
    );
  }

  Widget _buildMobileMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuSelection(value, context, ref),
      itemBuilder: (context) => _getMenuItems(context, isMobile: true),
      icon: const Icon(Icons.more_vert),
      tooltip: 'More options',
    );
  }

  Widget _buildDesktopMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuSelection(value, context, ref),
      itemBuilder: (context) => _getMenuItems(context, isMobile: false),
      icon: const Icon(Icons.more_horiz),
      tooltip: 'More options',
    );
  }

  List<PopupMenuEntry<String>> _getMenuItems(BuildContext context, {bool isMobile = false}) {
    return [
      const PopupMenuItem(
        value: 'bookmarks',
        child: ListTile(
          leading: Icon(Icons.bookmark),
          title: Text('Bookmarks'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: 'history',
        child: ListTile(
          leading: Icon(Icons.history),
          title: Text('History'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: 'account',
        child: ListTile(
          leading: Icon(Icons.account_circle),
          title: Text('Account'),
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: 'settings',
        child: ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          dense: true,
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'new_incognito_tab',
        child: ListTile(
          leading: Icon(Icons.visibility_off),
          title: Text('New Incognito Tab'),
          dense: true,
        ),
      ),
      if (!isMobile) ...[
        const PopupMenuItem(
          value: 'dev_tools',
          child: ListTile(
            leading: Icon(Icons.developer_mode),
            title: Text('Developer Tools'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'pin_taskbar',
          child: ListTile(
            leading: Icon(Icons.push_pin),
            title: Text('Pin to Taskbar'),
            dense: true,
          ),
        ),
      ],
    ];
  }

  void _handleMenuSelection(String value, BuildContext context, WidgetRef ref) {
    switch (value) {
      case 'bookmarks':
        context.go('/bookmarks');
        break;
      case 'history':
        context.go('/history');
        break;
      case 'account':
        context.go('/account');
        break;
      case 'settings':
        onSettings();
        break;
      case 'new_incognito_tab':
        ref.read(browserProvider.notifier).addNewTab(incognito: true);
        break;
      case 'pin_taskbar':
        _pinToTaskbar(context);
        break;
      case 'dev_tools':
        onToggleDevTools();
        break;
    }
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
  
  void _pinToTaskbar(BuildContext context) async {
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