import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

import '../providers/browser_provider.dart';
import '../providers/ai_provider.dart';
import '../widgets/browser_app_bar.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/ai_assistant_toggle.dart';
import '../widgets/developer_tools_panel.dart';
import '../services/storage_service.dart';
import '../services/browser_engine_service.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  InAppWebViewController? _webViewController;
  bool _showAIPanel = false;
  bool _showDevTools = false;
  final TextEditingController _urlController = TextEditingController();
  Map<String, dynamic>? _currentPageContext;
  final GlobalKey<_DeveloperToolsPanelState> _devToolsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    BrowserEngineService.init();
  }

  void _updateNavigationState() async {
    if (_webViewController == null) return;
    
    final canGoBack = await _webViewController!.canGoBack();
    final canGoForward = await _webViewController!.canGoForward();
    
    ref.read(browserProvider.notifier).setTabNavigationState(
      canGoBack: canGoBack,
      canGoForward: canGoForward,
    );
  }

  void _updatePageTitle() async {
    if (_webViewController == null) return;
    
    final title = await _webViewController!.getTitle();
    if (title != null) {
      ref.read(browserProvider.notifier).setTabTitle(title);
    }
  }

  void _updatePageContext() async {
    if (_webViewController == null) return;
    
    try {
      final result = await _webViewController!.evaluateJavascript(
        source: 'window.titanAI ? window.titanAI.getPageContext() : null'
      );
      
      if (result != null && result is Map) {
        setState(() {
          _currentPageContext = Map<String, dynamic>.from(result);
        });
      }
    } catch (e) {
      print('Failed to get page context: $e');
    }
  }

  void _navigateToUrl(String url) {
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('titan://')) {
      if (url.contains('.') && !url.contains(' ')) {
        formattedUrl = 'https://$url';
      } else {
        formattedUrl = '${StorageService.defaultSearchEngine}$url';
      }
    }
    
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(formattedUrl)));
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final activeTab = browserState.activeTab;

    return Scaffold(
      body: Column(
        children: [
          // Browser App Bar
          BrowserAppBar(
            urlController: _urlController,
            onNavigate: _navigateToUrl,
            onRefresh: () => _webViewController?.reload(),
            onBack: () => _webViewController?.goBack(),
            onForward: () => _webViewController?.goForward(),
            onToggleAI: () => setState(() => _showAIPanel = !_showAIPanel),
            onSettings: () => context.go('/settings'),
            onToggleDevTools: () => setState(() => _showDevTools = !_showDevTools),
          ),
          
          // Tab Bar
          TabBarWidget(
            tabs: browserState.tabs,
            activeIndex: browserState.activeTabIndex,
            onTabSelected: (index) {
              ref.read(browserProvider.notifier).switchToTab(index);
              if (index < browserState.tabs.length) {
                final tab = browserState.tabs[index];
                _urlController.text = tab.url;
                if (tab.url != 'about:blank') {
                  _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(tab.url)));
                }
              }
            },
            onTabClosed: (index) {
              ref.read(browserProvider.notifier).closeTab(index);
            },
            onNewTab: () {
              ref.read(browserProvider.notifier).addNewTab();
            },
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Web View and AI Panel Row
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          // Web View
                          Expanded(
                            flex: _showAIPanel ? 2 : 1,
                            child: activeTab != null
                                ? Stack(
                                    children: [
                                      InAppWebView(
                                        initialUrlRequest: URLRequest(
                                          url: WebUri(activeTab.url == 'about:blank' 
                                              ? 'titan://newtab' 
                                              : activeTab.url),
                                        ),
                                        initialSettings: BrowserEngineService.getWebViewSettings(),
                                        onWebViewCreated: (controller) {
                                          _webViewController = controller;
                                          BrowserEngineService.registerController(activeTab.id, controller);
                                          
                                          // Add JavaScript handlers
                                          controller.addJavaScriptHandler(
                                            handlerName: 'aiContextReady',
                                            callback: (args) {
                                              if (args.isNotEmpty) {
                                                setState(() {
                                                  _currentPageContext = Map<String, dynamic>.from(args[0]);
                                                });
                                              }
                                            },
                                          );
                                          
                                          controller.addJavaScriptHandler(
                                            handlerName: 'devConsoleLog',
                                            callback: (args) {
                                              _devToolsKey.currentState?.addConsoleLog('log', args[0].toString());
                                            },
                                          );
                                          
                                          controller.addJavaScriptHandler(
                                            handlerName: 'devConsoleError',
                                            callback: (args) {
                                              _devToolsKey.currentState?.addConsoleLog('error', args[0].toString());
                                            },
                                          );
                                          
                                          controller.addJavaScriptHandler(
                                            handlerName: 'devConsoleWarn',
                                            callback: (args) {
                                              _devToolsKey.currentState?.addConsoleLog('warn', args[0].toString());
                                            },
                                          );
                                        },
                                        onLoadStart: (controller, url) {
                                          ref.read(browserProvider.notifier).setTabLoading(true);
                                          if (url != null) {
                                            _urlController.text = url.toString();
                                          }
                                        },
                                        onLoadStop: (controller, url) async {
                                          ref.read(browserProvider.notifier).setTabLoading(false);
                                          _updateNavigationState();
                                          _updatePageTitle();
                                          
                                          // Inject AI context script
                                          await BrowserEngineService.injectAIContextScript(controller);
                                          _updatePageContext();
                                          
                                          // Add to history
                                          if (url != null && !url.toString().startsWith('titan://')) {
                                            final title = await controller.getTitle() ?? 'Untitled';
                                            StorageService.addToHistory(url.toString(), title);
                                          }
                                        },
                                        shouldOverrideUrlLoading: (controller, navigationAction) async {
                                          return NavigationActionPolicy.ALLOW;
                                        },
                                        shouldInterceptRequest: (controller, request) async {
                                          final response = await BrowserEngineService.shouldInterceptRequest(controller, request);
                                          
                                          // Log network request for dev tools
                                          _devToolsKey.currentState?.addNetworkLog({
                                            'url': request.url.toString(),
                                            'method': request.method,
                                            'timestamp': DateTime.now().toIso8601String(),
                                            'status': 200, // Would need actual status
                                          });
                                          
                                          return response;
                                        },
                                      ),
                                      if (activeTab.isLoading)
                                        const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    ],
                                  )
                                : const Center(
                                    child: Text('No active tab'),
                                  ),
                          ),
                        ],
                      ),
                      
                      // AI Assistant Toggle
                      AIAssistantToggle(
                        onToggle: () => setState(() => _showAIPanel = !_showAIPanel),
                        isVisible: _showAIPanel,
                      ),
                      
                      // AI Assistant Collapsible Pane
                      if (_showAIPanel)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: AIAssistantCollapsiblePane(
                            isVisible: _showAIPanel,
                            pageContext: _currentPageContext,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Developer Tools Panel
                if (_showDevTools)
                  DeveloperToolsPanel(key: _devToolsKey),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "devtools",
            mini: true,
            onPressed: () => setState(() => _showDevTools = !_showDevTools),
            child: Icon(_showDevTools ? Icons.close : Icons.developer_mode),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "ai",
            onPressed: () => setState(() => _showAIPanel = !_showAIPanel),
            child: Icon(_showAIPanel ? Icons.close : Icons.smart_toy),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}