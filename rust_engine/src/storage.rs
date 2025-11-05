//! Storage engine using SQLite for persistent data

use std::collections::HashMap;
use std::path::Path;
use rusqlite::{Connection, params, Result as SqliteResult};
use serde::{Serialize, Deserialize};
use crate::core::{Result, EngineError};

/// Storage engine for persistent data management
pub struct StorageEngine {
    /// SQLite connection
    connection: Connection,
    
    /// In-memory cache for frequently accessed data
    cache: HashMap<String, CachedValue>,
    
    /// Storage configuration
    config: StorageConfig,
}

impl StorageEngine {
    /// Create a new storage engine
    pub async fn new() -> Result<Self> {
        let db_path = "titan_browser.db";
        let connection = Connection::open(db_path)
            .map_err(|e| EngineError::StorageError(format!("Failed to open database: {}", e)))?;
        
        let mut engine = Self {
            connection,
            cache: HashMap::new(),
            config: StorageConfig::default(),
        };
        
        // Initialize database schema
        engine.initialize_schema().await?;
        
        Ok(engine)
    }
    
    /// Initialize database schema
    async fn initialize_schema(&mut self) -> Result<()> {
        // Create tables
        self.connection.execute_batch(r#"
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            );
            
            CREATE TABLE IF NOT EXISTS cookies (
                domain TEXT NOT NULL,
                name TEXT NOT NULL,
                value TEXT NOT NULL,
                path TEXT NOT NULL DEFAULT '/',
                expires INTEGER,
                secure BOOLEAN NOT NULL DEFAULT 0,
                http_only BOOLEAN NOT NULL DEFAULT 0,
                same_site TEXT DEFAULT 'Lax',
                created_at INTEGER NOT NULL,
                PRIMARY KEY (domain, name, path)
            );
            
            CREATE TABLE IF NOT EXISTS local_storage (
                origin TEXT NOT NULL,
                key TEXT NOT NULL,
                value TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                PRIMARY KEY (origin, key)
            );
            
            CREATE TABLE IF NOT EXISTS session_storage (
                session_id TEXT NOT NULL,
                origin TEXT NOT NULL,
                key TEXT NOT NULL,
                value TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                PRIMARY KEY (session_id, origin, key)
            );
            
            CREATE TABLE IF NOT EXISTS cache_entries (
                url TEXT PRIMARY KEY,
                headers TEXT NOT NULL,
                body BLOB NOT NULL,
                expires_at INTEGER NOT NULL,
                created_at INTEGER NOT NULL
            );
            
            CREATE TABLE IF NOT EXISTS downloads (
                id TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                filename TEXT NOT NULL,
                path TEXT NOT NULL,
                status TEXT NOT NULL,
                progress REAL NOT NULL DEFAULT 0.0,
                total_bytes INTEGER NOT NULL DEFAULT 0,
                downloaded_bytes INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                completed_at INTEGER
            );
            
            CREATE TABLE IF NOT EXISTS bookmarks (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                url TEXT NOT NULL,
                description TEXT,
                favicon TEXT,
                tags TEXT,
                folder_id TEXT,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            );
            
            CREATE TABLE IF NOT EXISTS history (
                id TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                title TEXT NOT NULL,
                visit_count INTEGER NOT NULL DEFAULT 1,
                last_visit INTEGER NOT NULL,
                created_at INTEGER NOT NULL
            );
            
            CREATE INDEX IF NOT EXISTS idx_cookies_domain ON cookies(domain);
            CREATE INDEX IF NOT EXISTS idx_local_storage_origin ON local_storage(origin);
            CREATE INDEX IF NOT EXISTS idx_cache_expires ON cache_entries(expires_at);
            CREATE INDEX IF NOT EXISTS idx_history_url ON history(url);
            CREATE INDEX IF NOT EXISTS idx_history_last_visit ON history(last_visit);
        "#).map_err(|e| EngineError::StorageError(format!("Failed to initialize schema: {}", e)))?;
        
        Ok(())
    }
    
    /// Store a setting
    pub async fn set_setting(&mut self, key: &str, value: &str) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        
        self.connection.execute(
            "INSERT OR REPLACE INTO settings (key, value, created_at, updated_at) VALUES (?1, ?2, ?3, ?4)",
            params![key, value, now, now],
        ).map_err(|e| EngineError::StorageError(format!("Failed to set setting: {}", e)))?;
        
        // Update cache
        self.cache.insert(key.to_string(), CachedValue {
            value: value.to_string(),
            expires_at: None,
        });
        
        Ok(())
    }
    
    /// Get a setting
    pub async fn get_setting(&self, key: &str) -> Result<Option<String>> {
        // Check cache first
        if let Some(cached) = self.cache.get(key) {
            if !cached.is_expired() {
                return Ok(Some(cached.value.clone()));
            }
        }
        
        let mut stmt = self.connection.prepare("SELECT value FROM settings WHERE key = ?1")
            .map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        
        let result = stmt.query_row(params![key], |row| {
            Ok(row.get::<_, String>(0)?)
        });
        
        match result {
            Ok(value) => Ok(Some(value)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(EngineError::StorageError(format!("Failed to get setting: {}", e))),
        }
    }
    
    /// Store a cookie
    pub async fn set_cookie(&mut self, cookie: Cookie) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        
        self.connection.execute(
            r#"INSERT OR REPLACE INTO cookies 
               (domain, name, value, path, expires, secure, http_only, same_site, created_at) 
               VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)"#,
            params![
                cookie.domain,
                cookie.name,
                cookie.value,
                cookie.path,
                cookie.expires,
                cookie.secure,
                cookie.http_only,
                cookie.same_site,
                now
            ],
        ).map_err(|e| EngineError::StorageError(format!("Failed to set cookie: {}", e)))?;
        
        Ok(())
    }
    
    /// Get cookies for a domain
    pub async fn get_cookies(&self, domain: &str) -> Result<Vec<Cookie>> {
        let mut stmt = self.connection.prepare(
            "SELECT domain, name, value, path, expires, secure, http_only, same_site FROM cookies WHERE domain = ?1 OR domain = ?2"
        ).map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        
        let domain_wildcard = format!(".{}", domain);
        let rows = stmt.query_map(params![domain, domain_wildcard], |row| {
            Ok(Cookie {
                domain: row.get(0)?,
                name: row.get(1)?,
                value: row.get(2)?,
                path: row.get(3)?,
                expires: row.get(4)?,
                secure: row.get(5)?,
                http_only: row.get(6)?,
                same_site: row.get(7)?,
            })
        }).map_err(|e| EngineError::StorageError(format!("Failed to query cookies: {}", e)))?;
        
        let mut cookies = Vec::new();
        for row in rows {
            cookies.push(row.map_err(|e| EngineError::StorageError(format!("Failed to parse cookie: {}", e)))?);
        }
        
        Ok(cookies)
    }
    
    /// Store local storage item
    pub async fn set_local_storage(&mut self, origin: &str, key: &str, value: &str) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        
        self.connection.execute(
            "INSERT OR REPLACE INTO local_storage (origin, key, value, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5)",
            params![origin, key, value, now, now],
        ).map_err(|e| EngineError::StorageError(format!("Failed to set local storage: {}", e)))?;
        
        Ok(())
    }
    
    /// Get local storage item
    pub async fn get_local_storage(&self, origin: &str, key: &str) -> Result<Option<String>> {
        let mut stmt = self.connection.prepare("SELECT value FROM local_storage WHERE origin = ?1 AND key = ?2")
            .map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        
        let result = stmt.query_row(params![origin, key], |row| {
            Ok(row.get::<_, String>(0)?)
        });
        
        match result {
            Ok(value) => Ok(Some(value)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(EngineError::StorageError(format!("Failed to get local storage: {}", e))),
        }
    }
    
    /// Cache HTTP response
    pub async fn cache_response(&mut self, url: &str, headers: &str, body: &[u8], expires_at: i64) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        
        self.connection.execute(
            "INSERT OR REPLACE INTO cache_entries (url, headers, body, expires_at, created_at) VALUES (?1, ?2, ?3, ?4, ?5)",
            params![url, headers, body, expires_at, now],
        ).map_err(|e| EngineError::StorageError(format!("Failed to cache response: {}", e)))?;
        
        Ok(())
    }
    
    /// Get cached response
    pub async fn get_cached_response(&self, url: &str) -> Result<Option<CachedResponse>> {
        let now = chrono::Utc::now().timestamp();
        
        let mut stmt = self.connection.prepare(
            "SELECT headers, body, expires_at FROM cache_entries WHERE url = ?1 AND expires_at > ?2"
        ).map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        
        let result = stmt.query_row(params![url, now], |row| {
            Ok(CachedResponse {
                headers: row.get(0)?,
                body: row.get(1)?,
                expires_at: row.get(2)?,
            })
        });
        
        match result {
            Ok(response) => Ok(Some(response)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(EngineError::StorageError(format!("Failed to get cached response: {}", e))),
        }
    }
    
    /// Add bookmark
    pub async fn add_bookmark(&mut self, bookmark: Bookmark) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        let tags_json = serde_json::to_string(&bookmark.tags)
            .map_err(|e| EngineError::StorageError(format!("Failed to serialize tags: {}", e)))?;
        
        self.connection.execute(
            r#"INSERT INTO bookmarks 
               (id, title, url, description, favicon, tags, folder_id, created_at, updated_at) 
               VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)"#,
            params![
                bookmark.id,
                bookmark.title,
                bookmark.url,
                bookmark.description,
                bookmark.favicon,
                tags_json,
                bookmark.folder_id,
                now,
                now
            ],
        ).map_err(|e| EngineError::StorageError(format!("Failed to add bookmark: {}", e)))?;
        
        Ok(())
    }
    
    /// Get all bookmarks
    pub async fn get_bookmarks(&self) -> Result<Vec<Bookmark>> {
        let mut stmt = self.connection.prepare(
            "SELECT id, title, url, description, favicon, tags, folder_id FROM bookmarks ORDER BY created_at DESC"
        ).map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        
        let rows = stmt.query_map([], |row| {
            let tags_json: String = row.get(5)?;
            let tags: Vec<String> = serde_json::from_str(&tags_json).unwrap_or_default();
            
            Ok(Bookmark {
                id: row.get(0)?,
                title: row.get(1)?,
                url: row.get(2)?,
                description: row.get(3)?,
                favicon: row.get(4)?,
                tags,
                folder_id: row.get(6)?,
            })
        }).map_err(|e| EngineError::StorageError(format!("Failed to query bookmarks: {}", e)))?;
        
        let mut bookmarks = Vec::new();
        for row in rows {
            bookmarks.push(row.map_err(|e| EngineError::StorageError(format!("Failed to parse bookmark: {}", e)))?);
        }
        
        Ok(bookmarks)
    }
    
    /// Add history entry
    pub async fn add_history(&mut self, url: &str, title: &str) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        
        // Check if URL already exists
        let mut stmt = self.connection.prepare("SELECT visit_count FROM history WHERE url = ?1")
            .map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        
        let existing_count = stmt.query_row(params![url], |row| {
            Ok(row.get::<_, i32>(0)?)
        });
        
        match existing_count {
            Ok(count) => {
                // Update existing entry
                self.connection.execute(
                    "UPDATE history SET title = ?1, visit_count = ?2, last_visit = ?3 WHERE url = ?4",
                    params![title, count + 1, now, url],
                ).map_err(|e| EngineError::StorageError(format!("Failed to update history: {}", e)))?;
            }
            Err(rusqlite::Error::QueryReturnedNoRows) => {
                // Insert new entry
                let id = uuid::Uuid::new_v4().to_string();
                self.connection.execute(
                    "INSERT INTO history (id, url, title, visit_count, last_visit, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
                    params![id, url, title, 1, now, now],
                ).map_err(|e| EngineError::StorageError(format!("Failed to insert history: {}", e)))?;
            }
            Err(e) => return Err(EngineError::StorageError(format!("Failed to query history: {}", e))),
        }
        
        Ok(())
    }
    
    /// Get history entries
    pub async fn get_history(&self, limit: Option<i32>) -> Result<Vec<HistoryEntry>> {
        let query = if let Some(limit) = limit {
            format!("SELECT id, url, title, visit_count, last_visit FROM history ORDER BY last_visit DESC LIMIT {}", limit)
        } else {
            "SELECT id, url, title, visit_count, last_visit FROM history ORDER BY last_visit DESC".to_string()
        };
        
        let mut stmt = self.connection.prepare(&query)
            .map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        
        let rows = stmt.query_map([], |row| {
            Ok(HistoryEntry {
                id: row.get(0)?,
                url: row.get(1)?,
                title: row.get(2)?,
                visit_count: row.get(3)?,
                last_visit: row.get(4)?,
            })
        }).map_err(|e| EngineError::StorageError(format!("Failed to query history: {}", e)))?;
        
        let mut history = Vec::new();
        for row in rows {
            history.push(row.map_err(|e| EngineError::StorageError(format!("Failed to parse history: {}", e)))?);
        }
        
        Ok(history)
    }
    
    /// Clear expired cache entries
    pub async fn cleanup_cache(&mut self) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        
        self.connection.execute(
            "DELETE FROM cache_entries WHERE expires_at <= ?1",
            params![now],
        ).map_err(|e| EngineError::StorageError(format!("Failed to cleanup cache: {}", e)))?;
        
        Ok(())
    }
    
    /// Get storage statistics
    pub async fn get_storage_stats(&self) -> Result<StorageStats> {
        let mut stats = StorageStats::default();
        
        // Get table sizes
        let tables = vec![
            "settings", "cookies", "local_storage", "session_storage",
            "cache_entries", "downloads", "bookmarks", "history"
        ];
        
        for table in tables {
            let mut stmt = self.connection.prepare(&format!("SELECT COUNT(*) FROM {}", table))
                .map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
            
            let count: i64 = stmt.query_row([], |row| Ok(row.get(0)?))
                .map_err(|e| EngineError::StorageError(format!("Failed to get count: {}", e)))?;
            
            match table {
                "settings" => stats.settings_count = count as u64,
                "cookies" => stats.cookies_count = count as u64,
                "local_storage" => stats.local_storage_count = count as u64,
                "cache_entries" => stats.cache_entries_count = count as u64,
                "bookmarks" => stats.bookmarks_count = count as u64,
                "history" => stats.history_count = count as u64,
                _ => {}
            }
        }
        
        // Get database size
        let mut stmt = self.connection.prepare("PRAGMA page_count")
            .map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        let page_count: i64 = stmt.query_row([], |row| Ok(row.get(0)?))
            .map_err(|e| EngineError::StorageError(format!("Failed to get page count: {}", e)))?;
        
        let mut stmt = self.connection.prepare("PRAGMA page_size")
            .map_err(|e| EngineError::StorageError(format!("Failed to prepare statement: {}", e)))?;
        let page_size: i64 = stmt.query_row([], |row| Ok(row.get(0)?))
            .map_err(|e| EngineError::StorageError(format!("Failed to get page size: {}", e)))?;
        
        stats.database_size_bytes = (page_count * page_size) as u64;
        
        Ok(stats)
    }
    
    /// Shutdown storage engine
    pub async fn shutdown(&self) -> Result<()> {
        // SQLite connection will be closed when dropped
        Ok(())
    }
}

/// Cookie representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Cookie {
    pub domain: String,
    pub name: String,
    pub value: String,
    pub path: String,
    pub expires: Option<i64>,
    pub secure: bool,
    pub http_only: bool,
    pub same_site: String,
}

/// Bookmark representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bookmark {
    pub id: String,
    pub title: String,
    pub url: String,
    pub description: Option<String>,
    pub favicon: Option<String>,
    pub tags: Vec<String>,
    pub folder_id: Option<String>,
}

/// History entry representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HistoryEntry {
    pub id: String,
    pub url: String,
    pub title: String,
    pub visit_count: i32,
    pub last_visit: i64,
}

/// Cached HTTP response
#[derive(Debug, Clone)]
pub struct CachedResponse {
    pub headers: String,
    pub body: Vec<u8>,
    pub expires_at: i64,
}

/// Cached value with expiration
#[derive(Debug, Clone)]
struct CachedValue {
    value: String,
    expires_at: Option<i64>,
}

impl CachedValue {
    fn is_expired(&self) -> bool {
        if let Some(expires_at) = self.expires_at {
            chrono::Utc::now().timestamp() > expires_at
        } else {
            false
        }
    }
}

/// Storage configuration
#[derive(Debug, Clone)]
pub struct StorageConfig {
    pub max_cache_size_mb: u64,
    pub max_history_entries: u32,
    pub cookie_expiry_days: u32,
    pub auto_cleanup_interval_hours: u32,
}

impl Default for StorageConfig {
    fn default() -> Self {
        Self {
            max_cache_size_mb: 500,
            max_history_entries: 10000,
            cookie_expiry_days: 365,
            auto_cleanup_interval_hours: 24,
        }
    }
}

/// Storage statistics
#[derive(Debug, Clone, Default)]
pub struct StorageStats {
    pub database_size_bytes: u64,
    pub settings_count: u64,
    pub cookies_count: u64,
    pub local_storage_count: u64,
    pub cache_entries_count: u64,
    pub bookmarks_count: u64,
    pub history_count: u64,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_storage_engine_creation() {
        let engine = StorageEngine::new().await.unwrap();
        // Basic test to ensure engine can be created
    }
    
    #[tokio::test]
    async fn test_settings_operations() {
        let mut engine = StorageEngine::new().await.unwrap();
        
        // Set a setting
        engine.set_setting("test_key", "test_value").await.unwrap();
        
        // Get the setting
        let value = engine.get_setting("test_key").await.unwrap();
        assert_eq!(value, Some("test_value".to_string()));
        
        // Get non-existent setting
        let none_value = engine.get_setting("non_existent").await.unwrap();
        assert_eq!(none_value, None);
    }
    
    #[tokio::test]
    async fn test_cookie_operations() {
        let mut engine = StorageEngine::new().await.unwrap();
        
        let cookie = Cookie {
            domain: "example.com".to_string(),
            name: "test_cookie".to_string(),
            value: "test_value".to_string(),
            path: "/".to_string(),
            expires: None,
            secure: false,
            http_only: false,
            same_site: "Lax".to_string(),
        };
        
        engine.set_cookie(cookie).await.unwrap();
        
        let cookies = engine.get_cookies("example.com").await.unwrap();
        assert_eq!(cookies.len(), 1);
        assert_eq!(cookies[0].name, "test_cookie");
        assert_eq!(cookies[0].value, "test_value");
    }
    
    #[tokio::test]
    async fn test_bookmark_operations() {
        let mut engine = StorageEngine::new().await.unwrap();
        
        let bookmark = Bookmark {
            id: "test_id".to_string(),
            title: "Test Bookmark".to_string(),
            url: "https://example.com".to_string(),
            description: Some("Test description".to_string()),
            favicon: None,
            tags: vec!["test".to_string(), "bookmark".to_string()],
            folder_id: None,
        };
        
        engine.add_bookmark(bookmark).await.unwrap();
        
        let bookmarks = engine.get_bookmarks().await.unwrap();
        assert_eq!(bookmarks.len(), 1);
        assert_eq!(bookmarks[0].title, "Test Bookmark");
        assert_eq!(bookmarks[0].tags.len(), 2);
    }
}