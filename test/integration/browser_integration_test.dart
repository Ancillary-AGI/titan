import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:titan_browser/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Browser Integration Tests', () {
    testWidgets('should launch browser and navigate to URL', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find the address bar
      final addressBar = find.byKey(Key('address_bar'));
      expect(addressBar, findsOneWidget);

      // Enter URL
      await tester.enterText(addressBar, 'https://example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('should create and manage multiple tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find new tab button
      final newTabButton = find.byKey(Key('new_tab_button'));
      expect(newTabButton, findsOneWidget);

      // Create new tab
      await tester.tap(newTabButton);
      await tester.pumpAndSettle();

      // Verify tab count
      final tabBar = find.byKey(Key('tab_bar'));
      expect(tabBar, findsOneWidget);
    });

    testWidgets('should handle bookmarks', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a page
      final addressBar = find.byKey(Key('address_bar'));
      await tester.enterText(addressBar, 'https://example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Add bookmark
      final bookmarkButton = find.byKey(Key('bookmark_button'));
      await tester.tap(bookmarkButton);
      await tester.pumpAndSettle();

      // Verify bookmark was added
      final bookmarksButton = find.byKey(Key('bookmarks_menu'));
      await tester.tap(bookmarksButton);
      await tester.pumpAndSettle();

      expect(find.text('example.com'), findsOneWidget);
    });

    testWidgets('should handle history', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to multiple pages
      final addressBar = find.byKey(Key('address_bar'));
      
      await tester.enterText(addressBar, 'https://example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.enterText(addressBar, 'https://google.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Open history
      final historyButton = find.byKey(Key('history_menu'));
      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      // Verify history entries
      expect(find.text('example.com'), findsOneWidget);
      expect(find.text('google.com'), findsOneWidget);
    });

    testWidgets('should handle AI assistant', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open AI assistant
      final aiButton = find.byKey(Key('ai_assistant_button'));
      await tester.tap(aiButton);
      await tester.pumpAndSettle();

      // Verify AI panel is open
      final aiPanel = find.byKey(Key('ai_assistant_panel'));
      expect(aiPanel, findsOneWidget);

      // Send a query
      final aiInput = find.byKey(Key('ai_input'));
      await tester.enterText(aiInput, 'Summarize this page');
      
      final sendButton = find.byKey(Key('ai_send_button'));
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify response
      expect(find.byKey(Key('ai_response')), findsOneWidget);
    });

    testWidgets('should handle downloads', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a page with downloadable content
      final addressBar = find.byKey(Key('address_bar'));
      await tester.enterText(addressBar, 'https://example.com/file.pdf');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Trigger download
      final downloadButton = find.byKey(Key('download_button'));
      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      // Verify download started
      final downloadNotification = find.byKey(Key('download_notification'));
      expect(downloadNotification, findsOneWidget);
    });

    testWidgets('should handle settings', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open settings
      final menuButton = find.byKey(Key('menu_button'));
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final settingsButton = find.byKey(Key('settings_button'));
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Verify settings screen
      final settingsScreen = find.byKey(Key('settings_screen'));
      expect(settingsScreen, findsOneWidget);

      // Test theme change
      final themeToggle = find.byKey(Key('theme_toggle'));
      await tester.tap(themeToggle);
      await tester.pumpAndSettle();

      // Verify theme changed
      // This would depend on your theme implementation
    });

    testWidgets('should handle incognito mode', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open incognito tab
      final menuButton = find.byKey(Key('menu_button'));
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final incognitoButton = find.byKey(Key('incognito_button'));
      await tester.tap(incognitoButton);
      await tester.pumpAndSettle();

      // Verify incognito mode
      final incognitoIndicator = find.byKey(Key('incognito_indicator'));
      expect(incognitoIndicator, findsOneWidget);
    });

    testWidgets('should handle extensions', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open extensions
      final menuButton = find.byKey(Key('menu_button'));
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final extensionsButton = find.byKey(Key('extensions_button'));
      await tester.tap(extensionsButton);
      await tester.pumpAndSettle();

      // Verify extensions screen
      final extensionsScreen = find.byKey(Key('extensions_screen'));
      expect(extensionsScreen, findsOneWidget);
    });

    testWidgets('should handle developer tools', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a page
      final addressBar = find.byKey(Key('address_bar'));
      await tester.enterText(addressBar, 'https://example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Open developer tools
      final devToolsButton = find.byKey(Key('dev_tools_button'));
      await tester.tap(devToolsButton);
      await tester.pumpAndSettle();

      // Verify developer tools panel
      final devToolsPanel = find.byKey(Key('dev_tools_panel'));
      expect(devToolsPanel, findsOneWidget);
    });
  });
}