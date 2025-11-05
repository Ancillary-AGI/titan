import 'package:flutter/material.dart';
import '../models/browser_tab.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

class TabBarWidget extends StatelessWidget {
  final List<BrowserTab> tabs;
  final int activeIndex;
  final Function(int) onTabSelected;
  final Function(int) onTabClosed;
  final VoidCallback onNewTab;

  const TabBarWidget({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onNewTab,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileTabBar(context),
      tablet: _buildTabletTabBar(context),
      desktop: _buildDesktopTabBar(context),
    );
  }

  Widget _buildMobileTabBar(BuildContext context) {
    // On mobile, show a horizontal scrollable tab indicator
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Tab counter and current tab info
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: Row(
                children: [
                  // Current tab favicon
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: activeIndex < tabs.length && tabs[activeIndex].isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : activeIndex < tabs.length && tabs[activeIndex].favicon != null
                            ? Image.network(
                                tabs[activeIndex].favicon!,
                                width: 20,
                                height: 20,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.public, size: 20);
                                },
                              )
                            : const Icon(Icons.public, size: 20),
                  ),
                  
                  SizedBox(width: AppTheme.spaceSm),
                  
                  // Current tab title
                  Expanded(
                    child: Text(
                      activeIndex < tabs.length ? tabs[activeIndex].title : 'New Tab',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Tab counter
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSm,
                      vertical: AppTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '${tabs.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab switcher button
          IconButton(
            onPressed: () => _showMobileTabSwitcher(context),
            icon: const Icon(Icons.tab),
            tooltip: 'Switch tabs',
          ),
          
          // New tab button
          IconButton(
            onPressed: onNewTab,
            icon: const Icon(Icons.add),
            tooltip: 'New tab',
          ),
        ],
      ),
    );
  }

  Widget _buildTabletTabBar(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Tabs (scrollable)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) => _buildTabItem(
                context,
                index,
                isCompact: true,
              ),
            ),
          ),
          
          // New tab button
          _buildNewTabButton(context, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildDesktopTabBar(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Tabs (scrollable)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) => _buildTabItem(context, index),
            ),
          ),
          
          // New tab button
          _buildNewTabButton(context),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, {bool isCompact = false}) {
    final tab = tabs[index];
    final isActive = index == activeIndex;
    
    return Container(
      constraints: BoxConstraints(
        minWidth: isCompact ? 100 : 120,
        maxWidth: isCompact ? 180 : 200,
      ),
      child: Material(
        color: isActive
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        child: InkWell(
          onTap: () => onTabSelected(index),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? AppTheme.spaceSm : AppTheme.spaceMd,
              vertical: AppTheme.spaceSm,
            ),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                // Favicon or loading indicator
                SizedBox(
                  width: isCompact ? 14 : 16,
                  height: isCompact ? 14 : 16,
                  child: tab.isLoading
                      ? CircularProgressIndicator(
                          strokeWidth: isCompact ? 1.5 : 2,
                        )
                      : tab.favicon != null
                          ? Image.network(
                              tab.favicon!,
                              width: isCompact ? 14 : 16,
                              height: isCompact ? 14 : 16,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.public,
                                  size: isCompact ? 14 : 16,
                                );
                              },
                            )
                          : Icon(
                              Icons.public,
                              size: isCompact ? 14 : 16,
                            ),
                ),
                
                SizedBox(width: AppTheme.spaceSm),
                
                // Tab title
                Expanded(
                  child: Text(
                    tab.title,
                    style: (isCompact 
                        ? Theme.of(context).textTheme.bodySmall 
                        : Theme.of(context).textTheme.bodyMedium)?.copyWith(
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                      color: isActive
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                SizedBox(width: AppTheme.spaceXs),
                
                // Close button
                InkWell(
                  onTap: () => onTabClosed(index),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Container(
                    padding: EdgeInsets.all(AppTheme.spaceXs),
                    child: Icon(
                      Icons.close,
                      size: isCompact ? 12 : 14,
                      color: isActive
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewTabButton(BuildContext context, {bool isCompact = false}) {
    return Container(
      width: isCompact ? 36 : 40,
      height: isCompact ? 36 : 40,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: IconButton(
        onPressed: onNewTab,
        icon: Icon(Icons.add, size: isCompact ? 16 : 18),
        tooltip: 'New Tab',
        constraints: BoxConstraints(
          minWidth: isCompact ? 36 : 40,
          minHeight: isCompact ? 36 : 40,
        ),
      ),
    );
  }

  void _showMobileTabSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MobileTabSwitcher(
        tabs: tabs,
        activeIndex: activeIndex,
        onTabSelected: (index) {
          Navigator.pop(context);
          onTabSelected(index);
        },
        onTabClosed: onTabClosed,
        onNewTab: () {
          Navigator.pop(context);
          onNewTab();
        },
      ),
    );
  }
}

class _MobileTabSwitcher extends StatelessWidget {
  final List<BrowserTab> tabs;
  final int activeIndex;
  final Function(int) onTabSelected;
  final Function(int) onTabClosed;
  final VoidCallback onNewTab;

  const _MobileTabSwitcher({
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onNewTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(AppTheme.spaceMd),
            child: Row(
              children: [
                Text(
                  'Tabs (${tabs.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onNewTab,
                  icon: const Icon(Icons.add),
                  label: const Text('New Tab'),
                ),
              ],
            ),
          ),
          
          // Tab grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(AppTheme.spaceMd),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = index == activeIndex;
                
                return Card(
                  elevation: isActive ? AppTheme.elevationMd : AppTheme.elevationSm,
                  color: isActive 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: InkWell(
                    onTap: () => onTabSelected(index),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Column(
                      children: [
                        // Tab preview (placeholder)
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: Center(
                              child: tab.isLoading
                                  ? const CircularProgressIndicator()
                                  : Icon(
                                      Icons.web,
                                      size: 32,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                            ),
                          ),
                        ),
                        
                        // Tab info
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.all(AppTheme.spaceSm),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Favicon
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: tab.favicon != null
                                          ? Image.network(
                                              tab.favicon!,
                                              width: 16,
                                              height: 16,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.public, size: 16);
                                              },
                                            )
                                          : const Icon(Icons.public, size: 16),
                                    ),
                                    
                                    SizedBox(width: AppTheme.spaceSm),
                                    
                                    // Title
                                    Expanded(
                                      child: Text(
                                        tab.title,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    
                                    // Close button
                                    InkWell(
                                      onTap: () => onTabClosed(index),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      child: Padding(
                                        padding: EdgeInsets.all(AppTheme.spaceXs),
                                        child: const Icon(Icons.close, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: AppTheme.spaceXs),
                                
                                // URL
                                Text(
                                  tab.url,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}