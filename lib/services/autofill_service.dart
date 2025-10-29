import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/storage_service.dart';
import '../services/account_service.dart';

enum AutofillType {
  address,
  creditCard,
  password,
  personalInfo,
  custom,
}

class AutofillData {
  final String id;
  final AutofillType type;
  final Map<String, String> fields;
  final String label;
  final DateTime createdAt;
  final DateTime lastUsed;
  final int useCount;
  final bool isEncrypted;
  
  AutofillData({
    required this.id,
    required this.type,
    required this.fields,
    required this.label,
    DateTime? createdAt,
    DateTime? lastUsed,
    this.useCount = 0,
    this.isEncrypted = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastUsed = lastUsed ?? DateTime.now();
  
  AutofillData copyWith({
    AutofillType? type,
    Map<String, String>? fields,
    String? label,
    DateTime? lastUsed,
    int? useCount,
    bool? isEncrypted,
  }) {
    return AutofillData(
      id: id,
      type: type ?? this.type,
      fields: fields ?? this.fields,
      label: label ?? this.label,
      createdAt: createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      useCount: useCount ?? this.useCount,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'fields': fields,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'useCount': useCount,
      'isEncrypted': isEncrypted,
    };
  }
  
  factory AutofillData.fromJson(Map<String, dynamic> json) {
    return AutofillData(
      id: json['id'],
      type: AutofillType.values.firstWhere((e) => e.name == json['type']),
      fields: Map<String, String>.from(json['fields']),
      label: json['label'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: DateTime.parse(json['lastUsed']),
      useCount: json['useCount'] ?? 0,
      isEncrypted: json['isEncrypted'] ?? false,
    );
  }
}

class AutofillService {
  static final Map<String, List<AutofillData>> _autofillData = {};
  static final Map<String, String> _encryptionKeys = {};
  static bool _isEnabled = true;
  static bool _savePasswords = true;
  static bool _saveAddresses = true;
  static bool _saveCreditCards = false;
  
  static Future<void> init() async {
    await _loadSettings();
    await _loadAutofillData();
  }
  
  static Future<void> _loadSettings() async {
    _isEnabled = StorageService.getSetting<bool>('autofill_enabled') ?? true;
    _savePasswords = StorageService.getSetting<bool>('autofill_save_passwords') ?? true;
    _saveAddresses = StorageService.getSetting<bool>('autofill_save_addresses') ?? true;
    _saveCreditCards = StorageService.getSetting<bool>('autofill_save_credit_cards') ?? false;
  }
  
  static Future<void> _loadAutofillData() async {
    final data = StorageService.getSetting<String>('autofill_data');
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(data);
        for (final entry in decoded.entries) {
          final List<dynamic> items = entry.value;
          _autofillData[entry.key] = items
              .map((item) => AutofillData.fromJson(item))
              .toList();
        }
      } catch (e) {
        print('Failed to load autofill data: $e');
      }
    }
  }
  
  static Future<void> _saveAutofillData() async {
    final Map<String, dynamic> data = {};
    for (final entry in _autofillData.entries) {
      data[entry.key] = entry.value.map((item) => item.toJson()).toList();
    }
    await StorageService.setSetting('autofill_data', jsonEncode(data));
  }
  
  // Settings Management
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await StorageService.setSetting('autofill_enabled', enabled);
  }
  
  static Future<void> setSavePasswords(bool save) async {
    _savePasswords = save;
    await StorageService.setSetting('autofill_save_passwords', save);
  }
  
  static Future<void> setSaveAddresses(bool save) async {
    _saveAddresses = save;
    await StorageService.setSetting('autofill_save_addresses', save);
  }
  
  static Future<void> setSaveCreditCards(bool save) async {
    _saveCreditCards = save;
    await StorageService.setSetting('autofill_save_credit_cards', save);
  }
  
  static bool get isEnabled => _isEnabled;
  static bool get savePasswords => _savePasswords;
  static bool get saveAddresses => _saveAddresses;
  static bool get saveCreditCards => _saveCreditCards;
  
  // Data Management
  static Future<void> saveAutofillData(AutofillData data) async {
    if (!_isEnabled) return;
    
    final userId = AccountService.currentUser?.uid ?? 'anonymous';
    
    if (!_autofillData.containsKey(userId)) {
      _autofillData[userId] = [];
    }
    
    // Check if similar data already exists
    final existingIndex = _autofillData[userId]!.indexWhere(
      (existing) => existing.type == data.type && _isSimilarData(existing, data),
    );
    
    if (existingIndex != -1) {
      // Update existing data
      _autofillData[userId]![existingIndex] = data.copyWith(
        lastUsed: DateTime.now(),
        useCount: _autofillData[userId]![existingIndex].useCount + 1,
      );
    } else {
      // Add new data
      _autofillData[userId]!.add(data);
    }
    
    await _saveAutofillData();
  }
  
  static bool _isSimilarData(AutofillData existing, AutofillData newData) {
    switch (newData.type) {
      case AutofillType.password:
        return existing.fields['username'] == newData.fields['username'] &&
               existing.fields['domain'] == newData.fields['domain'];
      case AutofillType.address:
        return existing.fields['street'] == newData.fields['street'] &&
               existing.fields['city'] == newData.fields['city'];
      case AutofillType.creditCard:
        return existing.fields['number'] == newData.fields['number'];
      case AutofillType.personalInfo:
        return existing.fields['email'] == newData.fields['email'];
      default:
        return false;
    }
  }
  
  static List<AutofillData> getAutofillSuggestions(AutofillType type, {String? domain}) {
    if (!_isEnabled) return [];
    
    final userId = AccountService.currentUser?.uid ?? 'anonymous';
    final userAutofillData = _autofillData[userId] ?? [];
    
    var suggestions = userAutofillData.where((data) => data.type == type).toList();
    
    // Filter by domain for passwords
    if (type == AutofillType.password && domain != null) {
      suggestions = suggestions.where((data) => 
          data.fields['domain'] == domain ||
          _isDomainMatch(data.fields['domain'] ?? '', domain)
      ).toList();
    }
    
    // Sort by usage frequency and recency
    suggestions.sort((a, b) {
      final aScore = a.useCount * 0.7 + 
          (DateTime.now().difference(a.lastUsed).inDays * -0.3);
      final bScore = b.useCount * 0.7 + 
          (DateTime.now().difference(b.lastUsed).inDays * -0.3);
      return bScore.compareTo(aScore);
    });
    
    return suggestions.take(5).toList();
  }
  
  static bool _isDomainMatch(String storedDomain, String currentDomain) {
    // Extract base domain for matching
    final storedBase = _extractBaseDomain(storedDomain);
    final currentBase = _extractBaseDomain(currentDomain);
    return storedBase == currentBase;
  }
  
  static String _extractBaseDomain(String domain) {
    final parts = domain.split('.');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
    }
    return domain;
  }
  
  static Future<void> deleteAutofillData(String id) async {
    final userId = AccountService.currentUser?.uid ?? 'anonymous';
    if (_autofillData.containsKey(userId)) {
      _autofillData[userId]!.removeWhere((data) => data.id == id);
      await _saveAutofillData();
    }
  }
  
  static Future<void> clearAllAutofillData() async {
    final userId = AccountService.currentUser?.uid ?? 'anonymous';
    _autofillData[userId] = [];
    await _saveAutofillData();
  }
  
  // Form Detection and Filling
  static Map<String, dynamic> detectFormFields(String html) {
    final formFields = <String, dynamic>{};
    
    // Detect password fields
    if (html.contains('type="password"') || html.contains('name="password"')) {
      formFields['hasPassword'] = true;
      formFields['type'] = AutofillType.password;
    }
    
    // Detect address fields
    if (html.contains('address') || html.contains('street') || html.contains('city')) {
      formFields['hasAddress'] = true;
      formFields['type'] = AutofillType.address;
    }
    
    // Detect credit card fields
    if (html.contains('card') || html.contains('credit') || html.contains('cvv')) {
      formFields['hasCreditCard'] = true;
      formFields['type'] = AutofillType.creditCard;
    }
    
    // Detect personal info fields
    if (html.contains('email') || html.contains('phone') || html.contains('name')) {
      formFields['hasPersonalInfo'] = true;
      formFields['type'] = AutofillType.personalInfo;
    }
    
    return formFields;
  }
  
  static String generateFillScript(AutofillData data) {
    final script = StringBuffer();
    
    for (final entry in data.fields.entries) {
      final field = entry.key;
      final value = entry.value;
      
      script.writeln('''
        // Fill field: $field
        var elements = document.querySelectorAll('input[name="$field"], input[id="$field"], input[placeholder*="$field"]');
        for (var i = 0; i < elements.length; i++) {
          elements[i].value = '$value';
          elements[i].dispatchEvent(new Event('input', { bubbles: true }));
          elements[i].dispatchEvent(new Event('change', { bubbles: true }));
        }
      ''');
    }
    
    return script.toString();
  }
  
  // Password Generation
  static String generateSecurePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeSimilar = true,
  }) {
    String chars = '';
    
    if (includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (includeNumbers) chars += '0123456789';
    if (includeSymbols) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    if (excludeSimilar) {
      chars = chars.replaceAll(RegExp(r'[0O1lI]'), '');
    }
    
    final random = DateTime.now().millisecondsSinceEpoch;
    String password = '';
    
    for (int i = 0; i < length; i++) {
      final index = (random + i) % chars.length;
      password += chars[index];
    }
    
    return password;
  }
  
  static int calculatePasswordStrength(String password) {
    int score = 0;
    
    // Length
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;
    
    // Character types
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 1;
    
    // Patterns
    if (!password.contains(RegExp(r'(.)\1{2,}'))) score += 1; // No repeated chars
    if (!password.contains(RegExp(r'(012|123|234|345|456|567|678|789|890)'))) score += 1; // No sequences
    
    return (score / 9 * 100).round();
  }
  
  // Encryption for sensitive data
  static String _encryptData(String data, String key) {
    // Simple encryption - in production, use proper encryption
    final bytes = utf8.encode(data + key);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }
  
  static String _decryptData(String encryptedData, String key) {
    // Simple decryption - in production, use proper decryption
    return encryptedData; // Placeholder
  }
  
  // Breach Detection
  static Future<bool> checkPasswordBreach(String password) async {
    try {
      // Implementation would check against Have I Been Pwned API
      // Using SHA-1 hash prefix to maintain privacy
      final bytes = utf8.encode(password);
      final digest = sha1.convert(bytes);
      final hash = digest.toString().toUpperCase();
      final prefix = hash.substring(0, 5);
      
      // In real implementation, make API call to check breach
      return false; // Placeholder
    } catch (e) {
      return false;
    }
  }
}