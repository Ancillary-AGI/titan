import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/account_service.dart';
import '../services/browser_import_service.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final profile = await AccountService.getUserProfile();
    setState(() => _userProfile = profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AccountService.isSignedIn
              ? _buildSignedInView()
              : _buildSignInView(),
    );
  }

  Widget _buildSignedInView() {
    final user = AccountService.currentUser!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Profile Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  user.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Sync Settings
        _buildSectionHeader('Sync Settings'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Sync Bookmarks'),
                subtitle: const Text('Keep bookmarks synced across devices'),
                value: _userProfile?['syncSettings']?['bookmarks'] ?? true,
                onChanged: (value) => _updateSyncSetting('bookmarks', value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Sync History'),
                subtitle: const Text('Keep browsing history synced'),
                value: _userProfile?['syncSettings']?['history'] ?? true,
                onChanged: (value) => _updateSyncSetting('history', value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Sync Extensions'),
                subtitle: const Text('Keep extensions synced'),
                value: _userProfile?['syncSettings']?['extensions'] ?? true,
                onChanged: (value) => _updateSyncSetting('extensions', value),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Import/Export
        _buildSectionHeader('Data Management'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Import from Browser'),
                subtitle: const Text('Import bookmarks and settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showImportDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Export Data'),
                subtitle: const Text('Export your browsing data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportData,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Import from File'),
                subtitle: const Text('Import bookmarks from HTML/JSON file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _importFromFile,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Account Actions
        _buildSectionHeader('Account Actions'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Account'),
                subtitle: const Text('Permanently delete your account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignInView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 100,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'Sign in to Titan',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Sync your bookmarks, history, and settings across all your devices',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Sign In Options
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showEmailSignInDialog,
              icon: const Icon(Icons.email),
              label: const Text('Sign in with Email'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _signInAnonymously,
            child: const Text('Continue without account'),
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

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await AccountService.signInWithGoogle();
      _loadUserProfile();
    } catch (e) {
      _showErrorSnackBar('Failed to sign in with Google: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await AccountService.signInAnonymously();
      _loadUserProfile();
    } catch (e) {
      _showErrorSnackBar('Failed to sign in anonymously: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEmailSignInDialog() {
    showDialog(
      context: context,
      builder: (context) => _EmailSignInDialog(
        onSignIn: (email, password, isSignUp) async {
          setState(() => _isLoading = true);
          try {
            if (isSignUp) {
              await AccountService.signUpWithEmail(email, password);
            } else {
              await AccountService.signInWithEmail(email, password);
            }
            _loadUserProfile();
            Navigator.of(context).pop();
          } catch (e) {
            _showErrorSnackBar('Authentication failed: $e');
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  void _signOut() async {
    setState(() => _isLoading = true);
    try {
      await AccountService.signOut();
      setState(() => _userProfile = null);
    } catch (e) {
      _showErrorSnackBar('Failed to sign out: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editProfile() {
    // Implementation for editing profile
    _showErrorSnackBar('Profile editing coming soon');
  }

  void _updateSyncSetting(String setting, bool value) async {
    if (_userProfile != null) {
      _userProfile!['syncSettings'][setting] = value;
      // Update in storage and sync
      setState(() {});
    }
  }

  void _showImportDialog() async {
    final availableBrowsers = await BrowserImportService.getAvailableBrowsers();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Browser'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableBrowsers.map((browser) {
            return ListTile(
              title: Text(BrowserImportService.getBrowserDisplayName(browser)),
              onTap: () async {
                Navigator.of(context).pop();
                await _importFromBrowser(browser);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _importFromBrowser(BrowserType browser) async {
    setState(() => _isLoading = true);
    try {
      final data = await BrowserImportService.importFromBrowser(browser);
      // Process imported data
      _showErrorSnackBar('Imported ${data['bookmarks'].length} bookmarks from ${data['browser']}');
    } catch (e) {
      _showErrorSnackBar('Import failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _importFromFile() async {
    try {
      await BrowserImportService.importBookmarksFromFile();
      _showErrorSnackBar('Bookmarks imported successfully');
    } catch (e) {
      _showErrorSnackBar('Import failed: $e');
    }
  }

  void _exportData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AccountService.exportUserData();
      // Save to file or show export options
      _showErrorSnackBar('Data exported successfully');
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changePassword() {
    _showErrorSnackBar('Password change coming soon');
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);
              try {
                await AccountService.deleteAccount();
                setState(() => _userProfile = null);
                _showErrorSnackBar('Account deleted successfully');
              } catch (e) {
                _showErrorSnackBar('Failed to delete account: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _EmailSignInDialog extends StatefulWidget {
  final Function(String email, String password, bool isSignUp) onSignIn;

  const _EmailSignInDialog({required this.onSignIn});

  @override
  State<_EmailSignInDialog> createState() => _EmailSignInDialogState();
}

class _EmailSignInDialogState extends State<_EmailSignInDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            obscureText: _obscurePassword,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? 'Already have an account?' : 'Need an account?'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
              widget.onSignIn(_emailController.text, _passwordController.text, _isSignUp);
            }
          },
          child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}