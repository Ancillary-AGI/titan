# Developer Tools Panel Integration Guide

## Overview

The Titan Browser includes a comprehensive Developer Tools panel that provides web developers with essential debugging and inspection capabilities. This guide explains how to integrate the developer tools panel into the browser interface.

## Components

### 1. DeveloperToolsPanel Widget

The main developer tools panel is located at `lib/widgets/developer_tools_panel.dart`. It provides:

- **Console Tab**: JavaScript console with command execution
- **Network Tab**: HTTP request monitoring and inspection
- **Elements Tab**: DOM inspector (placeholder for future implementation)
- **Performance Tab**: Page performance metrics and analysis

### 2. DevToolsToggle Widget

A simple toggle button widget at `lib/widgets/dev_tools_toggle.dart` for showing/hiding the developer tools panel.

### 3. Demo Screen

A demonstration screen at `lib/screens/dev_tools_demo_screen.dart` showing how to integrate the panel.

## Integration Steps

### Step 1: Add State Management

In your browser screen state class, add a boolean flag to track developer tools visibility:

```dart
class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  // ... existing state variables
  bool _showDevToolsPanel = false;

  // ... rest of the class
}
```

### Step 2: Add Toggle Button to App Bar

In your app bar implementation, add a developer tools toggle button:

```dart
// In your app bar's action buttons
IconButton(
  onPressed: () => setState(() => _showDevToolsPanel = !_showDevToolsPanel),
  icon: Icon(_showDevToolsPanel ? Icons.developer_mode : Icons.developer_mode_outlined),
  tooltip: 'Developer Tools',
  color: _showDevToolsPanel ? Theme.of(context).colorScheme.primary : null,
),
```

### Step 3: Integrate Panel in Layout

Modify your layout to include the developer tools panel when visible:

```dart
Widget _buildDesktopLayout(BuildContext context) {
  return Scaffold(
    body: Row(
      children: [
        // Main content area
        Expanded(
          flex: _showDevToolsPanel ? 3 : 1,
          child: Column(
            children: [
              // Your existing browser UI
            ],
          ),
        ),

        // Developer Tools Panel
        if (_showDevToolsPanel)
          SizedBox(
            width: 400, // Adjust width as needed
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
```

### Step 4: Handle Console Logging

To capture JavaScript console messages, ensure your WebView controller is properly set up:

```dart
// In your WebView controller setup
controller.addJavaScriptHandler(
  handlerName: 'console_log',
  callback: (args) {
    // Forward to developer tools panel
    final devToolsKey = GlobalKey<DeveloperToolsPanelState>();
    devToolsKey.currentState?.addConsoleLog('log', args[0]);
  },
);

// Similar handlers for console.warn, console.error, etc.
```

## Features

### Console Tab

- Execute JavaScript commands
- View console output (logs, warnings, errors)
- Real-time logging from web pages

### Network Tab

- Monitor HTTP requests and responses
- Filter by request type (XHR, JS, CSS, Images)
- View request/response headers and timing

### Elements Tab

- DOM inspection (planned for future release)
- CSS style inspection (planned)
- Element manipulation (planned)

### Performance Tab

- Page load time metrics
- DOM content loaded time
- First paint timing
- Memory usage statistics
- Performance score calculation

## Usage Examples

### Basic Integration

```dart
class BrowserScreen extends StatefulWidget {
  @override
  _BrowserScreenState createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  bool _showDevTools = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Browser'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showDevTools = !_showDevTools),
            icon: Icon(Icons.developer_mode),
            tooltip: 'Developer Tools',
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(child: WebView(...)),
          if (_showDevTools)
            Container(
              width: 400,
              child: DeveloperToolsPanel(),
            ),
        ],
      ),
    );
  }
}
```

### Advanced Integration with State Management

```dart
class BrowserScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDevTools = ref.watch(devToolsVisibilityProvider);

    return Scaffold(
      body: Row(
        children: [
          Expanded(child: BrowserContent()),
          if (showDevTools)
            DeveloperToolsPanel(),
        ],
      ),
    );
  }
}
```

## Testing

To test the developer tools integration:

1. Navigate to `/dev-tools-demo` in the app
2. Click the "Show Dev Tools" button
3. The developer tools panel should appear on the right
4. Try executing JavaScript commands in the console
5. Check the network tab for any requests

## Future Enhancements

- DOM element inspection and manipulation
- CSS style debugging
- JavaScript debugging with breakpoints
- Network request/response interception
- Performance profiling and flame graphs
- Memory heap inspection
- Application cache and storage inspection

## Troubleshooting

### Panel Not Showing

- Ensure the `DeveloperToolsPanel` widget is properly imported
- Check that the visibility state is correctly managed
- Verify the layout constraints allow the panel to be displayed

### Console Not Working

- Ensure JavaScript handlers are properly registered on the WebView controller
- Check that the WebView allows JavaScript execution
- Verify console logging is enabled in WebView settings

### Performance Issues

- The developer tools panel can impact performance when visible
- Consider lazy loading the panel content
- Monitor memory usage when the panel is active

## API Reference

### DeveloperToolsPanel

```dart
const DeveloperToolsPanel({
  Key? key,
})
```

A stateful widget that provides the complete developer tools interface.

### DeveloperToolsPanelState

```dart
void addConsoleLog(String type, String message)
void addNetworkLog(Map<String, dynamic> request)
void clearLogs()
```

Methods for programmatically adding logs to the developer tools.

## Related Files

- `lib/widgets/developer_tools_panel.dart` - Main panel implementation
- `lib/widgets/dev_tools_toggle.dart` - Toggle button widget
- `lib/screens/dev_tools_demo_screen.dart` - Integration demo
- `lib/services/browser_engine_service.dart` - WebView integration
- `docs/WEB_API_IMPLEMENTATION_STATUS.md` - Web API documentation