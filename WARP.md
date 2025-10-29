# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common commands

- Install deps
  ```bash path=null start=null
  flutter pub get
  ```
- Run (choose a device)
  ```bash path=null start=null
  # List devices
  flutter devices
  # Examples
  flutter run -d windows
  flutter run -d android
  flutter run -d ios
  flutter run -d macos
  flutter run -d linux
  ```
- Build release
  ```bash path=null start=null
  # Android
  flutter build apk --release
  flutter build appbundle --release
  # iOS (build via Xcode signing as needed)
  flutter build ios --release
  # Desktop
  flutter build windows --release
  flutter build macos --release
  flutter build linux --release
  ```
- Lint and format
  ```bash path=null start=null
  flutter analyze
  dart format .
  ```
- Tests
  ```bash path=null start=null
  # Run all tests
  flutter test
  # Run a single file
  flutter test test/some_test.dart
  # Run by test name substring
  flutter test --plain-name "substring of test name"
  ```
- MCP server health check (desktop builds auto-start the local server)
  ```bash path=null start=null
  curl http://localhost:8080/health
  ```

## High-level architecture

- Entry point and bootstrap
  - `lib/main.dart` initializes Firebase, Hive, local storage, AI service, account service, desktop window manager, and starts the local MCP server on desktop before launching the app with Riverpod and GoRouter.
- Routing
  - `lib/core/app_router.dart` provides a `GoRouter` with named routes for browser (`/browser`), AI assistant (`/ai-assistant`), bookmarks, history, settings, and account screens.
- UI layers
  - Screens: `lib/screens/*.dart` (e.g., `browser_screen.dart`) compose the main views.
  - Widgets: `lib/widgets/*.dart` (e.g., `browser_app_bar.dart`, `tab_bar_widget.dart`, `ai_assistant_panel.dart`).
  - Theme: `lib/core/theme.dart` defines light/dark themes.
- State management (Riverpod)
  - `lib/providers/browser_provider.dart`: tab list, active tab, navigation/loading state, and history writes.
  - `lib/providers/ai_provider.dart`: AI task queue/state, create/execute/cancel/retry flows.
- Domain models
  - `lib/models/browser_tab.dart`: tab metadata (URL, title, nav state, timestamps).
  - `lib/models/ai_task.dart`: task type/status, parameters, progress, results.
- Persistence
  - `lib/services/storage_service.dart` uses Hive boxes for tabs/history/bookmarks/tasks and SharedPreferences for settings (keys include `search_engine`, `home_page`, `ai_assistant_enabled`, `openai_key`, `anthropic_key`).
- Browser engine integration
  - `lib/screens/browser_screen.dart` uses `webview_flutter` with a `WebViewController` and a `NavigationDelegate` to:
    - Update tab state (loading/title/nav-capabilities) via `browserProvider`.
    - Normalize input into URL vs. search using `StorageService.defaultSearchEngine`.
- AI integration
  - `lib/services/ai_service.dart` provides `generateResponse` via the OpenAI Chat Completions API and higher-level helpers (summarize/translate/suggestions).
  - `aiProvider` builds prompts per task, calls `AIService.executeWebTask`, persists updates via `StorageService`.
  - API keys are expected to be set via the app’s settings and stored in SharedPreferences; `AIService.setOpenAIKey` / `setAnthropicKey` are available.
- Local MCP server (Model Context Protocol)
  - `lib/services/mcp_server.dart` starts a Shelf HTTP server on `localhost:8080` (desktop only) and exposes:
    - Capabilities: `GET /mcp/capabilities`
    - Tools: `POST /mcp/tools/list`, `POST /mcp/tools/call`
    - Resources: `POST /mcp/resources/list`, `POST /mcp/resources/read`
    - Realtime: `GET /ws` WebSocket endpoint
    - Health: `GET /health`
  - Tool implementations are currently placeholders intended to integrate with browser/provider state.
- System and account services
  - `lib/services/system_integration_service.dart` (desktop niceties like tray/startup) and `lib/services/account_service.dart` (Firebase auth) are initialized in `main.dart`.

## Notes for agents

- Prefer using `flutter` CLI for all build/run/test/analyze operations.
- Desktop runs auto-start the MCP server; mobile runs do not. Test MCP endpoints only when running on desktop.
- When adding tests, create a `test/` directory and use `flutter test` with file or name filters as shown above.
- Keys for AI providers are read from SharedPreferences; avoid hardcoding in source and prefer using the in-app settings flow.
