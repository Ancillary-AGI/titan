//! Media engine for audio/video processing using GStreamer

use std::collections::HashMap;
use std::sync::Arc;
use gstreamer as gst;
use gstreamer_video as gst_video;
use gstreamer_audio as gst_audio;
use crate::core::{ElementId, Result, EngineError};

/// Media engine for handling audio and video content
pub struct MediaEngine {
    /// GStreamer pipeline manager
    pipeline_manager: Arc<tokio::sync::RwLock<PipelineManager>>,
    
    /// Active media elements
    media_elements: HashMap<ElementId, MediaElement>,
    
    /// Media capabilities
    capabilities: MediaCapabilities,
}

impl MediaEngine {
    /// Create a new media engine
    pub async fn new() -> Result<Self> {
        // Initialize GStreamer
        gst::init().map_err(|e| EngineError::MediaError(format!("Failed to initialize GStreamer: {}", e)))?;
        
        let capabilities = MediaCapabilities::detect().await?;
        
        Ok(Self {
            pipeline_manager: Arc::new(tokio::sync::RwLock::new(PipelineManager::new())),
            media_elements: HashMap::new(),
            capabilities,
        })
    }
    
    /// Create a media element for video playback
    pub async fn create_video_element(&mut self, element_id: ElementId, src: &str) -> Result<()> {
        let pipeline = self.create_video_pipeline(src).await?;
        
        let media_element = MediaElement {
            element_id,
            media_type: MediaType::Video,
            src: src.to_string(),
            pipeline: Some(pipeline),
            state: MediaState::Stopped,
            volume: 1.0,
            muted: false,
            current_time: 0.0,
            duration: 0.0,
        };
        
        self.media_elements.insert(element_id, media_element);
        
        Ok(())
    }
    
    /// Create a media element for audio playback
    pub async fn create_audio_element(&mut self, element_id: ElementId, src: &str) -> Result<()> {
        let pipeline = self.create_audio_pipeline(src).await?;
        
        let media_element = MediaElement {
            element_id,
            media_type: MediaType::Audio,
            src: src.to_string(),
            pipeline: Some(pipeline),
            state: MediaState::Stopped,
            volume: 1.0,
            muted: false,
            current_time: 0.0,
            duration: 0.0,
        };
        
        self.media_elements.insert(element_id, media_element);
        
        Ok(())
    }
    
    /// Play media element
    pub async fn play(&mut self, element_id: ElementId) -> Result<()> {
        if let Some(media_element) = self.media_elements.get_mut(&element_id) {
            if let Some(pipeline) = &media_element.pipeline {
                pipeline.set_state(gst::State::Playing)
                    .map_err(|e| EngineError::MediaError(format!("Failed to play media: {:?}", e)))?;
                
                media_element.state = MediaState::Playing;
            }
        }
        
        Ok(())
    }
    
    /// Pause media element
    pub async fn pause(&mut self, element_id: ElementId) -> Result<()> {
        if let Some(media_element) = self.media_elements.get_mut(&element_id) {
            if let Some(pipeline) = &media_element.pipeline {
                pipeline.set_state(gst::State::Paused)
                    .map_err(|e| EngineError::MediaError(format!("Failed to pause media: {:?}", e)))?;
                
                media_element.state = MediaState::Paused;
            }
        }
        
        Ok(())
    }
    
    /// Stop media element
    pub async fn stop(&mut self, element_id: ElementId) -> Result<()> {
        if let Some(media_element) = self.media_elements.get_mut(&element_id) {
            if let Some(pipeline) = &media_element.pipeline {
                pipeline.set_state(gst::State::Null)
                    .map_err(|e| EngineError::MediaError(format!("Failed to stop media: {:?}", e)))?;
                
                media_element.state = MediaState::Stopped;
                media_element.current_time = 0.0;
            }
        }
        
        Ok(())
    }
    
    /// Set volume for media element
    pub async fn set_volume(&mut self, element_id: ElementId, volume: f64) -> Result<()> {
        if let Some(media_element) = self.media_elements.get_mut(&element_id) {
            media_element.volume = volume.clamp(0.0, 1.0);
            
            // Update pipeline volume
            if let Some(pipeline) = &media_element.pipeline {
                if let Some(volume_element) = pipeline.by_name("volume") {
                    volume_element.set_property("volume", &media_element.volume);
                }
            }
        }
        
        Ok(())
    }
    
    /// Set mute state for media element
    pub async fn set_muted(&mut self, element_id: ElementId, muted: bool) -> Result<()> {
        if let Some(media_element) = self.media_elements.get_mut(&element_id) {
            media_element.muted = muted;
            
            // Update pipeline mute
            if let Some(pipeline) = &media_element.pipeline {
                if let Some(volume_element) = pipeline.by_name("volume") {
                    volume_element.set_property("mute", &muted);
                }
            }
        }
        
        Ok(())
    }
    
    /// Seek to specific time
    pub async fn seek(&mut self, element_id: ElementId, time: f64) -> Result<()> {
        if let Some(media_element) = self.media_elements.get_mut(&element_id) {
            if let Some(pipeline) = &media_element.pipeline {
                let seek_time = gst::ClockTime::from_seconds(time as u64);
                
                pipeline.seek_simple(
                    gst::SeekFlags::FLUSH | gst::SeekFlags::KEY_UNIT,
                    seek_time,
                ).map_err(|e| EngineError::MediaError(format!("Failed to seek: {:?}", e)))?;
                
                media_element.current_time = time;
            }
        }
        
        Ok(())
    }
    
    /// Get current playback time
    pub async fn get_current_time(&self, element_id: ElementId) -> Option<f64> {
        if let Some(media_element) = self.media_elements.get(&element_id) {
            if let Some(pipeline) = &media_element.pipeline {
                if let Some(position) = pipeline.query_position::<gst::ClockTime>() {
                    return Some(position.seconds() as f64);
                }
            }
        }
        
        None
    }
    
    /// Get media duration
    pub async fn get_duration(&self, element_id: ElementId) -> Option<f64> {
        if let Some(media_element) = self.media_elements.get(&element_id) {
            if let Some(pipeline) = &media_element.pipeline {
                if let Some(duration) = pipeline.query_duration::<gst::ClockTime>() {
                    return Some(duration.seconds() as f64);
                }
            }
        }
        
        None
    }
    
    /// Create video pipeline
    async fn create_video_pipeline(&self, src: &str) -> Result<gst::Pipeline> {
        let pipeline = gst::Pipeline::new(None);
        
        // Create elements
        let source = gst::ElementFactory::make("uridecodebin", Some("source"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create source: {}", e)))?;
        
        let videoconvert = gst::ElementFactory::make("videoconvert", Some("videoconvert"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create videoconvert: {}", e)))?;
        
        let videoscale = gst::ElementFactory::make("videoscale", Some("videoscale"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create videoscale: {}", e)))?;
        
        let sink = gst::ElementFactory::make("appsink", Some("sink"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create sink: {}", e)))?;
        
        // Configure source
        source.set_property("uri", &src);
        
        // Configure sink
        let caps = gst_video::VideoCapsBuilder::new()
            .format(gst_video::VideoFormat::Rgba)
            .build();
        sink.set_property("caps", &caps);
        sink.set_property("emit-signals", &true);
        
        // Add elements to pipeline
        pipeline.add_many(&[&source, &videoconvert, &videoscale, &sink])
            .map_err(|e| EngineError::MediaError(format!("Failed to add elements: {}", e)))?;
        
        // Link elements (will be done dynamically when pads are available)
        gst::Element::link_many(&[&videoconvert, &videoscale, &sink])
            .map_err(|e| EngineError::MediaError(format!("Failed to link elements: {}", e)))?;
        
        // Connect pad-added signal for dynamic linking
        source.connect_pad_added(move |_, pad| {
            let caps = pad.current_caps().unwrap();
            let structure = caps.structure(0).unwrap();
            let name = structure.name();
            
            if name.starts_with("video/") {
                let sink_pad = videoconvert.static_pad("sink").unwrap();
                if sink_pad.is_linked() {
                    return;
                }
                
                let _ = pad.link(&sink_pad);
            }
        });
        
        Ok(pipeline)
    }
    
    /// Create audio pipeline
    async fn create_audio_pipeline(&self, src: &str) -> Result<gst::Pipeline> {
        let pipeline = gst::Pipeline::new(None);
        
        // Create elements
        let source = gst::ElementFactory::make("uridecodebin", Some("source"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create source: {}", e)))?;
        
        let audioconvert = gst::ElementFactory::make("audioconvert", Some("audioconvert"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create audioconvert: {}", e)))?;
        
        let audioresample = gst::ElementFactory::make("audioresample", Some("audioresample"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create audioresample: {}", e)))?;
        
        let volume = gst::ElementFactory::make("volume", Some("volume"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create volume: {}", e)))?;
        
        let sink = gst::ElementFactory::make("autoaudiosink", Some("sink"))
            .map_err(|e| EngineError::MediaError(format!("Failed to create sink: {}", e)))?;
        
        // Configure source
        source.set_property("uri", &src);
        
        // Add elements to pipeline
        pipeline.add_many(&[&source, &audioconvert, &audioresample, &volume, &sink])
            .map_err(|e| EngineError::MediaError(format!("Failed to add elements: {}", e)))?;
        
        // Link elements
        gst::Element::link_many(&[&audioconvert, &audioresample, &volume, &sink])
            .map_err(|e| EngineError::MediaError(format!("Failed to link elements: {}", e)))?;
        
        // Connect pad-added signal
        source.connect_pad_added(move |_, pad| {
            let caps = pad.current_caps().unwrap();
            let structure = caps.structure(0).unwrap();
            let name = structure.name();
            
            if name.starts_with("audio/") {
                let sink_pad = audioconvert.static_pad("sink").unwrap();
                if sink_pad.is_linked() {
                    return;
                }
                
                let _ = pad.link(&sink_pad);
            }
        });
        
        Ok(pipeline)
    }
    
    /// Get media capabilities
    pub fn get_capabilities(&self) -> &MediaCapabilities {
        &self.capabilities
    }
    
    /// Remove media element
    pub async fn remove_element(&mut self, element_id: ElementId) -> Result<()> {
        if let Some(media_element) = self.media_elements.remove(&element_id) {
            if let Some(pipeline) = media_element.pipeline {
                pipeline.set_state(gst::State::Null)
                    .map_err(|e| EngineError::MediaError(format!("Failed to stop pipeline: {:?}", e)))?;
            }
        }
        
        Ok(())
    }
    
    /// Shutdown media engine
    pub async fn shutdown(&self) -> Result<()> {
        // Stop all pipelines
        for media_element in self.media_elements.values() {
            if let Some(pipeline) = &media_element.pipeline {
                let _ = pipeline.set_state(gst::State::Null);
            }
        }
        
        Ok(())
    }
}

/// Media element representation
#[derive(Debug, Clone)]
pub struct MediaElement {
    pub element_id: ElementId,
    pub media_type: MediaType,
    pub src: String,
    pub pipeline: Option<gst::Pipeline>,
    pub state: MediaState,
    pub volume: f64,
    pub muted: bool,
    pub current_time: f64,
    pub duration: f64,
}

/// Media type enumeration
#[derive(Debug, Clone, PartialEq)]
pub enum MediaType {
    Audio,
    Video,
}

/// Media playback state
#[derive(Debug, Clone, PartialEq)]
pub enum MediaState {
    Stopped,
    Playing,
    Paused,
    Buffering,
    Error,
}

/// Media capabilities detection
#[derive(Debug, Clone)]
pub struct MediaCapabilities {
    pub supported_video_formats: Vec<String>,
    pub supported_audio_formats: Vec<String>,
    pub hardware_acceleration: bool,
    pub max_video_resolution: (u32, u32),
    pub audio_channels: u32,
}

impl MediaCapabilities {
    /// Detect system media capabilities
    pub async fn detect() -> Result<Self> {
        let mut capabilities = Self {
            supported_video_formats: Vec::new(),
            supported_audio_formats: Vec::new(),
            hardware_acceleration: false,
            max_video_resolution: (1920, 1080),
            audio_channels: 2,
        };
        
        // Detect video formats
        let video_formats = vec![
            "video/x-h264",
            "video/x-h265",
            "video/x-vp8",
            "video/x-vp9",
            "video/x-av1",
            "video/mpeg",
        ];
        
        for format in video_formats {
            if Self::is_format_supported(format) {
                capabilities.supported_video_formats.push(format.to_string());
            }
        }
        
        // Detect audio formats
        let audio_formats = vec![
            "audio/mpeg",
            "audio/x-vorbis",
            "audio/x-opus",
            "audio/x-flac",
            "audio/x-wav",
            "audio/aac",
        ];
        
        for format in audio_formats {
            if Self::is_format_supported(format) {
                capabilities.supported_audio_formats.push(format.to_string());
            }
        }
        
        // Check for hardware acceleration
        capabilities.hardware_acceleration = Self::detect_hardware_acceleration();
        
        Ok(capabilities)
    }
    
    /// Check if a format is supported
    fn is_format_supported(format: &str) -> bool {
        // Use GStreamer to check format support
        if let Ok(factory) = gst::ElementFactory::find("decodebin") {
            let caps = gst::Caps::builder(format).build();
            factory.can_sink_all_caps(&caps)
        } else {
            false
        }
    }
    
    /// Detect hardware acceleration support
    fn detect_hardware_acceleration() -> bool {
        // Check for hardware-accelerated decoders
        let hw_decoders = vec![
            "vaapidecode",
            "nvdec",
            "d3d11h264dec",
            "vtdec",
        ];
        
        for decoder in hw_decoders {
            if gst::ElementFactory::find(decoder).is_ok() {
                return true;
            }
        }
        
        false
    }
}

/// Pipeline manager for handling multiple media streams
struct PipelineManager {
    pipelines: HashMap<String, gst::Pipeline>,
}

impl PipelineManager {
    fn new() -> Self {
        Self {
            pipelines: HashMap::new(),
        }
    }
    
    fn add_pipeline(&mut self, id: String, pipeline: gst::Pipeline) {
        self.pipelines.insert(id, pipeline);
    }
    
    fn remove_pipeline(&mut self, id: &str) -> Option<gst::Pipeline> {
        self.pipelines.remove(id)
    }
    
    fn get_pipeline(&self, id: &str) -> Option<&gst::Pipeline> {
        self.pipelines.get(id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_media_engine_creation() {
        // Skip if GStreamer is not available
        if gst::init().is_err() {
            return;
        }
        
        let engine = MediaEngine::new().await.unwrap();
        assert!(!engine.capabilities.supported_video_formats.is_empty() || 
                !engine.capabilities.supported_audio_formats.is_empty());
    }
    
    #[test]
    fn test_media_element() {
        let element = MediaElement {
            element_id: ElementId::new(),
            media_type: MediaType::Video,
            src: "https://example.com/video.mp4".to_string(),
            pipeline: None,
            state: MediaState::Stopped,
            volume: 1.0,
            muted: false,
            current_time: 0.0,
            duration: 0.0,
        };
        
        assert_eq!(element.media_type, MediaType::Video);
        assert_eq!(element.state, MediaState::Stopped);
        assert_eq!(element.volume, 1.0);
        assert!(!element.muted);
    }
    
    #[test]
    fn test_pipeline_manager() {
        let mut manager = PipelineManager::new();
        
        // This would require actual GStreamer initialization
        // For now, just test the basic structure
        assert!(manager.get_pipeline("test").is_none());
    }
}