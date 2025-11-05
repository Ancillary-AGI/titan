//! AI engine for intelligent web browsing features

use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use serde::{Serialize, Deserialize};
use crate::core::{ElementId, Result, EngineError};
use crate::html::Document;
use crate::networking::NetworkResponse;

/// AI engine for intelligent browsing features
pub struct AIEngine {
    /// Page analysis cache
    analysis_cache: Arc<RwLock<HashMap<String, PageContext>>>,
    
    /// AI models and processors
    text_processor: TextProcessor,
    content_analyzer: ContentAnalyzer,
    interaction_predictor: InteractionPredictor,
    
    /// Configuration
    config: AIConfig,
}

impl AIEngine {
    /// Create a new AI engine
    pub async fn new() -> Result<Self> {
        Ok(Self {
            analysis_cache: Arc::new(RwLock::new(HashMap::new())),
            text_processor: TextProcessor::new(),
            content_analyzer: ContentAnalyzer::new(),
            interaction_predictor: InteractionPredictor::new(),
            config: AIConfig::default(),
        })
    }
    
    /// Analyze a web page for AI insights
    pub async fn analyze_page(&self, document: &Document, response: &NetworkResponse) -> Result<PageContext> {
        // Check cache first
        {
            let cache = self.analysis_cache.read().await;
            if let Some(cached_context) = cache.get(&document.url) {
                if !cached_context.is_expired() {
                    return Ok(cached_context.clone());
                }
            }
        }
        
        let mut context = PageContext::new(document.url.clone());
        
        // Extract and analyze text content
        let text_content = self.extract_text_content(document).await?;
        let text_analysis = self.text_processor.analyze(&text_content).await?;
        context.text_analysis = Some(text_analysis);
        
        // Analyze page structure and content
        let content_analysis = self.content_analyzer.analyze(document, response).await?;
        context.content_analysis = Some(content_analysis);
        
        // Predict user interactions
        let interaction_predictions = self.interaction_predictor.predict(document).await?;
        context.interaction_predictions = interaction_predictions;
        
        // Generate insights
        context.insights = self.generate_insights(&context).await?;
        
        // Cache the result
        {
            let mut cache = self.analysis_cache.write().await;
            cache.insert(document.url.clone(), context.clone());
            
            // Limit cache size
            if cache.len() > 100 {
                // Remove oldest entries (simplified LRU)
                let keys_to_remove: Vec<String> = cache.keys().take(20).cloned().collect();
                for key in keys_to_remove {
                    cache.remove(&key);
                }
            }
        }
        
        Ok(context)
    }
    
    /// Extract meaningful text content from document
    async fn extract_text_content(&self, document: &Document) -> Result<String> {
        let mut text_content = String::new();
        
        // Extract title
        text_content.push_str(&document.title);
        text_content.push('\n');
        
        // Extract text from body elements
        if let Some(body) = &document.body {
            self.extract_element_text(body, document, &mut text_content);
        }
        
        Ok(text_content)
    }
    
    /// Recursively extract text from elements
    fn extract_element_text(&self, element: &crate::html::Element, document: &Document, text_content: &mut String) {
        // Add element's text content
        if !element.text_content.is_empty() {
            text_content.push_str(&element.text_content);
            text_content.push(' ');
        }
        
        // Process children
        for child_id in &element.children {
            if let Some(child_element) = document.elements.get(child_id) {
                self.extract_element_text(child_element, document, text_content);
            }
        }
    }
    
    /// Generate AI insights from analysis
    async fn generate_insights(&self, context: &PageContext) -> Result<Vec<AIInsight>> {
        let mut insights = Vec::new();
        
        // Text-based insights
        if let Some(text_analysis) = &context.text_analysis {
            if text_analysis.sentiment_score < -0.5 {
                insights.push(AIInsight {
                    insight_type: "sentiment".to_string(),
                    title: "Negative Content Detected".to_string(),
                    description: "This page contains predominantly negative content".to_string(),
                    confidence: 0.8,
                    actionable: false,
                    metadata: HashMap::new(),
                });
            }
            
            if text_analysis.reading_difficulty > 0.8 {
                insights.push(AIInsight {
                    insight_type: "readability".to_string(),
                    title: "Complex Content".to_string(),
                    description: "This content may be difficult to read".to_string(),
                    confidence: 0.7,
                    actionable: true,
                    metadata: {
                        let mut meta = HashMap::new();
                        meta.insert("suggestion".to_string(), "Consider using reader mode".to_string());
                        meta
                    },
                });
            }
        }
        
        // Content-based insights
        if let Some(content_analysis) = &context.content_analysis {
            if content_analysis.has_forms && !content_analysis.has_https {
                insights.push(AIInsight {
                    insight_type: "security".to_string(),
                    title: "Insecure Form Detected".to_string(),
                    description: "This page has forms but is not using HTTPS".to_string(),
                    confidence: 0.9,
                    actionable: true,
                    metadata: {
                        let mut meta = HashMap::new();
                        meta.insert("risk".to_string(), "high".to_string());
                        meta
                    },
                });
            }
            
            if content_analysis.ad_density > 0.3 {
                insights.push(AIInsight {
                    insight_type: "user_experience".to_string(),
                    title: "High Ad Density".to_string(),
                    description: "This page has a high density of advertisements".to_string(),
                    confidence: 0.8,
                    actionable: true,
                    metadata: {
                        let mut meta = HashMap::new();
                        meta.insert("suggestion".to_string(), "Consider enabling ad blocker".to_string());
                        meta
                    },
                });
            }
        }
        
        // Interaction-based insights
        if !context.interaction_predictions.is_empty() {
            let high_confidence_predictions: Vec<_> = context.interaction_predictions
                .iter()
                .filter(|p| p.confidence > 0.8)
                .collect();
            
            if !high_confidence_predictions.is_empty() {
                insights.push(AIInsight {
                    insight_type: "navigation".to_string(),
                    title: "Predicted User Actions".to_string(),
                    description: format!("AI predicts you might want to {}", 
                        high_confidence_predictions[0].action_type),
                    confidence: high_confidence_predictions[0].confidence,
                    actionable: true,
                    metadata: HashMap::new(),
                });
            }
        }
        
        Ok(insights)
    }
    
    /// Smart form filling suggestions
    pub async fn suggest_form_fill(&self, form_data: &HashMap<String, String>) -> Result<HashMap<String, String>> {
        let mut suggestions = HashMap::new();
        
        for (field_name, field_type) in form_data {
            let field_lower = field_name.to_lowercase();
            
            // Email field detection
            if field_lower.contains("email") || field_lower.contains("e-mail") {
                suggestions.insert(field_name.clone(), "user@example.com".to_string());
            }
            
            // Name field detection
            else if field_lower.contains("name") {
                if field_lower.contains("first") {
                    suggestions.insert(field_name.clone(), "John".to_string());
                } else if field_lower.contains("last") {
                    suggestions.insert(field_name.clone(), "Doe".to_string());
                } else {
                    suggestions.insert(field_name.clone(), "John Doe".to_string());
                }
            }
            
            // Phone field detection
            else if field_lower.contains("phone") || field_lower.contains("tel") {
                suggestions.insert(field_name.clone(), "+1-555-123-4567".to_string());
            }
            
            // Address field detection
            else if field_lower.contains("address") {
                suggestions.insert(field_name.clone(), "123 Main St".to_string());
            }
            
            // City field detection
            else if field_lower.contains("city") {
                suggestions.insert(field_name.clone(), "New York".to_string());
            }
            
            // ZIP/Postal code detection
            else if field_lower.contains("zip") || field_lower.contains("postal") {
                suggestions.insert(field_name.clone(), "10001".to_string());
            }
        }
        
        Ok(suggestions)
    }
    
    /// Content summarization
    pub async fn summarize_content(&self, content: &str, max_length: usize) -> Result<String> {
        self.text_processor.summarize(content, max_length).await
    }
    
    /// Language detection
    pub async fn detect_language(&self, content: &str) -> Result<String> {
        self.text_processor.detect_language(content).await
    }
    
    /// Content translation
    pub async fn translate_content(&self, content: &str, target_language: &str) -> Result<String> {
        self.text_processor.translate(content, target_language).await
    }
    
    /// Update AI configuration
    pub fn update_config(&mut self, config: AIConfig) {
        self.config = config;
    }
    
    /// Shutdown AI engine
    pub async fn shutdown(&self) -> Result<()> {
        // Clean up resources
        let mut cache = self.analysis_cache.write().await;
        cache.clear();
        Ok(())
    }
}

/// Page context with AI analysis
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageContext {
    pub url: String,
    pub analyzed_at: chrono::DateTime<chrono::Utc>,
    pub text_analysis: Option<TextAnalysis>,
    pub content_analysis: Option<ContentAnalysis>,
    pub interaction_predictions: Vec<InteractionPrediction>,
    pub insights: Vec<AIInsight>,
}

impl PageContext {
    fn new(url: String) -> Self {
        Self {
            url,
            analyzed_at: chrono::Utc::now(),
            text_analysis: None,
            content_analysis: None,
            interaction_predictions: Vec::new(),
            insights: Vec::new(),
        }
    }
    
    fn is_expired(&self) -> bool {
        let now = chrono::Utc::now();
        let age = now.signed_duration_since(self.analyzed_at);
        age.num_minutes() > 30 // Expire after 30 minutes
    }
}

/// Text analysis results
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextAnalysis {
    pub word_count: usize,
    pub character_count: usize,
    pub sentence_count: usize,
    pub paragraph_count: usize,
    pub reading_time_minutes: f64,
    pub reading_difficulty: f64, // 0.0 = easy, 1.0 = very difficult
    pub sentiment_score: f64, // -1.0 = very negative, 1.0 = very positive
    pub language: String,
    pub keywords: Vec<String>,
    pub topics: Vec<String>,
}

/// Content analysis results
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentAnalysis {
    pub has_forms: bool,
    pub has_https: bool,
    pub has_images: bool,
    pub has_videos: bool,
    pub has_audio: bool,
    pub has_scripts: bool,
    pub has_external_links: bool,
    pub ad_density: f64, // 0.0 = no ads, 1.0 = all ads
    pub content_quality_score: f64, // 0.0 = poor, 1.0 = excellent
    pub mobile_friendly: bool,
    pub accessibility_score: f64, // 0.0 = poor, 1.0 = excellent
    pub performance_score: f64, // 0.0 = poor, 1.0 = excellent
}

/// Interaction prediction
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InteractionPrediction {
    pub element_id: Option<ElementId>,
    pub action_type: String, // "click", "scroll", "form_fill", etc.
    pub confidence: f64, // 0.0 = unlikely, 1.0 = very likely
    pub reasoning: String,
}

/// AI insight
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AIInsight {
    pub insight_type: String,
    pub title: String,
    pub description: String,
    pub confidence: f64,
    pub actionable: bool,
    pub metadata: HashMap<String, String>,
}

/// Text processing engine
struct TextProcessor;

impl TextProcessor {
    fn new() -> Self {
        Self
    }
    
    async fn analyze(&self, text: &str) -> Result<TextAnalysis> {
        let words: Vec<&str> = text.split_whitespace().collect();
        let sentences: Vec<&str> = text.split(&['.', '!', '?'][..]).collect();
        let paragraphs: Vec<&str> = text.split("\n\n").collect();
        
        Ok(TextAnalysis {
            word_count: words.len(),
            character_count: text.len(),
            sentence_count: sentences.len(),
            paragraph_count: paragraphs.len(),
            reading_time_minutes: words.len() as f64 / 200.0, // Average reading speed
            reading_difficulty: self.calculate_reading_difficulty(&words, &sentences),
            sentiment_score: self.analyze_sentiment(text),
            language: self.detect_language_simple(text),
            keywords: self.extract_keywords(&words),
            topics: self.extract_topics(&words),
        })
    }
    
    fn calculate_reading_difficulty(&self, words: &[&str], sentences: &[&str]) -> f64 {
        if sentences.is_empty() || words.is_empty() {
            return 0.0;
        }
        
        let avg_sentence_length = words.len() as f64 / sentences.len() as f64;
        let avg_syllables = words.iter()
            .map(|word| self.count_syllables(word))
            .sum::<usize>() as f64 / words.len() as f64;
        
        // Simplified Flesch Reading Ease
        let score = 206.835 - (1.015 * avg_sentence_length) - (84.6 * avg_syllables);
        (100.0 - score) / 100.0 // Convert to 0-1 scale where 1 is most difficult
    }
    
    fn count_syllables(&self, word: &str) -> usize {
        let vowels = "aeiouAEIOU";
        let mut count = 0;
        let mut prev_was_vowel = false;
        
        for ch in word.chars() {
            let is_vowel = vowels.contains(ch);
            if is_vowel && !prev_was_vowel {
                count += 1;
            }
            prev_was_vowel = is_vowel;
        }
        
        if word.ends_with('e') && count > 1 {
            count -= 1;
        }
        
        count.max(1)
    }
    
    fn analyze_sentiment(&self, text: &str) -> f64 {
        let positive_words = ["good", "great", "excellent", "amazing", "wonderful", "fantastic", "love", "like"];
        let negative_words = ["bad", "terrible", "awful", "horrible", "hate", "dislike", "poor", "worst"];
        
        let text_lower = text.to_lowercase();
        let mut positive_count = 0;
        let mut negative_count = 0;
        
        for word in &positive_words {
            positive_count += text_lower.matches(word).count();
        }
        
        for word in &negative_words {
            negative_count += text_lower.matches(word).count();
        }
        
        let total = positive_count + negative_count;
        if total == 0 {
            return 0.0;
        }
        
        (positive_count as f64 - negative_count as f64) / total as f64
    }
    
    fn detect_language_simple(&self, text: &str) -> String {
        let english_words = ["the", "and", "or", "but", "in", "on", "at", "to", "for", "of"];
        let spanish_words = ["el", "la", "y", "o", "pero", "en", "de", "para", "con", "por"];
        let french_words = ["le", "la", "et", "ou", "mais", "dans", "de", "pour", "avec", "par"];
        
        let text_lower = text.to_lowercase();
        let mut english_score = 0;
        let mut spanish_score = 0;
        let mut french_score = 0;
        
        for word in &english_words {
            english_score += text_lower.matches(word).count();
        }
        
        for word in &spanish_words {
            spanish_score += text_lower.matches(word).count();
        }
        
        for word in &french_words {
            french_score += text_lower.matches(word).count();
        }
        
        if english_score >= spanish_score && english_score >= french_score {
            "en".to_string()
        } else if spanish_score >= french_score {
            "es".to_string()
        } else {
            "fr".to_string()
        }
    }
    
    fn extract_keywords(&self, words: &[&str]) -> Vec<String> {
        let stop_words = ["the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"];
        let mut word_counts = HashMap::new();
        
        for word in words {
            let word_lower = word.to_lowercase();
            if word_lower.len() > 3 && !stop_words.contains(&word_lower.as_str()) {
                *word_counts.entry(word_lower).or_insert(0) += 1;
            }
        }
        
        let mut sorted_words: Vec<_> = word_counts.into_iter().collect();
        sorted_words.sort_by(|a, b| b.1.cmp(&a.1));
        
        sorted_words.into_iter().take(10).map(|(word, _)| word).collect()
    }
    
    fn extract_topics(&self, words: &[&str]) -> Vec<String> {
        // Simplified topic extraction based on keyword clustering
        let tech_words = ["technology", "computer", "software", "internet", "digital"];
        let business_words = ["business", "company", "market", "finance", "economy"];
        let health_words = ["health", "medical", "doctor", "hospital", "medicine"];
        
        let text = words.join(" ").to_lowercase();
        let mut topics = Vec::new();
        
        if tech_words.iter().any(|word| text.contains(word)) {
            topics.push("Technology".to_string());
        }
        
        if business_words.iter().any(|word| text.contains(word)) {
            topics.push("Business".to_string());
        }
        
        if health_words.iter().any(|word| text.contains(word)) {
            topics.push("Health".to_string());
        }
        
        topics
    }
    
    async fn summarize(&self, content: &str, max_length: usize) -> Result<String> {
        let sentences: Vec<&str> = content.split(&['.', '!', '?'][..])
            .filter(|s| !s.trim().is_empty())
            .collect();
        
        if sentences.is_empty() {
            return Ok(String::new());
        }
        
        // Simple extractive summarization - take first few sentences
        let mut summary = String::new();
        let mut current_length = 0;
        
        for sentence in sentences {
            let sentence_trimmed = sentence.trim();
            if current_length + sentence_trimmed.len() > max_length {
                break;
            }
            
            if !summary.is_empty() {
                summary.push_str(". ");
            }
            summary.push_str(sentence_trimmed);
            current_length += sentence_trimmed.len() + 2;
        }
        
        Ok(summary)
    }
    
    async fn detect_language(&self, content: &str) -> Result<String> {
        Ok(self.detect_language_simple(content))
    }
    
    async fn translate(&self, _content: &str, _target_language: &str) -> Result<String> {
        // Placeholder for translation functionality
        Ok("Translation not implemented".to_string())
    }
}

/// Content analysis engine
struct ContentAnalyzer;

impl ContentAnalyzer {
    fn new() -> Self {
        Self
    }
    
    async fn analyze(&self, document: &Document, response: &NetworkResponse) -> Result<ContentAnalysis> {
        Ok(ContentAnalysis {
            has_forms: self.has_forms(document),
            has_https: response.url.starts_with("https://"),
            has_images: self.has_images(document),
            has_videos: self.has_videos(document),
            has_audio: self.has_audio(document),
            has_scripts: self.has_scripts(document),
            has_external_links: self.has_external_links(document),
            ad_density: self.calculate_ad_density(document),
            content_quality_score: self.calculate_content_quality(document),
            mobile_friendly: self.is_mobile_friendly(document),
            accessibility_score: self.calculate_accessibility_score(document),
            performance_score: self.calculate_performance_score(response),
        })
    }
    
    fn has_forms(&self, document: &Document) -> bool {
        !document.get_elements_by_tag_name("form").is_empty()
    }
    
    fn has_images(&self, document: &Document) -> bool {
        !document.get_elements_by_tag_name("img").is_empty()
    }
    
    fn has_videos(&self, document: &Document) -> bool {
        !document.get_elements_by_tag_name("video").is_empty()
    }
    
    fn has_audio(&self, document: &Document) -> bool {
        !document.get_elements_by_tag_name("audio").is_empty()
    }
    
    fn has_scripts(&self, document: &Document) -> bool {
        !document.get_elements_by_tag_name("script").is_empty()
    }
    
    fn has_external_links(&self, document: &Document) -> bool {
        let links = document.get_elements_by_tag_name("a");
        links.iter().any(|link| {
            if let Some(href) = link.get_attribute("href") {
                href.starts_with("http://") || href.starts_with("https://")
            } else {
                false
            }
        })
    }
    
    fn calculate_ad_density(&self, _document: &Document) -> f64 {
        // Simplified ad detection
        0.1 // Placeholder
    }
    
    fn calculate_content_quality(&self, _document: &Document) -> f64 {
        // Simplified content quality assessment
        0.7 // Placeholder
    }
    
    fn is_mobile_friendly(&self, _document: &Document) -> bool {
        // Simplified mobile-friendliness check
        true // Placeholder
    }
    
    fn calculate_accessibility_score(&self, _document: &Document) -> f64 {
        // Simplified accessibility assessment
        0.8 // Placeholder
    }
    
    fn calculate_performance_score(&self, response: &NetworkResponse) -> f64 {
        // Simple performance score based on load time
        let load_time_ms = response.load_time.as_millis() as f64;
        if load_time_ms < 1000.0 {
            1.0
        } else if load_time_ms < 3000.0 {
            0.8
        } else if load_time_ms < 5000.0 {
            0.6
        } else {
            0.4
        }
    }
}

/// Interaction prediction engine
struct InteractionPredictor;

impl InteractionPredictor {
    fn new() -> Self {
        Self
    }
    
    async fn predict(&self, document: &Document) -> Result<Vec<InteractionPrediction>> {
        let mut predictions = Vec::new();
        
        // Predict form interactions
        let forms = document.get_elements_by_tag_name("form");
        for form in forms {
            predictions.push(InteractionPrediction {
                element_id: Some(form.id),
                action_type: "form_fill".to_string(),
                confidence: 0.7,
                reasoning: "Form detected on page".to_string(),
            });
        }
        
        // Predict button clicks
        let buttons = document.get_elements_by_tag_name("button");
        for button in buttons {
            predictions.push(InteractionPrediction {
                element_id: Some(button.id),
                action_type: "click".to_string(),
                confidence: 0.6,
                reasoning: "Interactive button element".to_string(),
            });
        }
        
        // Predict link navigation
        let links = document.get_elements_by_tag_name("a");
        for link in links.iter().take(3) { // Only predict top 3 links
            if link.get_attribute("href").is_some() {
                predictions.push(InteractionPrediction {
                    element_id: Some(link.id),
                    action_type: "navigate".to_string(),
                    confidence: 0.5,
                    reasoning: "Navigation link detected".to_string(),
                });
            }
        }
        
        Ok(predictions)
    }
}

/// AI configuration
#[derive(Debug, Clone)]
pub struct AIConfig {
    pub enable_text_analysis: bool,
    pub enable_content_analysis: bool,
    pub enable_interaction_prediction: bool,
    pub enable_form_suggestions: bool,
    pub enable_translation: bool,
    pub cache_analysis_results: bool,
    pub max_cache_size: usize,
}

impl Default for AIConfig {
    fn default() -> Self {
        Self {
            enable_text_analysis: true,
            enable_content_analysis: true,
            enable_interaction_prediction: true,
            enable_form_suggestions: true,
            enable_translation: false,
            cache_analysis_results: true,
            max_cache_size: 100,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_ai_engine_creation() {
        let engine = AIEngine::new().await.unwrap();
        // Basic test to ensure engine can be created
    }
    
    #[tokio::test]
    async fn test_text_analysis() {
        let processor = TextProcessor::new();
        let text = "This is a test sentence. It has multiple sentences! How wonderful?";
        
        let analysis = processor.analyze(text).await.unwrap();
        assert_eq!(analysis.sentence_count, 3);
        assert!(analysis.word_count > 0);
        assert!(analysis.reading_time_minutes > 0.0);
    }
    
    #[test]
    fn test_syllable_counting() {
        let processor = TextProcessor::new();
        
        assert_eq!(processor.count_syllables("hello"), 2);
        assert_eq!(processor.count_syllables("world"), 1);
        assert_eq!(processor.count_syllables("beautiful"), 3);
        assert_eq!(processor.count_syllables("a"), 1);
    }
    
    #[test]
    fn test_sentiment_analysis() {
        let processor = TextProcessor::new();
        
        let positive_text = "This is great and wonderful and amazing";
        assert!(processor.analyze_sentiment(positive_text) > 0.0);
        
        let negative_text = "This is terrible and awful and horrible";
        assert!(processor.analyze_sentiment(negative_text) < 0.0);
        
        let neutral_text = "This is a normal sentence with no sentiment";
        assert_eq!(processor.analyze_sentiment(neutral_text), 0.0);
    }
    
    #[tokio::test]
    async fn test_content_summarization() {
        let processor = TextProcessor::new();
        let long_text = "This is the first sentence. This is the second sentence. This is the third sentence. This is the fourth sentence.";
        
        let summary = processor.summarize(long_text, 50).await.unwrap();
        assert!(summary.len() <= 50);
        assert!(!summary.is_empty());
    }
}