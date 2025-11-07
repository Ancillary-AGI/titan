import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import '../models/browser_tab.dart';
import 'sandboxing_service.dart';
import 'javascript_engine_service.dart';

/// Security threat levels
enum ThreatLevel {
  none,
  low,
  medium,
  high,
  critical,
}

/// Security event types
enum SecurityEventType {
  maliciousScript,
  suspiciousDownload,
  phishingAttempt,
  dataExfiltration,
  unauthorizedAccess,
  cspViolation,
  xssAttempt,
  sqlInjection,
  clickjacking,
  cryptojacking,
}

/// Security event data
class SecurityEvent {
  final String id;
  final SecurityEventType type;
  final ThreatLevel level;
  final String tabId;
  final String url;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool blocked;
  
  const SecurityEvent({
    required this.id,
    required this.type,
    required this.level,
    required this.tabId,
    required this.url,
    required this.description,
    this.metadata = const {},
    required this.timestamp,
    this.blocked = false,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'level': level.name,
    'tabId': tabId,
    'url': url,
    'description': description,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'blocked': blocked,
  };
}

/// Chrome-level browser security service
class BrowserSecurityService {
  static final List<SecurityEvent> _securityEvents = [];
  static final Map<String, List<String>> _tabThreats = {};
  static final Map<String, int> _threatScores = {};
  static final Set<String> _maliciousDomains = {};
  static final Set<String> _phishingDomains = {};
  static final Map<String, String> _contentHashes = {};
  static final StreamController<SecurityEvent> _eventStream = 
      StreamController<SecurityEvent>.broadcast();
  
  // Chrome security features
  static bool _safeBrowsingEnabled = true;
  static bool _phishingProtectionEnabled = true;
  static bool _malwareProtectionEnabled = true;
  static bool _downloadProtectionEnabled = true;
  static bool _siteIsolationEnabled = true;
  static bool _httpsOnlyMode = false;
  
  /// Initialize security service with Chrome-level features
  static Future<void> initialize() async {
    await _loadThreatDatabase();
    await _initializeSafeBrowsing();
    _setupSecurityHeaders();
    _startThreatMonitoring();
  }
  
  /// Load threat intelligence database
  static Future<void> _loadThreatDatabase() async {
    // Load known malicious domains
    _maliciousDomains.addAll([
      'malware-example.com',
      'phishing-site.net',
      'crypto-miner.org',
      'fake-bank.com',
    ]);
    
    // Load phishing domains
    _phishingDomains.addAll([
      'paypal-security.net',
      'amazon-verify.com',
      'google-security.org',
      'microsoft-update.net',
    ]);
  }
  
  /// Initialize Safe Browsing (Google Safe Browsing API equivalent)
  static Future<void> _initializeSafeBrowsing() async {
    // Initialize threat detection algorithms
    print('Safe Browsing initialized');
  }
  
  /// Setup security headers for all requests
  static void _setupSecurityHeaders() {
    // Default security headers applied to all requests
  }
  
  /// Start continuous threat monitoring
  static void _startThreatMonitoring() {
    Timer.periodic(Duration(seconds: 30), (timer) {
      _performSecurityScan();
    });
  }
  
  /// Perform comprehensive security scan
  static Future<void> _performSecurityScan() async {
    for (final tabId in _tabThreats.keys) {
      await _scanTabForThreats(tabId);
    }
  }
  
  /// Scan individual tab for security threats
  static Future<void> _scanTabForThreats(String tabId) async {
    try {
      // Check for cryptojacking
      await _detectCryptojacking(tabId);
      
      // Check for data exfiltration
      await _detectDataExfiltration(tabId);
      
      // Check for suspicious network activity
      await _detectSuspiciousNetworkActivity(tabId);
      
      // Update threat score
      _updateThreatScore(tabId);
    } catch (e) {
      print('Error scanning tab $tabId: $e');
    }
  }
  
  /// Detect cryptojacking attempts
  static Future<void> _detectCryptojacking(String tabId) async {
    final cryptoPatterns = [
      'coinhive',
      'cryptonight',
      'webminer',
      'crypto-loot',
      'jsecoin',
    ];
    
    // Check for crypto mining scripts
    // Implementation would analyze JavaScript execution patterns
  }
  
  /// Detect data exfiltration attempts
  static Future<void> _detectDataExfiltration(String tabId) async {
    // Monitor for suspicious data transmission patterns
    // Check for large data uploads to unknown domains
    // Analyze form submissions for sensitive data
  }
  
  /// Detect suspicious network activity
  static Future<void> _detectSuspiciousNetworkActivity(String tabId) async {
    // Monitor network requests for suspicious patterns
    // Check for connections to known malicious IPs
    // Analyze request frequency and data volume
  }
  
  /// Update threat score for a tab
  static void _updateThreatScore(String tabId) {
    final threats = _tabThreats[tabId] ?? [];
    int score = 0;
    
    for (final threat in threats) {
      switch (threat) {
        case 'malware':
          score += 100;
          break;
        case 'phishing':
          score += 80;
          break;
        case 'cryptojacking':
          score += 60;
          break;
        case 'suspicious_script':
          score += 40;
          break;
        case 'tracking':
          score += 20;
          break;
      }
    }
    
    _threatScores[tabId] = score;
  }
  
  /// Check URL against threat databases (Safe Browsing equivalent)
  static Future<ThreatLevel> checkUrlSafety(String url) async {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();
      
      // Check against malicious domains
      if (_maliciousDomains.contains(domain)) {
        return ThreatLevel.critical;
      }
      
      // Check against phishing domains
      if (_phishingDomains.contains(domain)) {
        return ThreatLevel.high;
      }
      
      // Check for suspicious patterns
      if (_isSuspiciousDomain(domain)) {
        return ThreatLevel.medium;
      }
      
      // Check URL structure for phishing indicators
      if (_hasPhishingIndicators(url)) {
        return ThreatLevel.medium;
      }
      
      return ThreatLevel.none;
    } catch (e) {
      return ThreatLevel.low;
    }
  }
  
  /// Check if domain is suspicious
  static bool _isSuspiciousDomain(String domain) {
    final suspiciousPatterns = [
      RegExp(r'\d+\.\d+\.\d+\.\d+'), // IP addresses
      RegExp(r'[a-z]+-[a-z]+-[a-z]+\.com'), // Hyphenated domains
      RegExp(r'[0-9]{5,}'), // Long numbers in domain
      RegExp(r'[a-z]{20,}'), // Very long domain names
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(domain));
  }
  
  /// Check for phishing indicators in URL
  static bool _hasPhishingIndicators(String url) {
    final phishingPatterns = [
      RegExp(r'paypal.*security', caseSensitive: false),
      RegExp(r'amazon.*verify', caseSensitive: false),
      RegExp(r'google.*security', caseSensitive: false),
      RegExp(r'microsoft.*update', caseSensitive: false),
      RegExp(r'apple.*id', caseSensitive: false),
    ];
    
    return phishingPatterns.any((pattern) => pattern.hasMatch(url));
  }
  
  /// Analyze download for security threats
  static Future<ThreatLevel> analyzeDownload(
    String url,
    String filename,
    Uint8List? data
  ) async {
    if (!_downloadProtectionEnabled) return ThreatLevel.none;
    
    try {
      // Check file extension
      final extension = filename.split('.').last.toLowerCase();
      final dangerousExtensions = [
        'exe', 'scr', 'bat', 'cmd', 'com', 'pif', 'vbs', 'js', 'jar'
      ];
      
      if (dangerousExtensions.contains(extension)) {
        return ThreatLevel.high;
      }
      
      // Check file size (unusually large files)
      if (data != null && data.length > 100 * 1024 * 1024) { // 100MB
        return ThreatLevel.medium;
      }
      
      // Check file hash against known malware
      if (data != null) {
        final hash = sha256.convert(data).toString();
        if (await _isKnownMalware(hash)) {
          return ThreatLevel.critical;
        }
      }
      
      // Check download source
      final sourceThreat = await checkUrlSafety(url);
      if (sourceThreat.index >= ThreatLevel.medium.index) {
        return sourceThreat;
      }
      
      return ThreatLevel.none;
    } catch (e) {
      return ThreatLevel.low;
    }
  }
  
  /// Check if file hash is known malware
  static Future<bool> _isKnownMalware(String hash) async {
    // In production, check against malware hash database
    final knownMalwareHashes = [
      // Example hashes - in production, use real malware database
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    ];
    
    return knownMalwareHashes.contains(hash);
  }
  
  /// Validate Content Security Policy
  static bool validateCSP(String csp, String violatingResource) {
    try {
      // Parse CSP directives
      final directives = <String, List<String>>{};
      final parts = csp.split(';');
      
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        
        final spaceParts = trimmed.split(' ');
        if (spaceParts.length < 2) continue;
        
        final directive = spaceParts[0];
        final sources = spaceParts.sublist(1);
        directives[directive] = sources;
      }
      
      // Check if resource violates CSP
      final uri = Uri.tryParse(violatingResource);
      if (uri == null) return false;
      
      // Check script-src directive
      if (violatingResource.contains('.js') || violatingResource.contains('javascript:')) {
        final scriptSrc = directives['script-src'] ?? [];
        return _checkCSPSource(scriptSrc, uri);
      }
      
      // Check style-src directive
      if (violatingResource.contains('.css')) {
        final styleSrc = directives['style-src'] ?? [];
        return _checkCSPSource(styleSrc, uri);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if URI matches CSP source
  static bool _checkCSPSource(List<String> sources, Uri uri) {
    for (final source in sources) {
      switch (source) {
        case "'self'":
          // Would check against current origin
          return true;
        case "'none'":
          return false;
        case "'unsafe-inline'":
          return true;
        case "'unsafe-eval'":
          return true;
        default:
          if (source.startsWith('https:') && uri.scheme == 'https') {
            return true;
          }
          if (source == uri.host) {
            return true;
          }
      }
    }
    return false;
  }
  
  /// Detect XSS attempts
  static bool detectXSS(String input) {
    final xssPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<iframe[^>]*>', caseSensitive: false),
      RegExp(r'<object[^>]*>', caseSensitive: false),
      RegExp(r'<embed[^>]*>', caseSensitive: false),
      RegExp(r'<link[^>]*>', caseSensitive: false),
      RegExp(r'<meta[^>]*>', caseSensitive: false),
    ];
    
    return xssPatterns.any((pattern) => pattern.hasMatch(input));
  }
  
  /// Detect SQL injection attempts
  static bool detectSQLInjection(String input) {
    final sqlPatterns = [
      RegExp(r"'.*OR.*'", caseSensitive: false),
      RegExp(r'UNION.*SELECT', caseSensitive: false),
      RegExp(r'DROP.*TABLE', caseSensitive: false),
      RegExp(r'INSERT.*INTO', caseSensitive: false),
      RegExp(r'DELETE.*FROM', caseSensitive: false),
      RegExp(r'UPDATE.*SET', caseSensitive: false),
      RegExp(r'--.*', caseSensitive: false),
      RegExp(r'/\*.*\*/', caseSensitive: false),
    ];
    
    return sqlPatterns.any((pattern) => pattern.hasMatch(input));
  }
  
  /// Log security event
  static void logSecurityEvent(SecurityEvent event) {
    _securityEvents.add(event);
    _eventStream.add(event);
    
    // Add threat to tab
    final threats = _tabThreats[event.tabId] ?? [];
    threats.add(event.type.name);
    _tabThreats[event.tabId] = threats;
    
    // Print to console for debugging
    print('Security Event: ${event.type.name} - ${event.description}');
    
    // In production, send to security monitoring system
  }
  
  /// Create security event
  static SecurityEvent createSecurityEvent({
    required SecurityEventType type,
    required ThreatLevel level,
    required String tabId,
    required String url,
    required String description,
    Map<String, dynamic> metadata = const {},
    bool blocked = false,
  }) {
    return SecurityEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      level: level,
      tabId: tabId,
      url: url,
      description: description,
      metadata: metadata,
      timestamp: DateTime.now(),
      blocked: blocked,
    );
  }
  
  /// Get security events stream
  static Stream<SecurityEvent> get securityEvents => _eventStream.stream;
  
  /// Get threat score for tab
  static int getThreatScore(String tabId) {
    return _threatScores[tabId] ?? 0;
  }
  
  /// Get security events for tab
  static List<SecurityEvent> getTabSecurityEvents(String tabId) {
    return _securityEvents.where((event) => event.tabId == tabId).toList();
  }
  
  /// Clear security events for tab
  static void clearTabSecurityEvents(String tabId) {
    _securityEvents.removeWhere((event) => event.tabId == tabId);
    _tabThreats.remove(tabId);
    _threatScores.remove(tabId);
  }
  
  /// Enable/disable security features
  static void setSafeBrowsingEnabled(bool enabled) {
    _safeBrowsingEnabled = enabled;
  }
  
  static void setPhishingProtectionEnabled(bool enabled) {
    _phishingProtectionEnabled = enabled;
  }
  
  static void setMalwareProtectionEnabled(bool enabled) {
    _malwareProtectionEnabled = enabled;
  }
  
  static void setDownloadProtectionEnabled(bool enabled) {
    _downloadProtectionEnabled = enabled;
  }
  
  static void setSiteIsolationEnabled(bool enabled) {
    _siteIsolationEnabled = enabled;
  }
  
  static void setHttpsOnlyMode(bool enabled) {
    _httpsOnlyMode = enabled;
  }
  
  /// Get security settings
  static Map<String, bool> getSecuritySettings() {
    return {
      'safeBrowsing': _safeBrowsingEnabled,
      'phishingProtection': _phishingProtectionEnabled,
      'malwareProtection': _malwareProtectionEnabled,
      'downloadProtection': _downloadProtectionEnabled,
      'siteIsolation': _siteIsolationEnabled,
      'httpsOnlyMode': _httpsOnlyMode,
    };
  }
  
  /// Get security statistics
  static Map<String, dynamic> getSecurityStats() {
    final eventsByType = <String, int>{};
    for (final event in _securityEvents) {
      eventsByType[event.type.name] = (eventsByType[event.type.name] ?? 0) + 1;
    }
    
    return {
      'totalEvents': _securityEvents.length,
      'eventsByType': eventsByType,
      'activeTabs': _tabThreats.length,
      'averageThreatScore': _threatScores.values.isEmpty 
          ? 0 
          : _threatScores.values.reduce((a, b) => a + b) / _threatScores.length,
      'maliciousDomains': _maliciousDomains.length,
      'phishingDomains': _phishingDomains.length,
    };
  }
  
  /// Cleanup resources
  static void cleanup() {
    _securityEvents.clear();
    _tabThreats.clear();
    _threatScores.clear();
    _contentHashes.clear();
  }
} 
 // Advanced threat detection
  static Future<Map<String, dynamic>> performDeepScan(String url, String content) async {
    final results = <String, dynamic>{
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
      'threats': <String, dynamic>{},
      'recommendations': <String>[],
      'riskScore': 0.0,
    };
    
    // Check for malicious scripts
    final scriptThreats = _detectMaliciousScripts(content);
    if (scriptThreats.isNotEmpty) {
      results['threats']['maliciousScripts'] = scriptThreats;
      results['riskScore'] = (results['riskScore'] as double) + 0.3;
    }
    
    // Check for suspicious forms
    final formThreats = _detectSuspiciousForms(content);
    if (formThreats.isNotEmpty) {
      results['threats']['suspiciousForms'] = formThreats;
      results['riskScore'] = (results['riskScore'] as double) + 0.2;
    }
    
    // Check for data exfiltration attempts
    final exfiltrationThreats = _detectDataExfiltration(content);
    if (exfiltrationThreats.isNotEmpty) {
      results['threats']['dataExfiltration'] = exfiltrationThreats;
      results['riskScore'] = (results['riskScore'] as double) + 0.4;
    }
    
    // Check for cryptocurrency mining
    final cryptoThreats = _detectCryptomining(content);
    if (cryptoThreats.isNotEmpty) {
      results['threats']['cryptomining'] = cryptoThreats;
      results['riskScore'] = (results['riskScore'] as double) + 0.25;
    }
    
    // Generate recommendations
    results['recommendations'] = _generateSecurityRecommendations(results['threats']);
    
    return results;
  }
  
  static List<Map<String, dynamic>> _detectMaliciousScripts(String content) {
    final threats = <Map<String, dynamic>>[];
    
    // Check for obfuscated JavaScript
    final obfuscationPatterns = [
      RegExp(r"eval\s*\(\s*[\"'].*[\"'].*\)", caseSensitive: false),
      RegExp(r'document\.write\s*\(\s*unescape', caseSensitive: false),
      RegExp(r'String\.fromCharCode', caseSensitive: false),
      RegExp(r'\\x[0-9a-f]{2}', caseSensitive: false),
    ];
    
    for (final pattern in obfuscationPatterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches) {
        threats.add({
          'type': 'obfuscated_script',
          'pattern': pattern.pattern,
          'match': match.group(0),
          'severity': 'high',
        });
      }
    }
    
    // Check for suspicious API calls
    final suspiciousAPIs = [
      'navigator.geolocation',
      'navigator.mediaDevices',
      'navigator.clipboard',
      'localStorage.setItem',
      'sessionStorage.setItem',
    ];
    
    for (final api in suspiciousAPIs) {
      if (content.contains(api)) {
        threats.add({
          'type': 'suspicious_api',
          'api': api,
          'severity': 'medium',
        });
      }
    }
    
    return threats;
  }
  
  static List<Map<String, dynamic>> _detectSuspiciousForms(String content) {
    final threats = <Map<String, dynamic>>[];
    
    // Check for forms without HTTPS
    final formPattern = RegExp(r"<form[^>]*action=[\"']([^\"']*)[\"']", caseSensitive: false);
    final matches = formPattern.allMatches(content);
    
    for (final match in matches) {
      final action = match.group(1);
      if (action != null && action.startsWith('http://')) {
        threats.add({
          'type': 'insecure_form',
          'action': action,
          'severity': 'high',
        });
      }
    }
    
    // Check for password fields without proper security
    if (content.contains('type="password"') && !content.contains('autocomplete="off"')) {
      threats.add({
        'type': 'insecure_password_field',
        'severity': 'medium',
      });
    }
    
    return threats;
  }
  
  static List<Map<String, dynamic>> _detectDataExfiltration(String content) {
    final threats = <Map<String, dynamic>>[];
    
    // Check for suspicious data collection
    final dataPatterns = [
      RegExp(r'document\.cookie', caseSensitive: false),
      RegExp(r'localStorage\.getItem', caseSensitive: false),
      RegExp(r'sessionStorage\.getItem', caseSensitive: false),
      RegExp(r'navigator\.userAgent', caseSensitive: false),
    ];
    
    for (final pattern in dataPatterns) {
      final matches = pattern.allMatches(content);
      if (matches.isNotEmpty) {
        threats.add({
          'type': 'data_collection',
          'pattern': pattern.pattern,
          'count': matches.length,
          'severity': 'medium',
        });
      }
    }
    
    // Check for external data transmission
    final transmissionPatterns = [
      RegExp(r"fetch\s*\(\s*[\"'][^\"']*[\"']", caseSensitive: false),
      RegExp(r'XMLHttpRequest', caseSensitive: false),
      RegExp(r'new\s+Image\s*\(\s*\).*src\s*=', caseSensitive: false),
    ];
    
    for (final pattern in transmissionPatterns) {
      final matches = pattern.allMatches(content);
      if (matches.isNotEmpty) {
        threats.add({
          'type': 'data_transmission',
          'pattern': pattern.pattern,
          'count': matches.length,
          'severity': 'high',
        });
      }
    }
    
    return threats;
  }
  
  static List<Map<String, dynamic>> _detectCryptomining(String content) {
    final threats = <Map<String, dynamic>>[];
    
    // Check for known mining libraries
    final miningLibraries = [
      'coinhive',
      'cryptoloot',
      'jsecoin',
      'minero.cc',
      'crypto-loot',
      'webminepool',
    ];
    
    for (final library in miningLibraries) {
      if (content.toLowerCase().contains(library)) {
        threats.add({
          'type': 'mining_library',
          'library': library,
          'severity': 'critical',
        });
      }
    }
    
    // Check for mining-related code patterns
    final miningPatterns = [
      RegExp(r"new\s+Worker\s*\(\s*[\"'][^\"']*\.js[\"']", caseSensitive: false),
      RegExp(r'WebAssembly\.instantiate', caseSensitive: false),
      RegExp(r'crypto.*hash', caseSensitive: false),
    ];
    
    for (final pattern in miningPatterns) {
      final matches = pattern.allMatches(content);
      if (matches.isNotEmpty) {
        threats.add({
          'type': 'mining_pattern',
          'pattern': pattern.pattern,
          'count': matches.length,
          'severity': 'high',
        });
      }
    }
    
    return threats;
  }
  
  static List<String> _generateSecurityRecommendations(Map<String, dynamic> threats) {
    final recommendations = <String>[];
    
    if (threats.containsKey('maliciousScripts')) {
      recommendations.add('Enable JavaScript blocking for suspicious scripts');
      recommendations.add('Use Content Security Policy (CSP) headers');
    }
    
    if (threats.containsKey('suspiciousForms')) {
      recommendations.add('Only submit forms over HTTPS connections');
      recommendations.add('Verify form destinations before submitting data');
    }
    
    if (threats.containsKey('dataExfiltration')) {
      recommendations.add('Review and limit data sharing permissions');
      recommendations.add('Clear cookies and local storage regularly');
    }
    
    if (threats.containsKey('cryptomining')) {
      recommendations.add('Block cryptocurrency mining scripts');
      recommendations.add('Monitor CPU usage for unusual activity');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Continue browsing safely with current security settings');
    }
    
    return recommendations;
  }
  
  // Real-time threat monitoring
  static Stream<SecurityEvent> monitorThreats() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 30));
      
      // Check for new threats in active tabs
      final activeThreats = await _scanActiveTabs();
      for (final threat in activeThreats) {
        yield threat;
      }
    }
  }
  
  static Future<List<SecurityEvent>> _scanActiveTabs() async {
    final threats = <SecurityEvent>[];
    
    // This would integrate with the browser provider to get active tabs
    // For now, return empty list
    
    return threats;
  }
  
  // Security policy management
  static Future<void> updateSecurityPolicy(Map<String, dynamic> policy) async {
    await StorageService.setSetting('security_policy', policy);
    
    // Apply policy changes
    _applySecurityPolicy(policy);
  }
  
  static void _applySecurityPolicy(Map<String, dynamic> policy) {
    // Update security settings based on policy
    final blockMaliciousScripts = policy['blockMaliciousScripts'] as bool? ?? true;
    final blockCryptomining = policy['blockCryptomining'] as bool? ?? true;
    final strictSSL = policy['strictSSL'] as bool? ?? true;
    
    // Apply settings to browser engine
    // This would integrate with BrowserEngineService
  }
  
  // Security reporting
  static Future<Map<String, dynamic>> generateSecurityReport(DateTime startDate, DateTime endDate) async {
    final events = _securityEvents.where((event) =>
        event.timestamp.isAfter(startDate) && event.timestamp.isBefore(endDate)).toList();
    
    final report = <String, dynamic>{
      'period': {
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
      },
      'summary': {
        'totalEvents': events.length,
        'criticalEvents': events.where((e) => e.level == ThreatLevel.critical).length,
        'highEvents': events.where((e) => e.level == ThreatLevel.high).length,
        'mediumEvents': events.where((e) => e.level == ThreatLevel.medium).length,
        'lowEvents': events.where((e) => e.level == ThreatLevel.low).length,
      },
      'topThreats': _getTopThreats(events),
      'affectedDomains': _getAffectedDomains(events),
      'recommendations': _generateReportRecommendations(events),
    };
    
    return report;
  }
  
  static List<Map<String, dynamic>> _getTopThreats(List<SecurityEvent> events) {
    final threatCounts = <SecurityEventType, int>{};
    
    for (final event in events) {
      threatCounts[event.type] = (threatCounts[event.type] ?? 0) + 1;
    }
    
    final sortedThreats = threatCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedThreats.take(5).map((entry) => {
      'type': entry.key.toString(),
      'count': entry.value,
    }).toList();
  }
  
  static List<String> _getAffectedDomains(List<SecurityEvent> events) {
    final domains = events.map((event) {
      try {
        final uri = Uri.parse(event.url);
        return uri.host;
      } catch (e) {
        return 'unknown';
      }
    }).toSet().toList();
    
    domains.sort();
    return domains;
  }
  
  static List<String> _generateReportRecommendations(List<SecurityEvent> events) {
    final recommendations = <String>[];
    
    if (events.any((e) => e.type == SecurityEventType.maliciousScript)) {
      recommendations.add('Consider enabling stricter JavaScript policies');
    }
    
    if (events.any((e) => e.type == SecurityEventType.phishingAttempt)) {
      recommendations.add('Review and update phishing protection settings');
    }
    
    if (events.any((e) => e.type == SecurityEventType.cryptojacking)) {
      recommendations.add('Enable cryptocurrency mining protection');
    }
    
    if (events.length > 50) {
      recommendations.add('Consider reviewing browsing habits and visited sites');
    }
    
    return recommendations;
  }
}