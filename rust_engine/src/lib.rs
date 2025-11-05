//! Titan Browser Engine - Custom Rust-based Web Engine
//! 
//! This is the core implementation of Titan's custom browser engine,
//! built from the ground up in Rust for maximum performance, security,
//! and AI integration.

pub mod core;
pub mod html;
pub mod css;
pub mod layout;
pub mod rendering;
pub mod javascript;
pub mod networking;
pub mod media;
pub mod storage;
pub mod security;
pub mod ai;
pub mod ffi;

// Re-export main types for easier access
pub use core::*;
pub use html::{HTMLParser, Document, Element};
pub use css::{CSSEngine, ComputedStyle};
pub use layout::{LayoutEngine, LayoutTree};
pub use rendering::{RenderingEngine, RenderTree};
pub use javascript::{JSRuntime, JSValue};
pub use networking::{NetworkStack, NetworkResponse};
pub use media::{MediaEngine, MediaElement};
pub use storage::{StorageEngine, Bookmark, HistoryEntry};
pub use security::{SecurityEngine, SecurityEvent};
pub use ai::{AIEngine, PageContext, AIInsight};

use std::sync::Arc;
use tokio::sync::RwLock;
use anyhow::Result;

/// Main engine instance that coordinates all subsystems
pub struct TitanEngine {
    /// HTML parser for processing web content
    pub html_parser: Arc<html::HTMLParser>,
    
    /// CSS engine for styling and layout
    pub css_engine: Arc<css::CSSEngine>,
    
    /// Layout engine for computing element positions
    pub layout_engine: Arc<RwLock<layout::LayoutEngine>>,
    
    /// Rendering engine for GPU-accelerated display
    pub rendering_engine: Arc<RwLock<rendering::RenderingEngine>>,
    
    /// JavaScript runtime for script execution
    pub js_runtime: Arc<RwLock<javascript::JSRuntime>>,
    
    /// Network stack for HTTP/WebSocket/WebRTC
    pub network_stack: Arc<networking::NetworkStack>,
    
    /// Media engine for audio/video processing
    pub media_engine: Arc<media::MediaEngine>,
    
    /// Storage system for persistent data
    pub storage: Arc<storage::StorageEngine>,
    
    /// Security monitor for threat detection
    pub security: Arc<security::SecurityEngine>,
    
    /// AI integration for intelligent features
    pub ai_engine: Arc<ai::AIEngine>,
}

impl TitanEngine {
    /// Initialize the Titan Engine with default configuration
    pub async fn new() -> Result<Self> {
        log::info!("Initializing Titan Browser Engine");
        
        let html_parser = Arc::new(html::HTMLParser::new());
        let css_engine = Arc::new(css::CSSEngine::new());
        let layout_engine = Arc::new(RwLock::new(layout::LayoutEngine::new()));
        let rendering_engine = Arc::new(RwLock::new(rendering::RenderingEngine::new().await?));
        let js_runtime = Arc::new(RwLock::new(javascript::JSRuntime::new().await?));
        let network_stack = Arc::new(networking::NetworkStack::new().await?);
        let media_engine = Arc::new(media::MediaEngine::new().await?);
        let storage = Arc::new(storage::StorageEngine::new().await?);
        let security = Arc::new(security::SecurityEngine::new().await?);
        let ai_engine = Arc::new(ai::AIEngine::new().await?);
        
        Ok(Self {
            html_parser,
            css_engine,
            layout_engine,
            rendering_engine,
            js_runtime,
            network_stack,
            media_engine,
            storage,
            security,
            ai_engine,
        })
    }
    
    /// Load and render a web page
    pub async fn load_page(&self, url: &str) -> Result<core::PageHandle> {
        log::info!("Loading page: {}", url);
        
        // Security check
        self.security.validate_url(url).await?;
        
        // Fetch content
        let response = self.network_stack.fetch(url).await?;
        
        // Parse HTML
        let document = self.html_parser.parse(&response.body)?;
        
        // Parse CSS
        let stylesheets = self.css_engine.parse_stylesheets(&document).await?;
        
        // Compute layout
        let mut layout_engine = self.layout_engine.write().await;
        let layout_tree = layout_engine.compute_layout(&document, &stylesheets).await?;
        
        // Execute JavaScript
        let mut js_runtime = self.js_runtime.write().await;
        js_runtime.execute_page_scripts(&document).await?;
        
        // Render page
        let mut rendering_engine = self.rendering_engine.write().await;
        let render_tree = rendering_engine.create_render_tree(&layout_tree).await?;
        
        // AI analysis
        let ai_context = self.ai_engine.analyze_page(&document, &response).await?;
        
        Ok(core::PageHandle::new(document, layout_tree, render_tree, ai_context))
    }
    
    /// Shutdown the engine gracefully
    pub async fn shutdown(&self) -> Result<()> {
        log::info!("Shutting down Titan Browser Engine");
        
        // Shutdown subsystems in reverse order
        self.ai_engine.shutdown().await?;
        self.security.shutdown().await?;
        self.storage.shutdown().await?;
        self.media_engine.shutdown().await?;
        self.network_stack.shutdown().await?;
        
        {
            let mut js_runtime = self.js_runtime.write().await;
            js_runtime.shutdown().await?;
        }
        
        {
            let mut rendering_engine = self.rendering_engine.write().await;
            rendering_engine.shutdown().await?;
        }
        
        Ok(())
    }
}

/// Engine configuration options
#[derive(Debug, Clone)]
pub struct EngineConfig {
    /// Enable JavaScript execution
    pub javascript_enabled: bool,
    
    /// Enable WebGL rendering
    pub webgl_enabled: bool,
    
    /// Enable media playback
    pub media_enabled: bool,
    
    /// Enable AI features
    pub ai_enabled: bool,
    
    /// Security level (0-3, higher is more restrictive)
    pub security_level: u8,
    
    /// User agent string
    pub user_agent: String,
    
    /// Maximum memory usage in MB
    pub max_memory_mb: u64,
    
    /// Enable hardware acceleration
    pub hardware_acceleration: bool,
}

impl Default for EngineConfig {
    fn default() -> Self {
        Self {
            javascript_enabled: true,
            webgl_enabled: true,
            media_enabled: true,
            ai_enabled: true,
            security_level: 2,
            user_agent: "TitanBrowser/1.0 (Rust Engine)".to_string(),
            max_memory_mb: 2048,
            hardware_acceleration: true,
        }
    }
}

/// Initialize logging for the engine
pub fn init_logging() {
    env_logger::Builder::from_default_env()
        .filter_level(log::LevelFilter::Info)
        .init();
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_engine_initialization() {
        init_logging();
        let engine = TitanEngine::new().await.unwrap();
        engine.shutdown().await.unwrap();
    }
    
    #[tokio::test]
    async fn test_simple_page_load() {
        init_logging();
        let engine = TitanEngine::new().await.unwrap();
        
        // This would require a test server, so we'll skip for now
        // let page = engine.load_page("http://example.com").await.unwrap();
        
        engine.shutdown().await.unwrap();
    }
}