import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/browser_engine_service.dart';

class DeveloperToolsPanel extends ConsumerStatefulWidget {
  const DeveloperToolsPanel({super.key});

  @override
  ConsumerState<DeveloperToolsPanel> createState() => _DeveloperToolsPanelState();
}

class _DeveloperToolsPanelState extends ConsumerState<DeveloperToolsPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _consoleLogs = [];
  final List<Map<String, dynamic>> _networkLogs = [];
  final TextEditingController _consoleInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNetworkLogs();
  }

  void _loadNetworkLogs() async {
    // Load network logs from storage
    // Implementation would load actual network logs
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_mode, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Developer Tools',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear_all, size: 18),
                  tooltip: 'Clear All Logs',
                ),
                IconButton(
                  onPressed: () {
                    // Close developer tools
                  },
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Close Developer Tools',
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Console'),
              Tab(text: 'Network'),
              Tab(text: 'Elements'),
              Tab(text: 'Performance'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConsoleTab(),
                _buildNetworkTab(),
                _buildElementsTab(),
                _buildPerformanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleTab() {
    return Column(
      children: [
        // Console output
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _consoleLogs.length,
            itemBuilder: (context, index) {
              final log = _consoleLogs[index];
              return _ConsoleLogItem(log: log);
            },
          ),
        ),

        // Console input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Text('> ', style: TextStyle(fontFamily: 'monospace')),
              Expanded(
                child: TextField(
                  controller: _consoleInputController,
                  decoration: const InputDecoration(
                    hintText: 'Enter JavaScript command...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                  onSubmitted: _executeConsoleCommand,
                ),
              ),
              IconButton(
                onPressed: () => _executeConsoleCommand(_consoleInputController.text),
                icon: const Icon(Icons.play_arrow, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkTab() {
    return Column(
      children: [
        // Network filters
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: true,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('XHR'),
                selected: false,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('JS'),
                selected: false,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('CSS'),
                selected: false,
                onSelected: (selected) {},
              ),
            ],
          ),
        ),

        // Network requests list
        Expanded(
          child: ListView.builder(
            itemCount: _networkLogs.length,
            itemBuilder: (context, index) {
              final request = _networkLogs[index];
              return _NetworkRequestItem(request: request);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildElementsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('DOM Inspector'),
          Text('Coming Soon', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildPerformanceMetric('Page Load Time', '1.2s', Colors.green),
          _buildPerformanceMetric('DOM Content Loaded', '0.8s', Colors.blue),
          _buildPerformanceMetric('First Paint', '0.5s', Colors.orange),
          _buildPerformanceMetric('Memory Usage', '45.2 MB', Colors.purple),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _runPerformanceAudit,
            icon: const Icon(Icons.speed),
            label: const Text('Run Performance Audit'),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _executeConsoleCommand(String command) {
    if (command.trim().isEmpty) return;

    // Add command to console log
    setState(() {
      _consoleLogs.add({
        'type': 'command',
        'message': command,
        'timestamp': DateTime.now(),
      });
    });

    // Execute JavaScript in WebView
    final controller = BrowserEngineService.currentController;
    if (controller != null) {
      controller.evaluateJavascript(source: command).then((result) {
        setState(() {
          _consoleLogs.add({
            'type': 'result',
            'message': result?.toString() ?? 'undefined',
            'timestamp': DateTime.now(),
          });
        });
      }).catchError((error) {
        setState(() {
          _consoleLogs.add({
            'type': 'error',
            'message': error.toString(),
            'timestamp': DateTime.now(),
          });
        });
      });
    }

    _consoleInputController.clear();
  }

  void _clearLogs() {
    setState(() {
      _consoleLogs.clear();
      _networkLogs.clear();
    });
  }

  void _runPerformanceAudit() {
    // Implementation for performance audit
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Running performance audit...')),
    );
  }

  void addConsoleLog(String type, String message) {
    setState(() {
      _consoleLogs.add({
        'type': type,
        'message': message,
        'timestamp': DateTime.now(),
      });
    });
  }

  void addNetworkLog(Map<String, dynamic> request) {
    setState(() {
      _networkLogs.add(request);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _consoleInputController.dispose();
    super.dispose();
  }
}

class _ConsoleLogItem extends StatelessWidget {
  final Map<String, dynamic> log;

  const _ConsoleLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    IconData icon;

    switch (log['type']) {
      case 'error':
        textColor = Colors.red;
        icon = Icons.error;
        break;
      case 'warn':
        textColor = Colors.orange;
        icon = Icons.warning;
        break;
      case 'command':
        textColor = Colors.blue;
        icon = Icons.keyboard_arrow_right;
        break;
      default:
        textColor = Theme.of(context).colorScheme.onSurface;
        icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log['message'],
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
          Text(
            _formatTime(log['timestamp']),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

class _NetworkRequestItem extends StatelessWidget {
  final Map<String, dynamic> request;

  const _NetworkRequestItem({required this.request});

  @override
  Widget build(BuildContext context) {
    final url = request['url'] ?? '';
    final method = request['method'] ?? 'GET';
    final status = request['status'] ?? 200;
    
    Color statusColor;
    if (status >= 200 && status < 300) {
      statusColor = Colors.green;
    } else if (status >= 300 && status < 400) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getMethodColor(method),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          method,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        _getFileName(url),
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        url,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.outline,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      return segments.isNotEmpty ? segments.last : uri.host;
    } catch (e) {
      return url;
    }
  }
}