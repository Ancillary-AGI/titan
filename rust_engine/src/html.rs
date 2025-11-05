//! HTML parsing and DOM implementation using html5ever

use std::collections::HashMap;
use std::sync::Arc;
use html5ever::parse_document;
use html5ever::rcdom::{RcDom, NodeData, Handle};
use html5ever::tendril::TendrilSink;
use markup5ever::{LocalName, Namespace, QualName};
use crate::core::{ElementId, Result, EngineError};

/// HTML parser using html5ever for standards compliance
pub struct HTMLParser {
    /// Parser options and configuration
    options: html5ever::ParseOpts,
}

impl HTMLParser {
    pub fn new() -> Self {
        Self {
            options: html5ever::ParseOpts::default(),
        }
    }
    
    /// Parse HTML string into a Document
    pub fn parse(&self, html: &str) -> Result<Document> {
        let dom = parse_document(RcDom::default(), self.options.clone())
            .from_utf8()
            .read_from(&mut html.as_bytes())
            .map_err(|e| EngineError::HtmlParseError(format!("Parse error: {:?}", e)))?;
        
        let document = Document::from_rcdom(dom)?;
        Ok(document)
    }
    
    /// Parse HTML fragment (for innerHTML operations)
    pub fn parse_fragment(&self, html: &str, context_element: &Element) -> Result<DocumentFragment> {
        // Implementation for fragment parsing
        let fragment = DocumentFragment::new();
        // TODO: Implement fragment parsing with html5ever
        Ok(fragment)
    }
}

/// Represents a complete HTML document
#[derive(Debug, Clone)]
pub struct Document {
    pub url: String,
    pub title: String,
    pub head: Option<Arc<Element>>,
    pub body: Option<Arc<Element>>,
    pub doctype: Option<DocumentType>,
    pub elements: HashMap<ElementId, Arc<Element>>,
    pub root: Arc<Element>,
}

impl Document {
    pub fn new(url: String) -> Self {
        let root = Arc::new(Element::new("html".to_string(), ElementId::new()));
        let mut elements = HashMap::new();
        elements.insert(root.id, root.clone());
        
        Self {
            url,
            title: String::new(),
            head: None,
            body: None,
            doctype: None,
            elements,
            root,
        }
    }
    
    /// Convert from html5ever's RcDom to our Document structure
    pub fn from_rcdom(dom: RcDom) -> Result<Self> {
        let mut document = Document::new("about:blank".to_string());
        
        // Traverse the DOM tree and convert nodes
        document.traverse_node(&dom.document, None)?;
        
        // Extract title from head
        if let Some(head) = &document.head {
            if let Some(title_element) = head.find_child_by_tag("title") {
                document.title = title_element.text_content();
            }
        }
        
        Ok(document)
    }
    
    fn traverse_node(&mut self, handle: &Handle, parent_id: Option<ElementId>) -> Result<()> {
        let node = handle.borrow();
        
        match &node.data {
            NodeData::Document => {
                // Process document children
                for child in &node.children {
                    self.traverse_node(child, None)?;
                }
            }
            NodeData::Doctype { name, public_id, system_id } => {
                self.doctype = Some(DocumentType {
                    name: name.to_string(),
                    public_id: public_id.to_string(),
                    system_id: system_id.to_string(),
                });
            }
            NodeData::Text { contents } => {
                // Handle text nodes
                if let Some(parent_id) = parent_id {
                    if let Some(parent) = self.elements.get_mut(&parent_id) {
                        // Add text content to parent element
                        // This is a simplified approach - in reality we'd need proper text node handling
                    }
                }
            }
            NodeData::Comment { .. } => {
                // Skip comments for now
            }
            NodeData::Element { name, attrs, .. } => {
                let tag_name = name.local.to_string();
                let element_id = ElementId::new();
                
                let mut element = Element::new(tag_name.clone(), element_id);
                
                // Process attributes
                for attr in attrs.borrow().iter() {
                    element.attributes.insert(
                        attr.name.local.to_string(),
                        attr.value.to_string(),
                    );
                }
                
                // Set special references for html, head, body
                match tag_name.as_str() {
                    "html" => {
                        self.root = Arc::new(element.clone());
                    }
                    "head" => {
                        self.head = Some(Arc::new(element.clone()));
                    }
                    "body" => {
                        self.body = Some(Arc::new(element.clone()));
                    }
                    _ => {}
                }
                
                // Add to elements map
                self.elements.insert(element_id, Arc::new(element));
                
                // Process children
                for child in &node.children {
                    self.traverse_node(child, Some(element_id))?;
                }
            }
            NodeData::ProcessingInstruction { .. } => {
                // Skip processing instructions
            }
        }
        
        Ok(())
    }
    
    /// Find element by ID
    pub fn get_element_by_id(&self, id: &str) -> Option<Arc<Element>> {
        self.elements.values()
            .find(|element| element.get_attribute("id") == Some(id))
            .cloned()
    }
    
    /// Find elements by tag name
    pub fn get_elements_by_tag_name(&self, tag_name: &str) -> Vec<Arc<Element>> {
        self.elements.values()
            .filter(|element| element.tag_name.eq_ignore_ascii_case(tag_name))
            .cloned()
            .collect()
    }
    
    /// Find elements by class name
    pub fn get_elements_by_class_name(&self, class_name: &str) -> Vec<Arc<Element>> {
        self.elements.values()
            .filter(|element| {
                if let Some(class_attr) = element.get_attribute("class") {
                    class_attr.split_whitespace().any(|c| c == class_name)
                } else {
                    false
                }
            })
            .cloned()
            .collect()
    }
}

/// Represents an HTML element
#[derive(Debug, Clone)]
pub struct Element {
    pub id: ElementId,
    pub tag_name: String,
    pub attributes: HashMap<String, String>,
    pub children: Vec<ElementId>,
    pub parent: Option<ElementId>,
    pub text_content: String,
}

impl Element {
    pub fn new(tag_name: String, id: ElementId) -> Self {
        Self {
            id,
            tag_name,
            attributes: HashMap::new(),
            children: Vec::new(),
            parent: None,
            text_content: String::new(),
        }
    }
    
    /// Get attribute value
    pub fn get_attribute(&self, name: &str) -> Option<&str> {
        self.attributes.get(name).map(|s| s.as_str())
    }
    
    /// Set attribute value
    pub fn set_attribute(&mut self, name: String, value: String) {
        self.attributes.insert(name, value);
    }
    
    /// Remove attribute
    pub fn remove_attribute(&mut self, name: &str) {
        self.attributes.remove(name);
    }
    
    /// Check if element has attribute
    pub fn has_attribute(&self, name: &str) -> bool {
        self.attributes.contains_key(name)
    }
    
    /// Get text content of element
    pub fn text_content(&self) -> String {
        self.text_content.clone()
    }
    
    /// Set text content of element
    pub fn set_text_content(&mut self, content: String) {
        self.text_content = content;
    }
    
    /// Find child element by tag name
    pub fn find_child_by_tag(&self, tag_name: &str) -> Option<Arc<Element>> {
        // This would require access to the document to resolve child IDs
        // For now, return None - proper implementation would traverse children
        None
    }
    
    /// Check if element matches a CSS selector (simplified)
    pub fn matches_selector(&self, selector: &str) -> bool {
        // Simplified selector matching - in reality this would use the selectors crate
        match selector.chars().next() {
            Some('#') => {
                // ID selector
                let id = &selector[1..];
                self.get_attribute("id") == Some(id)
            }
            Some('.') => {
                // Class selector
                let class = &selector[1..];
                if let Some(class_attr) = self.get_attribute("class") {
                    class_attr.split_whitespace().any(|c| c == class)
                } else {
                    false
                }
            }
            _ => {
                // Tag selector
                self.tag_name.eq_ignore_ascii_case(selector)
            }
        }
    }
    
    /// Get computed style for this element (placeholder)
    pub fn get_computed_style(&self) -> ComputedStyle {
        ComputedStyle::default()
    }
}

/// Document fragment for partial DOM operations
#[derive(Debug, Clone)]
pub struct DocumentFragment {
    pub children: Vec<ElementId>,
}

impl DocumentFragment {
    pub fn new() -> Self {
        Self {
            children: Vec::new(),
        }
    }
}

/// Document type declaration
#[derive(Debug, Clone)]
pub struct DocumentType {
    pub name: String,
    pub public_id: String,
    pub system_id: String,
}

/// Computed style for an element (simplified)
#[derive(Debug, Clone, Default)]
pub struct ComputedStyle {
    pub display: String,
    pub position: String,
    pub width: String,
    pub height: String,
    pub margin: String,
    pub padding: String,
    pub border: String,
    pub background_color: String,
    pub color: String,
    pub font_family: String,
    pub font_size: String,
    pub font_weight: String,
    pub text_align: String,
    pub line_height: String,
}

/// HTML parsing utilities
pub struct HTMLUtils;

impl HTMLUtils {
    /// Sanitize HTML to prevent XSS attacks
    pub fn sanitize_html(html: &str) -> String {
        // Basic HTML sanitization - remove script tags and dangerous attributes
        let mut sanitized = html.to_string();
        
        // Remove script tags
        sanitized = regex::Regex::new(r"(?i)<script[^>]*>.*?</script>")
            .unwrap()
            .replace_all(&sanitized, "")
            .to_string();
        
        // Remove dangerous event handlers
        let dangerous_attrs = [
            "onload", "onerror", "onclick", "onmouseover", "onmouseout",
            "onfocus", "onblur", "onchange", "onsubmit", "onreset",
        ];
        
        for attr in &dangerous_attrs {
            let pattern = format!(r"(?i){}=[^>\s]*", attr);
            sanitized = regex::Regex::new(&pattern)
                .unwrap()
                .replace_all(&sanitized, "")
                .to_string();
        }
        
        sanitized
    }
    
    /// Extract text content from HTML
    pub fn extract_text(html: &str) -> String {
        // Remove HTML tags and return plain text
        regex::Regex::new(r"<[^>]*>")
            .unwrap()
            .replace_all(html, "")
            .to_string()
    }
    
    /// Extract links from HTML
    pub fn extract_links(html: &str) -> Vec<String> {
        let mut links = Vec::new();
        
        // Extract href attributes from anchor tags
        let link_regex = regex::Regex::new(r#"(?i)<a[^>]*href=["']([^"']*)["'][^>]*>"#).unwrap();
        
        for cap in link_regex.captures_iter(html) {
            if let Some(href) = cap.get(1) {
                links.push(href.as_str().to_string());
            }
        }
        
        links
    }
    
    /// Extract images from HTML
    pub fn extract_images(html: &str) -> Vec<String> {
        let mut images = Vec::new();
        
        // Extract src attributes from img tags
        let img_regex = regex::Regex::new(r#"(?i)<img[^>]*src=["']([^"']*)["'][^>]*>"#).unwrap();
        
        for cap in img_regex.captures_iter(html) {
            if let Some(src) = cap.get(1) {
                images.push(src.as_str().to_string());
            }
        }
        
        images
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_html_parser_creation() {
        let parser = HTMLParser::new();
        // Basic test to ensure parser can be created
    }
    
    #[test]
    fn test_simple_html_parsing() {
        let parser = HTMLParser::new();
        let html = r#"
            <!DOCTYPE html>
            <html>
                <head>
                    <title>Test Page</title>
                </head>
                <body>
                    <h1 id="main-title">Hello World</h1>
                    <p class="content">This is a test paragraph.</p>
                </body>
            </html>
        "#;
        
        let document = parser.parse(html).unwrap();
        assert_eq!(document.title, "Test Page");
        assert!(document.head.is_some());
        assert!(document.body.is_some());
    }
    
    #[test]
    fn test_element_attribute_operations() {
        let mut element = Element::new("div".to_string(), ElementId::new());
        
        element.set_attribute("id".to_string(), "test-id".to_string());
        element.set_attribute("class".to_string(), "test-class".to_string());
        
        assert_eq!(element.get_attribute("id"), Some("test-id"));
        assert_eq!(element.get_attribute("class"), Some("test-class"));
        assert!(element.has_attribute("id"));
        assert!(!element.has_attribute("data-test"));
        
        element.remove_attribute("class");
        assert!(!element.has_attribute("class"));
    }
    
    #[test]
    fn test_html_sanitization() {
        let dangerous_html = r#"
            <div>Safe content</div>
            <script>alert('xss')</script>
            <img src="x" onerror="alert('xss')">
        "#;
        
        let sanitized = HTMLUtils::sanitize_html(dangerous_html);
        assert!(!sanitized.contains("<script"));
        assert!(!sanitized.contains("onerror"));
    }
    
    #[test]
    fn test_text_extraction() {
        let html = "<div><p>Hello <strong>World</strong>!</p></div>";
        let text = HTMLUtils::extract_text(html);
        assert_eq!(text, "Hello World!");
    }
    
    #[test]
    fn test_link_extraction() {
        let html = r#"
            <a href="https://example.com">Link 1</a>
            <a href="/relative">Link 2</a>
        "#;
        
        let links = HTMLUtils::extract_links(html);
        assert_eq!(links.len(), 2);
        assert!(links.contains(&"https://example.com".to_string()));
        assert!(links.contains(&"/relative".to_string()));
    }
}