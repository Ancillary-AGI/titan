# Web API Testing Guide

This guide explains how to test the implemented Web APIs in Titan Browser.

## Quick Start

1. **Launch Titan Browser**
2. **Navigate to the test page**: `file:///path/to/assets/test_web_apis.html`
3. **Click the test buttons** to verify each API works correctly

## Implemented APIs

### ✅ Clipboard API

**What it does**: Integrates with the system clipboard for copy/paste operations.

**How to test**:
```javascript
// Write to clipboard
await navigator.clipboard.writeText('Hello World');

// Read from clipboard
const text = await navigator.clipboard.readText();
console.log(text);
```

**Expected behavior**:
- Text should be copied to system clipboard
- You can paste it in other applications
- Reading should return the current clipboard content

---

### ✅ Web Share API

**What it does**: Opens the native sharing dialog to share content.

**How to test**:
```javascript
await navigator.share({
  title: 'My Title',
  text: 'Check this out!',
  url: 'https://example.com'
});
```

**Expected behavior**:
- Native share dialog appears
- Can share to installed apps (email, messaging, etc.)
- Works on all platforms

---

### ✅ Geolocation API

**What it does**: Provides access to GPS/location services.

**How to test**:
```javascript
// Get current position
navigator.geolocation.getCurrentPosition(
  (position) => {
    console.log('Lat:', position.coords.latitude);
    console.log('Lng:', position.coords.longitude);
  },
  (error) => console.error(error)
);

// Watch position changes
const watchId = navigator.geolocation.watchPosition(
  (position) => console.log('Position update:', position.coords),
  (error) => console.error(error)
);

// Stop watching
navigator.geolocation.clearWatch(watchId);
```

**Expected behavior**:
- Permission dialog appears on first use
- Returns accurate GPS coordinates
- Watch position updates as device moves
- Requires location permission

---

### ✅ Notifications API

**What it does**: Shows system notifications.

**How to test**:
```javascript
// Request permission
const permission = await Notification.requestPermission();

// Show notification
if (permission === 'granted') {
  new Notification('Hello!', {
    body: 'This is a notification',
    icon: 'https://example.com/icon.png'
  });
}
```

**Expected behavior**:
- Permission dialog appears on first use
- System notification appears
- Notification shows in system tray/notification center
- Requires notification permission

---

### ✅ Vibration API

**What it does**: Triggers haptic feedback on mobile devices.

**How to test**:
```javascript
// Single vibration
navigator.vibrate(200); // 200ms

// Pattern: vibrate, pause, vibrate
navigator.vibrate([100, 50, 100, 50, 200]);

// Cancel vibration
navigator.vibrate(0);
```

**Expected behavior**:
- Device vibrates on mobile
- No effect on desktop (gracefully ignored)
- Pattern creates rhythm of vibrations

---

### ✅ Console Forwarding

**What it does**: Forwards all console messages to Flutter/DevTools.

**How to test**:
```javascript
console.log('Debug message');
console.warn('Warning message');
console.error('Error message');
console.info('Info message');
```

**Expected behavior**:
- Messages appear in Titan Browser DevTools
- Messages logged in Flutter console
- Useful for debugging web content

---

## Built-in WebView APIs

These APIs work automatically via `flutter_inappwebview`:

### localStorage / sessionStorage
```javascript
localStorage.setItem('key', 'value');
const value = localStorage.getItem('key');
```

### Fetch API
```javascript
const response = await fetch('https://api.example.com/data');
const data = await response.json();
```

### WebSocket
```javascript
const ws = new WebSocket('wss://echo.websocket.org');
ws.onmessage = (event) => console.log(event.data);
ws.send('Hello');
```

### IndexedDB
```javascript
const request = indexedDB.open('myDatabase', 1);
request.onsuccess = (event) => {
  const db = event.target.result;
  // Use database
};
```

### Service Workers
```javascript
navigator.serviceWorker.register('/sw.js');
```

### Web Workers
```javascript
const worker = new Worker('worker.js');
worker.postMessage('Hello');
```

---

## Testing Checklist

Use this checklist when testing Web APIs:

- [ ] **Clipboard API**
  - [ ] Write text to clipboard
  - [ ] Read text from clipboard
  - [ ] Verify text appears in other apps
  
- [ ] **Web Share API**
  - [ ] Share with title, text, and URL
  - [ ] Native share dialog appears
  - [ ] Can share to installed apps
  
- [ ] **Geolocation API**
  - [ ] Permission dialog appears
  - [ ] Returns accurate coordinates
  - [ ] Watch position updates
  - [ ] Clear watch stops updates
  
- [ ] **Notifications API**
  - [ ] Permission dialog appears
  - [ ] Notification shows in system
  - [ ] Notification has correct title/body
  - [ ] Click handler works
  
- [ ] **Vibration API**
  - [ ] Single vibration works on mobile
  - [ ] Pattern vibration works
  - [ ] Gracefully ignored on desktop
  
- [ ] **Console Forwarding**
  - [ ] console.log appears in DevTools
  - [ ] console.warn appears in DevTools
  - [ ] console.error appears in DevTools

---

## Troubleshooting

### Clipboard API not working
- **Issue**: Permission denied
- **Solution**: Ensure page is served over HTTPS or localhost

### Geolocation API not working
- **Issue**: Location permission denied
- **Solution**: Grant location permission in system settings

### Notifications API not working
- **Issue**: Notification permission denied
- **Solution**: Grant notification permission in system settings

### Vibration API not working
- **Issue**: No vibration on device
- **Solution**: Check if device supports vibration (mobile only)

---

## Adding New APIs

To add a new Web API implementation:

1. **Add native implementation** in `lib/services/web_apis/implemented_apis.dart`:
```dart
controller.addJavaScriptHandler(
  handlerName: 'my_new_api',
  callback: (args) async {
    // Your implementation
    return 'success';
  },
);
```

2. **Inject JavaScript bindings** in `_injectAPIs()`:
```dart
await controller.evaluateJavascript(source: '''
  window.myNewAPI = {
    doSomething: async function() {
      return await window.flutter_inappwebview
        .callHandler('my_new_api');
    }
  };
''');
```

3. **Add tests** to `assets/test_web_apis.html`

4. **Update documentation** in README.md and this guide

---

## Platform-Specific Notes

### Android
- All APIs work as expected
- Requires appropriate permissions in AndroidManifest.xml
- Vibration requires VIBRATE permission

### iOS
- All APIs work as expected
- Requires appropriate permissions in Info.plist
- Location requires NSLocationWhenInUseUsageDescription

### Windows/macOS/Linux
- Clipboard, Share, Notifications work
- Geolocation may require additional setup
- Vibration is gracefully ignored

---

## Performance Considerations

- **Clipboard**: Fast, synchronous operations
- **Web Share**: Native dialog, no performance impact
- **Geolocation**: Can be slow, use timeout parameter
- **Notifications**: Lightweight, no performance impact
- **Vibration**: Instant, no performance impact
- **Console Forwarding**: Minimal overhead

---

## Security Considerations

- **Clipboard**: Requires user interaction or permission
- **Web Share**: User must confirm share action
- **Geolocation**: Requires explicit permission
- **Notifications**: Requires explicit permission
- **Vibration**: No permission required
- **Console Forwarding**: No security concerns

---

## Resources

- [MDN Web APIs](https://developer.mozilla.org/en-US/docs/Web/API)
- [Flutter InAppWebView](https://inappwebview.dev/)
- [Titan Browser README](../README.md)
