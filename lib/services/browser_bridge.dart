// A simple bridge to allow non-UI services (like MCPServer) to trigger
// actions on the active WebView and access browser state without holding
// Flutter context or Riverpod refs directly.

class BrowserBridge {
  // Navigation and interactions
  static Future<String> Function(String url)? navigateToUrl;
  static Future<String> Function(String selector)? clickElement;
  static Future<String> Function(String selector, {String? attribute})?
      extract;
  static Future<String> Function(Map<String, dynamic> fields)? fillForm;
  static Future<String> Function()? getPageContent;

  // State queries
  static Future<List<Map<String, dynamic>>> Function()? getTabsInfo;
  static Future<Map<String, dynamic>?> Function()? getCurrentTab;
}
