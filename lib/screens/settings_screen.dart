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
import '../providers/browser_provider.dart';
import '../providers/ai_provider.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

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
  bool _externalEngineEnabled = false;
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
    _externalEngineEnabled = StorageService.getSetting<bool>('external_engine_enabled') ?? false;
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
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      padding: Responsive.getPadding(context),
      children: _buildSettingsSections(context, isMobile: true),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings navigation
        SizedBox(
          width: 250,
          child: _buildSettingsNavigation(context),
        ),
        
        // Settings content
        Expanded(
          child: ListView(
            padding: Responsive.getPadding(context),
            children: _buildSettingsSections(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings navigation
        SizedBox(
          width: 300,
          child: _buildSettingsNavigation(context),
        ),
        
        // Settings content
        Expanded(
          child: AdaptiveContainer(
            maxWidth: 800,
            child: ListView(
              padding: Responsive.getPadding(context),
              children: _buildSettingsSections(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsNavigation(BuildContext context) {
    final sections = [
      {'title': 'AI Assistant', 'icon': Icons.smart_toy},
      {'title': 'Browser', 'icon': Icons.web},
      {'title': 'System', 'icon': Icons.computer},
      {'title': 'Autofill', 'icon': Icons.auto_fix_high},
      {'title': 'Security', 'icon': Icons.security},
      {'title': 'Privacy', 'icon': Icons.privacy_tip},
      {'title': 'Advanced', 'icon': Icons.settings_applications},
      {'title': 'About', 'icon': Icons.info},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spaceMd),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spaceLg),
          ...sections.map((section) => ListTile(
            leading: Icon(section['icon'] as IconData),
            title: Text(section['title'] as String),
            onTap: () {
              // Scroll to section or navigate
            },
          )),
        ],
      ),
    );
  }

  List<Widget> _buildSettingsSections(BuildContext context, {bool isMobile = false}) {
    return [
      // AI Settings
      _buildSectionHeader('AI Assistant', Icons.smart_toy),
      _buildAISettingsCard(context, isMobile),
      
      SizedBox(height: AppTheme.spaceLg),
      
      // Browser Settings
      _buildSectionHeader('Browser', Icons.web),
      _buildBrowserSettingsCard(context, isMobile),
      
      SizedBox(height: AppTheme.spaceLg),
      
      // System Integration
      _buildSectionHeader('System Integration', Icons.computer),
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
                  SwitchListTile(
                    title: const Text('External Engine (Rust sidecar)'),
                    subtitle: const Text('Use CDP-controlled Chromium via sidecar on http://127.0.0.1:9224'),
                    value: _externalEngineEnabled,
                    onChanged: (value) async {
                      await StorageService.setSetting('external_engine_enabled', value);
                      setState(() => _externalEngineEnabled = value);
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
      
      SizedBox(height: AppTheme.spaceLg),
      
      // Autofill & Passwords
      _buildSectionHeader('Autofill & Passwords', Icons.auto_fix_high),
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
      
      SizedBox(height: AppTheme.spaceLg),
      
      // Security & Privacy
      _buildSectionHeader('Security & Privacy', Icons.security),
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
      
      SizedBox(height: AppTheme.spaceLg),
      
      // Privacy & Data
      _buildSectionHeader('Privacy & Data', Icons.privacy_tip),
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
      
      SizedBox(height: AppTheme.spaceLg),
      
      // About
      _buildSectionHeader('About', Icons.info),
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
    ];
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: AppTheme.spaceSm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISettingsCard(BuildContext context, bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppTheme.spaceMd : AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            
            if (_aiAssistantEnabled) ...[
              const Divider(),
              
              // AI Configuration Status
              Consumer(
                builder: (context, ref, child) {
                  final aiState = ref.watch(aiProvider);
                  return Container(
                    padding: EdgeInsets.all(AppTheme.spaceMd),
                    decoration: BoxDecoration(
                      color: aiState.isConfigured 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: aiState.isConfigured 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          aiState.isConfigured ? Icons.check_circle : Icons.warning,
                          color: aiState.isConfigured ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: Text(
                            aiState.isConfigured 
                                ? 'AI Assistant is configured and ready'
                                : 'AI Assistant requires API key configuration',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              SizedBox(height: AppTheme.spaceMd),
              
              TextField(
                controller: _openAIKeyController,
                decoration: const InputDecoration(
                  labelText: 'OpenAI API Key',
                  hintText: 'sk-...',
                  helperText: 'Required for GPT models',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
                onChanged: (value) async {
                  await StorageService.setString('openai_api_key', value);
                  await AIService.setOpenAIKey(value);
                },
              ),
              
              SizedBox(height: AppTheme.spaceMd),
              
              TextField(
                controller: _anthropicKeyController,
                decoration: const InputDecoration(
                  labelText: 'Anthropic API Key (Optional)',
                  hintText: 'sk-ant-...',
                  helperText: 'For Claude AI models',
                  prefixIcon: Icon(Icons.psychology),
                ),
                obscureText: true,
                onChanged: (value) async {
                  await StorageService.setString('anthropic_api_key', value);
                  await AIService.setAnthropicKey(value);
                },
              ),
              
              SizedBox(height: AppTheme.spaceMd),
              
              // AI Model Settings
              Consumer(
                builder: (context, ref, child) {
                  final aiState = ref.watch(aiProvider);
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: aiState.settings['model'] ?? 'gpt-4',
                        decoration: const InputDecoration(
                          labelText: 'Default AI Model',
                          prefixIcon: Icon(Icons.model_training),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'gpt-4', child: Text('GPT-4')),
                          DropdownMenuItem(value: 'gpt-3.5-turbo', child: Text('GPT-3.5 Turbo')),
                          DropdownMenuItem(value: 'claude-3', child: Text('Claude 3')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(aiProvider.notifier).updateSetting('model', value);
                          }
                        },
                      ),
                      
                      SizedBox(height: AppTheme.spaceMd),
                      
                      // Temperature Slider
                      Text(
                        'Creativity Level: ${(aiState.settings['temperature'] ?? 0.7).toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        value: aiState.settings['temperature'] ?? 0.7,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (value) {
                          ref.read(aiProvider.notifier).updateSetting('temperature', value);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrowserSettingsCard(BuildContext context, bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppTheme.spaceMd : AppTheme.spaceLg),
        child: Column(
          children: [
            TextField(
              controller: _homePageController,
              decoration: const InputDecoration(
                labelText: 'Home Page',
                hintText: 'titan://newtab',
                prefixIcon: Icon(Icons.home),
              ),
              onChanged: (value) {
                StorageService.setSetting('home_page', value);
              },
            ),
            
            SizedBox(height: AppTheme.spaceMd),
            
            DropdownButtonFormField<String>(
              value: _selectedSearchEngine,
              decoration: const InputDecoration(
                labelText: 'Default Search Engine',
                prefixIcon: Icon(Icons.search),
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
            
            SizedBox(height: AppTheme.spaceMd),
            
            // Browser Statistics
            Consumer(
              builder: (context, ref, child) {
                final browserState = ref.watch(browserProvider);
                final stats = browserState.getBrowsingStats();
                
                return Container(
                  padding: EdgeInsets.all(AppTheme.spaceMd),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browser Statistics',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppTheme.spaceSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(context, 'Open Tabs', '${stats['total_tabs']}'),
                          _buildStatItem(context, 'Loading', '${stats['loading_tabs']}'),
                          _buildStatItem(context, 'Incognito', '${stats['incognito_tabs']}'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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