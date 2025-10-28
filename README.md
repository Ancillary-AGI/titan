# Titan Browser

A full-featured cross-platform AI-powered browser built with Flutter that runs on Android, iOS, Windows, macOS, and Linux. Titan features intelligent AI agents that can autonomously perform complex browsing tasks, similar to Perplexity Comet and OpenAI Atlas, with full browser functionality including system integration, account management, and MCP server support.

## Features

### 🌐 Full-Featured Browser
- **Multi-platform support**: Android, iOS, Windows, macOS, Linux
- **Modern web engine**: Built on WebView with full JavaScript support
- **Tab management**: Multiple tabs with session persistence
- **Bookmarks & History**: Full browsing history and bookmark management
- **System integration**: Pin to taskbar, launch at startup, system tray
- **Import/Export**: Import from Chrome, Firefox, Safari, Edge, Opera, Brave

### 🤖 AI-Powered Assistance
- **Intelligent agents**: AI agents that can perform complex browsing tasks
- **Web search automation**: AI can search and navigate websites autonomously
- **Data extraction**: Extract structured data from web pages
- **Form filling**: Automatically fill out forms with AI assistance
- **Content summarization**: Get AI-generated summaries of web pages
- **Translation**: Real-time page translation to multiple languages

### 🎯 Smart Features
- **Natural language commands**: Tell the AI what you want to accomplish
- **Task automation**: Chain multiple actions together
- **Context awareness**: AI understands the current page context
- **Learning capabilities**: Improves performance over time
- **MCP Server**: Model Context Protocol server for AI agent integration
- **Account sync**: Cloud sync for bookmarks, history, and settings

## Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Platform-specific requirements:
  - **Android**: Android Studio, Android SDK
  - **iOS**: Xcode, iOS SDK
  - **Desktop**: Platform-specific build tools

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/titan-browser.git
   cd titan-browser
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure AI Services**
   - Get an OpenAI API key from [OpenAI](https://platform.openai.com/)
   - (Optional) Get an Anthropic API key from [Anthropic](https://console.anthropic.com/)
   - Add your keys in the app settings

### Running the App

#### Mobile (Android/iOS)
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

#### Desktop
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Architecture

### Core Components
- **Browser Engine**: WebView-based browsing with tab management
- **AI Service**: Integration with OpenAI and Anthropic APIs
- **Storage Service**: Local data persistence with Hive
- **State Management**: Riverpod for reactive state management
- **MCP Server**: Built-in Model Context Protocol server
- **Account Service**: Firebase-based user authentication and sync
- **System Integration**: Native OS integration and taskbar pinning
- **Import Service**: Browser data import from major browsers

### AI Agent Capabilities
- **Web Navigation**: Navigate to URLs, click elements, scroll pages
- **Data Extraction**: Extract text, images, and structured data
- **Form Interaction**: Fill forms, submit data, handle authentication
- **Content Analysis**: Summarize, translate, and analyze web content
- **Task Chaining**: Execute complex multi-step workflows

## Configuration

### AI API Keys
1. Open the app settings
2. Navigate to "AI Assistant" section
3. Enter your OpenAI API key (required)
4. Optionally enter Anthropic API key for Claude models

### Account Setup
1. Go to Account screen
2. Sign in with Google or create an email account
3. Enable sync for bookmarks, history, and settings
4. Import data from your existing browser

### System Integration
1. Pin Titan to your taskbar for quick access
2. Enable launch at startup in settings
3. MCP server runs automatically for AI agent integration

### Browser Settings
- **Home Page**: Set your preferred home page
- **Search Engine**: Choose default search engine
- **Privacy**: Configure history and data retention

## Usage Examples

### Basic Browsing
- Open new tabs with the "+" button
- Navigate using the address bar
- Bookmark pages for quick access
- View browsing history

### AI Assistant Commands
- **"Summarize this page"** - Get a concise summary
- **"Extract all email addresses"** - Find contact information
- **"Fill out this form with my details"** - Automate form completion
- **"Translate this page to Spanish"** - Real-time translation
- **"Find the best deals on this shopping site"** - Smart shopping assistance

### Advanced AI Tasks
- **Research workflows**: "Research the top 5 competitors for this company"
- **Data collection**: "Extract all product prices from this category"
- **Content creation**: "Summarize the key points from these 3 articles"

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Privacy & Security

- **Local Storage**: All browsing data is stored locally on your device
- **API Security**: AI API keys are stored securely and never shared
- **No Tracking**: We don't track your browsing habits
- **Open Source**: Full transparency with open source code

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Report bugs on [GitHub Issues](https://github.com/yourusername/ai-browser/issues)
- **Discussions**: Join our [GitHub Discussions](https://github.com/yourusername/ai-browser/discussions)
- **Documentation**: Visit our [Wiki](https://github.com/yourusername/ai-browser/wiki)

## Roadmap

- [ ] Voice commands for AI assistant
- [ ] Browser extensions support
- [ ] Collaborative browsing features
- [ ] Advanced privacy controls
- [ ] Custom AI model integration
- [ ] Offline AI capabilities

---

Built with ❤️ using Flutter and AI