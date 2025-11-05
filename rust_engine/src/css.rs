//! CSS parsing and styling engine using cssparser and selectors

use std::collections::HashMap;
use std::sync::Arc;
use cssparser::{Parser, ParserInput, ParseError, Token, Color as CSSColor};
use selectors::parser::{SelectorList, ParseRelative};
use selectors::{Element as SelectorElement, OpaqueElement};
use crate::core::{ElementId, Result, EngineError, Color};
use crate::html::{Document, Element};

/// CSS engine for parsing stylesheets and computing styles
pub struct CSSEngine {
    /// Default user agent stylesheet
    user_agent_stylesheet: Stylesheet,
    
    /// Cached parsed stylesheets
    stylesheet_cache: HashMap<String, Arc<Stylesheet>>,
}

impl CSSEngine {
    pub fn new() -> Self {
        Self {
            user_agent_stylesheet: Stylesheet::default_user_agent(),
            stylesheet_cache: HashMap::new(),
        }
    }
    
    /// Parse CSS string into a stylesheet
    pub fn parse_stylesheet(&self, css: &str, origin: StylesheetOrigin) -> Result<Stylesheet> {
        let mut input = ParserInput::new(css);
        let mut parser = Parser::new(&mut input);
        
        let mut rules = Vec::new();
        
        while !parser.is_exhausted() {
            match self.parse_rule(&mut parser) {
                Ok(rule) => rules.push(rule),
                Err(e) => {
                    // Log error but continue parsing
                    log::warn!("CSS parse error: {:?}", e);
                    // Skip to next rule
                    while !parser.is_exhausted() {
                        if let Ok(Token::CurlyBracketBlock) = parser.next() {
                            break;
                        }
                    }
                }
            }
        }
        
        Ok(Stylesheet {
            rules,
            origin,
            media_queries: Vec::new(),
        })
    }
    
    /// Parse stylesheets from a document
    pub async fn parse_stylesheets(&self, document: &Document) -> Result<Vec<Arc<Stylesheet>>> {
        let mut stylesheets = Vec::new();
        
        // Add user agent stylesheet
        stylesheets.push(Arc::new(self.user_agent_stylesheet.clone()));
        
        // Parse <style> elements
        let style_elements = document.get_elements_by_tag_name("style");
        for style_element in style_elements {
            let css_text = style_element.text_content();
            if !css_text.is_empty() {
                match self.parse_stylesheet(&css_text, StylesheetOrigin::Author) {
                    Ok(stylesheet) => stylesheets.push(Arc::new(stylesheet)),
                    Err(e) => log::warn!("Failed to parse inline stylesheet: {:?}", e),
                }
            }
        }
        
        // Parse <link> elements for external stylesheets
        let link_elements = document.get_elements_by_tag_name("link");
        for link_element in link_elements {
            if let Some(rel) = link_element.get_attribute("rel") {
                if rel == "stylesheet" {
                    if let Some(href) = link_element.get_attribute("href") {
                        // TODO: Fetch external stylesheet
                        // For now, we'll skip external stylesheets
                        log::info!("External stylesheet found: {}", href);
                    }
                }
            }
        }
        
        Ok(stylesheets)
    }
    
    /// Compute the final style for an element
    pub fn compute_style(&self, element: &Element, stylesheets: &[Arc<Stylesheet>]) -> ComputedStyle {
        let mut computed_style = ComputedStyle::default();
        
        // Apply styles from all stylesheets in cascade order
        for stylesheet in stylesheets {
            for rule in &stylesheet.rules {
                if let CSSRule::StyleRule(style_rule) = rule {
                    // Check if any selector matches the element
                    for selector in &style_rule.selectors {
                        if self.selector_matches(selector, element) {
                            // Apply declarations
                            for declaration in &style_rule.declarations {
                                self.apply_declaration(&mut computed_style, declaration);
                            }
                        }
                    }
                }
            }
        }
        
        // Apply inline styles (highest specificity)
        if let Some(style_attr) = element.get_attribute("style") {
            if let Ok(declarations) = self.parse_declaration_list(style_attr) {
                for declaration in declarations {
                    self.apply_declaration(&mut computed_style, &declaration);
                }
            }
        }
        
        computed_style
    }
    
    fn parse_rule(&self, parser: &mut Parser) -> Result<CSSRule> {
        // Simplified rule parsing - in reality this would be much more complex
        let selector_text = self.parse_selector_list(parser)?;
        
        parser.expect_curly_bracket_block()?;
        let declarations = parser.parse_nested_block(|parser| {
            self.parse_declaration_list_from_parser(parser)
        })?;
        
        Ok(CSSRule::StyleRule(StyleRule {
            selectors: vec![selector_text],
            declarations,
        }))
    }
    
    fn parse_selector_list(&self, parser: &mut Parser) -> Result<String> {
        // Simplified selector parsing
        let mut selector = String::new();
        
        while !parser.is_exhausted() {
            match parser.next() {
                Ok(Token::CurlyBracketBlock) => break,
                Ok(token) => {
                    selector.push_str(&token.to_css_string());
                }
                Err(_) => break,
            }
        }
        
        Ok(selector.trim().to_string())
    }
    
    fn parse_declaration_list_from_parser(&self, parser: &mut Parser) -> Result<Vec<Declaration>> {
        let mut declarations = Vec::new();
        
        while !parser.is_exhausted() {
            if let Ok(declaration) = self.parse_declaration(parser) {
                declarations.push(declaration);
            }
            
            // Skip to next declaration
            while !parser.is_exhausted() {
                match parser.next() {
                    Ok(Token::Semicolon) => break,
                    Ok(Token::EOF) => break,
                    _ => continue,
                }
            }
        }
        
        Ok(declarations)
    }
    
    fn parse_declaration_list(&self, css: &str) -> Result<Vec<Declaration>> {
        let mut input = ParserInput::new(css);
        let mut parser = Parser::new(&mut input);
        self.parse_declaration_list_from_parser(&mut parser)
    }
    
    fn parse_declaration(&self, parser: &mut Parser) -> Result<Declaration> {
        let property = match parser.next() {
            Ok(Token::Ident(name)) => name.to_string(),
            _ => return Err(EngineError::CssParseError("Expected property name".to_string())),
        };
        
        parser.expect_colon()?;
        
        let mut value = String::new();
        while !parser.is_exhausted() {
            match parser.next() {
                Ok(Token::Semicolon) | Ok(Token::EOF) => break,
                Ok(token) => {
                    if !value.is_empty() {
                        value.push(' ');
                    }
                    value.push_str(&token.to_css_string());
                }
                Err(_) => break,
            }
        }
        
        Ok(Declaration {
            property,
            value: value.trim().to_string(),
            important: false, // TODO: Parse !important
        })
    }
    
    fn selector_matches(&self, selector: &str, element: &Element) -> bool {
        // Simplified selector matching
        element.matches_selector(selector)
    }
    
    fn apply_declaration(&self, computed_style: &mut ComputedStyle, declaration: &Declaration) {
        match declaration.property.as_str() {
            "color" => {
                computed_style.color = self.parse_color(&declaration.value)
                    .unwrap_or(Color::black());
            }
            "background-color" => {
                computed_style.background_color = self.parse_color(&declaration.value)
                    .unwrap_or(Color::transparent());
            }
            "font-size" => {
                computed_style.font_size = self.parse_length(&declaration.value)
                    .unwrap_or(16.0);
            }
            "font-family" => {
                computed_style.font_family = declaration.value.clone();
            }
            "font-weight" => {
                computed_style.font_weight = self.parse_font_weight(&declaration.value)
                    .unwrap_or(400);
            }
            "display" => {
                computed_style.display = self.parse_display(&declaration.value)
                    .unwrap_or(DisplayType::Block);
            }
            "position" => {
                computed_style.position = self.parse_position(&declaration.value)
                    .unwrap_or(PositionType::Static);
            }
            "width" => {
                computed_style.width = self.parse_length(&declaration.value);
            }
            "height" => {
                computed_style.height = self.parse_length(&declaration.value);
            }
            "margin" => {
                computed_style.margin = self.parse_box_values(&declaration.value);
            }
            "padding" => {
                computed_style.padding = self.parse_box_values(&declaration.value);
            }
            "border-width" => {
                computed_style.border_width = self.parse_box_values(&declaration.value);
            }
            _ => {
                // Unknown property, store as custom property
                computed_style.custom_properties.insert(
                    declaration.property.clone(),
                    declaration.value.clone(),
                );
            }
        }
    }
    
    fn parse_color(&self, value: &str) -> Option<Color> {
        let mut input = ParserInput::new(value);
        let mut parser = Parser::new(&mut input);
        
        if let Ok(css_color) = CSSColor::parse(&mut parser) {
            match css_color {
                CSSColor::RGBA(rgba) => Some(Color::new(
                    rgba.red as f32 / 255.0,
                    rgba.green as f32 / 255.0,
                    rgba.blue as f32 / 255.0,
                    rgba.alpha,
                )),
                _ => None,
            }
        } else {
            // Try named colors
            match value.to_lowercase().as_str() {
                "red" => Some(Color::rgb(1.0, 0.0, 0.0)),
                "green" => Some(Color::rgb(0.0, 1.0, 0.0)),
                "blue" => Some(Color::rgb(0.0, 0.0, 1.0)),
                "white" => Some(Color::white()),
                "black" => Some(Color::black()),
                "transparent" => Some(Color::transparent()),
                _ => None,
            }
        }
    }
    
    fn parse_length(&self, value: &str) -> Option<f32> {
        // Simple length parsing - supports px, em, rem, %
        if let Some(px_pos) = value.find("px") {
            value[..px_pos].parse().ok()
        } else if let Some(em_pos) = value.find("em") {
            value[..em_pos].parse::<f32>().ok().map(|v| v * 16.0) // Assume 16px base
        } else if let Some(rem_pos) = value.find("rem") {
            value[..rem_pos].parse::<f32>().ok().map(|v| v * 16.0) // Assume 16px base
        } else if let Some(percent_pos) = value.find('%') {
            value[..percent_pos].parse().ok()
        } else {
            value.parse().ok()
        }
    }
    
    fn parse_font_weight(&self, value: &str) -> Option<u16> {
        match value {
            "normal" => Some(400),
            "bold" => Some(700),
            "lighter" => Some(300),
            "bolder" => Some(600),
            _ => value.parse().ok(),
        }
    }
    
    fn parse_display(&self, value: &str) -> Option<DisplayType> {
        match value {
            "block" => Some(DisplayType::Block),
            "inline" => Some(DisplayType::Inline),
            "inline-block" => Some(DisplayType::InlineBlock),
            "flex" => Some(DisplayType::Flex),
            "grid" => Some(DisplayType::Grid),
            "none" => Some(DisplayType::None),
            _ => None,
        }
    }
    
    fn parse_position(&self, value: &str) -> Option<PositionType> {
        match value {
            "static" => Some(PositionType::Static),
            "relative" => Some(PositionType::Relative),
            "absolute" => Some(PositionType::Absolute),
            "fixed" => Some(PositionType::Fixed),
            "sticky" => Some(PositionType::Sticky),
            _ => None,
        }
    }
    
    fn parse_box_values(&self, value: &str) -> BoxValues {
        let values: Vec<f32> = value
            .split_whitespace()
            .filter_map(|v| self.parse_length(v))
            .collect();
        
        match values.len() {
            1 => BoxValues::all(values[0]),
            2 => BoxValues::new(values[0], values[1], values[0], values[1]),
            3 => BoxValues::new(values[0], values[1], values[2], values[1]),
            4 => BoxValues::new(values[0], values[1], values[2], values[3]),
            _ => BoxValues::zero(),
        }
    }
}

/// Represents a CSS stylesheet
#[derive(Debug, Clone)]
pub struct Stylesheet {
    pub rules: Vec<CSSRule>,
    pub origin: StylesheetOrigin,
    pub media_queries: Vec<MediaQuery>,
}

impl Stylesheet {
    /// Create default user agent stylesheet
    pub fn default_user_agent() -> Self {
        let mut rules = Vec::new();
        
        // Basic HTML element styles
        rules.push(CSSRule::StyleRule(StyleRule {
            selectors: vec!["html".to_string()],
            declarations: vec![
                Declaration {
                    property: "display".to_string(),
                    value: "block".to_string(),
                    important: false,
                },
            ],
        }));
        
        rules.push(CSSRule::StyleRule(StyleRule {
            selectors: vec!["body".to_string()],
            declarations: vec![
                Declaration {
                    property: "display".to_string(),
                    value: "block".to_string(),
                    important: false,
                },
                Declaration {
                    property: "margin".to_string(),
                    value: "8px".to_string(),
                    important: false,
                },
            ],
        }));
        
        rules.push(CSSRule::StyleRule(StyleRule {
            selectors: vec!["h1".to_string()],
            declarations: vec![
                Declaration {
                    property: "display".to_string(),
                    value: "block".to_string(),
                    important: false,
                },
                Declaration {
                    property: "font-size".to_string(),
                    value: "2em".to_string(),
                    important: false,
                },
                Declaration {
                    property: "font-weight".to_string(),
                    value: "bold".to_string(),
                    important: false,
                },
                Declaration {
                    property: "margin".to_string(),
                    value: "0.67em 0".to_string(),
                    important: false,
                },
            ],
        }));
        
        Self {
            rules,
            origin: StylesheetOrigin::UserAgent,
            media_queries: Vec::new(),
        }
    }
}

/// CSS rule types
#[derive(Debug, Clone)]
pub enum CSSRule {
    StyleRule(StyleRule),
    MediaRule(MediaRule),
    ImportRule(ImportRule),
    FontFaceRule(FontFaceRule),
    KeyframesRule(KeyframesRule),
}

/// Style rule with selectors and declarations
#[derive(Debug, Clone)]
pub struct StyleRule {
    pub selectors: Vec<String>,
    pub declarations: Vec<Declaration>,
}

/// Media rule for responsive design
#[derive(Debug, Clone)]
pub struct MediaRule {
    pub media_queries: Vec<MediaQuery>,
    pub rules: Vec<CSSRule>,
}

/// Import rule for external stylesheets
#[derive(Debug, Clone)]
pub struct ImportRule {
    pub url: String,
    pub media_queries: Vec<MediaQuery>,
}

/// Font face rule for custom fonts
#[derive(Debug, Clone)]
pub struct FontFaceRule {
    pub declarations: Vec<Declaration>,
}

/// Keyframes rule for animations
#[derive(Debug, Clone)]
pub struct KeyframesRule {
    pub name: String,
    pub keyframes: Vec<Keyframe>,
}

/// Individual keyframe in animation
#[derive(Debug, Clone)]
pub struct Keyframe {
    pub selector: String, // e.g., "0%", "50%", "100%"
    pub declarations: Vec<Declaration>,
}

/// CSS declaration (property: value)
#[derive(Debug, Clone)]
pub struct Declaration {
    pub property: String,
    pub value: String,
    pub important: bool,
}

/// Media query for responsive design
#[derive(Debug, Clone)]
pub struct MediaQuery {
    pub media_type: String,
    pub conditions: Vec<MediaCondition>,
}

/// Media query condition
#[derive(Debug, Clone)]
pub struct MediaCondition {
    pub feature: String,
    pub value: Option<String>,
}

/// Stylesheet origin for cascade ordering
#[derive(Debug, Clone, PartialEq)]
pub enum StylesheetOrigin {
    UserAgent,
    User,
    Author,
}

/// Computed style for an element
#[derive(Debug, Clone)]
pub struct ComputedStyle {
    pub color: Color,
    pub background_color: Color,
    pub font_size: f32,
    pub font_family: String,
    pub font_weight: u16,
    pub display: DisplayType,
    pub position: PositionType,
    pub width: Option<f32>,
    pub height: Option<f32>,
    pub margin: BoxValues,
    pub padding: BoxValues,
    pub border_width: BoxValues,
    pub custom_properties: HashMap<String, String>,
}

impl Default for ComputedStyle {
    fn default() -> Self {
        Self {
            color: Color::black(),
            background_color: Color::transparent(),
            font_size: 16.0,
            font_family: "serif".to_string(),
            font_weight: 400,
            display: DisplayType::Block,
            position: PositionType::Static,
            width: None,
            height: None,
            margin: BoxValues::zero(),
            padding: BoxValues::zero(),
            border_width: BoxValues::zero(),
            custom_properties: HashMap::new(),
        }
    }
}

/// CSS display types
#[derive(Debug, Clone, PartialEq)]
pub enum DisplayType {
    Block,
    Inline,
    InlineBlock,
    Flex,
    Grid,
    None,
}

/// CSS position types
#[derive(Debug, Clone, PartialEq)]
pub enum PositionType {
    Static,
    Relative,
    Absolute,
    Fixed,
    Sticky,
}

/// Box model values (top, right, bottom, left)
#[derive(Debug, Clone, PartialEq)]
pub struct BoxValues {
    pub top: f32,
    pub right: f32,
    pub bottom: f32,
    pub left: f32,
}

impl BoxValues {
    pub fn new(top: f32, right: f32, bottom: f32, left: f32) -> Self {
        Self { top, right, bottom, left }
    }
    
    pub fn all(value: f32) -> Self {
        Self::new(value, value, value, value)
    }
    
    pub fn zero() -> Self {
        Self::all(0.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_css_engine_creation() {
        let engine = CSSEngine::new();
        // Basic test to ensure engine can be created
    }
    
    #[test]
    fn test_simple_css_parsing() {
        let engine = CSSEngine::new();
        let css = r#"
            body {
                color: red;
                font-size: 16px;
                margin: 10px;
            }
            
            .highlight {
                background-color: yellow;
                font-weight: bold;
            }
        "#;
        
        let stylesheet = engine.parse_stylesheet(css, StylesheetOrigin::Author).unwrap();
        assert_eq!(stylesheet.rules.len(), 2);
    }
    
    #[test]
    fn test_color_parsing() {
        let engine = CSSEngine::new();
        
        let red = engine.parse_color("red").unwrap();
        assert_eq!(red.r, 1.0);
        assert_eq!(red.g, 0.0);
        assert_eq!(red.b, 0.0);
        
        let transparent = engine.parse_color("transparent").unwrap();
        assert_eq!(transparent.a, 0.0);
    }
    
    #[test]
    fn test_length_parsing() {
        let engine = CSSEngine::new();
        
        assert_eq!(engine.parse_length("16px"), Some(16.0));
        assert_eq!(engine.parse_length("1em"), Some(16.0)); // Assuming 16px base
        assert_eq!(engine.parse_length("50%"), Some(50.0));
    }
    
    #[test]
    fn test_box_values_parsing() {
        let engine = CSSEngine::new();
        
        let single = engine.parse_box_values("10px");
        assert_eq!(single, BoxValues::all(10.0));
        
        let quad = engine.parse_box_values("10px 20px 30px 40px");
        assert_eq!(quad, BoxValues::new(10.0, 20.0, 30.0, 40.0));
    }
}