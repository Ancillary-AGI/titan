import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../providers/browser_provider.dart';
import '../widgets/platform_adaptive.dart';
import '../widgets/tab_bar_widget.dart';
import '../services/storage_service.dart';
import '../services/browser_engine_service.dart';
import '../services/browser_bridge.dart';
import '../core/responsive.dart';
import '../core/platform_theme.dart';
import '../core/localization/app_localizations.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  final String? windowId;
  final bool isIncognito;
  
  const BrowserScreen({
    super.key,
    this.windowId,
    this.isIncognito = false,
  });

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  InAppWebViewController? _webViewController;
  bool _showAIPanel = false;
  final TextEditingController _urlController = TextEditingController();
  Map<String, dynamic>? _currentPageContext;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  void _initializeServices() async {
    await BrowserEngineService.init();
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

    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, browserState, activeTab),
      tablet: _buildTabletLayout(context, browserState, activeTab),
      desktop: _buildDesktopLayout(context, browserState, activeTab),
    );
  }

  Widget _buildMobileLayout(BuildContext context, browserState, activeTab) {
    return PlatformScaffold(
      body: Column(
        children: [
          // Browser App Bar
          _buildAppBar(context),
          
          // Tab Bar
          TabBarWidget(
            tabs: browserState.tabs,
            activeIndex: browserState.activeTabIndex,
            onTabSelected: _handleTabSelected,
            onTabClosed: (index) => ref.read(browserProvider.notifier).closeTab(index),
            onNewTab: () => ref.read(browserProvider.notifier).addNewTab(),
          ),
          
          // Web View
          Expanded(
            child: _buildWebView(context, activeTab),
          ),
        ],
      ),
      bottomNavigationBar: _buildMobileBottomNav(context),
    );
  }

  Widget _buildTabletLayout(BuildContext context, browserState, activeTab) {
    return PlatformScaffold(
      body: Column(
        children: [
          _buildAppBar(context),
          TabBarWidget(
            tabs: browserState.tabs,
            activeIndex: browserState.activeTabIndex,
            onTabSelected: _handleTabSelected,
            onTabClosed: (index) => ref.read(browserProvider.notifier).closeTab(index),
            onNewTab: () => ref.read(browserProvider.notifier).addNewTab(),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: _showAIPanel ? 2 : 1,
                  child: _buildWebView(context, activeTab),
                ),
                if (_showAIPanel)
                  SizedBox(
                    width: 400,
                    child: Container(
                      color: PlatformColors(context).surface,
                      child: const Center(child: Text('AI Assistant Panel')),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, browserState, activeTab) {
    return PlatformScaffold(
      body: Column(
        children: [
          _buildAppBar(context),
          TabBarWidget(
            tabs: browserState.tabs,
            activeIndex: browserState.activeTabIndex,
            onTabSelected: _handleTabSelected,
            onTabClosed: (index) => ref.read(browserProvider.notifier).closeTab(index),
            onNewTab: () => ref.read(browserProvider.notifier).addNewTab(),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: _showAIPanel ? 3 : 1,
                  child: _buildWebView(context, activeTab),
                ),
                if (_showAIPanel)
                  SizedBox(
                    width: 350,
                    child: Container(
                      color: PlatformColors(context).surface,
                      child: const Center(child: Text('AI Assistant Panel')),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final activeTab = browserState.activeTab;
    final l10n = context.l10n;
    final isCompact = Responsive.isMobile(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? PlatformTheme.spaceSm : PlatformTheme.spaceMd,
        vertical: PlatformTheme.spaceSm,
      ),
      decoration: BoxDecoration(
        color: PlatformColors(context).surface,
        border: Border(
          bottom: BorderSide(
            color: PlatformColors(context).onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Navigation buttons
            if (!isCompact || Responsive.isLandscape(context)) ...[
              PlatformIconButton(
                onPressed: activeTab?.canGoBack == true 
                    ? () => _webViewController?.goBack() 
                    : null,
                icon: PlatformTheme.isCupertinoPlatform 
                    ? CupertinoIcons.back 
                    : Icons.arrow_back,
                tooltip: l10n.back,
              ),
              PlatformIconButton(
                onPressed: activeTab?.canGoForward == true 
                    ? () => _webViewController?.goForward() 
                    : null,
                icon: PlatformTheme.isCupertinoPlatform 
                    ? CupertinoIcons.forward 
                    : Icons.arrow_forward,
                tooltip: l10n.forward,
              ),
            ],
            PlatformIconButton(
              onPressed: () => _webViewController?.reload(),
              icon: PlatformTheme.isCupertinoPlatform 
                  ? CupertinoIcons.refresh 
                  : Icons.refresh,
              tooltip: l10n.refresh,
            ),
            
            SizedBox(width: isCompact ? PlatformTheme.spaceSm : PlatformTheme.spaceMd),
            
            // URL bar
            Expanded(
              child: PlatformTextField(
                controller: _urlController,
                placeholder: l10n.searchOrEnterUrl,
                onSubmitted: _navigateToUrl,
                prefix: Padding(
                  padding: EdgeInsets.all(PlatformTheme.spaceSm),
                  child: Icon(
                    _getSecurityIcon(activeTab?.url),
                    size: 18,
                    color: _getSecurityColor(activeTab?.url, context),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: isCompact ? PlatformTheme.spaceSm : PlatformTheme.spaceMd),
            
            // AI toggle (hide on very small screens in portrait)
            if (!isCompact || Responsive.isLandscape(context))
              PlatformIconButton(
                onPressed: () => setState(() => _showAIPanel = !_showAIPanel),
                icon: PlatformTheme.isCupertinoPlatform 
                    ? CupertinoIcons.sparkles 
                    : Icons.smart_toy,
                tooltip: l10n.aiAssistant,
              ),
            
            // Menu
            PlatformIconButton(
              onPressed: () => _showMenu(context),
              icon: PlatformTheme.isCupertinoPlatform 
                  ? CupertinoIcons.ellipsis 
                  : Icons.more_vert,
              tooltip: l10n.menu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView(BuildContext context, activeTab) {
    final l10n = context.l10n;
    
    if (activeTab == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformTheme.isCupertinoPlatform 
                  ? CupertinoIcons.globe 
                  : Icons.web,
              size: Responsive.getValue(context, mobile: 48.0, tablet: 56.0, desktop: 64.0),
              color: PlatformColors(context).onSurface.withOpacity(0.5),
            ),
            SizedBox(height: PlatformTheme.spaceMd),
            Text(
              l10n.noActiveTab,
              style: TextStyle(
                fontSize: Responsive.getValue(context, mobile: 16.0, tablet: 17.0, desktop: 18.0),
                color: PlatformColors(context).onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: PlatformTheme.spaceSm),
            PlatformButton(
              onPressed: () => ref.read(browserProvider.notifier).addNewTab(),
              child: Text(l10n.newTab),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(activeTab.url == 'about:blank' 
                ? 'https://www.google.com' 
                : activeTab.url),
          ),
          initialSettings: BrowserEngineService.getWebViewSettings(),
          onWebViewCreated: (controller) => _setupWebViewController(controller, activeTab),
          onLoadStart: (controller, url) => _handleLoadStart(controller, url),
          onLoadStop: (controller, url) => _handleLoadStop(controller, url),
        ),
        
        if (activeTab.isLoading)
          Container(
            color: PlatformColors(context).background.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PlatformProgressIndicator(),
                  SizedBox(height: PlatformTheme.spaceMd),
                  Text(
                    context.l10n.loading,
                    style: TextStyle(
                      color: PlatformColors(context).onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    final l10n = context.l10n;
    
    return Container(
      decoration: BoxDecoration(
        color: PlatformColors(context).surface,
        border: Border(
          top: BorderSide(
            color: PlatformColors(context).onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PlatformTheme.spaceMd,
            vertical: PlatformTheme.spaceSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PlatformIconButton(
                onPressed: () {},
                icon: PlatformTheme.isCupertinoPlatform 
                    ? CupertinoIcons.bookmark 
                    : Icons.bookmark,
                tooltip: l10n.bookmarks,
              ),
              PlatformIconButton(
                onPressed: () {},
                icon: PlatformTheme.isCupertinoPlatform 
                    ? CupertinoIcons.time 
                    : Icons.history,
                tooltip: l10n.history,
              ),
              PlatformIconButton(
                onPressed: () => setState(() => _showAIPanel = !_showAIPanel),
                icon: PlatformTheme.isCupertinoPlatform 
                    ? CupertinoIcons.sparkles 
                    : Icons.smart_toy,
                tooltip: l10n.aiAssistant,
              ),
              PlatformIconButton(
                onPressed: () {},
                icon: PlatformTheme.isCupertinoPlatform 
                    ? CupertinoIcons.settings 
                    : Icons.settings,
                tooltip: l10n.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTabSelected(int index) {
    ref.read(browserProvider.notifier).switchToTab(index);
    final browserState = ref.read(browserProvider);
    if (index < browserState.tabs.length) {
      final tab = browserState.tabs[index];
      _urlController.text = tab.url;
      if (tab.url != 'about:blank') {
        _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(tab.url)));
      }
    }
  }

  void _setupWebViewController(InAppWebViewController controller, activeTab) {
    _webViewController = controller;
    BrowserEngineService.registerController(activeTab.id, controller);

    // Wire BrowserBridge
    BrowserBridge.navigateToUrl = (String url) async {
      _navigateToUrl(url);
      return 'Navigated to: $url';
    };
    
    BrowserBridge.getPageContent = () async {
      final js = "document.documentElement.outerHTML";
      final res = await _webViewController?.evaluateJavascript(source: js);
      return res?.toString() ?? '';
    };
    
    BrowserBridge.getCurrentTab = () async {
      final t = ref.read(browserProvider).activeTab;
      if (t == null) return null;
      return {
        'id': t.id,
        'title': t.title,
        'url': t.url,
        'isLoading': t.isLoading,
      };
    };
  }

  void _handleLoadStart(InAppWebViewController controller, WebUri? url) {
    ref.read(browserProvider.notifier).setTabLoading(true);
    if (url != null) {
      _urlController.text = url.toString();
    }
  }

  Future<void> _handleLoadStop(InAppWebViewController controller, WebUri? url) async {
    ref.read(browserProvider.notifier).setTabLoading(false);
    _updateNavigationState();
    _updatePageTitle();
    
    if (url != null && !url.toString().startsWith('titan://')) {
      final current = ref.read(browserProvider).activeTab;
      if (current == null || !current.incognito) {
        final title = await controller.getTitle() ?? 'Untitled';
        StorageService.addToHistory(url.toString(), title);
      }
    }
  }

  IconData _getSecurityIcon(String? url) {
    if (url == null) {
      return PlatformTheme.isCupertinoPlatform 
          ? CupertinoIcons.search 
          : Icons.search;
    }
    if (url.startsWith('https://')) {
      return PlatformTheme.isCupertinoPlatform 
          ? CupertinoIcons.lock_fill 
          : Icons.lock;
    }
    if (url.startsWith('http://')) {
      return PlatformTheme.isCupertinoPlatform 
          ? CupertinoIcons.info_circle 
          : Icons.info_outline;
    }
    return PlatformTheme.isCupertinoPlatform 
        ? CupertinoIcons.search 
        : Icons.search;
  }

  Color _getSecurityColor(String? url, BuildContext context) {
    if (url == null) return PlatformColors(context).onSurface;
    if (url.startsWith('https://')) {
      return PlatformTheme.isCupertinoPlatform 
          ? CupertinoColors.systemGreen 
          : Colors.green;
    }
    if (url.startsWith('http://')) {
      return PlatformTheme.isCupertinoPlatform 
          ? CupertinoColors.systemOrange 
          : Colors.orange;
    }
    return PlatformColors(context).onSurface;
  }
  
  void _showMenu(BuildContext context) {
    final l10n = context.l10n;
    
    if (PlatformTheme.isCupertinoPlatform) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.bookmarks),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.history),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.downloads),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.settings),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                ref.read(browserProvider.notifier).addNewTab(incognito: true);
              },
              child: Text(l10n.newIncognitoWindow),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(PlatformTheme.radiusLg),
          ),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text(l10n.bookmarks),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(l10n.history),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(l10n.downloads),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l10n.settings),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: Text(l10n.newIncognitoWindow),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(browserProvider.notifier).addNewTab(incognito: true);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
