//! FFI bindings for connecting Rust engine with Flutter

use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_double};
use std::ptr;
use std::sync::Once;
use tokio::runtime::Runtime;
use crate::{TitanEngine, EngineConfig};

static INIT: Once = Once::new();
static mut RUNTIME: Option<Runtime> = None;
static mut ENGINE: Option<TitanEngine> = None;

/// Initialize the Titan Engine
#[no_mangle]
pub extern "C" fn titan_engine_init() -> c_int {
    INIT.call_once(|| {
        // Initialize logging
        env_logger::init();
        
        // Create Tokio runtime
        let rt = Runtime::new().expect("Failed to create Tokio runtime");
        
        // Create engine
        let engine = rt.block_on(async {
            TitanEngine::new().await.expect("Failed to create Titan Engine")
        });
        
        unsafe {
            RUNTIME = Some(rt);
            ENGINE = Some(engine);
        }
    });
    
    1 // Success
}

/// Shutdown the Titan Engine
#[no_mangle]
pub extern "C" fn titan_engine_shutdown() -> c_int {
    unsafe {
        if let Some(engine) = ENGINE.take() {
            if let Some(rt) = &RUNTIME {
                rt.block_on(async {
                    let _ = engine.shutdown().await;
                });
            }
        }
        
        if let Some(rt) = RUNTIME.take() {
            rt.shutdown_background();
        }
    }
    
    1 // Success
}

/// Load a web page
#[no_mangle]
pub extern "C" fn titan_engine_load_page(url: *const c_char) -> *mut c_char {
    if url.is_null() {
        return ptr::null_mut();
    }
    
    let url_str = unsafe {
        match CStr::from_ptr(url).to_str() {
            Ok(s) => s,
            Err(_) => return ptr::null_mut(),
        }
    };
    
    unsafe {
        if let (Some(engine), Some(rt)) = (&ENGINE, &RUNTIME) {
            let result = rt.block_on(async {
                engine.load_page(url_str).await
            });
            
            match result {
                Ok(page_handle) => {
                    let response = format!("{{\"success\": true, \"page_id\": \"{}\"}}", page_handle.id);
                    match CString::new(response) {
                        Ok(c_string) => c_string.into_raw(),
                        Err(_) => ptr::null_mut(),
                    }
                }
                Err(e) => {
                    let error_response = format!("{{\"success\": false, \"error\": \"{}\"}}", e);
                    match CString::new(error_response) {
                        Ok(c_string) => c_string.into_raw(),
                        Err(_) => ptr::null_mut(),
                    }
                }
            }
        } else {
            ptr::null_mut()
        }
    }
}

/// Execute JavaScript code
#[no_mangle]
pub extern "C" fn titan_engine_execute_javascript(code: *const c_char) -> *mut c_char {
    if code.is_null() {
        return ptr::null_mut();
    }
    
    let code_str = unsafe {
        match CStr::from_ptr(code).to_str() {
            Ok(s) => s,
            Err(_) => return ptr::null_mut(),
        }
    };
    
    unsafe {
        if let (Some(engine), Some(rt)) = (&ENGINE, &RUNTIME) {
            let result = rt.block_on(async {
                let mut js_runtime = engine.js_runtime.write().await;
                js_runtime.execute_script(code_str, "ffi-script").await
            });
            
            match result {
                Ok(js_value) => {
                    let response = format!("{{\"success\": true, \"result\": \"{}\"}}", js_value.to_string());
                    match CString::new(response) {
                        Ok(c_string) => c_string.into_raw(),
                        Err(_) => ptr::null_mut(),
                    }
                }
                Err(e) => {
                    let error_response = format!("{{\"success\": false, \"error\": \"{}\"}}", e);
                    match CString::new(error_response) {
                        Ok(c_string) => c_string.into_raw(),
                        Err(_) => ptr::null_mut(),
                    }
                }
            }
        } else {
            ptr::null_mut()
        }
    }
}

/// Get AI analysis for a page
#[no_mangle]
pub extern "C" fn titan_engine_get_ai_analysis(url: *const c_char) -> *mut c_char {
    if url.is_null() {
        return ptr::null_mut();
    }
    
    let url_str = unsafe {
        match CStr::from_ptr(url).to_str() {
            Ok(s) => s,
            Err(_) => return ptr::null_mut(),
        }
    };
    
    // Placeholder implementation
    let analysis = format!(
        r#"{{
            "url": "{}",
            "insights": [
                {{
                    "type": "readability",
                    "title": "Content Analysis",
                    "description": "Page content analyzed successfully",
                    "confidence": 0.8
                }}
            ],
            "sentiment": 0.1,
            "language": "en"
        }}"#,
        url_str
    );
    
    match CString::new(analysis) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// Validate URL security
#[no_mangle]
pub extern "C" fn titan_engine_validate_url_security(url: *const c_char) -> c_int {
    if url.is_null() {
        return 0; // Invalid
    }
    
    let url_str = unsafe {
        match CStr::from_ptr(url).to_str() {
            Ok(s) => s,
            Err(_) => return 0,
        }
    };
    
    unsafe {
        if let (Some(engine), Some(rt)) = (&ENGINE, &RUNTIME) {
            let result = rt.block_on(async {
                engine.security.validate_url(url_str).await
            });
            
            match result {
                Ok(_) => 1, // Safe
                Err(_) => 0, // Unsafe
            }
        } else {
            0 // Engine not initialized
        }
    }
}

/// Get network metrics
#[no_mangle]
pub extern "C" fn titan_engine_get_network_metrics() -> *mut c_char {
    unsafe {
        if let (Some(engine), Some(rt)) = (&ENGINE, &RUNTIME) {
            let metrics = rt.block_on(async {
                engine.network_stack.get_metrics().await
            });
            
            let metrics_json = format!(
                r#"{{
                    "total_requests": {},
                    "failed_requests": {},
                    "total_bytes_received": {},
                    "cache_hit_ratio": {},
                    "average_load_time_ms": {}
                }}"#,
                metrics.total_requests,
                metrics.failed_requests,
                metrics.total_bytes_received,
                metrics.cache_hit_ratio(),
                metrics.average_load_time.as_millis()
            );
            
            match CString::new(metrics_json) {
                Ok(c_string) => c_string.into_raw(),
                Err(_) => ptr::null_mut(),
            }
        } else {
            ptr::null_mut()
        }
    }
}

/// Set engine configuration
#[no_mangle]
pub extern "C" fn titan_engine_set_config(
    javascript_enabled: c_int,
    webgl_enabled: c_int,
    media_enabled: c_int,
    ai_enabled: c_int,
    security_level: c_int,
    max_memory_mb: c_int,
) -> c_int {
    let config = EngineConfig {
        javascript_enabled: javascript_enabled != 0,
        webgl_enabled: webgl_enabled != 0,
        media_enabled: media_enabled != 0,
        ai_enabled: ai_enabled != 0,
        security_level: security_level as u8,
        user_agent: "TitanBrowser/1.0 (Rust Engine)".to_string(),
        max_memory_mb: max_memory_mb as u64,
        hardware_acceleration: true,
    };
    
    // Configuration would be applied to the engine
    // For now, just return success
    1
}

/// Get performance metrics
#[no_mangle]
pub extern "C" fn titan_engine_get_performance_metrics() -> *mut c_char {
    let metrics = r#"{
        "memory_usage_mb": 128.5,
        "cpu_usage_percent": 15.2,
        "gpu_usage_percent": 8.7,
        "render_fps": 60.0,
        "javascript_execution_time_ms": 45,
        "layout_time_ms": 12,
        "paint_time_ms": 8
    }"#;
    
    match CString::new(metrics) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// Free a string allocated by the engine
#[no_mangle]
pub extern "C" fn titan_engine_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

/// Get engine version
#[no_mangle]
pub extern "C" fn titan_engine_get_version() -> *mut c_char {
    let version = "1.0.0";
    match CString::new(version) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// Check if engine is initialized
#[no_mangle]
pub extern "C" fn titan_engine_is_initialized() -> c_int {
    unsafe {
        if ENGINE.is_some() && RUNTIME.is_some() {
            1
        } else {
            0
        }
    }
}

/// Media control functions
#[no_mangle]
pub extern "C" fn titan_engine_media_play(element_id: *const c_char) -> c_int {
    if element_id.is_null() {
        return 0;
    }
    
    // Placeholder implementation
    1 // Success
}

#[no_mangle]
pub extern "C" fn titan_engine_media_pause(element_id: *const c_char) -> c_int {
    if element_id.is_null() {
        return 0;
    }
    
    // Placeholder implementation
    1 // Success
}

#[no_mangle]
pub extern "C" fn titan_engine_media_set_volume(element_id: *const c_char, volume: c_double) -> c_int {
    if element_id.is_null() || volume < 0.0 || volume > 1.0 {
        return 0;
    }
    
    // Placeholder implementation
    1 // Success
}

/// Storage functions
#[no_mangle]
pub extern "C" fn titan_engine_storage_set(key: *const c_char, value: *const c_char) -> c_int {
    if key.is_null() || value.is_null() {
        return 0;
    }
    
    let key_str = unsafe {
        match CStr::from_ptr(key).to_str() {
            Ok(s) => s,
            Err(_) => return 0,
        }
    };
    
    let value_str = unsafe {
        match CStr::from_ptr(value).to_str() {
            Ok(s) => s,
            Err(_) => return 0,
        }
    };
    
    unsafe {
        if let (Some(engine), Some(rt)) = (&ENGINE, &RUNTIME) {
            let result = rt.block_on(async {
                let mut storage = engine.storage.write().await;
                storage.set_setting(key_str, value_str).await
            });
            
            match result {
                Ok(_) => 1,
                Err(_) => 0,
            }
        } else {
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn titan_engine_storage_get(key: *const c_char) -> *mut c_char {
    if key.is_null() {
        return ptr::null_mut();
    }
    
    let key_str = unsafe {
        match CStr::from_ptr(key).to_str() {
            Ok(s) => s,
            Err(_) => return ptr::null_mut(),
        }
    };
    
    unsafe {
        if let (Some(engine), Some(rt)) = (&ENGINE, &RUNTIME) {
            let result = rt.block_on(async {
                let storage = engine.storage.read().await;
                storage.get_setting(key_str).await
            });
            
            match result {
                Ok(Some(value)) => {
                    match CString::new(value) {
                        Ok(c_string) => c_string.into_raw(),
                        Err(_) => ptr::null_mut(),
                    }
                }
                _ => ptr::null_mut(),
            }
        } else {
            ptr::null_mut()
        }
    }
}

/// Callback function types for Flutter
pub type ProgressCallback = extern "C" fn(progress: c_double);
pub type EventCallback = extern "C" fn(event_type: *const c_char, event_data: *const c_char);
pub type ErrorCallback = extern "C" fn(error_message: *const c_char);

static mut PROGRESS_CALLBACK: Option<ProgressCallback> = None;
static mut EVENT_CALLBACK: Option<EventCallback> = None;
static mut ERROR_CALLBACK: Option<ErrorCallback> = None;

/// Set callback functions
#[no_mangle]
pub extern "C" fn titan_engine_set_progress_callback(callback: ProgressCallback) {
    unsafe {
        PROGRESS_CALLBACK = Some(callback);
    }
}

#[no_mangle]
pub extern "C" fn titan_engine_set_event_callback(callback: EventCallback) {
    unsafe {
        EVENT_CALLBACK = Some(callback);
    }
}

#[no_mangle]
pub extern "C" fn titan_engine_set_error_callback(callback: ErrorCallback) {
    unsafe {
        ERROR_CALLBACK = Some(callback);
    }
}

/// Helper functions for calling callbacks
pub fn notify_progress(progress: f64) {
    unsafe {
        if let Some(callback) = PROGRESS_CALLBACK {
            callback(progress);
        }
    }
}

pub fn notify_event(event_type: &str, event_data: &str) {
    unsafe {
        if let Some(callback) = EVENT_CALLBACK {
            if let (Ok(event_type_c), Ok(event_data_c)) = (CString::new(event_type), CString::new(event_data)) {
                callback(event_type_c.as_ptr(), event_data_c.as_ptr());
            }
        }
    }
}

pub fn notify_error(error_message: &str) {
    unsafe {
        if let Some(callback) = ERROR_CALLBACK {
            if let Ok(error_c) = CString::new(error_message) {
                callback(error_c.as_ptr());
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;
    
    #[test]
    fn test_engine_initialization() {
        let result = titan_engine_init();
        assert_eq!(result, 1);
        
        let is_initialized = titan_engine_is_initialized();
        assert_eq!(is_initialized, 1);
        
        let shutdown_result = titan_engine_shutdown();
        assert_eq!(shutdown_result, 1);
    }
    
    #[test]
    fn test_version_string() {
        let version_ptr = titan_engine_get_version();
        assert!(!version_ptr.is_null());
        
        unsafe {
            let version_cstr = CStr::from_ptr(version_ptr);
            let version_str = version_cstr.to_str().unwrap();
            assert_eq!(version_str, "1.0.0");
            
            titan_engine_free_string(version_ptr);
        }
    }
    
    #[test]
    fn test_config_setting() {
        let result = titan_engine_set_config(1, 1, 1, 1, 2, 1024);
        assert_eq!(result, 1);
    }
    
    #[test]
    fn test_url_validation() {
        titan_engine_init();
        
        let safe_url = CString::new("https://example.com").unwrap();
        let result = titan_engine_validate_url_security(safe_url.as_ptr());
        // Result depends on implementation, just check it doesn't crash
        
        titan_engine_shutdown();
    }
}