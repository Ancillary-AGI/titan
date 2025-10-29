import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/browser_window.dart';
import '../services/window_manager_service.dart';
import '../services/incognito_service.dart';
import '../screens/browser_screen.dart';

class BrowserWindowScreen extends ConsumerStatefulWidget {
  final String windowId;
  
  const BrowserWindowScreen({
    super.key,
    required this.windowId,
  });

  @override
  ConsumerState<BrowserWindowScreen> createState() => _BrowserWindowScreenState();
}

class _BrowserWindowScreenState extends ConsumerState<BrowserWindowScreen> {
  BrowserWindow? _window;

  @override
  void initState() {
    super.initState();
    _loadWindow();
  }

  void _loadWindow() {
    _window = WindowManagerService.getWindow(widget.windowId);
    if (_window?.isIncognito == true) {
      IncognitoService.registerIncognitoWindow(widget.windowId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_window == null) {
      return const Scaffold(
        body: Center(
          child: Text('Window not found'),
        ),
      );
    }

    return Scaffold(
      appBar: _window!.isIncognito ? _buildIncognitoAppBar() : null,
      body: BrowserScreen(
        windowId: widget.windowId,
        isIncognito: _window!.isIncognito,
      ),
    );
  }

  PreferredSizeWidget _buildIncognitoAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.security, color: Colors.white),
          const SizedBox(width: 8),
          const Text('Incognito Mode'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showIncognitoInfo(),
          icon: const Icon(Icons.info_outline),
        ),
      ],
    );
  }

  void _showIncognitoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security),
            SizedBox(width: 8),
            Text('Incognito Mode'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You\'re browsing privately. Titan won\'t save:'),
            SizedBox(height: 8),
            Text('• Your browsing history'),
            Text('• Cookies and site data'),
            Text('• Information entered in forms'),
            SizedBox(height: 16),
            Text('Your activity might still be visible to:'),
            SizedBox(height: 8),
            Text('• Websites you visit'),
            Text('• Your employer or school'),
            Text('• Your internet service provider'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_window?.isIncognito == true) {
      IncognitoService.unregisterIncognitoWindow(widget.windowId);
    }
    super.dispose();
  }
}