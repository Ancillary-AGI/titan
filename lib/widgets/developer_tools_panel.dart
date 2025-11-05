import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/browser_engine_service.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

class DeveloperToolsPanel extends ConsumerStatefulWidget {
  const DeveloperToolsPanel({super.key});

  @override
  ConsumerState<DeveloperToolsPanel> createState() => DeveloperToolsPanelState();
}

// Public state type so external widgets can hold a GlobalKey<DeveloperToolsPanelState>
class DeveloperToolsPanelState extends ConsumerState<DeveloperToolsPanel>
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
    return ResponsiveLayout(
      mobile: _buildMobileDevTools(context),
      tablet: _buildTabletDevTools(context),
      desktop: _buildDesktopDevTools(context),
    );
  }

  Widget _buildMobileDevTools(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
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
          
          _buildHeader(context, isMobile: true),
          _buildTabBar(context, isMobile: true),
          Expanded(child: _buildTabViews(context, isMobile: true)),
        ],
      ),
    );
  }

  Widget _buildTabletDevTools(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(context),
          Expanded(child: _buildTabViews(context)),
        ],
      ),
    );
  }

  Widget _buildDesktopDevTools(BuildContext context) {
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
          _buildHeader(context),
          _buildTabBar(context),
          Expanded(child: _buildTabViews(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spaceMd : AppTheme.spaceLg,
        vertical: isMobile ? AppTheme.spaceSm : AppTheme.spaceMd,
      ),
      decoration: BoxDecoration(
        color: isMobile 
            ? Theme.of(context).colorScheme.surface 
            : Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.developer_mode,
            size: isMobile ? 20 : 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: AppTheme.spaceSm),
          Text(
            'Developer Tools',
            style: (isMobile 
                ? Theme.of(context).textTheme.titleMedium 
                : Theme.of(context).textTheme.titleLarge)?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _clearLogs,
            icon: Icon(Icons.clear_all, size: isMobile ? 18 : 20),
            tooltip: 'Clear All Logs',
          ),
          if (!isMobile)
            IconButton(
              onPressed: () {
                // Close developer tools
              },
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Close Developer Tools',
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, {bool isMobile = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isMobile,
        labelStyle: isMobile 
            ? Theme.of(context).textTheme.bodyMedium 
            : Theme.of(context).textTheme.bodyLarge,
        tabs: [
          Tab(
            text: 'Console',
            icon: isMobile ? const Icon(Icons.terminal, size: 16) : null,
          ),
          Tab(
            text: 'Network',
            icon: isMobile ? const Icon(Icons.network_check, size: 16) : null,
          ),
          Tab(
            text: 'Elements',
            icon: isMobile ? const Icon(Icons.code, size: 16) : null,
          ),
          Tab(
            text: 'Performance',
            icon: isMobile ? const Icon(Icons.speed, size: 16) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTabViews(BuildContext context, {bool isMobile = false}) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildConsoleTab(isMobile: isMobile),
        _buildNetworkTab(isMobile: isMobile),
        _buildElementsTab(isMobile: isMobile),
        _buildPerformanceTab(isMobile: isMobile),
      ],
    );
  }

  Widget _buildConsoleTab({bool isMobile = false}) {
    return Column(
      children: [
        // Console output
        Expanded(
          child: _consoleLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terminal,
                        size: isMobile ? 48 : 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      SizedBox(height: AppTheme.spaceMd),
                      Text(
                        'No console logs',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      SizedBox(height: AppTheme.spaceSm),
                      Text(
                        'JavaScript console output will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
                  itemCount: _consoleLogs.length,
                  itemBuilder: (context, index) {
                    final log = _consoleLogs[index];
                    return _ConsoleLogItem(
                      log: log,
                      isCompact: isMobile,
                    );
                  },
                ),
        ),

        // Console input
        Container(
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
                Text(
                  '> ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: isMobile ? 14 : 16,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _consoleInputController,
                    decoration: InputDecoration(
                      hintText: 'Enter JavaScript command...',
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: isMobile ? 2 : 1,
                    onSubmitted: _executeConsoleCommand,
                  ),
                ),
                IconButton(
                  onPressed: () => _executeConsoleCommand(_consoleInputController.text),
                  icon: Icon(
                    Icons.play_arrow,
                    size: isMobile ? 20 : 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: Size(
                      isMobile ? 40 : 44,
                      isMobile ? 40 : 44,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkTab({bool isMobile = false}) {
    return Column(
      children: [
        // Network filters
        Container(
          padding: EdgeInsets.all(isMobile ? AppTheme.spaceSm : AppTheme.spaceMd),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: true,
                  onSelected: (selected) {},
                  labelStyle: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                SizedBox(width: AppTheme.spaceSm),
                FilterChip(
                  label: const Text('XHR'),
                  selected: false,
                  onSelected: (selected) {},
                  labelStyle: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                SizedBox(width: AppTheme.spaceSm),
                FilterChip(
                  label: const Text('JS'),
                  selected: false,
                  onSelected: (selected) {},
                  labelStyle: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                SizedBox(width: AppTheme.spaceSm),
                FilterChip(
                  label: const Text('CSS'),
                  selected: false,
                  onSelected: (selected) {},
                  labelStyle: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                SizedBox(width: AppTheme.spaceSm),
                FilterChip(
                  label: const Text('Images'),
                  selected: false,
                  onSelected: (selected) {},
                  labelStyle: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Network requests list
        Expanded(
          child: _networkLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.network_check,
                        size: isMobile ? 48 : 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      SizedBox(height: AppTheme.spaceMd),
                      Text(
                        'No network requests',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      SizedBox(height: AppTheme.spaceSm),
                      Text(
                        'Network activity will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _networkLogs.length,
                  itemBuilder: (context, index) {
                    final request = _networkLogs[index];
                    return _NetworkRequestItem(
                      request: request,
                      isCompact: isMobile,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildElementsTab({bool isMobile = false}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppTheme.spaceLg : AppTheme.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: isMobile ? 48 : 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppTheme.spaceMd),
            Text(
              'DOM Inspector',
              style: (isMobile 
                  ? Theme.of(context).textTheme.titleMedium 
                  : Theme.of(context).textTheme.titleLarge)?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: AppTheme.spaceLg),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement DOM inspector
              },
              icon: const Icon(Icons.construction),
              label: const Text('View Roadmap'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab({bool isMobile = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppTheme.spaceMd : AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: (isMobile 
                ? Theme.of(context).textTheme.titleMedium 
                : Theme.of(context).textTheme.titleLarge)?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.spaceMd),
          
          // Performance metrics grid
          ResponsiveGrid(
            forceColumns: isMobile ? 1 : 2,
            spacing: AppTheme.spaceMd,
            runSpacing: AppTheme.spaceMd,
            children: [
              _buildPerformanceMetric(
                'Page Load Time',
                '1.2s',
                Colors.green,
                Icons.timer,
                isCompact: isMobile,
              ),
              _buildPerformanceMetric(
                'DOM Content Loaded',
                '0.8s',
                Colors.blue,
                Icons.web,
                isCompact: isMobile,
              ),
              _buildPerformanceMetric(
                'First Paint',
                '0.5s',
                Colors.orange,
                Icons.palette,
                isCompact: isMobile,
              ),
              _buildPerformanceMetric(
                'Memory Usage',
                '45.2 MB',
                Colors.purple,
                Icons.memory,
                isCompact: isMobile,
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.spaceLg),
          
          // Performance score
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Score',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.spaceMd),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: 0.85,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      SizedBox(width: AppTheme.spaceMd),
                      Text(
                        '85/100',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: AppTheme.spaceLg),
          
          // Action buttons
          if (isMobile) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runPerformanceAudit,
                icon: const Icon(Icons.speed),
                label: const Text('Run Performance Audit'),
              ),
            ),
            SizedBox(height: AppTheme.spaceMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _exportPerformanceReport,
                icon: const Icon(Icons.download),
                label: const Text('Export Report'),
              ),
            ),
          ] else ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _runPerformanceAudit,
                  icon: const Icon(Icons.speed),
                  label: const Text('Run Performance Audit'),
                ),
                SizedBox(width: AppTheme.spaceMd),
                OutlinedButton.icon(
                  onPressed: _exportPerformanceReport,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isCompact = false,
  }) {
    return Card(
      elevation: AppTheme.elevationSm,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppTheme.spaceMd : AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spaceSm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: isCompact ? 16 : 20,
                    color: color,
                  ),
                ),
                SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Text(
                    label,
                    style: (isCompact 
                        ? Theme.of(context).textTheme.bodyMedium 
                        : Theme.of(context).textTheme.bodyLarge)?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              value,
              style: (isCompact 
                  ? Theme.of(context).textTheme.titleLarge 
                  : Theme.of(context).textTheme.headlineSmall)?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
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

  void _exportPerformanceReport() {
    // Implementation for exporting performance report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting performance report...')),
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
  final bool isCompact;

  const _ConsoleLogItem({
    required this.log,
    this.isCompact = false,
  });

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

    return Container(
      margin: EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
      padding: EdgeInsets.all(isCompact ? AppTheme.spaceSm : AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: log['type'] == 'error' 
            ? Colors.red.withOpacity(0.05)
            : log['type'] == 'warn'
                ? Colors.orange.withOpacity(0.05)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: log['type'] == 'error' || log['type'] == 'warn'
            ? Border.all(
                color: textColor.withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: isCompact ? 14 : 16,
                color: textColor,
              ),
              SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Text(
                  log['message'],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: isCompact ? 11 : 12,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
              if (!isCompact)
                Text(
                  _formatTime(log['timestamp']),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.outline,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          if (isCompact) ...[
            SizedBox(height: AppTheme.spaceXs),
            Text(
              _formatTime(log['timestamp']),
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.outline,
                fontFamily: 'monospace',
              ),
            ),
          ],
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
  final bool isCompact;

  const _NetworkRequestItem({
    required this.request,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = request['url'] ?? '';
    final method = request['method'] ?? 'GET';
    final status = request['status'] ?? 200;
    final timestamp = request['timestamp'] ?? '';
    
    Color statusColor;
    if (status >= 200 && status < 300) {
      statusColor = Colors.green;
    } else if (status >= 300 && status < 400) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    if (isCompact) {
      return Card(
        margin: EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceXs,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceXs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getMethodColor(method),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    child: Text(
                      method,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: Text(
                      _getFileName(url),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceXs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    child: Text(
                      status.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spaceXs),
              Text(
                url,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      );
    }

    return ListTile(
      dense: true,
      leading: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spaceXs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: _getMethodColor(method),
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
        ),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (timestamp.isNotEmpty) ...[
            Text(
              _formatNetworkTime(timestamp),
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(width: AppTheme.spaceSm),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spaceXs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
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
        ],
      ),
    );
  }

  String _formatNetworkTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:'
             '${dateTime.minute.toString().padLeft(2, '0')}:'
             '${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
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