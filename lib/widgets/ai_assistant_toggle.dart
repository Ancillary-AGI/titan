import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';
import '../services/ai_service.dart';

enum AIMode { ask, agent }

class AIAssistantToggle extends ConsumerStatefulWidget {
  final VoidCallback onToggle;
  final bool isVisible;

  const AIAssistantToggle({
    super.key,
    required this.onToggle,
    required this.isVisible,
  });

  @override
  ConsumerState<AIAssistantToggle> createState() => _AIAssistantToggleState();
}

class _AIAssistantToggleState extends ConsumerState<AIAssistantToggle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final isProcessing = aiState.isProcessing;
    
    return Positioned(
      top: 8,
      right: 8,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: isProcessing ? _pulseAnimation.value : 1.0,
            child: Transform.rotate(
              angle: widget.isVisible ? _rotationAnimation.value * 3.14159 : 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isProcessing
                        ? [Colors.purple, Colors.blue, Colors.cyan]
                        : [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      widget.onToggle();
                      if (widget.isVisible) {
                        _rotationController.forward();
                      } else {
                        _rotationController.reverse();
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(12),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              widget.isVisible ? Icons.close : Icons.smart_toy,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          if (isProcessing)
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          if (aiState.tasks.any((task) => task.status == AITaskStatus.failed))
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

class AIAssistantCollapsiblePane extends ConsumerStatefulWidget {
  final bool isVisible;
  final Map<String, dynamic>? pageContext;

  const AIAssistantCollapsiblePane({
    super.key,
    required this.isVisible,
    this.pageContext,
  });

  @override
  ConsumerState<AIAssistantCollapsiblePane> createState() => _AIAssistantCollapsiblePaneState();
}

class _AIAssistantCollapsiblePaneState extends ConsumerState<AIAssistantCollapsiblePane>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  AIMode _currentMode = AIMode.ask;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _conversation = [];

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AIAssistantCollapsiblePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
        _addContextMessage();
      } else {
        _slideController.reverse();
      }
    }
  }

  void _addContextMessage() {
    if (widget.pageContext != null) {
      setState(() {
        _conversation.add({
          'type': 'system',
          'message': 'I can see you\'re on "${widget.pageContext!['title']}" at ${widget.pageContext!['url']}. How can I help you with this page?',
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: 400,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            left: BorderSide(color: Theme.of(context).dividerColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildModeSelector(),
            Expanded(child: _buildConversation()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Titan AI Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _currentMode == AIMode.ask ? 'Ask Mode' : 'Agent Mode',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _clearConversation,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Clear Conversation',
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<AIMode>(
              segments: const [
                ButtonSegment(
                  value: AIMode.ask,
                  label: Text('Ask'),
                  icon: Icon(Icons.chat, size: 16),
                ),
                ButtonSegment(
                  value: AIMode.agent,
                  label: Text('Agent'),
                  icon: Icon(Icons.auto_awesome, size: 16),
                ),
              ],
              selected: {_currentMode},
              onSelectionChanged: (Set<AIMode> selection) {
                setState(() {
                  _currentMode = selection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversation() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _conversation.length,
      itemBuilder: (context, index) {
        final message = _conversation[index];
        return _ConversationBubble(message: message);
      },
    );
  }

  Widget _buildInputArea() {
    final aiState = ref.watch(aiProvider);
    final isProcessing = aiState.isProcessing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          if (_currentMode == AIMode.agent) _buildQuickActions(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: _currentMode == AIMode.ask
                        ? 'Ask me anything about this page...'
                        : 'Tell me what you want me to do...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  enabled: !isProcessing,
                  onSubmitted: _handleInput,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: isProcessing ? null : () => _handleInput(_inputController.text),
                icon: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _QuickActionChip(
            label: 'Summarize',
            icon: Icons.summarize,
            onTap: () => _handleQuickAction('Summarize this page for me'),
          ),
          _QuickActionChip(
            label: 'Extract Data',
            icon: Icons.table_chart,
            onTap: () => _handleQuickAction('Extract the main data from this page'),
          ),
          _QuickActionChip(
            label: 'Find Links',
            icon: Icons.link,
            onTap: () => _handleQuickAction('Find all important links on this page'),
          ),
          _QuickActionChip(
            label: 'Fill Form',
            icon: Icons.edit_note,
            onTap: () => _handleQuickAction('Help me fill out the form on this page'),
          ),
        ],
      ),
    );
  }

  void _handleInput(String input) {
    if (input.trim().isEmpty) return;

    setState(() {
      _conversation.add({
        'type': 'user',
        'message': input,
        'timestamp': DateTime.now(),
      });
    });

    _inputController.clear();
    _scrollToBottom();

    if (_currentMode == AIMode.ask) {
      _handleAskMode(input);
    } else {
      _handleAgentMode(input);
    }
  }

  void _handleQuickAction(String action) {
    _inputController.text = action;
    _handleInput(action);
  }

  void _handleAskMode(String question) async {
    try {
      final context = widget.pageContext != null
          ? 'Current page: ${widget.pageContext!['title']}\nURL: ${widget.pageContext!['url']}\nContent: ${widget.pageContext!['content']}\n\n'
          : '';
      
      final prompt = '${context}User question: $question';
      final response = await AIService.generateResponse(prompt);

      setState(() {
        _conversation.add({
          'type': 'assistant',
          'message': response,
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _conversation.add({
          'type': 'error',
          'message': 'Sorry, I encountered an error: $e',
          'timestamp': DateTime.now(),
        });
      });
    }
    _scrollToBottom();
  }

  void _handleAgentMode(String instruction) async {
    try {
      await ref.read(aiProvider.notifier).createTask(
        type: AITaskType.custom,
        description: instruction,
        parameters: {
          'instruction': instruction,
          'pageContext': widget.pageContext,
        },
      );

      setState(() {
        _conversation.add({
          'type': 'assistant',
          'message': 'I\'ll help you with that. Starting the task now...',
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _conversation.add({
          'type': 'error',
          'message': 'Failed to create task: $e',
          'timestamp': DateTime.now(),
        });
      });
    }
    _scrollToBottom();
  }

  void _clearConversation() {
    setState(() {
      _conversation.clear();
    });
    _addContextMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ConversationBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _ConversationBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message['type'] == 'user';
    final isSystem = message['type'] == 'system';
    final isError = message['type'] == 'error';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: isError
                  ? Colors.red
                  : isSystem
                      ? Colors.orange
                      : Colors.blue,
              child: Icon(
                isError
                    ? Icons.error
                    : isSystem
                        ? Icons.info
                        : Icons.smart_toy,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : isError
                        ? Colors.red.withOpacity(0.1)
                        : isSystem
                            ? Colors.orange.withOpacity(0.1)
                            : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message['message'],
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : isError
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.person,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
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
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}