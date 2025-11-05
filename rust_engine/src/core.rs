//! Core types and structures for the Titan Engine

use std::collections::HashMap;
use std::sync::Arc;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Unique identifier for DOM elements
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ElementId(pub Uuid);

impl ElementId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

/// Represents a loaded web page with all its components
#[derive(Debug)]
pub struct PageHandle {
    pub id: Uuid,
    pub url: String,
    pub document: Arc<crate::html::Document>,
    pub layout_tree: Arc<crate::layout::LayoutTree>,
    pub render_tree: Arc<crate::rendering::RenderTree>,
    pub ai_context: Arc<crate::ai::PageContext>,
    pub metadata: PageMetadata,
}

impl PageHandle {
    pub fn new(
        document: crate::html::Document,
        layout_tree: crate::layout::LayoutTree,
        render_tree: crate::rendering::RenderTree,
        ai_context: crate::ai::PageContext,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            url: document.url.clone(),
            document: Arc::new(document),
            layout_tree: Arc::new(layout_tree),
            render_tree: Arc::new(render_tree),
            ai_context: Arc::new(ai_context),
            metadata: PageMetadata::default(),
        }
    }
}

/// Metadata about a loaded page
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct PageMetadata {
    pub title: String,
    pub description: Option<String>,
    pub keywords: Vec<String>,
    pub language: Option<String>,
    pub load_time_ms: u64,
    pub resource_count: u32,
    pub security_score: f32,
    pub ai_insights: Vec<String>,
}

/// Represents a point in 2D space
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Point {
    pub x: f32,
    pub y: f32,
}

impl Point {
    pub fn new(x: f32, y: f32) -> Self {
        Self { x, y }
    }
    
    pub fn zero() -> Self {
        Self { x: 0.0, y: 0.0 }
    }
}

/// Represents a size in 2D space
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Size {
    pub width: f32,
    pub height: f32,
}

impl Size {
    pub fn new(width: f32, height: f32) -> Self {
        Self { width, height }
    }
    
    pub fn zero() -> Self {
        Self { width: 0.0, height: 0.0 }
    }
}

/// Represents a rectangle in 2D space
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Rect {
    pub origin: Point,
    pub size: Size,
}

impl Rect {
    pub fn new(x: f32, y: f32, width: f32, height: f32) -> Self {
        Self {
            origin: Point::new(x, y),
            size: Size::new(width, height),
        }
    }
    
    pub fn zero() -> Self {
        Self {
            origin: Point::zero(),
            size: Size::zero(),
        }
    }
    
    pub fn contains_point(&self, point: Point) -> bool {
        point.x >= self.origin.x
            && point.x <= self.origin.x + self.size.width
            && point.y >= self.origin.y
            && point.y <= self.origin.y + self.size.height
    }
}

/// Color representation with RGBA components
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Color {
    pub r: f32,
    pub g: f32,
    pub b: f32,
    pub a: f32,
}

impl Color {
    pub fn new(r: f32, g: f32, b: f32, a: f32) -> Self {
        Self { r, g, b, a }
    }
    
    pub fn rgb(r: f32, g: f32, b: f32) -> Self {
        Self::new(r, g, b, 1.0)
    }
    
    pub fn transparent() -> Self {
        Self::new(0.0, 0.0, 0.0, 0.0)
    }
    
    pub fn black() -> Self {
        Self::rgb(0.0, 0.0, 0.0)
    }
    
    pub fn white() -> Self {
        Self::rgb(1.0, 1.0, 1.0)
    }
}

/// Event types that can occur in the browser
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum BrowserEvent {
    /// Page navigation started
    NavigationStarted { url: String },
    
    /// Page loading progress
    LoadProgress { progress: f32 },
    
    /// Page load completed
    LoadCompleted { 
        url: String, 
        load_time_ms: u64,
        success: bool,
    },
    
    /// JavaScript console message
    ConsoleMessage {
        level: ConsoleLevel,
        message: String,
        source: String,
        line: u32,
    },
    
    /// Security event detected
    SecurityEvent {
        event_type: SecurityEventType,
        severity: SecuritySeverity,
        description: String,
    },
    
    /// AI insight generated
    AIInsight {
        insight_type: String,
        content: String,
        confidence: f32,
    },
    
    /// User interaction
    UserInteraction {
        interaction_type: InteractionType,
        element_id: Option<ElementId>,
        position: Point,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ConsoleLevel {
    Log,
    Info,
    Warn,
    Error,
    Debug,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SecurityEventType {
    MaliciousScript,
    SuspiciousDownload,
    PhishingAttempt,
    DataExfiltration,
    CryptojackingAttempt,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SecuritySeverity {
    Low,
    Medium,
    High,
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum InteractionType {
    Click,
    DoubleClick,
    RightClick,
    Hover,
    KeyPress,
    Scroll,
    Touch,
}

/// Performance metrics for monitoring
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct PerformanceMetrics {
    pub memory_usage_mb: f64,
    pub cpu_usage_percent: f64,
    pub gpu_usage_percent: f64,
    pub network_bytes_sent: u64,
    pub network_bytes_received: u64,
    pub render_fps: f32,
    pub javascript_execution_time_ms: u64,
    pub layout_time_ms: u64,
    pub paint_time_ms: u64,
}

/// Configuration for engine behavior
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EngineSettings {
    pub javascript_enabled: bool,
    pub images_enabled: bool,
    pub css_enabled: bool,
    pub plugins_enabled: bool,
    pub webgl_enabled: bool,
    pub webassembly_enabled: bool,
    pub local_storage_enabled: bool,
    pub cookies_enabled: bool,
    pub geolocation_enabled: bool,
    pub notifications_enabled: bool,
    pub microphone_enabled: bool,
    pub camera_enabled: bool,
    pub user_agent: String,
    pub accept_language: String,
    pub timezone: String,
    pub max_memory_mb: u64,
    pub max_cache_size_mb: u64,
}

impl Default for EngineSettings {
    fn default() -> Self {
        Self {
            javascript_enabled: true,
            images_enabled: true,
            css_enabled: true,
            plugins_enabled: false,
            webgl_enabled: true,
            webassembly_enabled: true,
            local_storage_enabled: true,
            cookies_enabled: true,
            geolocation_enabled: false,
            notifications_enabled: false,
            microphone_enabled: false,
            camera_enabled: false,
            user_agent: "TitanBrowser/1.0 (Rust Engine)".to_string(),
            accept_language: "en-US,en;q=0.9".to_string(),
            timezone: "UTC".to_string(),
            max_memory_mb: 2048,
            max_cache_size_mb: 512,
        }
    }
}

/// Error types for the engine
#[derive(Debug, thiserror::Error)]
pub enum EngineError {
    #[error("HTML parsing error: {0}")]
    HtmlParseError(String),
    
    #[error("CSS parsing error: {0}")]
    CssParseError(String),
    
    #[error("JavaScript execution error: {0}")]
    JavaScriptError(String),
    
    #[error("Network error: {0}")]
    NetworkError(String),
    
    #[error("Rendering error: {0}")]
    RenderingError(String),
    
    #[error("Security violation: {0}")]
    SecurityError(String),
    
    #[error("AI processing error: {0}")]
    AIError(String),
    
    #[error("Storage error: {0}")]
    StorageError(String),
    
    #[error("Media error: {0}")]
    MediaError(String),
    
    #[error("Configuration error: {0}")]
    ConfigError(String),
    
    #[error("Internal error: {0}")]
    InternalError(String),
}

pub type Result<T> = std::result::Result<T, EngineError>;

/// Trait for components that can be shut down gracefully
#[async_trait::async_trait]
pub trait Shutdown {
    async fn shutdown(&self) -> Result<()>;
}

/// Trait for components that can report performance metrics
pub trait MetricsReporter {
    fn get_metrics(&self) -> PerformanceMetrics;
}

/// Trait for components that can handle events
#[async_trait::async_trait]
pub trait EventHandler {
    async fn handle_event(&self, event: BrowserEvent) -> Result<()>;
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_point_operations() {
        let p1 = Point::new(10.0, 20.0);
        let p2 = Point::zero();
        
        assert_eq!(p1.x, 10.0);
        assert_eq!(p1.y, 20.0);
        assert_eq!(p2.x, 0.0);
        assert_eq!(p2.y, 0.0);
    }
    
    #[test]
    fn test_rect_contains_point() {
        let rect = Rect::new(10.0, 10.0, 100.0, 100.0);
        let inside = Point::new(50.0, 50.0);
        let outside = Point::new(5.0, 5.0);
        
        assert!(rect.contains_point(inside));
        assert!(!rect.contains_point(outside));
    }
    
    #[test]
    fn test_color_creation() {
        let red = Color::rgb(1.0, 0.0, 0.0);
        let transparent = Color::transparent();
        
        assert_eq!(red.r, 1.0);
        assert_eq!(red.a, 1.0);
        assert_eq!(transparent.a, 0.0);
    }
}