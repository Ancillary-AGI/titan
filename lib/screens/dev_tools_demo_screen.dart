import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/developer_tools_panel.dart';

class DevToolsDemoScreen extends ConsumerStatefulWidget {
  const DevToolsDemoScreen({super.key});

  @override
  ConsumerState<DevToolsDemoScreen> createState() => _DevToolsDemoScreenState();
}

class _DevToolsDemoScreenState extends ConsumerState<DevToolsDemoScreen> {
  bool _showDevTools = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools Demo'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showDevTools = !_showDevTools),
            icon: Icon(_showDevTools
                ? Icons.developer_mode
                : Icons.developer_mode_outlined),
            tooltip: 'Toggle Developer Tools',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Developer Tools Integration Demo',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Developer Tools: ${_showDevTools ? 'Visible' : 'Hidden'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _showDevTools = !_showDevTools),
                  child:
                      Text(_showDevTools ? 'Hide Dev Tools' : 'Show Dev Tools'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'This demonstrates how the DeveloperToolsPanel integrates with the browser UI.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Developer Tools Panel
          if (_showDevTools)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 400,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    left: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: const DeveloperToolsPanel(),
              ),
            ),
        ],
      ),
    );
  }
}
