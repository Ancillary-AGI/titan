import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/browser_security_service.dart';

@GenerateMocks([BrowserSecurityService])
import 'security_service_test.mocks.dart';

void main() {
  group('BrowserSecurityService Tests', () {
    late BrowserSecurityService securityService;

    setUp(() {
      securityService = BrowserSecurityService();
    });

    test('should initialize security service', () async {
      await securityService.initialize();
      
      expect(securityService.isInitialized, isTrue);
    });

    test('should validate URL security', () async {
      final safeUrl = 'https://google.com';
      final unsafeUrl = 'http://malicious-site.com';
      
      final safeResult = await securityService.validateUrl(safeUrl);
      final unsafeResult = await securityService.validateUrl(unsafeUrl);
      
      expect(safeResult.isSafe, isTrue);
      expect(safeResult.riskLevel, equals(RiskLevel.low));
      expect(unsafeResult.riskLevel, greaterThan(RiskLevel.low));
    });

    test('should detect phishing attempts', () async {
      final phishingUrl = 'https://g00gle.com'; // Suspicious domain
      
      final result = await securityService.checkPhishing(phishingUrl);
      
      expect(result.isPhishing, isTrue);
      expect(result.confidence, greaterThan(0.7));
    });

    test('should scan for malware', () async {
      final testUrl = 'https://example.com';
      
      final scanResult = await securityService.scanForMalware(testUrl);
      
      expect(scanResult, isNotNull);
      expect(scanResult.scanTime, isNotNull);
    });

    test('should manage content security policy', () async {
      const cspHeader = "default-src 'self'; script-src 'self' 'unsafe-inline'";
      
      final policy = securityService.parseCSP(cspHeader);
      
      expect(policy, isNotNull);
      expect(policy.defaultSrc, contains("'self'"));
      expect(policy.scriptSrc, contains("'unsafe-inline'"));
    });

    test('should handle certificate validation', () async {
      final certificate = await securityService.validateCertificate(
        'https://google.com'
      );
      
      expect(certificate.isValid, isTrue);
      expect(certificate.issuer, isNotEmpty);
      expect(certificate.expiryDate.isAfter(DateTime.now()), isTrue);
    });

    test('should block dangerous downloads', () async {
      final safeFile = 'document.pdf';
      final dangerousFile = 'virus.exe';
      
      final safeResult = securityService.isDownloadSafe(safeFile);
      final dangerousResult = securityService.isDownloadSafe(dangerousFile);
      
      expect(safeResult, isTrue);
      expect(dangerousResult, isFalse);
    });

    test('should manage privacy settings', () async {
      await securityService.setPrivacyLevel(PrivacyLevel.strict);
      
      final level = securityService.getPrivacyLevel();
      
      expect(level, equals(PrivacyLevel.strict));
      expect(securityService.isTrackingBlocked, isTrue);
      expect(securityService.isThirdPartyCookiesBlocked, isTrue);
    });

    test('should handle XSS protection', () async {
      const maliciousScript = '<script>alert("xss")</script>';
      const safeContent = '<p>Safe content</p>';
      
      final maliciousResult = securityService.detectXSS(maliciousScript);
      final safeResult = securityService.detectXSS(safeContent);
      
      expect(maliciousResult.isXSS, isTrue);
      expect(maliciousResult.riskLevel, equals(RiskLevel.high));
      expect(safeResult.isXSS, isFalse);
    });

    test('should manage secure storage', () async {
      const key = 'test_key';
      const value = 'sensitive_data';
      
      await securityService.secureStore(key, value);
      final retrieved = await securityService.secureRetrieve(key);
      
      expect(retrieved, equals(value));
    });

    test('should handle password security', () async {
      const weakPassword = '123456';
      const strongPassword = 'Str0ng!P@ssw0rd#2023';
      
      final weakResult = securityService.checkPasswordStrength(weakPassword);
      final strongResult = securityService.checkPasswordStrength(strongPassword);
      
      expect(weakResult.strength, equals(PasswordStrength.weak));
      expect(strongResult.strength, equals(PasswordStrength.strong));
      expect(strongResult.score, greaterThan(weakResult.score));
    });

    test('should detect suspicious network activity', () async {
      final networkActivity = NetworkActivity(
        destination: 'suspicious-domain.com',
        dataSize: 1000000, // Large data transfer
        frequency: 100, // High frequency
      );
      
      final result = securityService.analyzeNetworkActivity(networkActivity);
      
      expect(result.isSuspicious, isTrue);
      expect(result.riskFactors, isNotEmpty);
    });

    test('should manage firewall rules', () async {
      final rule = FirewallRule(
        domain: 'malicious-site.com',
        action: FirewallAction.block,
        reason: 'Known malware distributor',
      );
      
      securityService.addFirewallRule(rule);
      
      final isBlocked = securityService.isBlocked('malicious-site.com');
      expect(isBlocked, isTrue);
    });
  });
}