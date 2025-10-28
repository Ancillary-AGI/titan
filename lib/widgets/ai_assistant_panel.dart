import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';
import '../models/ai_task.dart';

class AIAssistantPanel extends ConsumerStatefulWidget {
  const AIAssistantPanel({super.key});

  @override
  ConsumerState<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends ConsumerState<AIAssistantPanel> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy),
                const SizedBox(width: 8),
                Text(
                  'AI Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (aiState.isProcessing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickActionChip(
                      label: 'Summarize Page',
                      icon: Icons.summarize,
                      onTap: () => ref.read(aiProvider.notifier).summarizePage(),
                    ),
                    _QuickActionChip(
                      label: 'Extract Data',
                      icon: Icons.data_extraction,
                      onTap: () => _showExtractDataDialog(),
                    ),
                    _QuickActionChip(
                      label: 'Fill Form',
                      icon: Icons.edit_note,
                      onTap: () => _showFillFormDialog(),
                    ),
                    _QuickActionChip(
                      label: 'Translate',
                      icon: Icons.translate,
                      onTap: () => _showTranslateDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: aiState.tasks.length,
              itemBuilder: (context, index) {
                final task = aiState.tasks[index];
                return _TaskCard(
                  task: task,
                  onRetry: () => ref.read(aiProvider.notifier).retryTask(task.id),
                  onCancel: () => ref.read(aiProvider.notifier).cancelTask(task.id),
                  onDelete: () => ref.read(aiProvider.notifier).deleteTask(task.id),
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: 'Ask AI to help with this page...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: _handlePromptSubmit,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _handlePromptSubmit(_promptController.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
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

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _TaskCard extends StatelessWidget {
  final AITask task;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onRetry,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getStatusIcon(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
                        child: Text('Retry'),
                      ),
                    if (task.status == AITaskStatus.running)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancel'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            
            if (task.status == AITaskStatus.running && task.progress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(value: task.progress),
              ),
            
            if (task.result != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.result!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            
            if (task.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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