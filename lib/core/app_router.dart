import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/browser_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/history_screen.dart';
import '../screens/account_screen.dart';
import '../screens/dev_tools_demo_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/browser',
    routes: [
      GoRoute(
        path: '/browser',
        name: 'browser',
        builder: (context, state) => const BrowserScreen(),
      ),
      GoRoute(
        path: '/ai-assistant',
        name: 'ai-assistant',
        builder: (context, state) => const AIAssistantScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/dev-tools-demo',
        name: 'dev-tools-demo',
        builder: (context, state) => const DevToolsDemoScreen(),
      ),
    ],
  );
});
