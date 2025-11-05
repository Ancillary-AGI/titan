import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Consolidated security service
class SecurityService {
  final List<String> _blockedDomains = [];
  final List<String> _trustedDomains = [];
  final Map<String, SecurityResult> _urlCache = {};
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Load security rules
    await _loadSecurityRules();
    _isInitialized = true;
  }
  
  /// Validate URL security
  Future<SecurityResult> validateUrl(String url) async {
    // Check cache first
    if (_urlCache.containsKey(url)) {
      return _urlCache[url]!;
    }
    
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return SecurityResult(
        isSafe: false,
        riskLevel: RiskLevel.high,
        reason: 'Invalid URL format',
      );
    }
    
    // Check blocked domains
    if (_blockedDomains.any((domain) => uri.host.contains(domain))) {
      final result = SecurityResult(
        isSafe: false,
        riskLevel: RiskLevel.high,
        reason: 'Domain is blocked',
      );
      _urlCache[url] = result;
      return result;
    }
    
    // Check trusted domains
    if (_trustedDomains.any((domain) => uri.host.contains(domain))) {
      final result = SecurityResult(
        isSafe: true,
        riskLevel: RiskLevel.low,
        reason: 'Trusted domain',
      );
      _urlCache[url] = result;
      return result;
    }
    
    // Perform security checks
    final riskLevel = await _assessRiskLevel(uri);
    final result = SecurityResult(
      isSafe: riskLevel != RiskLevel.high,
      riskLevel: riskLevel,
      reason: _getRiskReason(riskLevel),
    );
    
    _urlCache[url] = result;
    return result;
  }
  
  /// Check for phishing attempts
  Future<PhishingResult> checkPhishing(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return PhishingResult(isPhishing: false, confidence: 0.0);
    }
    
    // Simple phishing detection heuristics
    double suspicionScore = 0.0;
    
    // Check for suspicious characters in domain
    if (uri.host.contains(RegExp(r'[0-9]'))) suspicionScore += 0.2;
    if (uri.host.contains('-')) suspicionScore += 0.1;
    if (uri.host.length > 20) suspicionScore += 0.2;
    
    // Check for suspicious TLDs
    final suspiciousTlds = ['.tk', '.ml', '.ga', '.cf'];
    if (suspiciousTlds.any((tld) => uri.host.endsWith(tld))) {
      suspicionScore += 0.4;
    }
    
    // Check for URL shorteners
    final shorteners = ['bit.ly', 'tinyurl.com', 't.co', 'goo.gl'];
    if (shorteners.any((shortener) => uri.host.contains(shortener))) {
      suspicionScore += 0.3;
    }
    
    return PhishingResult(
      isPhishing: suspicionScore > 0.7,
      confidence: suspicionScore,
    );
  }
  
  /// Sanitize HTML content
  String sanitizeHtml(String html) {
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '')
        .replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false, dotAll: true), '');
  }
  
  /// Detect XSS attempts
  XSSResult detectXSS(String content) {
    final xssPatterns = [
      RegExp(r'<script[^>]*>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<iframe[^>]*>', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
    ];
    
    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(content)) {
        return XSSResult(
          isXSS: true,
          riskLevel: RiskLevel.high,
          pattern: pattern.pattern,
        );
      }
    }
    
    return XSSResult(isXSS: false, riskLevel: RiskLevel.low);
  }
  
  /// Encrypt sensitive data
  String encrypt(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    return base64.encode(digest.bytes);
  }
  
  /// Decrypt sensitive data
  String decrypt(String encryptedData, String key) {
    // Simple implementation - in production use proper encryption
    return encryptedData;
  }
  
  /// Add domain to blocklist
  void blockDomain(String domain) {
    if (!_blockedDomains.contains(domain)) {
      _blockedDomains.add(domain);
    }
  }
  
  /// Add domain to trusted list
  void trustDomain(String domain) {
    if (!_trustedDomains.contains(domain)) {
      _trustedDomains.add(domain);
    }
  }
  
  Future<void> _loadSecurityRules() async {
    // Load default security rules
    _trustedDomains.addAll([
      'google.com',
      'github.com',
      'stackoverflow.com',
      'mozilla.org',
      'wikipedia.org',
    ]);
    
    _blockedDomains.addAll([
      'malware-site.com',
      'phishing-example.com',
    ]);
  }
  
  Future<RiskLevel> _assessRiskLevel(Uri uri) async {
    // Simple risk assessment
    if (uri.scheme != 'https') return RiskLevel.medium;
    if (uri.host.contains('localhost')) return RiskLevel.low;
    if (uri.host.contains('127.0.0.1')) return RiskLevel.low;
    
    return RiskLevel.low;
  }
  
  String _getRiskReason(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'URL appears safe';
      case RiskLevel.medium:
        return 'URL has some security concerns';
      case RiskLevel.high:
        return 'URL is potentially dangerous';
    }
  }
}

enum RiskLevel { low, medium, high }

class SecurityResult {
  final bool isSafe;
  final RiskLevel riskLevel;
  final String reason;
  
  SecurityResult({
    required this.isSafe,
    required this.riskLevel,
    required this.reason,
  });
}

class PhishingResult {
  final bool isPhishing;
  final double confidence;
  
  PhishingResult({
    required this.isPhishing,
    required this.confidence,
  });
}

class XSSResult {
  final bool isXSS;
  final RiskLevel riskLevel;
  final String? pattern;
  
  XSSResult({
    required this.isXSS,
    required this.riskLevel,
    this.pattern,
  });
}