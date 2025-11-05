//! Layout engine using Taffy for modern CSS layout algorithms

use std::collections::HashMap;
use taffy::{
    Taffy, Node, Style, Dimension, LengthPercentage, LengthPercentageAuto,
    Display, Position, FlexDirection, FlexWrap, AlignItems, AlignContent,
    JustifyContent, Size, Rect as TaffyRect, Point as TaffyPoint,
};
use crate::core::{ElementId, Result, EngineError, Rect, Point, Size as CoreSize};
use crate::html::{Document, Element};
use crate::css::{ComputedStyle, DisplayType, PositionType, BoxValues};

/// Layout engine for computing element positions and sizes
pub struct LayoutEngine {
    /// Taffy layout engine instance
    taffy: Taffy,
    
    /// Mapping from element IDs to Taffy nodes
    element_to_node: HashMap<ElementId, Node>,
    
    /// Mapping from Taffy nodes to element IDs
    node_to_element: HashMap<Node, ElementId>,
    
    /// Computed layout results
    layout_cache: HashMap<ElementId, LayoutBox>,
}

impl LayoutEngine {
    pub fn new() -> Self {
        Self {
            taffy: Taffy::new(),
            element_to_node: HashMap::new(),
            node_to_element: HashMap::new(),
            layout_cache: HashMap::new(),
        }
    }
    
    /// Compute layout for the entire document
    pub async fn compute_layout(
        &mut self,
        document: &Document,
        stylesheets: &[std::sync::Arc<crate::css::Stylesheet>],
    ) -> Result<LayoutTree> {
        // Clear previous layout
        self.clear_layout();
        
        // Create layout tree from DOM
        let root_node = self.create_layout_tree(document, stylesheets).await?;
        
        // Compute layout with available space
        let available_space = Size::new(1920.0, 1080.0); // Default viewport size
        self.taffy.compute_layout(
            root_node,
            taffy::Size {
                width: taffy::AvailableSpace::Definite(available_space.width),
                height: taffy::AvailableSpace::Definite(available_space.height),
            },
        ).map_err(|e| EngineError::RenderingError(format!("Layout computation failed: {:?}", e)))?;
        
        // Extract layout results
        let layout_tree = self.extract_layout_tree(root_node, document)?;
        
        Ok(layout_tree)
    }
    
    /// Create Taffy layout tree from DOM
    async fn create_layout_tree(
        &mut self,
        document: &Document,
        stylesheets: &[std::sync::Arc<crate::css::Stylesheet>],
    ) -> Result<Node> {
        // Start with the root element (html)
        let root_element = &document.root;
        self.create_layout_node(root_element, document, stylesheets).await
    }
    
    /// Create a layout node for an element and its children
    async fn create_layout_node(
        &mut self,
        element: &Element,
        document: &Document,
        stylesheets: &[std::sync::Arc<crate::css::Stylesheet>],
    ) -> Result<Node> {
        // Compute style for this element
        let css_engine = crate::css::CSSEngine::new();
        let computed_style = css_engine.compute_style(element, stylesheets);
        
        // Convert CSS style to Taffy style
        let taffy_style = self.css_to_taffy_style(&computed_style);
        
        // Create child nodes
        let mut child_nodes = Vec::new();
        for child_id in &element.children {
            if let Some(child_element) = document.elements.get(child_id) {
                let child_node = self.create_layout_node(child_element, document, stylesheets).await?;
                child_nodes.push(child_node);
            }
        }
        
        // Create Taffy node
        let node = self.taffy.new_with_children(taffy_style, &child_nodes)
            .map_err(|e| EngineError::RenderingError(format!("Failed to create layout node: {:?}", e)))?;
        
        // Store mappings
        self.element_to_node.insert(element.id, node);
        self.node_to_element.insert(node, element.id);
        
        Ok(node)
    }
    
    /// Convert CSS computed style to Taffy style
    fn css_to_taffy_style(&self, computed_style: &ComputedStyle) -> Style {
        let mut style = Style::default();
        
        // Display type
        style.display = match computed_style.display {
            DisplayType::Block => Display::Block,
            DisplayType::Flex => Display::Flex,
            DisplayType::Grid => Display::Grid,
            DisplayType::None => Display::None,
            DisplayType::Inline | DisplayType::InlineBlock => Display::Block, // Simplified
        };
        
        // Position type
        style.position = match computed_style.position {
            PositionType::Static => Position::Static,
            PositionType::Relative => Position::Relative,
            PositionType::Absolute => Position::Absolute,
            PositionType::Fixed => Position::Absolute, // Treat fixed as absolute for now
            PositionType::Sticky => Position::Relative, // Treat sticky as relative for now
        };
        
        // Size
        if let Some(width) = computed_style.width {
            style.size.width = Dimension::Length(width);
        }
        if let Some(height) = computed_style.height {
            style.size.height = Dimension::Length(height);
        }
        
        // Margin
        style.margin = self.box_values_to_taffy_rect(&computed_style.margin);
        
        // Padding
        style.padding = self.box_values_to_taffy_rect(&computed_style.padding);
        
        // Border
        style.border = self.box_values_to_taffy_rect(&computed_style.border_width);
        
        // Flex properties (if display is flex)
        if matches!(computed_style.display, DisplayType::Flex) {
            style.flex_direction = FlexDirection::Row; // Default
            style.flex_wrap = FlexWrap::NoWrap; // Default
            style.align_items = Some(AlignItems::Stretch); // Default
            style.justify_content = Some(JustifyContent::FlexStart); // Default
        }
        
        style
    }
    
    /// Convert BoxValues to Taffy Rect
    fn box_values_to_taffy_rect(&self, box_values: &BoxValues) -> TaffyRect<LengthPercentageAuto> {
        TaffyRect {
            left: LengthPercentageAuto::Length(box_values.left),
            right: LengthPercentageAuto::Length(box_values.right),
            top: LengthPercentageAuto::Length(box_values.top),
            bottom: LengthPercentageAuto::Length(box_values.bottom),
        }
    }
    
    /// Extract layout results into our layout tree structure
    fn extract_layout_tree(&mut self, root_node: Node, document: &Document) -> Result<LayoutTree> {
        let mut layout_boxes = HashMap::new();
        
        self.extract_layout_recursive(root_node, &mut layout_boxes)?;
        
        let root_element_id = self.node_to_element[&root_node];
        
        Ok(LayoutTree {
            root_element_id,
            layout_boxes,
        })
    }
    
    /// Recursively extract layout information
    fn extract_layout_recursive(
        &mut self,
        node: Node,
        layout_boxes: &mut HashMap<ElementId, LayoutBox>,
    ) -> Result<()> {
        let element_id = self.node_to_element[&node];
        
        // Get layout from Taffy
        let layout = self.taffy.layout(node)
            .map_err(|e| EngineError::RenderingError(format!("Failed to get layout: {:?}", e)))?;
        
        // Convert to our layout box format
        let layout_box = LayoutBox {
            element_id,
            content_rect: Rect::new(
                layout.location.x,
                layout.location.y,
                layout.size.width,
                layout.size.height,
            ),
            padding_rect: Rect::new(
                layout.location.x - layout.padding.left,
                layout.location.y - layout.padding.top,
                layout.size.width + layout.padding.left + layout.padding.right,
                layout.size.height + layout.padding.top + layout.padding.bottom,
            ),
            border_rect: Rect::new(
                layout.location.x - layout.padding.left - layout.border.left,
                layout.location.y - layout.padding.top - layout.border.top,
                layout.size.width + layout.padding.left + layout.padding.right + layout.border.left + layout.border.right,
                layout.size.height + layout.padding.top + layout.padding.bottom + layout.border.top + layout.border.bottom,
            ),
            margin_rect: Rect::new(
                layout.location.x - layout.padding.left - layout.border.left - layout.margin.left,
                layout.location.y - layout.padding.top - layout.border.top - layout.margin.top,
                layout.size.width + layout.padding.left + layout.padding.right + layout.border.left + layout.border.right + layout.margin.left + layout.margin.right,
                layout.size.height + layout.padding.top + layout.padding.bottom + layout.border.top + layout.border.bottom + layout.margin.top + layout.margin.bottom,
            ),
            baseline: layout.location.y + layout.size.height, // Simplified baseline calculation
        };
        
        layout_boxes.insert(element_id, layout_box);
        self.layout_cache.insert(element_id, layout_box.clone());
        
        // Process children
        let children = self.taffy.children(node)
            .map_err(|e| EngineError::RenderingError(format!("Failed to get children: {:?}", e)))?;
        
        for child_node in children {
            self.extract_layout_recursive(child_node, layout_boxes)?;
        }
        
        Ok(())
    }
    
    /// Clear all layout data
    fn clear_layout(&mut self) {
        self.taffy.clear();
        self.element_to_node.clear();
        self.node_to_element.clear();
        self.layout_cache.clear();
    }
    
    /// Get layout box for an element
    pub fn get_layout_box(&self, element_id: ElementId) -> Option<&LayoutBox> {
        self.layout_cache.get(&element_id)
    }
    
    /// Update layout for a specific element (for dynamic changes)
    pub async fn update_element_layout(
        &mut self,
        element_id: ElementId,
        new_style: &ComputedStyle,
    ) -> Result<()> {
        if let Some(&node) = self.element_to_node.get(&element_id) {
            let taffy_style = self.css_to_taffy_style(new_style);
            self.taffy.set_style(node, taffy_style)
                .map_err(|e| EngineError::RenderingError(format!("Failed to update style: {:?}", e)))?;
            
            // Recompute layout for this subtree
            let available_space = Size::new(1920.0, 1080.0); // Should get from viewport
            self.taffy.compute_layout(
                node,
                taffy::Size {
                    width: taffy::AvailableSpace::Definite(available_space.width),
                    height: taffy::AvailableSpace::Definite(available_space.height),
                },
            ).map_err(|e| EngineError::RenderingError(format!("Layout recomputation failed: {:?}", e)))?;
            
            // Update cache
            self.update_layout_cache(node)?;
        }
        
        Ok(())
    }
    
    /// Update layout cache after recomputation
    fn update_layout_cache(&mut self, node: Node) -> Result<()> {
        let element_id = self.node_to_element[&node];
        
        let layout = self.taffy.layout(node)
            .map_err(|e| EngineError::RenderingError(format!("Failed to get layout: {:?}", e)))?;
        
        let layout_box = LayoutBox {
            element_id,
            content_rect: Rect::new(
                layout.location.x,
                layout.location.y,
                layout.size.width,
                layout.size.height,
            ),
            padding_rect: Rect::new(
                layout.location.x - layout.padding.left,
                layout.location.y - layout.padding.top,
                layout.size.width + layout.padding.left + layout.padding.right,
                layout.size.height + layout.padding.top + layout.padding.bottom,
            ),
            border_rect: Rect::new(
                layout.location.x - layout.padding.left - layout.border.left,
                layout.location.y - layout.padding.top - layout.border.top,
                layout.size.width + layout.padding.left + layout.padding.right + layout.border.left + layout.border.right,
                layout.size.height + layout.padding.top + layout.padding.bottom + layout.border.top + layout.border.bottom,
            ),
            margin_rect: Rect::new(
                layout.location.x - layout.padding.left - layout.border.left - layout.margin.left,
                layout.location.y - layout.padding.top - layout.border.top - layout.margin.top,
                layout.size.width + layout.padding.left + layout.padding.right + layout.border.left + layout.border.right + layout.margin.left + layout.margin.right,
                layout.size.height + layout.padding.top + layout.padding.bottom + layout.border.top + layout.border.bottom + layout.margin.top + layout.margin.bottom,
            ),
            baseline: layout.location.y + layout.size.height,
        };
        
        self.layout_cache.insert(element_id, layout_box);
        
        // Update children
        let children = self.taffy.children(node)
            .map_err(|e| EngineError::RenderingError(format!("Failed to get children: {:?}", e)))?;
        
        for child_node in children {
            self.update_layout_cache(child_node)?;
        }
        
        Ok(())
    }
    
    /// Perform hit testing to find element at point
    pub fn hit_test(&self, point: Point) -> Option<ElementId> {
        // Find the topmost element that contains the point
        let mut hit_element = None;
        let mut highest_z_index = i32::MIN;
        
        for (element_id, layout_box) in &self.layout_cache {
            if layout_box.border_rect.contains_point(point) {
                // For now, just return the first hit
                // In a real implementation, we'd consider z-index, stacking context, etc.
                hit_element = Some(*element_id);
                break;
            }
        }
        
        hit_element
    }
}

/// Complete layout tree for a document
#[derive(Debug, Clone)]
pub struct LayoutTree {
    pub root_element_id: ElementId,
    pub layout_boxes: HashMap<ElementId, LayoutBox>,
}

impl LayoutTree {
    /// Get layout box for an element
    pub fn get_layout_box(&self, element_id: ElementId) -> Option<&LayoutBox> {
        self.layout_boxes.get(&element_id)
    }
    
    /// Get all layout boxes
    pub fn get_all_layout_boxes(&self) -> &HashMap<ElementId, LayoutBox> {
        &self.layout_boxes
    }
    
    /// Find element at point
    pub fn element_at_point(&self, point: Point) -> Option<ElementId> {
        // Find the topmost element that contains the point
        for (element_id, layout_box) in &self.layout_boxes {
            if layout_box.border_rect.contains_point(point) {
                return Some(*element_id);
            }
        }
        None
    }
}

/// Layout information for a single element
#[derive(Debug, Clone)]
pub struct LayoutBox {
    pub element_id: ElementId,
    
    /// Content area (inside padding)
    pub content_rect: Rect,
    
    /// Padding area (inside border)
    pub padding_rect: Rect,
    
    /// Border area (inside margin)
    pub border_rect: Rect,
    
    /// Margin area (full element bounds)
    pub margin_rect: Rect,
    
    /// Baseline for text alignment
    pub baseline: f32,
}

impl LayoutBox {
    /// Get the visible bounds of the element
    pub fn visible_rect(&self) -> Rect {
        self.border_rect
    }
    
    /// Check if this layout box intersects with another
    pub fn intersects(&self, other: &LayoutBox) -> bool {
        let r1 = &self.border_rect;
        let r2 = &other.border_rect;
        
        !(r1.origin.x + r1.size.width < r2.origin.x
            || r2.origin.x + r2.size.width < r1.origin.x
            || r1.origin.y + r1.size.height < r2.origin.y
            || r2.origin.y + r2.size.height < r1.origin.y)
    }
    
    /// Get the center point of the element
    pub fn center(&self) -> Point {
        Point::new(
            self.border_rect.origin.x + self.border_rect.size.width / 2.0,
            self.border_rect.origin.y + self.border_rect.size.height / 2.0,
        )
    }
}

/// Layout constraints for responsive design
#[derive(Debug, Clone)]
pub struct LayoutConstraints {
    pub min_width: Option<f32>,
    pub max_width: Option<f32>,
    pub min_height: Option<f32>,
    pub max_height: Option<f32>,
    pub aspect_ratio: Option<f32>,
}

impl Default for LayoutConstraints {
    fn default() -> Self {
        Self {
            min_width: None,
            max_width: None,
            min_height: None,
            max_height: None,
            aspect_ratio: None,
        }
    }
}

/// Layout performance metrics
#[derive(Debug, Clone, Default)]
pub struct LayoutMetrics {
    pub layout_time_ms: u64,
    pub elements_laid_out: u32,
    pub layout_invalidations: u32,
    pub cache_hits: u32,
    pub cache_misses: u32,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::html::Document;
    use crate::css::{ComputedStyle, DisplayType};
    
    #[test]
    fn test_layout_engine_creation() {
        let engine = LayoutEngine::new();
        // Basic test to ensure engine can be created
    }
    
    #[test]
    fn test_css_to_taffy_style_conversion() {
        let engine = LayoutEngine::new();
        let mut computed_style = ComputedStyle::default();
        computed_style.display = DisplayType::Flex;
        computed_style.width = Some(100.0);
        computed_style.height = Some(200.0);
        
        let taffy_style = engine.css_to_taffy_style(&computed_style);
        
        assert_eq!(taffy_style.display, Display::Flex);
        assert_eq!(taffy_style.size.width, Dimension::Length(100.0));
        assert_eq!(taffy_style.size.height, Dimension::Length(200.0));
    }
    
    #[test]
    fn test_layout_box_operations() {
        let layout_box = LayoutBox {
            element_id: ElementId::new(),
            content_rect: Rect::new(10.0, 10.0, 100.0, 50.0),
            padding_rect: Rect::new(5.0, 5.0, 110.0, 60.0),
            border_rect: Rect::new(0.0, 0.0, 120.0, 70.0),
            margin_rect: Rect::new(-10.0, -10.0, 140.0, 90.0),
            baseline: 60.0,
        };
        
        let center = layout_box.center();
        assert_eq!(center.x, 60.0); // 0 + 120/2
        assert_eq!(center.y, 35.0); // 0 + 70/2
        
        let visible = layout_box.visible_rect();
        assert_eq!(visible, layout_box.border_rect);
    }
    
    #[test]
    fn test_hit_testing() {
        let mut engine = LayoutEngine::new();
        let element_id = ElementId::new();
        
        let layout_box = LayoutBox {
            element_id,
            content_rect: Rect::new(10.0, 10.0, 100.0, 50.0),
            padding_rect: Rect::new(5.0, 5.0, 110.0, 60.0),
            border_rect: Rect::new(0.0, 0.0, 120.0, 70.0),
            margin_rect: Rect::new(-10.0, -10.0, 140.0, 90.0),
            baseline: 60.0,
        };
        
        engine.layout_cache.insert(element_id, layout_box);
        
        // Point inside element
        let hit = engine.hit_test(Point::new(50.0, 30.0));
        assert_eq!(hit, Some(element_id));
        
        // Point outside element
        let miss = engine.hit_test(Point::new(200.0, 200.0));
        assert_eq!(miss, None);
    }
}