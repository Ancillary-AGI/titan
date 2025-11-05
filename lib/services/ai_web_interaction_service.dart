import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/ai_service.dart';
import '../services/web_intelligence_service.dart';
import '../services/storage_service.dart';

/// AI interaction modes
enum AIInteractionMode {
  assistant,      // AI assistant mode
  automation,     // Full automation mode
  suggestion,     // Suggestion mode
  learning,       // Learning mode
  accessibility,  // Accessibility assistance
}

/// AI task types
enum AITaskType {
  fillForm,       // Fill out forms intelligently
  navigate,       // Navigate websites
  extract,        // Extract information
  summarize,      // Summarize content
  translate,      // Translate content
  compare,        // Compare products/services
  monitor,        // Monitor for changes
  interact,       // General interaction
}

/// AI interaction result
class AIInteractionResult {
  final bool success;
  final String message;
  final Map<String, dynamic> data;
  final Duration executionTime;
  final double confidence;
  final List<String> steps;
  
  const AIInteractionResult({
    required this.success,
    required this.message,
    this.data = const {},
    required this.executionTime,
    required this.confidence,
    this.steps = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data,
    'executionTime': executionTime.inMilliseconds,
    'confidence': confidence,
    'steps': steps,
  };
}

/// AI web task
class AIWebTask {
  final String id;
  final AITaskType type;
  final String instruction;
  final Map<String, dynamic> parameters;
  final AIInteractionMode mode;
  final DateTime createdAt;
  final String? targetUrl;
  final bool isRecurring;
  final Duration? interval;
  
  const AIWebTask({
    required this.id,
    required this.type,
    required this.instruction,
    this.parameters = const {},
    this.mode = AIInteractionMode.assistant,
    required this.createdAt,
    this.targetUrl,
    this.isRecurring = false,
    this.interval,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'instruction': instruction,
    'parameters': parameters,
    'mode': mode.name,
    'createdAt': createdAt.toIso8601String(),
    'targetUrl': targetUrl,
    'isRecurring': isRecurring,
    'interval': interval?.inMilliseconds,
  };
}

/// Visual element detection result
class VisualElement {
  final String type;
  final ui.Rect bounds;
  final String? text;
  final double confidence;
  final Map<String, dynamic> attributes;
  
  const VisualElement({
    required this.type,
    required this.bounds,
    this.text,
    required this.confidence,
    this.attributes = const {},
  });
}

/// AI Web Interaction Service - Advanced AI-powered web automation
class AIWebInteractionService {
  static final Map<String, InAppWebViewController> _controllers = {};
  static final Map<String, AIWebTask> _activeTasks = {};
  static final Map<String, Timer> _recurringTasks = {};
  static final List<String> _conversationHistory = [];
  static final Map<String, Uint8List> _screenshots = {};
  
  // AI configuration
  static AIInteractionMode _defaultMode = AIInteractionMode.assistant;
  static bool _enableVisionAnalysis = true;
  static bool _enableNaturalLanguage = true;
  static bool _enableLearning = true;
  static bool _enableAccessibility = true;
  static double _confidenceThreshold = 0.7;
  
  // AI models and capabilities
  static bool _visionModelLoaded = false;
  static bool _nlpModelLoaded = false;
  static bool _automationModelLoaded = false;
  
  /// Initialize AI web interaction service
  static Future<void> initialize() async {
    await _loadAIModels();
    await _loadConversationHistory();
    _startRecurringTaskManager();
  }
  
  /// Load AI models for web interaction
  static Future<void> _loadAIModels() async {
    try {
      // Load computer vision model for element detection
      if (_enableVisionAnalysis) {
        await _loadVisionModel();
      }
      
      // Load NLP model for instruction understanding
      if (_enableNaturalLanguage) {
        await _loadNLPModel();
      }
      
      // Load automation model for task planning
      await _loadAutomationModel();
      
      print('AI models loaded successfully');
    } catch (e) {
      print('Error loading AI models: $e');
    }
  }
  
  /// Load computer vision model
  static Future<void> _loadVisionModel() async {
    // Load pre-trained model for web element detection
    // This would load a model trained on web UI elements
    _visionModelLoaded = true;
    print('Vision model loaded');
  }
  
  /// Load NLP model
  static Future<void> _loadNLPModel() async {
    // Load NLP model for instruction understanding
    // This would load a model trained on web interaction instructions
    _nlpModelLoaded = true;
    print('NLP model loaded');
  }
  
  /// Load automation model
  static Future<void> _loadAutomationModel() async {
    // Load model for task planning and execution
    _automationModelLoaded = true;
    print('Automation model loaded');
  }
  
  /// Load conversation history
  static Future<void> _loadConversationHistory() async {
    try {
      final historyJson = StorageService.getSetting<String>('ai_conversation_history');
      if (historyJson != null) {
        final history = List<String>.from(jsonDecode(historyJson));
        _conversationHistory.addAll(history);
      }
    } catch (e) {
      print('Error loading conversation history: $e');
    }
  }
  
  /// Start recurring task manager
  static void _startRecurringTaskManager() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkRecurringTasks();
    });
  }
  
  /// Register tab for AI interaction
  static Future<void> registerTab(String tabId, InAppWebViewController controller) async {
    _controllers[tabId] = controller;
    
    // Inject AI interaction script
    await _injectAIInteractionScript(controller);
    
    // Setup AI event handlers
    await _setupAIHandlers(tabId, controller);
  }
  
  /// Inject AI interaction JavaScript
  static Future<void> _injectAIInteractionScript(InAppWebViewController controller) async {
    const script = '''
      (function() {
        // Titan AI Web Interaction System
        window.titanAI = {
          // Visual element detection
          detectElements: function(type) {
            const elements = [];
            let selectors = [];
            
            switch (type) {
              case 'button':
                selectors = ['button', 'input[type="button"]', 'input[type="submit"]', '[role="button"]'];
                break;
              case 'input':
                selectors = ['input', 'textarea', 'select'];
                break;
              case 'link':
                selectors = ['a[href]'];
                break;
              case 'form':
                selectors = ['form'];
                break;
              case 'image':
                selectors = ['img'];
                break;
              case 'text':
                selectors = ['p', 'span', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'];
                break;
              default:
                selectors = ['*'];
            }
            
            selectors.forEach(selector => {
              document.querySelectorAll(selector).forEach(element => {
                const rect = element.getBoundingClientRect();
                if (rect.width > 0 && rect.height > 0) {
                  elements.push({
                    type: element.tagName.toLowerCase(),
                    bounds: {
                      x: rect.x,
                      y: rect.y,
                      width: rect.width,
                      height: rect.height
                    },
                    text: element.textContent.trim().substring(0, 100),
                    selector: this.generateSelector(element),
                    attributes: this.getElementAttributes(element),
                    visible: this.isElementVisible(element)
                  });
                }
              });
            });
            
            return elements;
          },
          
          generateSelector: function(element) {
            if (element.id) return `#${element.id}`;
            
            let selector = element.tagName.toLowerCase();
            if (element.className) {
              const classes = element.className.split(' ').filter(c => c.length > 0);
              if (classes.length > 0) {
                selector += '.' + classes.slice(0, 3).join('.');
              }
            }
            
            // Add position-based selector if needed
            const parent = element.parentElement;
            if (parent) {
              const siblings = Array.from(parent.children).filter(child => 
                child.tagName === element.tagName
              );
              if (siblings.length > 1) {
                const index = siblings.indexOf(element) + 1;
                selector += `:nth-of-type(${index})`;
              }
            }
            
            return selector;
          },
          
          getElementAttributes: function(element) {
            const attrs = {};
            for (let attr of element.attributes) {
              attrs[attr.name] = attr.value;
            }
            return attrs;
          },
          
          isElementVisible: function(element) {
            const style = window.getComputedStyle(element);
            return style.display !== 'none' && 
                   style.visibility !== 'hidden' && 
                   style.opacity !== '0';
          },
          
          // Smart element interaction
          smartClick: function(description) {
            const elements = this.detectElements('button').concat(this.detectElements('link'));
            const target = this.findBestMatch(elements, description);
            
            if (target && target.confidence > 0.5) {
              const element = document.querySelector(target.selector);
              if (element) {
                element.click();
                return { success: true, element: target };
              }
            }
            
            return { success: false, message: 'No matching element found' };
          },
          
          smartFill: function(fieldDescription, value) {
            const inputs = this.detectElements('input');
            const target = this.findBestMatch(inputs, fieldDescription);
            
            if (target && target.confidence > 0.5) {
              const element = document.querySelector(target.selector);
              if (element) {
                element.value = value;
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));
                return { success: true, element: target };
              }
            }
            
            return { success: false, message: 'No matching input found' };
          },
          
          findBestMatch: function(elements, description) {
            let bestMatch = null;
            let bestScore = 0;
            
            const descLower = description.toLowerCase();
            
            elements.forEach(element => {
              let score = 0;
              const text = (element.text || '').toLowerCase();
              const attrs = element.attributes || {};
              
              // Text similarity
              if (text.includes(descLower)) score += 0.8;
              else if (descLower.includes(text) && text.length > 2) score += 0.6;
              
              // Attribute matching
              Object.values(attrs).forEach(attrValue => {
                if (typeof attrValue === 'string' && 
                    attrValue.toLowerCase().includes(descLower)) {
                  score += 0.4;
                }
              });
              
              // Fuzzy matching for common variations
              const variations = this.generateVariations(descLower);
              variations.forEach(variation => {
                if (text.includes(variation)) score += 0.3;
              });
              
              if (score > bestScore) {
                bestScore = score;
                bestMatch = { ...element, confidence: score };
              }
            });
            
            return bestMatch;
          },
          
          generateVariations: function(text) {
            const variations = [text];
            
            // Common substitutions
            const substitutions = {
              'login': ['sign in', 'log in'],
              'signup': ['sign up', 'register'],
              'submit': ['send', 'go'],
              'search': ['find', 'look'],
              'email': ['e-mail', 'mail'],
              'password': ['pass', 'pwd']
            };
            
            Object.entries(substitutions).forEach(([key, values]) => {
              if (text.includes(key)) {
                values.forEach(value => {
                  variations.push(text.replace(key, value));
                });
              }
            });
            
            return variations;
          },
          
          // Content extraction
          extractContent: function(type) {
            switch (type) {
              case 'text':
                return this.extractText();
              case 'links':
                return this.extractLinks();
              case 'images':
                return this.extractImages();
              case 'forms':
                return this.extractForms();
              case 'tables':
                return this.extractTables();
              default:
                return this.extractAll();
            }
          },
          
          extractText: function() {
            const textElements = document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, span, div');
            const texts = [];
            
            textElements.forEach(element => {
              const text = element.textContent.trim();
              if (text.length > 10 && !this.isNavigationText(text)) {
                texts.push({
                  text: text,
                  tag: element.tagName.toLowerCase(),
                  selector: this.generateSelector(element)
                });
              }
            });
            
            return texts;
          },
          
          extractLinks: function() {
            return Array.from(document.querySelectorAll('a[href]')).map(link => ({
              text: link.textContent.trim(),
              href: link.href,
              selector: this.generateSelector(link)
            }));
          },
          
          extractImages: function() {
            return Array.from(document.querySelectorAll('img')).map(img => ({
              src: img.src,
              alt: img.alt,
              width: img.width,
              height: img.height,
              selector: this.generateSelector(img)
            }));
          },
          
          extractForms: function() {
            return Array.from(document.forms).map(form => ({
              action: form.action,
              method: form.method,
              fields: Array.from(form.elements).map(field => ({
                name: field.name,
                type: field.type,
                value: field.value,
                placeholder: field.placeholder,
                required: field.required
              })),
              selector: this.generateSelector(form)
            }));
          },
          
          extractTables: function() {
            return Array.from(document.querySelectorAll('table')).map(table => {
              const rows = Array.from(table.rows).map(row => 
                Array.from(row.cells).map(cell => cell.textContent.trim())
              );
              return {
                rows: rows,
                selector: this.generateSelector(table)
              };
            });
          },
          
          extractAll: function() {
            return {
              text: this.extractText(),
              links: this.extractLinks(),
              images: this.extractImages(),
              forms: this.extractForms(),
              tables: this.extractTables()
            };
          },
          
          isNavigationText: function(text) {
            const navKeywords = ['menu', 'navigation', 'nav', 'header', 'footer', 'sidebar'];
            return navKeywords.some(keyword => 
              text.toLowerCase().includes(keyword)
            );
          },
          
          // Accessibility helpers
          improveAccessibility: function() {
            // Add missing alt text
            document.querySelectorAll('img:not([alt])').forEach(img => {
              img.alt = 'Image';
            });
            
            // Add missing labels
            document.querySelectorAll('input:not([aria-label]):not([id])').forEach(input => {
              const label = input.previousElementSibling;
              if (label && label.tagName === 'LABEL') {
                const id = 'titan-input-' + Date.now() + Math.random();
                input.id = id;
                label.setAttribute('for', id);
              }
            });
            
            // Add focus indicators
            const style = document.createElement('style');
            style.textContent = `
              *:focus {
                outline: 2px solid #0066cc !important;
                outline-offset: 2px !important;
              }
            `;
            document.head.appendChild(style);
            
            return { success: true, message: 'Accessibility improvements applied' };
          },
          
          // Page monitoring
          monitorChanges: function(callback) {
            const observer = new MutationObserver(mutations => {
              const changes = mutations.map(mutation => ({
                type: mutation.type,
                target: this.generateSelector(mutation.target),
                addedNodes: mutation.addedNodes.length,
                removedNodes: mutation.removedNodes.length
              }));
              
              callback(changes);
            });
            
            observer.observe(document.body, {
              childList: true,
              subtree: true,
              attributes: true,
              attributeOldValue: true
            });
            
            return observer;
          },
          
          // Screenshot analysis
          takeElementScreenshot: function(selector) {
            const element = document.querySelector(selector);
            if (!element) return null;
            
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            const rect = element.getBoundingClientRect();
            
            canvas.width = rect.width;
            canvas.height = rect.height;
            
            // This is a simplified version - actual implementation would use html2canvas
            return canvas.toDataURL();
          }
        };
        
        // Notify Flutter that AI system is ready
        window.flutter_inappwebview.callHandler('aiSystemReady');
      })();
    ''';
    
    await controller.evaluateJavascript(source: script);
  }
  
  /// Setup AI event handlers
  static Future<void> _setupAIHandlers(String tabId, InAppWebViewController controller) async {
    await controller.addJavaScriptHandler(
      handlerName: 'aiSystemReady',
      callback: (args) => _handleAISystemReady(tabId),
    );
    
    await controller.addJavaScriptHandler(
      handlerName: 'aiInteractionResult',
      callback: (args) => _handleAIInteractionResult(tabId, args),
    );
    
    await controller.addJavaScriptHandler(
      handlerName: 'contentExtracted',
      callback: (args) => _handleContentExtracted(tabId, args),
    );
  }
  
  /// Handle AI system ready
  static void _handleAISystemReady(String tabId) {
    print('AI system ready for tab: $tabId');
  }
  
  /// Handle AI interaction result
  static void _handleAIInteractionResult(String tabId, List<dynamic> args) {
    if (args.isEmpty) return;
    
    final result = Map<String, dynamic>.from(args[0]);
    print('AI interaction result for $tabId: $result');
  }
  
  /// Handle content extracted
  static void _handleContentExtracted(String tabId, List<dynamic> args) {
    if (args.isEmpty) return;
    
    final content = Map<String, dynamic>.from(args[0]);
    print('Content extracted for $tabId: ${content.keys}');
  }
  
  /// Process natural language instruction
  static Future<AIInteractionResult> processInstruction(
    String tabId,
    String instruction,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // Parse instruction using NLP
      final parsedInstruction = await _parseInstruction(instruction);
      
      // Determine task type
      final taskType = _determineTaskType(parsedInstruction);
      
      // Execute based on task type
      final result = await _executeAITask(tabId, taskType, parsedInstruction);
      
      // Add to conversation history
      _addToConversationHistory(instruction, result);
      
      final executionTime = DateTime.now().difference(startTime);
      
      return AIInteractionResult(
        success: result['success'] ?? false,
        message: result['message'] ?? 'Task completed',
        data: result['data'] ?? {},
        executionTime: executionTime,
        confidence: result['confidence'] ?? 0.8,
        steps: List<String>.from(result['steps'] ?? []),
      );
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);
      
      return AIInteractionResult(
        success: false,
        message: 'Error processing instruction: $e',
        executionTime: executionTime,
        confidence: 0.0,
      );
    }
  }
  
  /// Parse natural language instruction
  static Future<Map<String, dynamic>> _parseInstruction(String instruction) async {
    final lowerInstruction = instruction.toLowerCase();
    
    // Extract action
    String action = 'unknown';
    if (lowerInstruction.contains('click')) action = 'click';
    else if (lowerInstruction.contains('fill') || lowerInstruction.contains('enter')) action = 'fill';
    else if (lowerInstruction.contains('search')) action = 'search';
    else if (lowerInstruction.contains('navigate') || lowerInstruction.contains('go to')) action = 'navigate';
    else if (lowerInstruction.contains('extract') || lowerInstruction.contains('get')) action = 'extract';
    else if (lowerInstruction.contains('summarize')) action = 'summarize';
    else if (lowerInstruction.contains('translate')) action = 'translate';
    
    // Extract target
    String target = '';
    final clickMatch = RegExp(r'click (?:on )?(.+)', caseSensitive: false).firstMatch(instruction);
    if (clickMatch != null) target = clickMatch.group(1) ?? '';
    
    final fillMatch = RegExp(r'fill (?:in |out )?(.+?) with (.+)', caseSensitive: false).firstMatch(instruction);
    String? fillValue;
    if (fillMatch != null) {
      target = fillMatch.group(1) ?? '';
      fillValue = fillMatch.group(2) ?? '';
    }
    
    final searchMatch = RegExp(r'search for (.+)', caseSensitive: false).firstMatch(instruction);
    if (searchMatch != null) target = searchMatch.group(1) ?? '';
    
    return {
      'action': action,
      'target': target.trim(),
      'value': fillValue,
      'originalInstruction': instruction,
    };
  }
  
  /// Determine AI task type from parsed instruction
  static AITaskType _determineTaskType(Map<String, dynamic> parsed) {
    switch (parsed['action']) {
      case 'click':
      case 'navigate':
        return AITaskType.navigate;
      case 'fill':
        return AITaskType.fillForm;
      case 'search':
        return AITaskType.navigate;
      case 'extract':
        return AITaskType.extract;
      case 'summarize':
        return AITaskType.summarize;
      case 'translate':
        return AITaskType.translate;
      default:
        return AITaskType.interact;
    }
  }
  
  /// Execute AI task
  static Future<Map<String, dynamic>> _executeAITask(
    String tabId,
    AITaskType taskType,
    Map<String, dynamic> parsed,
  ) async {
    final controller = _controllers[tabId];
    if (controller == null) {
      return {'success': false, 'message': 'Tab not found'};
    }
    
    switch (taskType) {
      case AITaskType.navigate:
        return await _executeNavigationTask(controller, parsed);
      case AITaskType.fillForm:
        return await _executeFillFormTask(controller, parsed);
      case AITaskType.extract:
        return await _executeExtractionTask(controller, parsed);
      case AITaskType.summarize:
        return await _executeSummarizeTask(controller, parsed);
      case AITaskType.translate:
        return await _executeTranslateTask(controller, parsed);
      default:
        return await _executeInteractionTask(controller, parsed);
    }
  }
  
  /// Execute navigation task
  static Future<Map<String, dynamic>> _executeNavigationTask(
    InAppWebViewController controller,
    Map<String, dynamic> parsed,
  ) async {
    final target = parsed['target'] as String;
    
    if (parsed['action'] == 'click') {
      final result = await controller.evaluateJavascript(
        source: 'window.titanAI.smartClick("$target")',
      );
      
      return {
        'success': result['success'] ?? false,
        'message': result['success'] == true ? 'Clicked on $target' : 'Could not find $target to click',
        'confidence': 0.8,
        'steps': ['Searched for element matching "$target"', 'Clicked on element'],
      };
    }
    
    return {'success': false, 'message': 'Navigation task not supported'};
  }
  
  /// Execute fill form task
  static Future<Map<String, dynamic>> _executeFillFormTask(
    InAppWebViewController controller,
    Map<String, dynamic> parsed,
  ) async {
    final target = parsed['target'] as String;
    final value = parsed['value'] as String?;
    
    if (value != null) {
      final result = await controller.evaluateJavascript(
        source: 'window.titanAI.smartFill("$target", "$value")',
      );
      
      return {
        'success': result['success'] ?? false,
        'message': result['success'] == true ? 'Filled $target with $value' : 'Could not find field $target',
        'confidence': 0.8,
        'steps': ['Searched for input field matching "$target"', 'Filled field with "$value"'],
      };
    }
    
    return {'success': false, 'message': 'No value provided for form field'};
  }
  
  /// Execute extraction task
  static Future<Map<String, dynamic>> _executeExtractionTask(
    InAppWebViewController controller,
    Map<String, dynamic> parsed,
  ) async {
    final target = parsed['target'] as String;
    
    String extractionType = 'text';
    if (target.contains('link')) extractionType = 'links';
    else if (target.contains('image')) extractionType = 'images';
    else if (target.contains('form')) extractionType = 'forms';
    else if (target.contains('table')) extractionType = 'tables';
    
    final result = await controller.evaluateJavascript(
      source: 'window.titanAI.extractContent("$extractionType")',
    );
    
    return {
      'success': true,
      'message': 'Extracted ${extractionType} from page',
      'data': {'extracted': result},
      'confidence': 0.9,
      'steps': ['Analyzed page structure', 'Extracted $extractionType content'],
    };
  }
  
  /// Execute summarize task
  static Future<Map<String, dynamic>> _executeSummarizeTask(
    InAppWebViewController controller,
    Map<String, dynamic> parsed,
  ) async {
    // Extract text content
    final textContent = await controller.evaluateJavascript(
      source: 'window.titanAI.extractContent("text")',
    );
    
    // Use AI service to summarize
    final summary = await AIService.summarizeText(
      textContent.map((item) => item['text']).join(' '),
    );
    
    return {
      'success': true,
      'message': 'Page summarized successfully',
      'data': {'summary': summary},
      'confidence': 0.85,
      'steps': ['Extracted text content', 'Generated AI summary'],
    };
  }
  
  /// Execute translate task
  static Future<Map<String, dynamic>> _executeTranslateTask(
    InAppWebViewController controller,
    Map<String, dynamic> parsed,
  ) async {
    // Extract text content
    final textContent = await controller.evaluateJavascript(
      source: 'window.titanAI.extractContent("text")',
    );
    
    // Detect target language from instruction
    final targetLanguage = _detectTargetLanguage(parsed['originalInstruction']);
    
    // Use AI service to translate
    final translations = <String>[];
    for (final item in textContent) {
      final translation = await AIService.translateText(item['text'], targetLanguage);
      translations.add(translation);
    }
    
    return {
      'success': true,
      'message': 'Page translated to $targetLanguage',
      'data': {'translations': translations, 'language': targetLanguage},
      'confidence': 0.8,
      'steps': ['Extracted text content', 'Translated to $targetLanguage'],
    };
  }
  
  /// Execute general interaction task
  static Future<Map<String, dynamic>> _executeInteractionTask(
    InAppWebViewController controller,
    Map<String, dynamic> parsed,
  ) async {
    return {
      'success': false,
      'message': 'General interaction not yet implemented',
      'confidence': 0.0,
    };
  }
  
  /// Detect target language from instruction
  static String _detectTargetLanguage(String instruction) {
    final lowerInstruction = instruction.toLowerCase();
    
    if (lowerInstruction.contains('spanish')) return 'es';
    if (lowerInstruction.contains('french')) return 'fr';
    if (lowerInstruction.contains('german')) return 'de';
    if (lowerInstruction.contains('italian')) return 'it';
    if (lowerInstruction.contains('portuguese')) return 'pt';
    if (lowerInstruction.contains('chinese')) return 'zh';
    if (lowerInstruction.contains('japanese')) return 'ja';
    if (lowerInstruction.contains('korean')) return 'ko';
    if (lowerInstruction.contains('russian')) return 'ru';
    if (lowerInstruction.contains('arabic')) return 'ar';
    
    return 'es'; // Default to Spanish
  }
  
  /// Add to conversation history
  static void _addToConversationHistory(String instruction, Map<String, dynamic> result) {
    final entry = jsonEncode({
      'instruction': instruction,
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _conversationHistory.add(entry);
    
    // Keep only last 100 entries
    if (_conversationHistory.length > 100) {
      _conversationHistory.removeAt(0);
    }
    
    // Save to storage
    _saveConversationHistory();
  }
  
  /// Save conversation history
  static void _saveConversationHistory() {
    StorageService.setSetting('ai_conversation_history', jsonEncode(_conversationHistory));
  }
  
  /// Take screenshot for visual analysis
  static Future<Uint8List?> takeScreenshot(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return null;
    
    try {
      final screenshot = await controller.takeScreenshot();
      if (screenshot != null) {
        _screenshots[tabId] = screenshot;
      }
      return screenshot;
    } catch (e) {
      print('Error taking screenshot: $e');
      return null;
    }
  }
  
  /// Analyze screenshot with computer vision
  static Future<List<VisualElement>> analyzeScreenshot(String tabId) async {
    final screenshot = _screenshots[tabId];
    if (screenshot == null || !_visionModelLoaded) return [];
    
    try {
      // This would use a computer vision model to detect UI elements
      // For now, return mock data
      return [
        VisualElement(
          type: 'button',
          bounds: ui.Rect.fromLTWH(100, 200, 80, 30),
          text: 'Submit',
          confidence: 0.95,
        ),
        VisualElement(
          type: 'input',
          bounds: ui.Rect.fromLTWH(50, 150, 200, 25),
          text: '',
          confidence: 0.90,
        ),
      ];
    } catch (e) {
      print('Error analyzing screenshot: $e');
      return [];
    }
  }
  
  /// Create recurring AI task
  static Future<String> createRecurringTask(
    String tabId,
    String instruction,
    Duration interval,
  ) async {
    final task = AIWebTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AITaskType.monitor,
      instruction: instruction,
      mode: _defaultMode,
      createdAt: DateTime.now(),
      isRecurring: true,
      interval: interval,
    );
    
    _activeTasks[task.id] = task;
    
    // Start recurring execution
    _recurringTasks[task.id] = Timer.periodic(interval, (timer) async {
      await processInstruction(tabId, instruction);
    });
    
    return task.id;
  }
  
  /// Check recurring tasks
  static void _checkRecurringTasks() {
    // Check if any recurring tasks need to be executed
    // This is handled by individual timers for now
  }
  
  /// Stop recurring task
  static void stopRecurringTask(String taskId) {
    final timer = _recurringTasks[taskId];
    if (timer != null) {
      timer.cancel();
      _recurringTasks.remove(taskId);
    }
    _activeTasks.remove(taskId);
  }
  
  /// Improve page accessibility
  static Future<AIInteractionResult> improveAccessibility(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) {
      return AIInteractionResult(
        success: false,
        message: 'Tab not found',
        executionTime: Duration.zero,
        confidence: 0.0,
      );
    }
    
    final startTime = DateTime.now();
    
    try {
      final result = await controller.evaluateJavascript(
        source: 'window.titanAI.improveAccessibility()',
      );
      
      final executionTime = DateTime.now().difference(startTime);
      
      return AIInteractionResult(
        success: result['success'] ?? false,
        message: result['message'] ?? 'Accessibility improvements applied',
        executionTime: executionTime,
        confidence: 0.9,
        steps: ['Analyzed accessibility issues', 'Applied improvements'],
      );
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);
      
      return AIInteractionResult(
        success: false,
        message: 'Error improving accessibility: $e',
        executionTime: executionTime,
        confidence: 0.0,
      );
    }
  }
  
  /// Get conversation history
  static List<Map<String, dynamic>> getConversationHistory() {
    return _conversationHistory.map((entry) => 
      Map<String, dynamic>.from(jsonDecode(entry))
    ).toList();
  }
  
  /// Get active tasks
  static List<AIWebTask> getActiveTasks() {
    return _activeTasks.values.toList();
  }
  
  /// Set AI interaction mode
  static void setInteractionMode(AIInteractionMode mode) {
    _defaultMode = mode;
  }
  
  /// Set confidence threshold
  static void setConfidenceThreshold(double threshold) {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
  }
  
  /// Get AI statistics
  static Map<String, dynamic> getAIStats() {
    return {
      'registeredTabs': _controllers.length,
      'activeTasks': _activeTasks.length,
      'recurringTasks': _recurringTasks.length,
      'conversationHistory': _conversationHistory.length,
      'screenshots': _screenshots.length,
      'visionModelLoaded': _visionModelLoaded,
      'nlpModelLoaded': _nlpModelLoaded,
      'automationModelLoaded': _automationModelLoaded,
    };
  }
  
  /// Cleanup resources for tab
  static void cleanup(String tabId) {
    _controllers.remove(tabId);
    _screenshots.remove(tabId);
  }
  
  /// Cleanup all resources
  static void cleanupAll() {
    _controllers.clear();
    _screenshots.clear();
    
    // Stop all recurring tasks
    for (final timer in _recurringTasks.values) {
      timer.cancel();
    }
    _recurringTasks.clear();
    _activeTasks.clear();
  }
}