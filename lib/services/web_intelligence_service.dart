import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

/// Web page analysis types
enum PageAnalysisType {
  content,        // Text content analysis
  structure,      // DOM structure analysis
  forms,          // Form detection and analysis
  navigation,     // Navigation elements
  media,          // Images, videos, audio
  commerce,       // E-commerce elements
  social,         // Social media elements
  accessibility,  // Accessibility features
  performance,    // Performance metrics
  security,       // Security indicators
}

/// Web interaction types
enum InteractionType {
  click,          // Click elements
  type,           // Type text
  select,         // Select options
  scroll,         // Scroll page
  hover,          // Hover over elements
  drag,           // Drag and drop
  swipe,          // Swipe gestures
  pinch,          // Pinch to zoom
  navigate,       // Navigate to URL
  submit,         // Submit forms
}

/// AI task complexity levels
enum TaskComplexity {
  simple,         // Single action (click, type)
  moderate,       // Multiple actions (fill form)
  complex,        // Multi-step workflow
  advanced,       // Cross-page workflow
  expert,         // Complex business logic
}

/// Web page intelligence data
class PageIntelligence {
  final String url;
  final String title;
  final String description;
  final Map<String, dynamic> content;
  final Map<String, dynamic> structure;
  final List<FormIntelligence> forms;
  final List<NavigationElement> navigation;
  final List<MediaElement> media;
  final Map<String, dynamic> commerce;
  final Map<String, dynamic> social;
  final AccessibilityInfo accessibility;
  final SecurityInfo security;
  final DateTime analyzedAt;
  final double confidenceScore;
  
  const PageIntelligence({
    required this.url,
    required this.title,
    required this.description,
    required this.content,
    required this.structure,
    required this.forms,
    required this.navigation,
    required this.media,
    required this.commerce,
    required this.social,
    required this.accessibility,
    required this.security,
    required this.analyzedAt,
    required this.confidenceScore,
  });
  
  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'description': description,
    'content': content,
    'structure': structure,
    'forms': forms.map((f) => f.toJson()).toList(),
    'navigation': navigation.map((n) => n.toJson()).toList(),
    'media': media.map((m) => m.toJson()).toList(),
    'commerce': commerce,
    'social': social,
    'accessibility': accessibility.toJson(),
    'security': security.toJson(),
    'analyzedAt': analyzedAt.toIso8601String(),
    'confidenceScore': confidenceScore,
  };
}

/// Form intelligence data
class FormIntelligence {
  final String selector;
  final String action;
  final String method;
  final List<FormField> fields;
  final String purpose;
  final double fillConfidence;
  final Map<String, String> suggestedValues;
  
  const FormIntelligence({
    required this.selector,
    required this.action,
    required this.method,
    required this.fields,
    required this.purpose,
    required this.fillConfidence,
    required this.suggestedValues,
  });
  
  Map<String, dynamic> toJson() => {
    'selector': selector,
    'action': action,
    'method': method,
    'fields': fields.map((f) => f.toJson()).toList(),
    'purpose': purpose,
    'fillConfidence': fillConfidence,
    'suggestedValues': suggestedValues,
  };
}

/// Form field data
class FormField {
  final String name;
  final String type;
  final String selector;
  final String? label;
  final String? placeholder;
  final bool required;
  final String? pattern;
  final List<String> options;
  final String fieldType; // email, password, name, etc.
  
  const FormField({
    required this.name,
    required this.type,
    required this.selector,
    this.label,
    this.placeholder,
    this.required = false,
    this.pattern,
    this.options = const [],
    required this.fieldType,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'selector': selector,
    'label': label,
    'placeholder': placeholder,
    'required': required,
    'pattern': pattern,
    'options': options,
    'fieldType': fieldType,
  };
}

/// Navigation element data
class NavigationElement {
  final String text;
  final String href;
  final String selector;
  final String type; // link, button, menu
  final double importance;
  
  const NavigationElement({
    required this.text,
    required this.href,
    required this.selector,
    required this.type,
    required this.importance,
  });
  
  Map<String, dynamic> toJson() => {
    'text': text,
    'href': href,
    'selector': selector,
    'type': type,
    'importance': importance,
  };
}

/// Media element data
class MediaElement {
  final String type; // image, video, audio
  final String src;
  final String? alt;
  final String selector;
  final Map<String, dynamic> attributes;
  
  const MediaElement({
    required this.type,
    required this.src,
    this.alt,
    required this.selector,
    required this.attributes,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type,
    'src': src,
    'alt': alt,
    'selector': selector,
    'attributes': attributes,
  };
}

/// Accessibility information
class AccessibilityInfo {
  final bool hasAltText;
  final bool hasHeadings;
  final bool hasLabels;
  final bool hasLandmarks;
  final bool hasSkipLinks;
  final double score;
  final List<String> issues;
  
  const AccessibilityInfo({
    required this.hasAltText,
    required this.hasHeadings,
    required this.hasLabels,
    required this.hasLandmarks,
    required this.hasSkipLinks,
    required this.score,
    required this.issues,
  });
  
  Map<String, dynamic> toJson() => {
    'hasAltText': hasAltText,
    'hasHeadings': hasHeadings,
    'hasLabels': hasLabels,
    'hasLandmarks': hasLandmarks,
    'hasSkipLinks': hasSkipLinks,
    'score': score,
    'issues': issues,
  };
}

/// Security information
class SecurityInfo {
  final bool isHttps;
  final bool hasValidCertificate;
  final bool hasMixedContent;
  final bool hasSecurityHeaders;
  final double trustScore;
  final List<String> warnings;
  
  const SecurityInfo({
    required this.isHttps,
    required this.hasValidCertificate,
    required this.hasMixedContent,
    required this.hasSecurityHeaders,
    required this.trustScore,
    required this.warnings,
  });
  
  Map<String, dynamic> toJson() => {
    'isHttps': isHttps,
    'hasValidCertificate': hasValidCertificate,
    'hasMixedContent': hasMixedContent,
    'hasSecurityHeaders': hasSecurityHeaders,
    'trustScore': trustScore,
    'warnings': warnings,
  };
}

/// Web automation task
class WebAutomationTask {
  final String id;
  final String name;
  final String description;
  final List<AutomationStep> steps;
  final TaskComplexity complexity;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final bool isReusable;
  
  const WebAutomationTask({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    required this.complexity,
    required this.parameters,
    required this.createdAt,
    this.isReusable = true,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'steps': steps.map((s) => s.toJson()).toList(),
    'complexity': complexity.name,
    'parameters': parameters,
    'createdAt': createdAt.toIso8601String(),
    'isReusable': isReusable,
  };
}

/// Automation step
class AutomationStep {
  final InteractionType type;
  final String selector;
  final String? value;
  final Map<String, dynamic> options;
  final Duration delay;
  final String description;
  
  const AutomationStep({
    required this.type,
    required this.selector,
    this.value,
    this.options = const {},
    this.delay = const Duration(milliseconds: 500),
    required this.description,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'selector': selector,
    'value': value,
    'options': options,
    'delay': delay.inMilliseconds,
    'description': description,
  };
}

/// Web Intelligence Service - AI-powered web understanding and automation
class WebIntelligenceService {
  static final Map<String, PageIntelligence> _pageCache = {};
  static final Map<String, WebAutomationTask> _automationTasks = {};
  static final Map<String, InAppWebViewController> _controllers = {};
  static final List<String> _learningData = [];
  
  // AI models and configurations
  static bool _enableContentAnalysis = true;
  static bool _enableFormDetection = true;
  static bool _enableNavigationMapping = true;
  static bool _enableCommerceDetection = true;
  static bool _enableAccessibilityAnalysis = true;
  static bool _enableSecurityAnalysis = true;
  static bool _enableLearning = true;
  
  /// Initialize web intelligence service
  static Future<void> initialize() async {
    await _loadAutomationTasks();
    await _initializeAIModels();
    _startLearningEngine();
  }
  
  /// Load saved automation tasks
  static Future<void> _loadAutomationTasks() async {
    try {
      final tasksJson = StorageService.getSetting<String>('automation_tasks');
      if (tasksJson != null) {
        final tasksList = jsonDecode(tasksJson) as List;
        for (final taskData in tasksList) {
          final task = _taskFromJson(taskData);
          _automationTasks[task.id] = task;
        }
      }
    } catch (e) {
      print('Error loading automation tasks: $e');
    }
  }
  
  /// Initialize AI models for web understanding
  static Future<void> _initializeAIModels() async {
    // Initialize content analysis models
    // Initialize form detection models
    // Initialize navigation mapping models
    print('AI models initialized for web intelligence');
  }
  
  /// Start learning engine for continuous improvement
  static void _startLearningEngine() {
    if (!_enableLearning) return;
    
    Timer.periodic(Duration(minutes: 30), (timer) {
      _processLearningData();
    });
  }
  
  /// Register tab for web intelligence
  static Future<void> registerTab(String tabId, InAppWebViewController controller) async {
    _controllers[tabId] = controller;
    
    // Inject intelligence gathering script
    await _injectIntelligenceScript(controller);
    
    // Setup event handlers
    await _setupIntelligenceHandlers(tabId, controller);
  }
  
  /// Inject intelligence gathering JavaScript
  static Future<void> _injectIntelligenceScript(InAppWebViewController controller) async {
    const script = '''
      (function() {
        // Titan Web Intelligence System
        window.titanIntelligence = {
          // Page analysis functions
          analyzePage: function() {
            return {
              title: document.title,
              description: this.getMetaDescription(),
              content: this.analyzeContent(),
              structure: this.analyzeStructure(),
              forms: this.analyzeForms(),
              navigation: this.analyzeNavigation(),
              media: this.analyzeMedia(),
              commerce: this.analyzeCommerce(),
              social: this.analyzeSocial(),
              accessibility: this.analyzeAccessibility(),
              security: this.analyzeSecurity()
            };
          },
          
          getMetaDescription: function() {
            const meta = document.querySelector('meta[name="description"]');
            return meta ? meta.content : '';
          },
          
          analyzeContent: function() {
            const textContent = document.body.innerText;
            const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'))
              .map(h => ({ level: h.tagName, text: h.textContent.trim() }));
            
            const paragraphs = Array.from(document.querySelectorAll('p'))
              .map(p => p.textContent.trim())
              .filter(text => text.length > 20);
            
            return {
              wordCount: textContent.split(/\\s+/).length,
              headings: headings,
              paragraphs: paragraphs.slice(0, 10), // First 10 paragraphs
              language: document.documentElement.lang || 'en',
              readingTime: Math.ceil(textContent.split(/\\s+/).length / 200) // 200 WPM
            };
          },
          
          analyzeStructure: function() {
            return {
              totalElements: document.querySelectorAll('*').length,
              divs: document.querySelectorAll('div').length,
              spans: document.querySelectorAll('span').length,
              links: document.querySelectorAll('a').length,
              images: document.querySelectorAll('img').length,
              buttons: document.querySelectorAll('button, input[type="button"], input[type="submit"]').length,
              inputs: document.querySelectorAll('input, textarea, select').length,
              depth: this.calculateDOMDepth()
            };
          },
          
          calculateDOMDepth: function() {
            let maxDepth = 0;
            function traverse(element, depth) {
              maxDepth = Math.max(maxDepth, depth);
              for (let child of element.children) {
                traverse(child, depth + 1);
              }
            }
            traverse(document.body, 0);
            return maxDepth;
          },
          
          analyzeForms: function() {
            return Array.from(document.forms).map(form => {
              const fields = Array.from(form.elements).map(field => ({
                name: field.name,
                type: field.type,
                selector: this.generateSelector(field),
                label: this.getFieldLabel(field),
                placeholder: field.placeholder,
                required: field.required,
                pattern: field.pattern,
                options: field.type === 'select-one' ? 
                  Array.from(field.options).map(opt => opt.text) : [],
                fieldType: this.detectFieldType(field)
              }));
              
              return {
                selector: this.generateSelector(form),
                action: form.action,
                method: form.method,
                fields: fields,
                purpose: this.detectFormPurpose(form, fields)
              };
            });
          },
          
          getFieldLabel: function(field) {
            // Try to find associated label
            const label = document.querySelector(`label[for="${field.id}"]`);
            if (label) return label.textContent.trim();
            
            // Check parent label
            const parentLabel = field.closest('label');
            if (parentLabel) return parentLabel.textContent.trim();
            
            // Check previous sibling
            const prevSibling = field.previousElementSibling;
            if (prevSibling && prevSibling.tagName === 'LABEL') {
              return prevSibling.textContent.trim();
            }
            
            return null;
          },
          
          detectFieldType: function(field) {
            const name = field.name.toLowerCase();
            const placeholder = (field.placeholder || '').toLowerCase();
            const label = (this.getFieldLabel(field) || '').toLowerCase();
            
            const combined = `${name} ${placeholder} ${label}`;
            
            if (/email/.test(combined)) return 'email';
            if (/password/.test(combined)) return 'password';
            if (/phone|tel/.test(combined)) return 'phone';
            if (/name|first|last/.test(combined)) return 'name';
            if (/address/.test(combined)) return 'address';
            if (/city/.test(combined)) return 'city';
            if (/zip|postal/.test(combined)) return 'zip';
            if (/country/.test(combined)) return 'country';
            if (/state|province/.test(combined)) return 'state';
            if (/card|credit/.test(combined)) return 'credit_card';
            if (/cvv|cvc/.test(combined)) return 'cvv';
            if (/expir/.test(combined)) return 'expiry';
            if (/search/.test(combined)) return 'search';
            if (/comment|message/.test(combined)) return 'message';
            
            return 'text';
          },
          
          detectFormPurpose: function(form, fields) {
            const fieldTypes = fields.map(f => f.fieldType);
            const action = form.action.toLowerCase();
            
            if (fieldTypes.includes('email') && fieldTypes.includes('password')) {
              if (action.includes('register') || action.includes('signup')) {
                return 'registration';
              }
              return 'login';
            }
            
            if (fieldTypes.includes('credit_card')) return 'payment';
            if (fieldTypes.includes('search')) return 'search';
            if (fieldTypes.includes('message')) return 'contact';
            if (action.includes('subscribe')) return 'subscription';
            
            return 'form';
          },
          
          analyzeNavigation: function() {
            const links = Array.from(document.querySelectorAll('a[href]'));
            const buttons = Array.from(document.querySelectorAll('button, input[type="button"]'));
            
            const navigation = [...links, ...buttons].map(element => ({
              text: element.textContent.trim(),
              href: element.href || '',
              selector: this.generateSelector(element),
              type: element.tagName.toLowerCase() === 'a' ? 'link' : 'button',
              importance: this.calculateImportance(element)
            }));
            
            return navigation.filter(nav => nav.text.length > 0);
          },
          
          calculateImportance: function(element) {
            let score = 0;
            
            // Position-based scoring
            const rect = element.getBoundingClientRect();
            if (rect.top < window.innerHeight) score += 2; // Above fold
            if (rect.left < window.innerWidth / 2) score += 1; // Left side
            
            // Class/ID based scoring
            const className = element.className.toLowerCase();
            const id = element.id.toLowerCase();
            
            if (/primary|main|important/.test(className + id)) score += 3;
            if (/secondary/.test(className + id)) score += 2;
            if (/nav|menu/.test(className + id)) score += 2;
            
            // Text content scoring
            const text = element.textContent.toLowerCase();
            if (/home|main|start/.test(text)) score += 2;
            if (/login|sign/.test(text)) score += 2;
            if (/buy|purchase|order/.test(text)) score += 3;
            
            return Math.min(score, 10) / 10; // Normalize to 0-1
          },
          
          analyzeMedia: function() {
            const images = Array.from(document.querySelectorAll('img')).map(img => ({
              type: 'image',
              src: img.src,
              alt: img.alt,
              selector: this.generateSelector(img),
              attributes: {
                width: img.width,
                height: img.height,
                loading: img.loading
              }
            }));
            
            const videos = Array.from(document.querySelectorAll('video')).map(video => ({
              type: 'video',
              src: video.src,
              selector: this.generateSelector(video),
              attributes: {
                controls: video.controls,
                autoplay: video.autoplay,
                muted: video.muted
              }
            }));
            
            return [...images, ...videos];
          },
          
          analyzeCommerce: function() {
            const priceElements = document.querySelectorAll('[class*="price"], [id*="price"]');
            const cartElements = document.querySelectorAll('[class*="cart"], [id*="cart"]');
            const buyButtons = document.querySelectorAll('button, a').filter(el => 
              /buy|purchase|add.*cart|checkout/i.test(el.textContent)
            );
            
            return {
              hasPrices: priceElements.length > 0,
              hasCart: cartElements.length > 0,
              hasBuyButtons: buyButtons.length > 0,
              isEcommerce: priceElements.length > 0 && (cartElements.length > 0 || buyButtons.length > 0)
            };
          },
          
          analyzeSocial: function() {
            const socialLinks = Array.from(document.querySelectorAll('a[href]'))
              .filter(link => /facebook|twitter|instagram|linkedin|youtube|tiktok/i.test(link.href));
            
            const shareButtons = Array.from(document.querySelectorAll('button, a'))
              .filter(el => /share|tweet|post/i.test(el.textContent));
            
            return {
              socialLinks: socialLinks.length,
              shareButtons: shareButtons.length,
              hasSocialFeatures: socialLinks.length > 0 || shareButtons.length > 0
            };
          },
          
          analyzeAccessibility: function() {
            const images = document.querySelectorAll('img');
            const imagesWithAlt = document.querySelectorAll('img[alt]');
            const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
            const labels = document.querySelectorAll('label');
            const inputs = document.querySelectorAll('input, textarea, select');
            const landmarks = document.querySelectorAll('main, nav, aside, footer, header');
            const skipLinks = document.querySelectorAll('a[href^="#"]');
            
            const issues = [];
            if (images.length > imagesWithAlt.length) {
              issues.push('Images missing alt text');
            }
            if (headings.length === 0) {
              issues.push('No heading structure');
            }
            if (inputs.length > labels.length) {
              issues.push('Form inputs missing labels');
            }
            
            return {
              hasAltText: images.length === imagesWithAlt.length,
              hasHeadings: headings.length > 0,
              hasLabels: labels.length >= inputs.length,
              hasLandmarks: landmarks.length > 0,
              hasSkipLinks: skipLinks.length > 0,
              score: Math.max(0, 100 - issues.length * 20) / 100,
              issues: issues
            };
          },
          
          analyzeSecurity: function() {
            const isHttps = location.protocol === 'https:';
            const mixedContent = Array.from(document.querySelectorAll('img, script, link'))
              .some(el => el.src && el.src.startsWith('http:'));
            
            const warnings = [];
            if (!isHttps) warnings.push('Not using HTTPS');
            if (mixedContent) warnings.push('Mixed content detected');
            
            return {
              isHttps: isHttps,
              hasValidCertificate: isHttps, // Simplified
              hasMixedContent: mixedContent,
              hasSecurityHeaders: true, // Would need to check actual headers
              trustScore: isHttps && !mixedContent ? 1.0 : 0.5,
              warnings: warnings
            };
          },
          
          generateSelector: function(element) {
            if (element.id) return `#${element.id}`;
            
            let selector = element.tagName.toLowerCase();
            if (element.className) {
              const classes = element.className.split(' ').filter(c => c.length > 0);
              if (classes.length > 0) {
                selector += '.' + classes.join('.');
              }
            }
            
            // Add nth-child if needed for uniqueness
            const siblings = Array.from(element.parentNode.children)
              .filter(sibling => sibling.tagName === element.tagName);
            
            if (siblings.length > 1) {
              const index = siblings.indexOf(element) + 1;
              selector += `:nth-child(${index})`;
            }
            
            return selector;
          },
          
          // Automation functions
          clickElement: function(selector) {
            const element = document.querySelector(selector);
            if (element) {
              element.click();
              return true;
            }
            return false;
          },
          
          typeText: function(selector, text) {
            const element = document.querySelector(selector);
            if (element) {
              element.value = text;
              element.dispatchEvent(new Event('input', { bubbles: true }));
              element.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }
            return false;
          },
          
          selectOption: function(selector, value) {
            const element = document.querySelector(selector);
            if (element && element.tagName === 'SELECT') {
              element.value = value;
              element.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }
            return false;
          },
          
          scrollToElement: function(selector) {
            const element = document.querySelector(selector);
            if (element) {
              element.scrollIntoView({ behavior: 'smooth', block: 'center' });
              return true;
            }
            return false;
          },
          
          highlightElement: function(selector) {
            const element = document.querySelector(selector);
            if (element) {
              element.style.outline = '3px solid #ff6b6b';
              element.style.outlineOffset = '2px';
              setTimeout(() => {
                element.style.outline = '';
                element.style.outlineOffset = '';
              }, 3000);
              return true;
            }
            return false;
          }
        };
        
        // Auto-analyze page when ready
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', () => {
            setTimeout(() => {
              const analysis = window.titanIntelligence.analyzePage();
              window.flutter_inappwebview.callHandler('pageAnalyzed', analysis);
            }, 1000);
          });
        } else {
          setTimeout(() => {
            const analysis = window.titanIntelligence.analyzePage();
            window.flutter_inappwebview.callHandler('pageAnalyzed', analysis);
          }, 1000);
        }
      })();
    ''';
    
    await controller.evaluateJavascript(source: script);
  }
  
  /// Setup intelligence event handlers
  static Future<void> _setupIntelligenceHandlers(String tabId, InAppWebViewController controller) async {
    await controller.addJavaScriptHandler(
      handlerName: 'pageAnalyzed',
      callback: (args) => _handlePageAnalysis(tabId, args),
    );
    
    await controller.addJavaScriptHandler(
      handlerName: 'automationResult',
      callback: (args) => _handleAutomationResult(tabId, args),
    );
    
    await controller.addJavaScriptHandler(
      handlerName: 'learningData',
      callback: (args) => _handleLearningData(args),
    );
  }
  
  /// Handle page analysis results
  static Future<void> _handlePageAnalysis(String tabId, List<dynamic> args) async {
    if (args.isEmpty) return;
    
    try {
      final analysisData = Map<String, dynamic>.from(args[0]);
      final controller = _controllers[tabId];
      
      if (controller != null) {
        final url = await controller.getUrl();
        if (url != null) {
          final intelligence = await _processPageAnalysis(url.toString(), analysisData);
          _pageCache[tabId] = intelligence;
          
          // Store learning data
          if (_enableLearning) {
            _learningData.add(jsonEncode({
              'url': url.toString(),
              'analysis': analysisData,
              'timestamp': DateTime.now().toIso8601String(),
            }));
          }
        }
      }
    } catch (e) {
      print('Error handling page analysis: $e');
    }
  }
  
  /// Process page analysis data into intelligence
  static Future<PageIntelligence> _processPageAnalysis(String url, Map<String, dynamic> data) async {
    // Process forms
    final formsData = data['forms'] as List? ?? [];
    final forms = formsData.map((formData) => _processFormData(formData)).toList();
    
    // Process navigation
    final navData = data['navigation'] as List? ?? [];
    final navigation = navData.map((navItem) => NavigationElement(
      text: navItem['text'] ?? '',
      href: navItem['href'] ?? '',
      selector: navItem['selector'] ?? '',
      type: navItem['type'] ?? 'link',
      importance: (navItem['importance'] ?? 0).toDouble(),
    )).toList();
    
    // Process media
    final mediaData = data['media'] as List? ?? [];
    final media = mediaData.map((mediaItem) => MediaElement(
      type: mediaItem['type'] ?? 'image',
      src: mediaItem['src'] ?? '',
      alt: mediaItem['alt'],
      selector: mediaItem['selector'] ?? '',
      attributes: Map<String, dynamic>.from(mediaItem['attributes'] ?? {}),
    )).toList();
    
    // Process accessibility
    final accessibilityData = data['accessibility'] as Map<String, dynamic>? ?? {};
    final accessibility = AccessibilityInfo(
      hasAltText: accessibilityData['hasAltText'] ?? false,
      hasHeadings: accessibilityData['hasHeadings'] ?? false,
      hasLabels: accessibilityData['hasLabels'] ?? false,
      hasLandmarks: accessibilityData['hasLandmarks'] ?? false,
      hasSkipLinks: accessibilityData['hasSkipLinks'] ?? false,
      score: (accessibilityData['score'] ?? 0).toDouble(),
      issues: List<String>.from(accessibilityData['issues'] ?? []),
    );
    
    // Process security
    final securityData = data['security'] as Map<String, dynamic>? ?? {};
    final security = SecurityInfo(
      isHttps: securityData['isHttps'] ?? false,
      hasValidCertificate: securityData['hasValidCertificate'] ?? false,
      hasMixedContent: securityData['hasMixedContent'] ?? false,
      hasSecurityHeaders: securityData['hasSecurityHeaders'] ?? false,
      trustScore: (securityData['trustScore'] ?? 0).toDouble(),
      warnings: List<String>.from(securityData['warnings'] ?? []),
    );
    
    // Calculate confidence score
    final confidenceScore = _calculateConfidenceScore(data);
    
    return PageIntelligence(
      url: url,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: Map<String, dynamic>.from(data['content'] ?? {}),
      structure: Map<String, dynamic>.from(data['structure'] ?? {}),
      forms: forms,
      navigation: navigation,
      media: media,
      commerce: Map<String, dynamic>.from(data['commerce'] ?? {}),
      social: Map<String, dynamic>.from(data['social'] ?? {}),
      accessibility: accessibility,
      security: security,
      analyzedAt: DateTime.now(),
      confidenceScore: confidenceScore,
    );
  }
  
  /// Process form data into FormIntelligence
  static FormIntelligence _processFormData(Map<String, dynamic> formData) {
    final fieldsData = formData['fields'] as List? ?? [];
    final fields = fieldsData.map((fieldData) => FormField(
      name: fieldData['name'] ?? '',
      type: fieldData['type'] ?? 'text',
      selector: fieldData['selector'] ?? '',
      label: fieldData['label'],
      placeholder: fieldData['placeholder'],
      required: fieldData['required'] ?? false,
      pattern: fieldData['pattern'],
      options: List<String>.from(fieldData['options'] ?? []),
      fieldType: fieldData['fieldType'] ?? 'text',
    )).toList();
    
    // Generate suggested values based on field types
    final suggestedValues = <String, String>{};
    for (final field in fields) {
      final suggestion = _generateFieldSuggestion(field);
      if (suggestion != null) {
        suggestedValues[field.name] = suggestion;
      }
    }
    
    return FormIntelligence(
      selector: formData['selector'] ?? '',
      action: formData['action'] ?? '',
      method: formData['method'] ?? 'GET',
      fields: fields,
      purpose: formData['purpose'] ?? 'form',
      fillConfidence: _calculateFillConfidence(fields),
      suggestedValues: suggestedValues,
    );
  }
  
  /// Generate field suggestion based on type
  static String? _generateFieldSuggestion(FormField field) {
    // This would integrate with user's stored data or AI suggestions
    switch (field.fieldType) {
      case 'email':
        return 'user@example.com'; // Would use actual user email
      case 'name':
        return 'John Doe'; // Would use actual user name
      case 'phone':
        return '+1234567890'; // Would use actual user phone
      case 'search':
        return ''; // No default for search
      default:
        return null;
    }
  }
  
  /// Calculate form fill confidence
  static double _calculateFillConfidence(List<FormField> fields) {
    if (fields.isEmpty) return 0.0;
    
    int recognizedFields = 0;
    for (final field in fields) {
      if (field.fieldType != 'text') {
        recognizedFields++;
      }
    }
    
    return recognizedFields / fields.length;
  }
  
  /// Calculate overall confidence score
  static double _calculateConfidenceScore(Map<String, dynamic> data) {
    double score = 0.0;
    int factors = 0;
    
    // Content analysis confidence
    final content = data['content'] as Map<String, dynamic>? ?? {};
    if (content['wordCount'] != null && content['wordCount'] > 100) {
      score += 0.2;
    }
    factors++;
    
    // Structure analysis confidence
    final structure = data['structure'] as Map<String, dynamic>? ?? {};
    if (structure['totalElements'] != null && structure['totalElements'] > 50) {
      score += 0.2;
    }
    factors++;
    
    // Forms analysis confidence
    final forms = data['forms'] as List? ?? [];
    if (forms.isNotEmpty) {
      score += 0.2;
    }
    factors++;
    
    // Navigation analysis confidence
    final navigation = data['navigation'] as List? ?? [];
    if (navigation.isNotEmpty) {
      score += 0.2;
    }
    factors++;
    
    // Security analysis confidence
    final security = data['security'] as Map<String, dynamic>? ?? {};
    if (security['isHttps'] == true) {
      score += 0.2;
    }
    factors++;
    
    return factors > 0 ? score : 0.0;
  }
  
  /// Handle automation results
  static void _handleAutomationResult(String tabId, List<dynamic> args) {
    if (args.isEmpty) return;
    
    final result = Map<String, dynamic>.from(args[0]);
    print('Automation result for $tabId: $result');
  }
  
  /// Handle learning data
  static void _handleLearningData(List<dynamic> args) {
    if (args.isEmpty || !_enableLearning) return;
    
    final data = Map<String, dynamic>.from(args[0]);
    _learningData.add(jsonEncode({
      'type': 'interaction',
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
  
  /// Process learning data for AI improvement
  static void _processLearningData() {
    if (_learningData.isEmpty) return;
    
    // Process learning data to improve AI models
    // This would involve training or fine-tuning models
    print('Processing ${_learningData.length} learning data points');
    
    // Clear processed data
    _learningData.clear();
  }
  
  /// Create automation task from natural language
  static Future<WebAutomationTask?> createAutomationTask(
    String tabId,
    String description,
  ) async {
    final intelligence = _pageCache[tabId];
    if (intelligence == null) return null;
    
    try {
      // Use AI to convert natural language to automation steps
      final steps = await _generateAutomationSteps(description, intelligence);
      
      final task = WebAutomationTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _generateTaskName(description),
        description: description,
        steps: steps,
        complexity: _determineComplexity(steps),
        parameters: {},
        createdAt: DateTime.now(),
      );
      
      _automationTasks[task.id] = task;
      await _saveAutomationTasks();
      
      return task;
    } catch (e) {
      print('Error creating automation task: $e');
      return null;
    }
  }
  
  /// Generate automation steps from description and page intelligence
  static Future<List<AutomationStep>> _generateAutomationSteps(
    String description,
    PageIntelligence intelligence,
  ) async {
    final steps = <AutomationStep>[];
    
    // Simple pattern matching for common tasks
    final lowerDesc = description.toLowerCase();
    
    if (lowerDesc.contains('fill') && lowerDesc.contains('form')) {
      // Fill form task
      for (final form in intelligence.forms) {
        for (final field in form.fields) {
          final suggestion = form.suggestedValues[field.name];
          if (suggestion != null) {
            steps.add(AutomationStep(
              type: InteractionType.type,
              selector: field.selector,
              value: suggestion,
              description: 'Fill ${field.label ?? field.name} field',
            ));
          }
        }
      }
    } else if (lowerDesc.contains('click')) {
      // Click task
      final clickTarget = _findClickTarget(lowerDesc, intelligence);
      if (clickTarget != null) {
        steps.add(AutomationStep(
          type: InteractionType.click,
          selector: clickTarget.selector,
          description: 'Click ${clickTarget.text}',
        ));
      }
    } else if (lowerDesc.contains('search')) {
      // Search task
      final searchForm = intelligence.forms.firstWhere(
        (form) => form.purpose == 'search',
        orElse: () => intelligence.forms.first,
      );
      
      if (searchForm.fields.isNotEmpty) {
        final searchField = searchForm.fields.first;
        steps.add(AutomationStep(
          type: InteractionType.type,
          selector: searchField.selector,
          value: _extractSearchQuery(description),
          description: 'Enter search query',
        ));
        
        steps.add(AutomationStep(
          type: InteractionType.submit,
          selector: searchForm.selector,
          description: 'Submit search',
        ));
      }
    }
    
    return steps;
  }
  
  /// Find click target from description
  static NavigationElement? _findClickTarget(String description, PageIntelligence intelligence) {
    for (final nav in intelligence.navigation) {
      if (description.contains(nav.text.toLowerCase())) {
        return nav;
      }
    }
    return null;
  }
  
  /// Extract search query from description
  static String _extractSearchQuery(String description) {
    final match = RegExp(r'search for (.+)', caseSensitive: false).firstMatch(description);
    return match?.group(1) ?? '';
  }
  
  /// Generate task name from description
  static String _generateTaskName(String description) {
    if (description.length <= 50) return description;
    return '${description.substring(0, 47)}...';
  }
  
  /// Determine task complexity
  static TaskComplexity _determineComplexity(List<AutomationStep> steps) {
    if (steps.length == 1) return TaskComplexity.simple;
    if (steps.length <= 3) return TaskComplexity.moderate;
    if (steps.length <= 6) return TaskComplexity.complex;
    if (steps.length <= 10) return TaskComplexity.advanced;
    return TaskComplexity.expert;
  }
  
  /// Execute automation task
  static Future<bool> executeAutomationTask(String tabId, String taskId) async {
    final task = _automationTasks[taskId];
    final controller = _controllers[tabId];
    
    if (task == null || controller == null) return false;
    
    try {
      for (final step in task.steps) {
        await _executeAutomationStep(controller, step);
        await Future.delayed(step.delay);
      }
      return true;
    } catch (e) {
      print('Error executing automation task: $e');
      return false;
    }
  }
  
  /// Execute single automation step
  static Future<void> _executeAutomationStep(
    InAppWebViewController controller,
    AutomationStep step,
  ) async {
    switch (step.type) {
      case InteractionType.click:
        await controller.evaluateJavascript(
          source: 'window.titanIntelligence.clickElement("${step.selector}")',
        );
        break;
      case InteractionType.type:
        await controller.evaluateJavascript(
          source: 'window.titanIntelligence.typeText("${step.selector}", "${step.value}")',
        );
        break;
      case InteractionType.select:
        await controller.evaluateJavascript(
          source: 'window.titanIntelligence.selectOption("${step.selector}", "${step.value}")',
        );
        break;
      case InteractionType.scroll:
        await controller.evaluateJavascript(
          source: 'window.titanIntelligence.scrollToElement("${step.selector}")',
        );
        break;
      case InteractionType.submit:
        await controller.evaluateJavascript(
          source: 'document.querySelector("${step.selector}").submit()',
        );
        break;
      default:
        print('Unsupported automation step type: ${step.type}');
    }
  }
  
  /// Save automation tasks
  static Future<void> _saveAutomationTasks() async {
    final tasksList = _automationTasks.values.map((task) => task.toJson()).toList();
    await StorageService.setSetting('automation_tasks', jsonEncode(tasksList));
  }
  
  /// Create task from JSON
  static WebAutomationTask _taskFromJson(Map<String, dynamic> json) {
    final stepsData = json['steps'] as List? ?? [];
    final steps = stepsData.map((stepData) => AutomationStep(
      type: InteractionType.values.firstWhere(
        (type) => type.name == stepData['type'],
        orElse: () => InteractionType.click,
      ),
      selector: stepData['selector'] ?? '',
      value: stepData['value'],
      options: Map<String, dynamic>.from(stepData['options'] ?? {}),
      delay: Duration(milliseconds: stepData['delay'] ?? 500),
      description: stepData['description'] ?? '',
    )).toList();
    
    return WebAutomationTask(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      steps: steps,
      complexity: TaskComplexity.values.firstWhere(
        (complexity) => complexity.name == json['complexity'],
        orElse: () => TaskComplexity.simple,
      ),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isReusable: json['isReusable'] ?? true,
    );
  }
  
  /// Get page intelligence for tab
  static PageIntelligence? getPageIntelligence(String tabId) {
    return _pageCache[tabId];
  }
  
  /// Get all automation tasks
  static List<WebAutomationTask> getAutomationTasks() {
    return _automationTasks.values.toList();
  }
  
  /// Delete automation task
  static Future<void> deleteAutomationTask(String taskId) async {
    _automationTasks.remove(taskId);
    await _saveAutomationTasks();
  }
  
  /// Get intelligence statistics
  static Map<String, dynamic> getIntelligenceStats() {
    return {
      'cachedPages': _pageCache.length,
      'automationTasks': _automationTasks.length,
      'learningDataPoints': _learningData.length,
      'registeredTabs': _controllers.length,
    };
  }
  
  /// Cleanup resources for tab
  static void cleanup(String tabId) {
    _controllers.remove(tabId);
    _pageCache.remove(tabId);
  }
  
  /// Cleanup all resources
  static void cleanupAll() {
    _controllers.clear();
    _pageCache.clear();
    _learningData.clear();
  }
}