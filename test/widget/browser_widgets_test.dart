import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../../lib/widgets/tab_bar_widget.dart';
import '../../lib/widgets/browser_app_bar.dart';
import '../../lib/widgets/ai_assistant_panel.dart';
import '../../lib/providers/browser_provider.dart';
import '../../lib/models/browser_tab.dart';

void main() {
  group('Browser Widget Tests', () {
    late MockBrowserProvider mockProvider;

    setUp(() {
      mockProvider = MockBrowserProvider();
    });

    testWidgets('TabBarWidget should display tabs correctly', (tester) async {
      final tabs = [
        BrowserTab(id: '1', url: 'https://example.com', title: 'Example'),
        BrowserTab(id: '2', url: 'https://google.com', title: 'Google'),
      ];

      when(mockProvider.tabs).thenReturn(tabs);
      when(mockProvider.activeTabIndex).thenReturn(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowserProvider>.value(
            value: mockProvider,
            child: Scaffold(
              body: TabBarWidget(),
            ),
          ),
        ),
      );

      expect(find.text('Example'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('TabBarWidget should handle tab selection', (tester) async {
      final tabs = [
        BrowserTab(id: '1', url: 'https://example.com', title: 'Example'),
        BrowserTab(id: '2', url: 'https://google.com', title: 'Google'),
      ];

      when(mockProvider.tabs).thenReturn(tabs);
      when(mockProvider.activeTabIndex).thenReturn(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowserProvider>.value(
            value: mockProvider,
            child: Scaffold(
              body: TabBarWidget(),
            ),
          ),
        ),
      );

      // Tap on second tab
      await tester.tap(find.text('Google'));
      await tester.pump();

      verify(mockProvider.setActiveTab(1)).called(1);
    });

    testWidgets('BrowserAppBar should display correctly', (tester) async {
      when(mockProvider.currentUrl).thenReturn('https://example.com');
      when(mockProvider.canGoBack).thenReturn(true);
      when(mockProvider.canGoForward).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowserProvider>.value(
            value: mockProvider,
            child: Scaffold(
              appBar: BrowserAppBar(),
            ),
          ),
        ),
      );

      expect(find.text('https://example.com'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('BrowserAppBar should handle navigation', (tester) async {
      when(mockProvider.currentUrl).thenReturn('https://example.com');
      when(mockProvider.canGoBack).thenReturn(true);
      when(mockProvider.canGoForward).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowserProvider>.value(
            value: mockProvider,
            child: Scaffold(
              appBar: BrowserAppBar(),
            ),
          ),
        ),
      );

      // Test back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      verify(mockProvider.goBack()).called(1);
    });

    testWidgets('AIAssistantPanel should display correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistantPanel(),
          ),
        ),
      );

      expect(find.byKey(Key('ai_input')), findsOneWidget);
      expect(find.byKey(Key('ai_send_button')), findsOneWidget);
    });

    testWidgets('AIAssistantPanel should handle user input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIAssistantPanel(),
          ),
        ),
      );

      final inputField = find.byKey(Key('ai_input'));
      await tester.enterText(inputField, 'Test query');
      
      final sendButton = find.byKey(Key('ai_send_button'));
      await tester.tap(sendButton);
      await tester.pump();

      // Verify input was processed
      expect(find.text('Test query'), findsOneWidget);
    });

    testWidgets('should handle responsive layout', (tester) async {
      // Test mobile layout
      await tester.binding.setSurfaceSize(Size(400, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowserProvider>.value(
            value: mockProvider,
            child: Scaffold(
              body: TabBarWidget(),
            ),
          ),
        ),
      );

      // Verify mobile-specific elements
      expect(find.byKey(Key('mobile_tab_bar')), findsOneWidget);

      // Test desktop layout
      await tester.binding.setSurfaceSize(Size(1200, 800));
      await tester.pump();

      // Verify desktop-specific elements
      expect(find.byKey(Key('desktop_tab_bar')), findsOneWidget);
    });

    testWidgets('should handle theme changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TabBarWidget(),
          ),
        ),
      );

      // Verify light theme
      final lightThemeElement = tester.widget<Material>(find.byType(Material).first);
      expect(lightThemeElement.color, equals(Colors.white));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TabBarWidget(),
          ),
        ),
      );

      // Verify dark theme
      final darkThemeElement = tester.widget<Material>(find.byType(Material).first);
      expect(darkThemeElement.color, equals(Colors.grey[900]));
    });

    testWidgets('should handle accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowserProvider>.value(
            value: mockProvider,
            child: Scaffold(
              body: TabBarWidget(),
            ),
          ),
        ),
      );

      // Test semantic labels
      expect(find.bySemanticsLabel('Browser tabs'), findsOneWidget);
      expect(find.bySemanticsLabel('New tab'), findsOneWidget);
    });

    testWidgets('should handle loading states', (tester) async {
      final loadingTab = BrowserTab(
        id: '1',
        url: 'https://example.com',
        title: 'Loading...',
        isLoading: true,
      );

      when(mockProvider.tabs).thenReturn([loadingTab]);
      when(mockProvider.activeTabIndex).thenReturn(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowserProvider>.value(
            value: mockProvider,
            child: Scaffold(
              body: TabBarWidget(),
            ),
          ),
        ),
      );

      // Verify loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle error states', (tester) async {
      final errorTab = BrowserTab(
        id: '1',
        url: 'https://invalid-url',
        title: 'Error',
        hasError: true,
      );

      when(mockProvider.tabs).thenReturn([errorTab]);
      when(mockProvider.activeTabIndex).thenReturn(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowserProvider>.value(
            value: mockProvider,
            child: Scaffold(
              body: TabBarWidget(),
            ),
          ),
        ),
      );

      // Verify error indicator
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}

class MockBrowserProvider extends Mock implements BrowserProvider {}