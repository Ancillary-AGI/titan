import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';
import '../models/ai_task.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

class AIAssistantPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic>? pageContext;
  final bool isVisible;
  
  const AIAssistantPanel({
    super.key,
    this.pageContext,
    this.isVisible = true,
  });

  @override
  ConsumerState<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

/// Collapsible AI Assistant Panel for mobile/tablet layouts
class AIAssistantCollapsiblePane extends StatefulWidget {
  final bool isVisible;
  final Map<String, dynamic>? pageContext;
  
  const AIAssistantCollapsiblePane({
    super.key,
    required this.isVisible,
    this.pageContext,
  });

  @override
  State<AIAssistantCollapsiblePane> createState() => _AIAssistantCollapsiblePaneState();
}

class _AIAssistantCollapsiblePaneState extends State<AIAssistantCollapsiblePane>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isVisible) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AIAssistantCollapsiblePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final width = Responsive.getValue(
      context,
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: 400.0,
      desktop: 350.0,
    );

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(width * _slideAnimation.value, 0),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: AIAssistantPanel(
              pageContext: widget.pageContext,
              isVisible: widget.isVisible,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _AIAssistantPanelState extends ConsumerState<AIAssistantPanel> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final isMobile = Responsive.isMobile(context);

    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, aiState),
      tablet: _buildTabletLayout(context, aiState),
      desktop: _buildDesktopLayout(context, aiState),
    );
  }

  Widget _buildMobileLayout(BuildContext context, aiState) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          _buildHeader(context, aiState, isMobile: true),
          _buildPageContext(context, isMobile: true),
          _buildQuickActions(context, isMobile: true),
          Expanded(child: _buildTasksList(context, isMobile: true)),
          _buildInputArea(context, isMobile: true),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, aiState) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, aiState),
          _buildPageContext(context),
          _buildQuickActions(context),
          Expanded(child: _buildTasksList(context)),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, aiState) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, aiState),
          _buildPageContext(context),
          _buildQuickActions(context),
          Expanded(child: _buildTasksList(context)),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, aiState, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.spaceMd : AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: isMobile ? Theme.of(context).colorScheme.surface : null,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.smart_toy,
            size: isMobile ? 20 : 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text(
              'AI Assistant',
              style: (isMobile 
                  ? Theme.of(context).textTheme.titleMedium 
                  : Theme.of(context).textTheme.titleLarge)?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (aiState.isProcessing)
            SizedBox(
              width: isMobile ? 16 : 20,
              height: isMobile ? 16 : 20,
              child: CircularProgressIndicator(
                strokeWidth: isMobile ? 2 : 2.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageContext(BuildContext context, {bool isMobile = false}) {
    if (widget.pageContext == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
      padding: EdgeInsets.all(isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.web,
                size: isMobile ? 14 : 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: AppTheme.spaceXs),
              Text(
                'Page Context',
                style: (isMobile 
                    ? Theme.of(context).textTheme.labelMedium 
                    : Theme.of(context).textTheme.labelLarge)?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spaceXs),
          Text(
            widget.pageContext!['title'] ?? 'Current Page',
            style: (isMobile 
                ? Theme.of(context).textTheme.bodySmall 
                : Theme.of(context).textTheme.bodyMedium)?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.pageContext!['url'] != null) ...[
            SizedBox(height: AppTheme.spaceXs),
            Text(
              widget.pageContext!['url'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: (isMobile 
                ? Theme.of(context).textTheme.labelMedium 
                : Theme.of(context).textTheme.labelLarge)?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.spaceSm),
          ResponsiveGrid(
            forceColumns: isMobile ? 2 : null,
            spacing: AppTheme.spaceSm,
            runSpacing: AppTheme.spaceSm,
            children: [
              _QuickActionChip(
                label: 'Summarize',
                icon: Icons.summarize,
                onTap: () => ref.read(aiProvider.notifier).summarizePage(),
                isCompact: isMobile,
              ),
              _QuickActionChip(
                label: 'Extract Data',
                icon: Icons.table_chart,
                onTap: () => _showExtractDataDialog(),
                isCompact: isMobile,
              ),
              _QuickActionChip(
                label: 'Fill Form',
                icon: Icons.edit_note,
                onTap: () => _showFillFormDialog(),
                isCompact: isMobile,
              ),
              _QuickActionChip(
                label: 'Translate',
                icon: Icons.translate,
                onTap: () => _showTranslateDialog(),
                isCompact: isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, {bool isMobile = false}) {
    final aiState = ref.watch(aiProvider);
    
    if (aiState.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppTheme.spaceLg : AppTheme.spaceXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: isMobile ? 48 : 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              SizedBox(height: AppTheme.spaceMd),
              Text(
                'No AI tasks yet',
                style: (isMobile 
                    ? Theme.of(context).textTheme.titleMedium 
                    : Theme.of(context).textTheme.titleLarge)?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              SizedBox(height: AppTheme.spaceSm),
              Text(
                'Use quick actions or ask AI for help',
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

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spaceSm : AppTheme.spaceMd,
      ),
      itemCount: aiState.tasks.length,
      itemBuilder: (context, index) {
        final task = aiState.tasks[index];
        return _TaskCard(
          task: task,
          onRetry: () => ref.read(aiProvider.notifier).retryTask(task.id),
          onCancel: () => ref.read(aiProvider.notifier).cancelTask(task.id),
          onDelete: () => ref.read(aiProvider.notifier).deleteTask(task.id),
          isCompact: isMobile,
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: isMobile ? Theme.of(context).colorScheme.surface : null,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  hintText: 'Ask AI to help with this page...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: isMobile ? AppTheme.spaceMd : AppTheme.spaceSm,
                  ),
                ),
                maxLines: isMobile ? 3 : null,
                textInputAction: TextInputAction.send,
                onSubmitted: _handlePromptSubmit,
              ),
            ),
            SizedBox(width: AppTheme.spaceSm),
            IconButton(
              onPressed: () => _handlePromptSubmit(_promptController.text),
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: Size(
                  isMobile ? 48 : 44,
                  isMobile ? 48 : 44,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePromptSubmit(String prompt) {
    if (prompt.trim().isEmpty) return;

    ref.read(aiProvider.notifier).createTask(
      type: AITaskType.custom,
      description: prompt,
      parameters: {'prompt': prompt},
    );

    _promptController.clear();
  }

  void _showExtractDataDialog() {
    showDialog(
      context: context,
      builder: (context) => _ExtractDataDialog(),
    );
  }

  void _showFillFormDialog() {
    showDialog(
      context: context,
      builder: (context) => _FillFormDialog(),
    );
  }

  void _showTranslateDialog() {
    showDialog(
      context: context,
      builder: (context) => _TranslateDialog(),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isCompact;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSm,
              vertical: AppTheme.spaceSm,
            ),
            alignment: Alignment.centerLeft,
          ),
        ),
      );
    }

    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceXs,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final AITask task;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final bool isCompact;

  const _TaskCard({
    required this.task,
    required this.onRetry,
    required this.onCancel,
    required this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spaceSm),
      elevation: isCompact ? AppTheme.elevationSm : AppTheme.elevationMd,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppTheme.spaceSm : AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getStatusIcon(),
                SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Text(
                    task.description,
                    style: (isCompact 
                        ? Theme.of(context).textTheme.bodySmall 
                        : Theme.of(context).textTheme.bodyMedium)?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: isCompact ? 2 : null,
                    overflow: isCompact ? TextOverflow.ellipsis : null,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'retry':
                        onRetry();
                        break;
                      case 'cancel':
                        onCancel();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (task.status == AITaskStatus.failed)
                      const PopupMenuItem(
                        value: 'retry',
                        child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Retry'),
                          dense: true,
                        ),
                      ),
                    if (task.status == AITaskStatus.running)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: ListTile(
                          leading: Icon(Icons.cancel),
                          title: Text('Cancel'),
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
                  icon: Icon(
                    Icons.more_vert,
                    size: isCompact ? 16 : 20,
                  ),
                ),
              ],
            ),
            
            if (task.status == AITaskStatus.running && task.progress > 0) ...[
              SizedBox(height: AppTheme.spaceSm),
              LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ],
            
            if (task.result != null) ...[
              SizedBox(height: AppTheme.spaceSm),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppTheme.spaceSm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  task.result!,
                  style: (isCompact 
                      ? Theme.of(context).textTheme.bodySmall 
                      : Theme.of(context).textTheme.bodyMedium)?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            
            if (task.error != null) ...[
              SizedBox(height: AppTheme.spaceSm),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppTheme.spaceSm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  task.error!,
                  style: (isCompact 
                      ? Theme.of(context).textTheme.bodySmall 
                      : Theme.of(context).textTheme.bodyMedium)?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            
            // Task timestamp
            if (!isCompact) ...[
              SizedBox(height: AppTheme.spaceXs),
              Text(
                _formatTimestamp(task.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _getStatusIcon() {
    switch (task.status) {
      case AITaskStatus.pending:
        return const Icon(Icons.schedule, size: 16, color: Colors.orange);
      case AITaskStatus.running:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case AITaskStatus.completed:
        return const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case AITaskStatus.failed:
        return const Icon(Icons.error, size: 16, color: Colors.red);
      case AITaskStatus.cancelled:
        return const Icon(Icons.cancel, size: 16, color: Colors.grey);
      case AITaskStatus.paused:
        return const Icon(Icons.pause_circle, size: 16, color: Colors.blue);
    }
  }
}

// Dialog widgets would be implemented here
class _ExtractDataDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Extract Data'),
      content: const Text('Data extraction dialog - to be implemented'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _FillFormDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fill Form'),
      content: const Text('Form filling dialog - to be implemented'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TranslateDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Translate Page'),
      content: const Text('Translation dialog - to be implemented'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}