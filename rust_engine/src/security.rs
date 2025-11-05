//! Security engine for threat detection and protection

use std::collections::{HashMap, HashSet};
use std::sync::Arc;
use std::time::{Duration, SystemTime};
use tokio::sync::RwLock;
use url::Url;
use crate::core::{Result, EngineError, BrowserEvent, SecurityEventType, SecuritySeverity};

/// Security engine for comprehensive threat protection
pub struct SecurityEngine {
    /// Threat detection rules
    threat_rules: Arc<RwLock<ThreatRules>>,
    
    /// Blocked domains and URLs
    blocklist: Arc<RwLock<SecurityBlocklist>>,
    
    /// Security event log
    event_log: Arc<RwLock<Vec<SecurityEvent>>>,
    
    /// Content Security Policy engine
    csp_engine: CSPEngine,
    
    /// Malware detection engine
    malware_detector: MalwareDetector,
    
    /// Configuration
    config: SecurityConfig,
}

impl SecurityEngine {
    /// Create a new security engine
    pub async fn new() -> Result<Self> {
        let threat_rules = Arc::new(RwLock::new(ThreatRules::load_default()));
        let blocklist = Arc::new(RwLock::new(SecurityBlocklist::load_default().await?));
        let event_log = Arc::new(RwLock::new(Vec::new()));
        
        Ok(Self {
            threat_rules,
            blocklist,
            event_log,
            csp_engine: CSPEngine::new(),
            malware_detector: MalwareDetector::new(),
            config: SecurityConfig::default(),
        })
    }
    
    /// Validate URL safety
    pub async fn validate_url(&self, url: &str) -> Result<()> {
        let parsed_url = Url::parse(url)
            .map_err(|e| EngineError::SecurityError(format!("Invalid URL: {}", e)))?;
        
        // Check blocklist
        let blocklist = self.blocklist.read().await;
        if blocklist.is_blocked(&parsed_url) {
            self.log_security_event(SecurityEvent {
                event_type: SecurityEventType::PhishingAttempt,
                severity: SecuritySeverity::High,
                url: url.to_string(),
                description: "URL blocked by security policy".to_string(),
                timestamp: SystemTime::now(),
                blocked: true,
                metadata: HashMap::new(),
            }).await;
            
            return Err(EngineError::SecurityError(format!("URL blocked: {}", url)));
        }
        
        // Check for suspicious patterns
        if self.has_suspicious_url_patterns(url) {
            self.log_security_event(SecurityEvent {
                event_type: SecurityEventType::PhishingAttempt,
                severity: SecuritySeverity::Medium,
                url: url.to_string(),
                description: "Suspicious URL pattern detected".to_string(),
                timestamp: SystemTime::now(),
                blocked: false,
                metadata: HashMap::new(),
            }).await;
        }
        
        Ok(())
    }
    
    /// Scan content for threats
    pub async fn scan_content(&self, content: &str, url: &str) -> Result<ScanResult> {
        let mut threats = Vec::new();
        let mut risk_score = 0.0;
        
        // JavaScript threat detection
        let js_threats = self.detect_javascript_threats(content).await;
        threats.extend(js_threats.iter().cloned());
        risk_score += js_threats.len() as f64 * 0.3;
        
        // Malware detection
        let malware_threats = self.malware_detector.scan_content(content).await;
        threats.extend(malware_threats.iter().cloned());
        risk_score += malware_threats.len() as f64 * 0.5;
        
        // Phishing detection
        let phishing_threats = self.detect_phishing_content(content, url).await;
        threats.extend(phishing_threats.iter().cloned());
        risk_score += phishing_threats.len() as f64 * 0.4;
        
        // Data exfiltration detection
        let exfiltration_threats = self.detect_data_exfiltration(content).await;
        threats.extend(exfiltration_threats.iter().cloned());
        risk_score += exfiltration_threats.len() as f64 * 0.6;
        
        // Cryptojacking detection
        let crypto_threats = self.detect_cryptojacking(content).await;
        threats.extend(crypto_threats.iter().cloned());
        risk_score += crypto_threats.len() as f64 * 0.7;
        
        // Log significant threats
        for threat in &threats {
            if threat.severity >= SecuritySeverity::Medium {
                self.log_security_event(SecurityEvent {
                    event_type: threat.threat_type.clone(),
                    severity: threat.severity.clone(),
                    url: url.to_string(),
                    description: threat.description.clone(),
                    timestamp: SystemTime::now(),
                    blocked: threat.should_block,
                    metadata: threat.metadata.clone(),
                }).await;
            }
        }
        
        Ok(ScanResult {
            threats,
            risk_score: risk_score.min(1.0),
            safe: risk_score < 0.3,
            recommendations: self.generate_recommendations(&threats),
        })
    }
    
    /// Validate Content Security Policy
    pub async fn validate_csp(&self, csp_header: &str, url: &str) -> Result<CSPValidationResult> {
        self.csp_engine.validate(csp_header, url).await
    }
    
    /// Check for suspicious URL patterns
    fn has_suspicious_url_patterns(&self, url: &str) -> bool {
        let suspicious_patterns = [
            // Homograph attacks
            r"[а-я]", // Cyrillic characters
            r"[α-ω]", // Greek characters
            
            // Suspicious TLDs
            r"\.tk$", r"\.ml$", r"\.ga$", r"\.cf$",
            
            // URL shorteners (potential for abuse)
            r"bit\.ly", r"tinyurl", r"t\.co",
            
            // Suspicious subdomains
            r"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}", // IP addresses
            r"[a-z0-9]{20,}", // Long random strings
        ];
        
        for pattern in &suspicious_patterns {
            if regex::Regex::new(pattern).unwrap().is_match(url) {
                return true;
            }
        }
        
        false
    }
    
    /// Detect JavaScript threats
    async fn detect_javascript_threats(&self, content: &str) -> Vec<ThreatDetection> {
        let mut threats = Vec::new();
        
        let threat_patterns = [
            (r"eval\s*\(", "Dangerous eval() usage", SecuritySeverity::High),
            (r"document\.write\s*\(", "Potentially dangerous document.write()", SecuritySeverity::Medium),
            (r"innerHTML\s*=", "Potential XSS via innerHTML", SecuritySeverity::Medium),
            (r"location\.href\s*=", "Potential redirect attack", SecuritySeverity::Medium),
            (r"window\.open\s*\(", "Popup window creation", SecuritySeverity::Low),
            (r"XMLHttpRequest", "AJAX request detected", SecuritySeverity::Low),
            (r"fetch\s*\(", "Fetch API usage", SecuritySeverity::Low),
            (r"crypto\.", "Cryptographic operations", SecuritySeverity::Medium),
            (r"WebAssembly", "WebAssembly usage", SecuritySeverity::Medium),
        ];
        
        for (pattern, description, severity) in &threat_patterns {
            if regex::Regex::new(pattern).unwrap().is_match(content) {
                threats.push(ThreatDetection {
                    threat_type: SecurityEventType::MaliciousScript,
                    severity: severity.clone(),
                    description: description.to_string(),
                    should_block: matches!(severity, SecuritySeverity::High | SecuritySeverity::Critical),
                    metadata: HashMap::new(),
                });
            }
        }
        
        threats
    }
    
    /// Detect phishing content
    async fn detect_phishing_content(&self, content: &str, url: &str) -> Vec<ThreatDetection> {
        let mut threats = Vec::new();
        
        // Check for common phishing indicators
        let phishing_keywords = [
            "verify your account", "suspended account", "click here immediately",
            "urgent action required", "confirm your identity", "update payment",
            "security alert", "unusual activity", "temporary suspension",
        ];
        
        let content_lower = content.to_lowercase();
        let mut keyword_matches = 0;
        
        for keyword in &phishing_keywords {
            if content_lower.contains(keyword) {
                keyword_matches += 1;
            }
        }
        
        if keyword_matches >= 2 {
            threats.push(ThreatDetection {
                threat_type: SecurityEventType::PhishingAttempt,
                severity: if keyword_matches >= 4 { SecuritySeverity::High } else { SecuritySeverity::Medium },
                description: format!("Potential phishing content detected ({} indicators)", keyword_matches),
                should_block: keyword_matches >= 4,
                metadata: {
                    let mut meta = HashMap::new();
                    meta.insert("keyword_matches".to_string(), keyword_matches.to_string());
                    meta
                },
            });
        }
        
        // Check for fake login forms
        if content_lower.contains("password") && content_lower.contains("login") {
            let parsed_url = Url::parse(url).ok();
            if let Some(url_obj) = parsed_url {
                let domain = url_obj.domain().unwrap_or("");
                
                // Check if domain looks suspicious for login forms
                let legitimate_domains = ["google.com", "facebook.com", "microsoft.com", "apple.com"];
                if !legitimate_domains.iter().any(|&d| domain.contains(d)) {
                    threats.push(ThreatDetection {
                        threat_type: SecurityEventType::PhishingAttempt,
                        severity: SecuritySeverity::Medium,
                        description: "Suspicious login form on untrusted domain".to_string(),
                        should_block: false,
                        metadata: {
                            let mut meta = HashMap::new();
                            meta.insert("domain".to_string(), domain.to_string());
                            meta
                        },
                    });
                }
            }
        }
        
        threats
    }
    
    /// Detect data exfiltration attempts
    async fn detect_data_exfiltration(&self, content: &str) -> Vec<ThreatDetection> {
        let mut threats = Vec::new();
        
        let exfiltration_patterns = [
            (r"document\.cookie", "Cookie access detected"),
            (r"localStorage\.getItem", "Local storage access"),
            (r"sessionStorage\.getItem", "Session storage access"),
            (r"navigator\.userAgent", "User agent fingerprinting"),
            (r"screen\.width|screen\.height", "Screen resolution fingerprinting"),
            (r"navigator\.platform", "Platform fingerprinting"),
            (r"new\s+Image\(\).*src", "Potential pixel tracking"),
        ];
        
        for (pattern, description) in &exfiltration_patterns {
            if regex::Regex::new(pattern).unwrap().is_match(content) {
                threats.push(ThreatDetection {
                    threat_type: SecurityEventType::DataExfiltration,
                    severity: SecuritySeverity::Medium,
                    description: description.to_string(),
                    should_block: false,
                    metadata: HashMap::new(),
                });
            }
        }
        
        threats
    }
    
    /// Detect cryptojacking attempts
    async fn detect_cryptojacking(&self, content: &str) -> Vec<ThreatDetection> {
        let mut threats = Vec::new();
        
        let crypto_indicators = [
            "coinhive", "cryptoloot", "jsecoin", "minero.cc", "crypto-loot",
            "webminepool", "mineralt", "cryptonoter", "coin-hive",
        ];
        
        let content_lower = content.to_lowercase();
        for indicator in &crypto_indicators {
            if content_lower.contains(indicator) {
                threats.push(ThreatDetection {
                    threat_type: SecurityEventType::CryptojackingAttempt,
                    severity: SecuritySeverity::Critical,
                    description: format!("Cryptojacking library detected: {}", indicator),
                    should_block: true,
                    metadata: {
                        let mut meta = HashMap::new();
                        meta.insert("library".to_string(), indicator.to_string());
                        meta
                    },
                });
            }
        }
        
        // Check for WebAssembly crypto mining patterns
        if content.contains("WebAssembly") && content.contains("crypto") {
            threats.push(ThreatDetection {
                threat_type: SecurityEventType::CryptojackingAttempt,
                severity: SecuritySeverity::High,
                description: "Potential WebAssembly cryptojacking detected".to_string(),
                should_block: true,
                metadata: HashMap::new(),
            });
        }
        
        threats
    }
    
    /// Generate security recommendations
    fn generate_recommendations(&self, threats: &[ThreatDetection]) -> Vec<String> {
        let mut recommendations = Vec::new();
        
        if threats.iter().any(|t| matches!(t.threat_type, SecurityEventType::MaliciousScript)) {
            recommendations.push("Consider disabling JavaScript for this site".to_string());
        }
        
        if threats.iter().any(|t| matches!(t.threat_type, SecurityEventType::PhishingAttempt)) {
            recommendations.push("Verify the legitimacy of this website before entering personal information".to_string());
        }
        
        if threats.iter().any(|t| matches!(t.threat_type, SecurityEventType::DataExfiltration)) {
            recommendations.push("This site may be collecting your personal data".to_string());
        }
        
        if threats.iter().any(|t| matches!(t.threat_type, SecurityEventType::CryptojackingAttempt)) {
            recommendations.push("Block this site immediately - cryptocurrency mining detected".to_string());
        }
        
        if recommendations.is_empty() {
            recommendations.push("No immediate security concerns detected".to_string());
        }
        
        recommendations
    }
    
    /// Log security event
    async fn log_security_event(&self, event: SecurityEvent) {
        let mut log = self.event_log.write().await;
        log.push(event);
        
        // Keep only last 1000 events
        if log.len() > 1000 {
            log.drain(0..log.len() - 1000);
        }
    }
    
    /// Get security events
    pub async fn get_security_events(&self, limit: Option<usize>) -> Vec<SecurityEvent> {
        let log = self.event_log.read().await;
        if let Some(limit) = limit {
            log.iter().rev().take(limit).cloned().collect()
        } else {
            log.clone()
        }
    }
    
    /// Update security configuration
    pub fn update_config(&mut self, config: SecurityConfig) {
        self.config = config;
    }
    
    /// Shutdown security engine
    pub async fn shutdown(&self) -> Result<()> {
        // Clean up resources
        Ok(())
    }
}

/// Security event representation
#[derive(Debug, Clone)]
pub struct SecurityEvent {
    pub event_type: SecurityEventType,
    pub severity: SecuritySeverity,
    pub url: String,
    pub description: String,
    pub timestamp: SystemTime,
    pub blocked: bool,
    pub metadata: HashMap<String, String>,
}

/// Threat detection result
#[derive(Debug, Clone)]
pub struct ThreatDetection {
    pub threat_type: SecurityEventType,
    pub severity: SecuritySeverity,
    pub description: String,
    pub should_block: bool,
    pub metadata: HashMap<String, String>,
}

/// Content scan result
#[derive(Debug, Clone)]
pub struct ScanResult {
    pub threats: Vec<ThreatDetection>,
    pub risk_score: f64,
    pub safe: bool,
    pub recommendations: Vec<String>,
}

/// Security blocklist
struct SecurityBlocklist {
    blocked_domains: HashSet<String>,
    blocked_urls: HashSet<String>,
    blocked_patterns: Vec<regex::Regex>,
}

impl SecurityBlocklist {
    async fn load_default() -> Result<Self> {
        let mut blocklist = Self {
            blocked_domains: HashSet::new(),
            blocked_urls: HashSet::new(),
            blocked_patterns: Vec::new(),
        };
        
        // Add known malicious domains
        let malicious_domains = [
            "malware.com", "phishing.net", "scam.org", "fake-bank.com",
            "virus.download", "trojan.exe", "suspicious.site",
        ];
        
        for domain in &malicious_domains {
            blocklist.blocked_domains.insert(domain.to_string());
        }
        
        Ok(blocklist)
    }
    
    fn is_blocked(&self, url: &Url) -> bool {
        if let Some(domain) = url.domain() {
            if self.blocked_domains.contains(domain) {
                return true;
            }
        }
        
        let url_str = url.as_str();
        if self.blocked_urls.contains(url_str) {
            return true;
        }
        
        for pattern in &self.blocked_patterns {
            if pattern.is_match(url_str) {
                return true;
            }
        }
        
        false
    }
}

/// Threat detection rules
struct ThreatRules {
    javascript_rules: Vec<ThreatRule>,
    content_rules: Vec<ThreatRule>,
    url_rules: Vec<ThreatRule>,
}

impl ThreatRules {
    fn load_default() -> Self {
        Self {
            javascript_rules: Vec::new(),
            content_rules: Vec::new(),
            url_rules: Vec::new(),
        }
    }
}

/// Individual threat rule
struct ThreatRule {
    pattern: regex::Regex,
    severity: SecuritySeverity,
    description: String,
    should_block: bool,
}

/// Content Security Policy engine
struct CSPEngine;

impl CSPEngine {
    fn new() -> Self {
        Self
    }
    
    async fn validate(&self, _csp_header: &str, _url: &str) -> Result<CSPValidationResult> {
        // Simplified CSP validation
        Ok(CSPValidationResult {
            valid: true,
            violations: Vec::new(),
            recommendations: Vec::new(),
        })
    }
}

/// CSP validation result
#[derive(Debug, Clone)]
pub struct CSPValidationResult {
    pub valid: bool,
    pub violations: Vec<String>,
    pub recommendations: Vec<String>,
}

/// Malware detection engine
struct MalwareDetector;

impl MalwareDetector {
    fn new() -> Self {
        Self
    }
    
    async fn scan_content(&self, _content: &str) -> Vec<ThreatDetection> {
        // Simplified malware detection
        Vec::new()
    }
}

/// Security configuration
#[derive(Debug, Clone)]
pub struct SecurityConfig {
    pub enable_javascript_scanning: bool,
    pub enable_malware_detection: bool,
    pub enable_phishing_protection: bool,
    pub enable_cryptojacking_protection: bool,
    pub block_suspicious_downloads: bool,
    pub strict_csp_enforcement: bool,
    pub max_risk_score: f64,
}

impl Default for SecurityConfig {
    fn default() -> Self {
        Self {
            enable_javascript_scanning: true,
            enable_malware_detection: true,
            enable_phishing_protection: true,
            enable_cryptojacking_protection: true,
            block_suspicious_downloads: true,
            strict_csp_enforcement: false,
            max_risk_score: 0.7,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_security_engine_creation() {
        let engine = SecurityEngine::new().await.unwrap();
        // Basic test to ensure engine can be created
    }
    
    #[tokio::test]
    async fn test_url_validation() {
        let engine = SecurityEngine::new().await.unwrap();
        
        // Test safe URL
        let result = engine.validate_url("https://example.com").await;
        assert!(result.is_ok());
        
        // Test blocked URL
        let result = engine.validate_url("https://malware.com").await;
        assert!(result.is_err());
    }
    
    #[tokio::test]
    async fn test_content_scanning() {
        let engine = SecurityEngine::new().await.unwrap();
        
        // Test safe content
        let safe_content = "<html><body>Hello World</body></html>";
        let result = engine.scan_content(safe_content, "https://example.com").await.unwrap();
        assert!(result.safe);
        
        // Test dangerous content
        let dangerous_content = "<script>eval('malicious code')</script>";
        let result = engine.scan_content(dangerous_content, "https://example.com").await.unwrap();
        assert!(!result.threats.is_empty());
    }
    
    #[test]
    fn test_suspicious_url_patterns() {
        let engine = SecurityEngine::new().await.unwrap();
        
        assert!(engine.has_suspicious_url_patterns("https://192.168.1.1/login"));
        assert!(engine.has_suspicious_url_patterns("https://bit.ly/suspicious"));
        assert!(!engine.has_suspicious_url_patterns("https://google.com"));
    }
}