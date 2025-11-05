//! JavaScript runtime using V8 for script execution

use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use rusty_v8 as v8;
use crate::core::{ElementId, Result, EngineError, BrowserEvent, ConsoleLevel};
use crate::html::{Document, Element};

/// JavaScript runtime for executing scripts
pub struct JSRuntime {
    /// V8 isolate for script execution
    isolate: v8::OwnedIsolate,
    
    /// Global context
    context: v8::Global<v8::Context>,
    
    /// Security settings
    security_settings: SecuritySettings,
    
    /// Performance monitoring
    execution_stats: Arc<Mutex<ExecutionStats>>,
    
    /// Event handlers
    event_handlers: HashMap<String, v8::Global<v8::Function>>,
    
    /// Console message callback
    console_callback: Option<Box<dyn Fn(ConsoleLevel, String, String, u32) + Send + Sync>>,
}

impl JSRuntime {
    /// Create a new JavaScript runtime
    pub async fn new() -> Result<Self> {
        // Initialize V8
        let platform = v8::new_default_platform(0, false).make_shared();
        v8::V8::initialize_platform(platform);
        v8::V8::initialize();
        
        // Create isolate
        let mut isolate = v8::Isolate::new(v8::CreateParams::default());
        
        // Create context
        let context = {
            let scope = &mut v8::HandleScope::new(&mut isolate);
            let context = v8::Context::new(scope);
            v8::Global::new(scope, context)
        };
        
        let mut runtime = Self {
            isolate,
            context,
            security_settings: SecuritySettings::default(),
            execution_stats: Arc::new(Mutex::new(ExecutionStats::default())),
            event_handlers: HashMap::new(),
            console_callback: None,
        };
        
        // Set up built-in objects and security
        runtime.setup_builtin_objects().await?;
        runtime.setup_security().await?;
        
        Ok(runtime)
    }
    
    /// Execute JavaScript code
    pub async fn execute_script(&mut self, code: &str, source_name: &str) -> Result<JSValue> {
        let start_time = Instant::now();
        
        // Security check
        if !self.security_settings.allow_execution {
            return Err(EngineError::SecurityError("JavaScript execution disabled".to_string()));
        }
        
        // Check for dangerous patterns
        if self.contains_dangerous_patterns(code) {
            return Err(EngineError::SecurityError("Potentially dangerous JavaScript detected".to_string()));
        }
        
        let scope = &mut v8::HandleScope::new(&mut self.isolate);
        let context = v8::Local::new(scope, &self.context);
        let scope = &mut v8::ContextScope::new(scope, context);
        
        // Compile script
        let source = v8::String::new(scope, code).unwrap();
        let name = v8::String::new(scope, source_name).unwrap();
        let origin = v8::ScriptOrigin::new(
            scope,
            name.into(),
            0,
            0,
            false,
            0,
            None,
            false,
            false,
            false,
        );
        
        let script = match v8::Script::compile(scope, source, Some(&origin)) {
            Some(script) => script,
            None => {
                let exception = scope.exception().unwrap();
                let exception_str = exception.to_rust_string_lossy(scope);
                return Err(EngineError::JavaScriptError(format!("Compilation error: {}", exception_str)));
            }
        };
        
        // Execute with timeout
        let result = self.execute_with_timeout(scope, script, Duration::from_millis(5000)).await?;
        
        // Update stats
        let execution_time = start_time.elapsed();
        {
            let mut stats = self.execution_stats.lock().unwrap();
            stats.total_executions += 1;
            stats.total_execution_time += execution_time;
            stats.last_execution_time = execution_time;
        }
        
        Ok(result)
    }
    
    /// Execute script with timeout protection
    async fn execute_with_timeout(
        &mut self,
        scope: &mut v8::HandleScope,
        script: v8::Local<v8::Script>,
        timeout: Duration,
    ) -> Result<JSValue> {
        // Set up timeout (simplified - in reality we'd need proper async handling)
        let start = Instant::now();
        
        let result = script.run(scope);
        
        if start.elapsed() > timeout {
            return Err(EngineError::JavaScriptError("Script execution timeout".to_string()));
        }
        
        match result {
            Some(value) => Ok(self.v8_value_to_js_value(scope, value)),
            None => {
                let exception = scope.exception().unwrap();
                let exception_str = exception.to_rust_string_lossy(scope);
                Err(EngineError::JavaScriptError(format!("Runtime error: {}", exception_str)))
            }
        }
    }
    
    /// Execute page scripts from document
    pub async fn execute_page_scripts(&mut self, document: &Document) -> Result<()> {
        // Find all script elements
        let script_elements = document.get_elements_by_tag_name("script");
        
        for script_element in script_elements {
            // Check if it's an inline script or external
            if let Some(src) = script_element.get_attribute("src") {
                // External script - would need to fetch
                log::info!("External script found: {}", src);
                // TODO: Implement external script loading
            } else {
                // Inline script
                let script_content = script_element.text_content();
                if !script_content.trim().is_empty() {
                    match self.execute_script(&script_content, "inline-script").await {
                        Ok(_) => log::debug!("Inline script executed successfully"),
                        Err(e) => log::warn!("Inline script execution failed: {:?}", e),
                    }
                }
            }
        }
        
        Ok(())
    }
    
    /// Set up built-in JavaScript objects
    async fn setup_builtin_objects(&mut self) -> Result<()> {
        let scope = &mut v8::HandleScope::new(&mut self.isolate);
        let context = v8::Local::new(scope, &self.context);
        let scope = &mut v8::ContextScope::new(scope, context);
        
        // Set up console object
        self.setup_console(scope)?;
        
        // Set up DOM APIs (simplified)
        self.setup_dom_apis(scope)?;
        
        // Set up Web APIs
        self.setup_web_apis(scope)?;
        
        // Set up Titan-specific APIs
        self.setup_titan_apis(scope)?;
        
        Ok(())
    }
    
    /// Set up console object
    fn setup_console(&mut self, scope: &mut v8::ContextScope) -> Result<()> {
        let global = scope.get_current_context().global(scope);
        
        // Create console object
        let console_obj = v8::Object::new(scope);
        
        // console.log
        let log_fn = v8::Function::new(
            scope,
            |scope: &mut v8::HandleScope,
             args: v8::FunctionCallbackArguments,
             _rv: v8::ReturnValue| {
                let message = args.get(0).to_rust_string_lossy(scope);
                // TODO: Call console callback
                println!("[JS Console] {}", message);
            },
        ).unwrap();
        
        let log_name = v8::String::new(scope, "log").unwrap();
        console_obj.set(scope, log_name.into(), log_fn.into());
        
        // console.error
        let error_fn = v8::Function::new(
            scope,
            |scope: &mut v8::HandleScope,
             args: v8::FunctionCallbackArguments,
             _rv: v8::ReturnValue| {
                let message = args.get(0).to_rust_string_lossy(scope);
                eprintln!("[JS Error] {}", message);
            },
        ).unwrap();
        
        let error_name = v8::String::new(scope, "error").unwrap();
        console_obj.set(scope, error_name.into(), error_fn.into());
        
        // Add console to global
        let console_name = v8::String::new(scope, "console").unwrap();
        global.set(scope, console_name.into(), console_obj.into());
        
        Ok(())
    }
    
    /// Set up DOM APIs
    fn setup_dom_apis(&mut self, scope: &mut v8::ContextScope) -> Result<()> {
        let global = scope.get_current_context().global(scope);
        
        // document object (simplified)
        let document_obj = v8::Object::new(scope);
        
        // document.getElementById
        let get_element_by_id_fn = v8::Function::new(
            scope,
            |scope: &mut v8::HandleScope,
             args: v8::FunctionCallbackArguments,
             mut rv: v8::ReturnValue| {
                let id = args.get(0).to_rust_string_lossy(scope);
                // TODO: Implement actual DOM lookup
                let null_value = v8::null(scope);
                rv.set(null_value.into());
            },
        ).unwrap();
        
        let get_element_by_id_name = v8::String::new(scope, "getElementById").unwrap();
        document_obj.set(scope, get_element_by_id_name.into(), get_element_by_id_fn.into());
        
        // Add document to global
        let document_name = v8::String::new(scope, "document").unwrap();
        global.set(scope, document_name.into(), document_obj.into());
        
        Ok(())
    }
    
    /// Set up Web APIs
    fn setup_web_apis(&mut self, scope: &mut v8::ContextScope) -> Result<()> {
        let global = scope.get_current_context().global(scope);
        
        // setTimeout (simplified)
        let set_timeout_fn = v8::Function::new(
            scope,
            |scope: &mut v8::HandleScope,
             args: v8::FunctionCallbackArguments,
             mut rv: v8::ReturnValue| {
                // TODO: Implement actual timer functionality
                let timer_id = v8::Number::new(scope, 1.0);
                rv.set(timer_id.into());
            },
        ).unwrap();
        
        let set_timeout_name = v8::String::new(scope, "setTimeout").unwrap();
        global.set(scope, set_timeout_name.into(), set_timeout_fn.into());
        
        // fetch API (simplified)
        let fetch_fn = v8::Function::new(
            scope,
            |scope: &mut v8::HandleScope,
             args: v8::FunctionCallbackArguments,
             mut rv: v8::ReturnValue| {
                let url = args.get(0).to_rust_string_lossy(scope);
                // TODO: Implement actual fetch functionality
                let promise = v8::Promise::resolver(scope).unwrap();
                rv.set(promise.get_promise(scope).into());
            },
        ).unwrap();
        
        let fetch_name = v8::String::new(scope, "fetch").unwrap();
        global.set(scope, fetch_name.into(), fetch_fn.into());
        
        Ok(())
    }
    
    /// Set up Titan-specific APIs
    fn setup_titan_apis(&mut self, scope: &mut v8::ContextScope) -> Result<()> {
        let global = scope.get_current_context().global(scope);
        
        // titanBrowser object
        let titan_obj = v8::Object::new(scope);
        
        // titanBrowser.version
        let version = v8::String::new(scope, "1.0.0").unwrap();
        let version_name = v8::String::new(scope, "version").unwrap();
        titan_obj.set(scope, version_name.into(), version.into());
        
        // titanBrowser.ai object
        let ai_obj = v8::Object::new(scope);
        
        // titanBrowser.ai.analyze
        let ai_analyze_fn = v8::Function::new(
            scope,
            |scope: &mut v8::HandleScope,
             args: v8::FunctionCallbackArguments,
             mut rv: v8::ReturnValue| {
                // TODO: Implement AI analysis
                let result = v8::String::new(scope, "AI analysis not implemented").unwrap();
                rv.set(result.into());
            },
        ).unwrap();
        
        let ai_analyze_name = v8::String::new(scope, "analyze").unwrap();
        ai_obj.set(scope, ai_analyze_name.into(), ai_analyze_fn.into());
        
        let ai_name = v8::String::new(scope, "ai").unwrap();
        titan_obj.set(scope, ai_name.into(), ai_obj.into());
        
        // Add titanBrowser to global
        let titan_name = v8::String::new(scope, "titanBrowser").unwrap();
        global.set(scope, titan_name.into(), titan_obj.into());
        
        Ok(())
    }
    
    /// Set up security restrictions
    async fn setup_security(&mut self) -> Result<()> {
        let scope = &mut v8::HandleScope::new(&mut self.isolate);
        let context = v8::Local::new(scope, &self.context);
        let scope = &mut v8::ContextScope::new(scope, context);
        let global = scope.get_current_context().global(scope);
        
        // Disable dangerous globals if security level is high
        if self.security_settings.security_level >= 2 {
            // Disable eval
            let eval_name = v8::String::new(scope, "eval").unwrap();
            let undefined = v8::undefined(scope);
            global.set(scope, eval_name.into(), undefined.into());
            
            // Disable Function constructor
            let function_name = v8::String::new(scope, "Function").unwrap();
            global.set(scope, function_name.into(), undefined.into());
        }
        
        Ok(())
    }
    
    /// Check for dangerous JavaScript patterns
    fn contains_dangerous_patterns(&self, code: &str) -> bool {
        let dangerous_patterns = [
            "eval(",
            "Function(",
            "document.write(",
            "innerHTML",
            "outerHTML",
            "document.cookie",
            "localStorage",
            "sessionStorage",
            "XMLHttpRequest",
            "fetch(",
            "import(",
            "require(",
        ];
        
        let code_lower = code.to_lowercase();
        for pattern in &dangerous_patterns {
            if code_lower.contains(pattern) {
                log::warn!("Dangerous JavaScript pattern detected: {}", pattern);
                if self.security_settings.block_dangerous_patterns {
                    return true;
                }
            }
        }
        
        false
    }
    
    /// Convert V8 value to our JSValue type
    fn v8_value_to_js_value(&self, scope: &mut v8::HandleScope, value: v8::Local<v8::Value>) -> JSValue {
        if value.is_undefined() {
            JSValue::Undefined
        } else if value.is_null() {
            JSValue::Null
        } else if value.is_boolean() {
            JSValue::Boolean(value.boolean_value(scope))
        } else if value.is_number() {
            JSValue::Number(value.number_value(scope).unwrap_or(0.0))
        } else if value.is_string() {
            JSValue::String(value.to_rust_string_lossy(scope))
        } else if value.is_array() {
            // TODO: Convert array
            JSValue::Array(Vec::new())
        } else if value.is_object() {
            // TODO: Convert object
            JSValue::Object(HashMap::new())
        } else {
            JSValue::Undefined
        }
    }
    
    /// Set console message callback
    pub fn set_console_callback<F>(&mut self, callback: F)
    where
        F: Fn(ConsoleLevel, String, String, u32) + Send + Sync + 'static,
    {
        self.console_callback = Some(Box::new(callback));
    }
    
    /// Get execution statistics
    pub fn get_execution_stats(&self) -> ExecutionStats {
        self.execution_stats.lock().unwrap().clone()
    }
    
    /// Update security settings
    pub fn update_security_settings(&mut self, settings: SecuritySettings) {
        self.security_settings = settings;
    }
    
    /// Shutdown the runtime
    pub async fn shutdown(&mut self) -> Result<()> {
        // Clean up V8 resources
        // Note: V8 doesn't provide explicit cleanup methods for isolates
        log::info!("JavaScript runtime shutting down");
        Ok(())
    }
}

/// JavaScript value types
#[derive(Debug, Clone)]
pub enum JSValue {
    Undefined,
    Null,
    Boolean(bool),
    Number(f64),
    String(String),
    Array(Vec<JSValue>),
    Object(HashMap<String, JSValue>),
    Function,
}

impl JSValue {
    /// Convert to string representation
    pub fn to_string(&self) -> String {
        match self {
            JSValue::Undefined => "undefined".to_string(),
            JSValue::Null => "null".to_string(),
            JSValue::Boolean(b) => b.to_string(),
            JSValue::Number(n) => n.to_string(),
            JSValue::String(s) => s.clone(),
            JSValue::Array(_) => "[object Array]".to_string(),
            JSValue::Object(_) => "[object Object]".to_string(),
            JSValue::Function => "[object Function]".to_string(),
        }
    }
    
    /// Check if value is truthy
    pub fn is_truthy(&self) -> bool {
        match self {
            JSValue::Undefined | JSValue::Null => false,
            JSValue::Boolean(b) => *b,
            JSValue::Number(n) => *n != 0.0 && !n.is_nan(),
            JSValue::String(s) => !s.is_empty(),
            JSValue::Array(_) | JSValue::Object(_) | JSValue::Function => true,
        }
    }
}

/// Security settings for JavaScript execution
#[derive(Debug, Clone)]
pub struct SecuritySettings {
    pub allow_execution: bool,
    pub security_level: u8, // 0-3, higher is more restrictive
    pub block_dangerous_patterns: bool,
    pub max_execution_time_ms: u64,
    pub max_memory_mb: u64,
    pub allow_eval: bool,
    pub allow_function_constructor: bool,
    pub allow_dom_access: bool,
    pub allow_network_access: bool,
    pub allow_storage_access: bool,
}

impl Default for SecuritySettings {
    fn default() -> Self {
        Self {
            allow_execution: true,
            security_level: 2,
            block_dangerous_patterns: true,
            max_execution_time_ms: 5000,
            max_memory_mb: 128,
            allow_eval: false,
            allow_function_constructor: false,
            allow_dom_access: true,
            allow_network_access: false,
            allow_storage_access: false,
        }
    }
}

/// JavaScript execution statistics
#[derive(Debug, Clone, Default)]
pub struct ExecutionStats {
    pub total_executions: u64,
    pub total_execution_time: Duration,
    pub last_execution_time: Duration,
    pub errors: u64,
    pub timeouts: u64,
    pub security_violations: u64,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_js_runtime_creation() {
        let runtime = JSRuntime::new().await.unwrap();
        // Basic test to ensure runtime can be created
    }
    
    #[tokio::test]
    async fn test_simple_script_execution() {
        let mut runtime = JSRuntime::new().await.unwrap();
        
        let result = runtime.execute_script("1 + 1", "test").await.unwrap();
        match result {
            JSValue::Number(n) => assert_eq!(n, 2.0),
            _ => panic!("Expected number result"),
        }
    }
    
    #[tokio::test]
    async fn test_security_restrictions() {
        let mut runtime = JSRuntime::new().await.unwrap();
        
        // This should be blocked by security settings
        let result = runtime.execute_script("eval('alert(1)')", "test").await;
        assert!(result.is_err());
    }
    
    #[test]
    fn test_js_value_operations() {
        let value = JSValue::String("hello".to_string());
        assert_eq!(value.to_string(), "hello");
        assert!(value.is_truthy());
        
        let undefined = JSValue::Undefined;
        assert!(!undefined.is_truthy());
        
        let zero = JSValue::Number(0.0);
        assert!(!zero.is_truthy());
    }
    
    #[test]
    fn test_dangerous_pattern_detection() {
        let runtime = JSRuntime::new().await.unwrap();
        
        assert!(runtime.contains_dangerous_patterns("eval('malicious code')"));
        assert!(runtime.contains_dangerous_patterns("document.cookie = 'steal'"));
        assert!(!runtime.contains_dangerous_patterns("console.log('safe')"));
    }
}