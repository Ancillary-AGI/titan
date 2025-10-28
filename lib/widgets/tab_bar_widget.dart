import 'package:flutter/material.dart';
import '../models/browser_tab.dart';

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
          // Tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = index == activeIndex;
                
                return Container(
                  constraints: const BoxConstraints(
                    minWidth: 120,
                    maxWidth: 200,
                  ),
                  child: Material(
                    color: isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                              width: 16,
                              height: 16,
                              child: tab.isLoading
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    )
                                  : tab.favicon != null
                                      ? Image.network(
                                          tab.favicon!,
                                          width: 16,
                                          height: 16,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.public,
                                              size: 16,
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.public,
                                          size: 16,
                                        ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Tab title
                            Expanded(
                              child: Text(
                                tab.title,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            const SizedBox(width: 4),
                            
                            // Close button
                            InkWell(
                              onTap: () => onTabClosed(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
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
              },
            ),
          ),
          
          // New tab button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: IconButton(
              onPressed: onNewTab,
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'New Tab',
            ),
          ),
        ],
      ),
    );
  }
}