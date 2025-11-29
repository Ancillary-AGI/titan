# Changelog

All notable changes to Titan Browser will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **📱 Screen Orientation API**: Implemented screen orientation lock/unlock functionality
  - `screen.orientation.lock()` - Lock screen to specific orientation
  - `screen.orientation.unlock()` - Unlock screen orientation
  - `screen.orientation.type` - Get current orientation type and angle
  - Uses Flutter's SystemChrome for native orientation control

### Changed
- 🔌 **Web API Implementation Overhaul**: Replaced stub implementations with real, functional Web APIs
  - Implemented actual Clipboard API with system clipboard integration
  - Implemented Web Share API with native sharing dialog
  - Implemented Notifications API with real system notifications
  - Implemented Geolocation API with GPS/location services
  - Implemented Vibration API with haptic feedback
  - Implemented Console Forwarding to DevTools
  - Removed non-functional stub files (web_api_bridge.dart, dom_apis.dart, storage_apis.dart, network_apis.dart)
  - Updated browser_engine_service.dart to use implemented_apis.dart
- 📝 **Documentation Updates**: Updated README with honest implementation status
  - Clearly documented which APIs are actually implemented
  - Documented which APIs work via built-in WebView support
  - Added usage examples for all implemented APIs
  - Added guide for adding new Web API implementations

### Added
- 🧪 **Web API Test Page**: Created comprehensive test page (assets/test_web_apis.html)
  - Interactive tests for all implemented APIs
  - Visual feedback for success/error states
  - Tests for built-in WebView APIs (localStorage, Fetch, WebSocket)
  - Developer-friendly interface for API validation

## [1.0.0] - 2024-12-28

### Added
- 🚀 **Initial Release of Titan Browser**
- 🌐 **Cross-Platform Support**: Android, iOS, Windows, macOS, Linux
- 🤖 **AI-Powered Browsing**: OpenAI and Anthropic integration
- 🛠️ **Professional Developer Tools**: Console, Network, Elements, Performance tabs
- 🎯 **Intelligent AI Assistant**: Context-aware AI with Ask and Agent modes
- 📱 **Modern Browser Engine**: Flutter InAppWebView with Chromium backend
- 🔒 **Security Features**: Ad blocking, HTTPS indicators, privacy controls
- 🎨 **Beautiful UI**: Material Design 3 with dark/light themes
- 📊 **Tab Management**: Multiple tabs with session persistence
- 🔖 **Bookmarks & History**: Full browsing history and bookmark management
- 👤 **Account System**: Firebase authentication with Google Sign-In
- ☁️ **Cloud Sync**: Sync bookmarks, history, and settings across devices
- 📥 **Browser Import**: Import data from Chrome, Firefox, Safari, Edge, Opera, Brave
- 🖥️ **System Integration**: Pin to taskbar, launch at startup, system tray
- 🌐 **MCP Server**: Model Context Protocol server for AI agent integration
- 🎛️ **Custom Protocols**: titan:// protocol for internal pages
- 🚫 **Ad Blocking**: Built-in ad blocker with configurable domains
- 🔧 **Network Interception**: Request/response monitoring and modification
- 📱 **Responsive Design**: Adaptive UI for all screen sizes
- ♿ **Accessibility**: Full accessibility support and screen reader compatibility

### Technical Features
- **Browser Engine**: Complete WebView integration with JavaScript support
- **AI Context**: Automatic page context extraction for AI assistance
- **Developer Tools**: Professional debugging and monitoring tools
- **Network Stack**: Custom request interception and caching
- **State Management**: Riverpod for reactive state management
- **Storage**: Hive for efficient local data persistence
- **Authentication**: Firebase Auth with multiple sign-in methods
- **Import/Export**: Comprehensive browser data migration tools

### Platforms Supported
- **Android**: Native Android app with full browser functionality
- **iOS**: Native iOS app with Safari-like experience
- **Windows**: Desktop app with taskbar integration
- **macOS**: Native macOS app with dock integration
- **Linux**: Desktop app with system integration

### AI Capabilities
- **Ask Mode**: Conversational AI about current page content
- **Agent Mode**: Autonomous task execution on web pages
- **Page Context**: Automatic extraction of page title, URL, content, forms, links
- **Quick Actions**: One-click summarize, extract data, find links, fill forms
- **Task Management**: Create, monitor, and manage AI tasks
- **Multi-Model Support**: OpenAI GPT and Anthropic Claude integration