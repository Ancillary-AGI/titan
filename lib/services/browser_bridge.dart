/// Browser Bridge Service - Provides programmatic access to browser functionality
/// This service acts as a bridge between the browser engine and external tools/extensions
class BrowserBridge {
  // Navigation functions
  static Future<String> Function(String url)? navigateToUrl;
  
  // Element interaction functions
  static Future<String> Function(String selector)? clickElement;
  static Future<String> Function(String selector, {String? attribute})? extract;
  static Future<String> Function(Map<String, dynamic> fields)? fillForm;
  
  // Content access functions
  static Future<String> Function()? getPageContent;
  
  // Tab management functions
  static Future<List<Map<String, dynamic>>> Function()? getTabsInfo;
  static Future<Map<String, dynamic>?> Function()? getCurrentTab;
  
  /// Navigate to a URL
  static Future<String> navigate(String url) async {
    if (navigateToUrl != null) {
      return await navigateToUrl!(url);
    }
    return 'Navigation function not available';
  }
  
  /// Click an element by selector
  static Future<String> click(String selector) async {
    if (clickElement != null) {
      return await clickElement!(selector);
    }
    return 'Click function not available';
  }
  
  /// Extract content from an element
  static Future<String> extractContent(String selector, {String? attribute}) async {
    if (extract != null) {
      return await extract!(selector, attribute: attribute);
    }
    return 'Extract function not available';
  }
  
  /// Fill form fields
  static Future<String> fillFormFields(Map<String, dynamic> fields) async {
    if (fillForm != null) {
      return await fillForm!(fields);
    }
    return 'Fill form function not available';
  }
  
  /// Get page content
  static Future<String> getContent() async {
    if (getPageContent != null) {
      return await getPageContent!();
    }
    return 'Get content function not available';
  }
  
  /// Get information about all tabs
  static Future<List<Map<String, dynamic>>> getTabs() async {
    if (getTabsInfo != null) {
      return await getTabsInfo!();
    }
    return [];
  }
  
  /// Get information about the current tab
  static Future<Map<String, dynamic>?> getActiveTab() async {
    if (getCurrentTab != null) {
      return await getCurrentTab!();
    }
    return null;
  }
}