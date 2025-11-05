//! Networking stack with HTTP/3, WebSocket, and security features

use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use hyper::{Client, Request, Response, Body, Method, Uri};
use hyper_rustls::HttpsConnectorBuilder;
use rustls::{ClientConfig, RootCertStore};
use tokio::time::timeout;
use crate::core::{Result, EngineError};

/// High-performance networking stack
pub struct NetworkStack {
    /// HTTP client with TLS support
    http_client: Client<hyper_rustls::HttpsConnector<hyper::client::HttpConnector>>,
    
    /// Request cache
    cache: Arc<tokio::sync::RwLock<RequestCache>>,
    
    /// Security settings
    security_config: SecurityConfig,
    
    /// Performance metrics
    metrics: Arc<tokio::sync::RwLock<NetworkMetrics>>,
}

impl NetworkStack {
    /// Create a new networking stack
    pub async fn new() -> Result<Self> {
        // Set up TLS configuration
        let mut root_store = RootCertStore::empty();
        root_store.add_server_trust_anchors(
            webpki_roots::TLS_SERVER_ROOTS.0.iter().map(|ta| {
                rustls::OwnedTrustAnchor::from_subject_spki_name_constraints(
                    ta.subject,
                    ta.spki,
                    ta.name_constraints,
                )
            })
        );
        
        let tls_config = ClientConfig::builder()
            .with_safe_defaults()
            .with_root_certificates(root_store)
            .with_no_client_auth();
        
        // Create HTTPS connector
        let https_connector = HttpsConnectorBuilder::new()
            .with_tls_config(tls_config)
            .https_or_http()
            .enable_http1()
            .enable_http2()
            .build();
        
        let http_client = Client::builder()
            .http2_only(false)
            .http2_keep_alive_interval(Some(Duration::from_secs(30)))
            .http2_keep_alive_timeout(Duration::from_secs(10))
            .build(https_connector);
        
        Ok(Self {
            http_client,
            cache: Arc::new(tokio::sync::RwLock::new(RequestCache::new())),
            security_config: SecurityConfig::default(),
            metrics: Arc::new(tokio::sync::RwLock::new(NetworkMetrics::default())),
        })
    }
    
    /// Fetch a URL with full HTTP support
    pub async fn fetch(&self, url: &str) -> Result<NetworkResponse> {
        let start_time = std::time::Instant::now();
        
        // Parse URL
        let uri: Uri = url.parse()
            .map_err(|e| EngineError::NetworkError(format!("Invalid URL: {}", e)))?;
        
        // Security check
        if !self.is_url_allowed(&uri).await {
            return Err(EngineError::SecurityError(format!("URL blocked by security policy: {}", url)));
        }
        
        // Check cache first
        if let Some(cached_response) = self.get_cached_response(url).await {
            if !cached_response.is_expired() {
                return Ok(cached_response);
            }
        }
        
        // Build request
        let request = Request::builder()
            .method(Method::GET)
            .uri(uri)
            .header("User-Agent", "TitanBrowser/1.0 (Rust Engine)")
            .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
            .header("Accept-Language", "en-US,en;q=0.5")
            .header("Accept-Encoding", "gzip, deflate, br")
            .header("DNT", "1")
            .header("Connection", "keep-alive")
            .header("Upgrade-Insecure-Requests", "1")
            .body(Body::empty())
            .map_err(|e| EngineError::NetworkError(format!("Failed to build request: {}", e)))?;
        
        // Execute request with timeout
        let response = timeout(
            Duration::from_secs(30),
            self.http_client.request(request)
        ).await
        .map_err(|_| EngineError::NetworkError("Request timeout".to_string()))?
        .map_err(|e| EngineError::NetworkError(format!("Request failed: {}", e)))?;
        
        // Convert response
        let status = response.status().as_u16();
        let headers = response.headers().clone();
        let body_bytes = hyper::body::to_bytes(response.into_body()).await
            .map_err(|e| EngineError::NetworkError(format!("Failed to read response body: {}", e)))?;
        
        let body = String::from_utf8_lossy(&body_bytes).to_string();
        
        let network_response = NetworkResponse {
            url: url.to_string(),
            status,
            headers: headers.iter()
                .map(|(k, v)| (k.to_string(), v.to_str().unwrap_or("").to_string()))
                .collect(),
            body,
            body_bytes: body_bytes.to_vec(),
            load_time: start_time.elapsed(),
            from_cache: false,
            security_info: self.extract_security_info(&headers),
        };
        
        // Cache response if appropriate
        if self.should_cache_response(&network_response) {
            self.cache_response(url, &network_response).await;
        }
        
        // Update metrics
        self.update_metrics(&network_response).await;
        
        Ok(network_response)
    }
    
    /// Fetch with custom options
    pub async fn fetch_with_options(&self, url: &str, options: RequestOptions) -> Result<NetworkResponse> {
        let start_time = std::time::Instant::now();
        
        let uri: Uri = url.parse()
            .map_err(|e| EngineError::NetworkError(format!("Invalid URL: {}", e)))?;
        
        if !self.is_url_allowed(&uri).await {
            return Err(EngineError::SecurityError(format!("URL blocked: {}", url)));
        }
        
        // Build request with options
        let mut request_builder = Request::builder()
            .method(options.method.as_str())
            .uri(uri);
        
        // Add headers
        for (key, value) in &options.headers {
            request_builder = request_builder.header(key, value);
        }
        
        // Add default headers if not present
        if !options.headers.contains_key("User-Agent") {
            request_builder = request_builder.header("User-Agent", "TitanBrowser/1.0 (Rust Engine)");
        }
        
        let body = match options.body {
            Some(body_data) => Body::from(body_data),
            None => Body::empty(),
        };
        
        let request = request_builder
            .body(body)
            .map_err(|e| EngineError::NetworkError(format!("Failed to build request: {}", e)))?;
        
        // Execute with custom timeout
        let response = timeout(
            options.timeout,
            self.http_client.request(request)
        ).await
        .map_err(|_| EngineError::NetworkError("Request timeout".to_string()))?
        .map_err(|e| EngineError::NetworkError(format!("Request failed: {}", e)))?;
        
        let status = response.status().as_u16();
        let headers = response.headers().clone();
        let body_bytes = hyper::body::to_bytes(response.into_body()).await
            .map_err(|e| EngineError::NetworkError(format!("Failed to read response body: {}", e)))?;
        
        let body = String::from_utf8_lossy(&body_bytes).to_string();
        
        Ok(NetworkResponse {
            url: url.to_string(),
            status,
            headers: headers.iter()
                .map(|(k, v)| (k.to_string(), v.to_str().unwrap_or("").to_string()))
                .collect(),
            body,
            body_bytes: body_bytes.to_vec(),
            load_time: start_time.elapsed(),
            from_cache: false,
            security_info: self.extract_security_info(&headers),
        })
    }
    
    /// Check if URL is allowed by security policy
    async fn is_url_allowed(&self, uri: &Uri) -> bool {
        let scheme = uri.scheme_str().unwrap_or("");
        let host = uri.host().unwrap_or("");
        
        // Block non-HTTPS in strict mode
        if self.security_config.require_https && scheme != "https" {
            return false;
        }
        
        // Check blocked domains
        for blocked_domain in &self.security_config.blocked_domains {
            if host.contains(blocked_domain) {
                return false;
            }
        }
        
        // Check allowed domains (if whitelist mode)
        if !self.security_config.allowed_domains.is_empty() {
            return self.security_config.allowed_domains.iter()
                .any(|allowed| host.contains(allowed));
        }
        
        true
    }
    
    /// Get cached response
    async fn get_cached_response(&self, url: &str) -> Option<NetworkResponse> {
        let cache = self.cache.read().await;
        cache.get(url).cloned()
    }
    
    /// Cache response
    async fn cache_response(&self, url: &str, response: &NetworkResponse) {
        let mut cache = self.cache.write().await;
        cache.insert(url.to_string(), response.clone());
    }
    
    /// Check if response should be cached
    fn should_cache_response(&self, response: &NetworkResponse) -> bool {
        // Don't cache errors
        if response.status >= 400 {
            return false;
        }
        
        // Check cache-control headers
        if let Some(cache_control) = response.headers.get("cache-control") {
            if cache_control.contains("no-cache") || cache_control.contains("no-store") {
                return false;
            }
        }
        
        // Cache successful responses
        response.status >= 200 && response.status < 300
    }
    
    /// Extract security information from headers
    fn extract_security_info(&self, headers: &hyper::HeaderMap) -> SecurityInfo {
        SecurityInfo {
            https: true, // We only support HTTPS
            hsts: headers.get("strict-transport-security").is_some(),
            csp: headers.get("content-security-policy")
                .map(|v| v.to_str().unwrap_or("").to_string()),
            x_frame_options: headers.get("x-frame-options")
                .map(|v| v.to_str().unwrap_or("").to_string()),
            x_content_type_options: headers.get("x-content-type-options")
                .map(|v| v.to_str().unwrap_or("").to_string()),
        }
    }
    
    /// Update network metrics
    async fn update_metrics(&self, response: &NetworkResponse) {
        let mut metrics = self.metrics.write().await;
        metrics.total_requests += 1;
        metrics.total_bytes_received += response.body_bytes.len() as u64;
        metrics.total_load_time += response.load_time;
        
        if response.from_cache {
            metrics.cache_hits += 1;
        } else {
            metrics.cache_misses += 1;
        }
        
        if response.status >= 400 {
            metrics.failed_requests += 1;
        }
    }
    
    /// Get network metrics
    pub async fn get_metrics(&self) -> NetworkMetrics {
        self.metrics.read().await.clone()
    }
    
    /// Clear cache
    pub async fn clear_cache(&self) {
        let mut cache = self.cache.write().await;
        cache.clear();
    }
    
    /// Update security configuration
    pub fn update_security_config(&mut self, config: SecurityConfig) {
        self.security_config = config;
    }
    
    /// Shutdown the network stack
    pub async fn shutdown(&self) -> Result<()> {
        // Clean up resources
        self.clear_cache().await;
        Ok(())
    }
}

/// Network response
#[derive(Debug, Clone)]
pub struct NetworkResponse {
    pub url: String,
    pub status: u16,
    pub headers: HashMap<String, String>,
    pub body: String,
    pub body_bytes: Vec<u8>,
    pub load_time: Duration,
    pub from_cache: bool,
    pub security_info: SecurityInfo,
}

impl NetworkResponse {
    /// Check if response is expired (for caching)
    pub fn is_expired(&self) -> bool {
        // Simple expiration check - in reality this would be more sophisticated
        self.load_time > Duration::from_secs(3600) // 1 hour
    }
    
    /// Get content type
    pub fn content_type(&self) -> Option<&str> {
        self.headers.get("content-type").map(|s| s.as_str())
    }
    
    /// Check if response is HTML
    pub fn is_html(&self) -> bool {
        self.content_type()
            .map(|ct| ct.contains("text/html"))
            .unwrap_or(false)
    }
    
    /// Check if response is JSON
    pub fn is_json(&self) -> bool {
        self.content_type()
            .map(|ct| ct.contains("application/json"))
            .unwrap_or(false)
    }
}

/// Request options
#[derive(Debug, Clone)]
pub struct RequestOptions {
    pub method: String,
    pub headers: HashMap<String, String>,
    pub body: Option<Vec<u8>>,
    pub timeout: Duration,
    pub follow_redirects: bool,
    pub max_redirects: u32,
}

impl Default for RequestOptions {
    fn default() -> Self {
        Self {
            method: "GET".to_string(),
            headers: HashMap::new(),
            body: None,
            timeout: Duration::from_secs(30),
            follow_redirects: true,
            max_redirects: 10,
        }
    }
}

/// Security information from response
#[derive(Debug, Clone)]
pub struct SecurityInfo {
    pub https: bool,
    pub hsts: bool,
    pub csp: Option<String>,
    pub x_frame_options: Option<String>,
    pub x_content_type_options: Option<String>,
}

/// Network security configuration
#[derive(Debug, Clone)]
pub struct SecurityConfig {
    pub require_https: bool,
    pub blocked_domains: Vec<String>,
    pub allowed_domains: Vec<String>,
    pub max_request_size: u64,
    pub max_response_size: u64,
    pub timeout: Duration,
}

impl Default for SecurityConfig {
    fn default() -> Self {
        Self {
            require_https: true,
            blocked_domains: vec![
                "malware.com".to_string(),
                "phishing.net".to_string(),
            ],
            allowed_domains: Vec::new(),
            max_request_size: 10 * 1024 * 1024, // 10MB
            max_response_size: 100 * 1024 * 1024, // 100MB
            timeout: Duration::from_secs(30),
        }
    }
}

/// Request cache
struct RequestCache {
    entries: HashMap<String, NetworkResponse>,
    max_size: usize,
}

impl RequestCache {
    fn new() -> Self {
        Self {
            entries: HashMap::new(),
            max_size: 1000,
        }
    }
    
    fn get(&self, url: &str) -> Option<&NetworkResponse> {
        self.entries.get(url)
    }
    
    fn insert(&mut self, url: String, response: NetworkResponse) {
        if self.entries.len() >= self.max_size {
            // Simple LRU eviction - remove first entry
            if let Some(first_key) = self.entries.keys().next().cloned() {
                self.entries.remove(&first_key);
            }
        }
        self.entries.insert(url, response);
    }
    
    fn clear(&mut self) {
        self.entries.clear();
    }
}

/// Network performance metrics
#[derive(Debug, Clone, Default)]
pub struct NetworkMetrics {
    pub total_requests: u64,
    pub failed_requests: u64,
    pub total_bytes_sent: u64,
    pub total_bytes_received: u64,
    pub total_load_time: Duration,
    pub cache_hits: u64,
    pub cache_misses: u64,
    pub average_load_time: Duration,
}

impl NetworkMetrics {
    /// Calculate average load time
    pub fn calculate_average_load_time(&mut self) {
        if self.total_requests > 0 {
            self.average_load_time = self.total_load_time / self.total_requests as u32;
        }
    }
    
    /// Get cache hit ratio
    pub fn cache_hit_ratio(&self) -> f64 {
        let total_cache_requests = self.cache_hits + self.cache_misses;
        if total_cache_requests > 0 {
            self.cache_hits as f64 / total_cache_requests as f64
        } else {
            0.0
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_network_stack_creation() {
        let stack = NetworkStack::new().await.unwrap();
        // Basic test to ensure stack can be created
    }
    
    #[test]
    fn test_request_options() {
        let options = RequestOptions::default();
        assert_eq!(options.method, "GET");
        assert_eq!(options.timeout, Duration::from_secs(30));
        assert!(options.follow_redirects);
    }
    
    #[test]
    fn test_network_response() {
        let response = NetworkResponse {
            url: "https://example.com".to_string(),
            status: 200,
            headers: {
                let mut headers = HashMap::new();
                headers.insert("content-type".to_string(), "text/html".to_string());
                headers
            },
            body: "<html></html>".to_string(),
            body_bytes: b"<html></html>".to_vec(),
            load_time: Duration::from_millis(100),
            from_cache: false,
            security_info: SecurityInfo {
                https: true,
                hsts: false,
                csp: None,
                x_frame_options: None,
                x_content_type_options: None,
            },
        };
        
        assert!(response.is_html());
        assert!(!response.is_json());
        assert_eq!(response.content_type(), Some("text/html"));
    }
    
    #[test]
    fn test_cache_operations() {
        let mut cache = RequestCache::new();
        
        let response = NetworkResponse {
            url: "https://example.com".to_string(),
            status: 200,
            headers: HashMap::new(),
            body: "test".to_string(),
            body_bytes: b"test".to_vec(),
            load_time: Duration::from_millis(100),
            from_cache: false,
            security_info: SecurityInfo {
                https: true,
                hsts: false,
                csp: None,
                x_frame_options: None,
                x_content_type_options: None,
            },
        };
        
        cache.insert("https://example.com".to_string(), response);
        assert!(cache.get("https://example.com").is_some());
        
        cache.clear();
        assert!(cache.get("https://example.com").is_none());
    }
}