import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/system_integration_service.dart';
import '../services/mcp_server.dart';
import '../services/autofill_service.dart';
import '../services/sandboxing_service.dart';
import '../services/rendering_engine_service.dart';
import '../services/networking_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _openAIKeyController = TextEditingController();
  final _anthropicKeyController = TextEditingController();
  final _homePageController = TextEditingController();
  
  String _selectedSearchEngine = 'Google';
  bool _aiAssistantEnabled = true;
  bool _launchAtStartup = false;
  bool _mcpServerEnabled = true;
  bool _autofillEnabled = true;
  bool _savePasswords = true;
  bool _adBlockEnabled = true;
  bool _javascriptEnabled = true;
  SandboxLevel _sandboxLevel = SandboxLevel.basic;
  
  final Map<String, String> _searchEngines = {
    'Google': 'https://www.google.com/search?q=',
    'Bing': 'https://www.bing.com/search?q=',
    'DuckDuckGo': 'https://duckduckgo.com/?q=',
    'Yahoo': 'https://search.yahoo.com/search?p=',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    _openAIKeyController.text = StorageService.openAIKey ?? '';
    _anthropicKeyController.text = StorageService.anthropicKey ?? '';
    _homePageController.text = StorageService.defaultHomePage;
    _aiAssistantEnabled = StorageService.aiAssistantEnabled;
    _launchAtStartup = await SystemIntegrationService.isLaunchAtStartupEnabled();
    _mcpServerEnabled = StorageService.getSetting<bool>('mcp_server_enabled') ?? true;
    _autofillEnabled = AutofillService.isEnabled;
    _savePasswords = AutofillService.savePasswords;
    _adBlockEnabled = BrowserEngineService.isAdBlockEnabled;
    _javascriptEnabled = BrowserEngineService.isJavaScriptEnabled;
    _sandboxLevel = SandboxingService.defaultSandboxLevel;
    
    final currentSearchEngine = StorageService.defaultSearchEngine;
    _selectedSearchEngine = _searchEngines.entries
        .firstWhere(
          (entry) => entry.value == currentSearchEngine,
          orElse: () => _searchEngines.entries.first,
        )
        .key;
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Settings
          _buildSectionHeader('AI Assistant'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable AI Assistant'),
                    subtitle: const Text('Allow AI to help with browsing tasks'),
                    value: _aiAssistantEnabled,
                    onChanged: (value) {
                      setState(() => _aiAssistantEnabled = value);
                      StorageService.setSetting('ai_assistant_enabled', value);
                    },
                  ),
                  const Divider(),
                  TextField(
                    controller: _openAIKeyController,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API Key',
                      hintText: 'sk-...',
                      helperText: 'Required for AI features',
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      StorageService.setSetting('openai_key', value);
                      AIService.setOpenAIKey(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _anthropicKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Anthropic API Key (Optional)',
                      hintText: 'sk-ant-...',
                      helperText: 'For Claude AI models',
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      StorageService.setSetting('anthropic_key', value);
                      AIService.setAnthropicKey(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Browser Settings
          _buildSectionHeader('Browser'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _homePageController,
                    decoration: const InputDecoration(
                      labelText: 'Home Page',
                      hintText: 'https://www.google.com',
                    ),
                    onChanged: (value) {
                      StorageService.setSetting('home_page', value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSearchEngine,
                    decoration: const InputDecoration(
                      labelText: 'Default Search Engine',
                    ),
                    items: _searchEngines.keys.map((engine) {
                      return DropdownMenuItem(
                        value: engine,
                        child: Text(engine),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSearchEngine = value);
                        StorageService.setSetting('search_engine', _searchEngines[value]);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // System Integration
          _buildSectionHeader('System Integration'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Launch at Startup'),
                    subtitle: const Text('Start Titan when your computer starts'),
                    value: _launchAtStartup,
                    onChanged: (value) async {
                      await SystemIntegrationService.enableLaunchAtStartup(value);
                      setState(() => _launchAtStartup = value);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('MCP Server'),
                    subtitle: Text('Enable MCP server on port ${MCPServer.port}'),
                    value: _mcpServerEnabled,
                    onChanged: (value) async {
                      if (value) {
                        await MCPServer.start();
                      } else {
                        await MCPServer.stop();
                      }
                      await StorageService.setSetting('mcp_server_enabled', value);
                      setState(() => _mcpServerEnabled = value);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Pin to Taskbar'),
                    subtitle: const Text('Add Titan to your taskbar for quick access'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        try {
                          await SystemIntegrationService.pinToTaskbar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pinned to taskbar successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to pin: $e')),
                          );
                        }
                      },
                      child: const Text('Pin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Autofill & Passwords
          _buildSectionHeader('Autofill & Passwords'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Autofill'),
                    subtitle: const Text('Automatically fill forms and login fields'),
                    value: _autofillEnabled,
                    onChanged: (value) async {
                      await AutofillService.setEnabled(value);
                      setState(() => _autofillEnabled = value);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Save Passwords'),
                    subtitle: const Text('Offer to save passwords when you sign in'),
                    value: _savePasswords,
                    onChanged: (value) async {
                      await AutofillService.setSavePasswords(value);
                      setState(() => _savePasswords = value);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Manage Passwords'),
                    subtitle: const Text('View and manage saved passwords'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to password manager
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Security & Privacy
          _buildSectionHeader('Security & Privacy'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Block Ads'),
                    subtitle: const Text('Block advertisements and trackers'),
                    value: _adBlockEnabled,
                    onChanged: (value) {
                      BrowserEngineService.toggleAdBlock();
                      setState(() => _adBlockEnabled = value);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Enable JavaScript'),
                    subtitle: const Text('Allow websites to run JavaScript'),
                    value: _javascriptEnabled,
                    onChanged: (value) {
                      BrowserEngineService.toggleJavaScript();
                      setState(() => _javascriptEnabled = value);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Sandbox Level'),
                    subtitle: Text('Current: ${_sandboxLevel.name}'),
                    trailing: DropdownButton<SandboxLevel>(
                      value: _sandboxLevel,
                      items: SandboxLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level.name),
                        );
                      }).toList(),
                      onChanged: (level) {
                        if (level != null) {
                          SandboxingService.setDefaultSandboxLevel(level);
                          setState(() => _sandboxLevel = level);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Privacy & Data
          _buildSectionHeader('Privacy & Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Clear Browsing History'),
                  subtitle: const Text('Remove all browsing history'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearHistoryDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Clear Bookmarks'),
                  subtitle: const Text('Remove all bookmarks'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearBookmarksDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Clear AI Tasks'),
                  subtitle: const Text('Remove all AI task history'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearTasksDialog(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                  trailing: const Icon(Icons.info_outline),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Open privacy policy
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Open terms of service
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Browsing History'),
        content: const Text('This will permanently delete all browsing history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              StorageService.clearHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Browsing history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearBookmarksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Bookmarks'),
        content: const Text('This will permanently delete all bookmarks. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear bookmarks logic would go here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmarks cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearTasksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear AI Tasks'),
        content: const Text('This will permanently delete all AI task history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear AI tasks logic would go here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI tasks cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _openAIKeyController.dispose();
    _anthropicKeyController.dispose();
    _homePageController.dispose();
    super.dispose();
  }
}