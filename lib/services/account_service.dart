import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';
import '../services/storage_service.dart';

class AccountService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static User? _currentUser;
  
  static Future<void> init() async {
    _currentUser = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _syncUserData();
      }
    });
  }
  
  static User? get currentUser => _currentUser;
  static bool get isSignedIn => _currentUser != null;
  
  // Email/Password Authentication
  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _createUserProfile(credential.user!);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _syncUserData();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Google Sign In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserProfile(userCredential.user!);
      }
      
      await _syncUserData();
      return userCredential;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }
  
  // Anonymous Sign In
  static Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      await _createUserProfile(credential.user!);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Sign Out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _currentUser = null;
  }
  
  // Password Reset
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Update Profile
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_currentUser == null) throw Exception('No user signed in');
    
    await _currentUser!.updateDisplayName(displayName);
    await _currentUser!.updatePhotoURL(photoURL);
    
    await _updateUserProfile({
      'displayName': displayName,
      'photoURL': photoURL,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  
  // Delete Account
  static Future<void> deleteAccount() async {
    if (_currentUser == null) throw Exception('No user signed in');
    
    await _deleteUserData();
    await _currentUser!.delete();
    _currentUser = null;
  }
  
  // User Profile Management
  static Future<void> _createUserProfile(User user) async {
    final profile = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? 'User',
      'photoURL': user.photoURL,
      'createdAt': DateTime.now().toIso8601String(),
      'lastSignIn': DateTime.now().toIso8601String(),
      'preferences': {
        'theme': 'system',
        'searchEngine': 'google',
        'homePage': 'https://www.google.com',
        'aiAssistantEnabled': true,
      },
      'syncSettings': {
        'bookmarks': true,
        'history': true,
        'passwords': false,
        'extensions': true,
      },
    };
    
    await StorageService.setSetting('user_profile', jsonEncode(profile));
  }
  
  static Future<void> _updateUserProfile(Map<String, dynamic> updates) async {
    final currentProfile = await getUserProfile();
    if (currentProfile != null) {
      final updatedProfile = {...currentProfile, ...updates};
      await StorageService.setSetting('user_profile', jsonEncode(updatedProfile));
    }
  }
  
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final profileJson = StorageService.getSetting<String>('user_profile');
    if (profileJson != null) {
      return jsonDecode(profileJson);
    }
    return null;
  }
  
  static Future<void> _syncUserData() async {
    if (_currentUser == null) return;
    
    final profile = await getUserProfile();
    if (profile != null && profile['syncSettings'] != null) {
      final syncSettings = profile['syncSettings'];
      
      // Sync based on user preferences
      if (syncSettings['bookmarks'] == true) {
        await _syncBookmarks();
      }
      
      if (syncSettings['history'] == true) {
        await _syncHistory();
      }
      
      if (syncSettings['extensions'] == true) {
        await _syncExtensions();
      }
    }
  }
  
  static Future<void> _syncBookmarks() async {
    // Implementation for syncing bookmarks to cloud
    print('Syncing bookmarks...');
  }
  
  static Future<void> _syncHistory() async {
    // Implementation for syncing history to cloud
    print('Syncing history...');
  }
  
  static Future<void> _syncExtensions() async {
    // Implementation for syncing extensions to cloud
    print('Syncing extensions...');
  }
  
  static Future<void> _deleteUserData() async {
    // Delete all user data from local storage
    await StorageService.setSetting('user_profile', null);
    // Additional cleanup as needed
  }
  
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
  
  // Import/Export functionality
  static Future<Map<String, dynamic>> exportUserData() async {
    final profile = await getUserProfile();
    final bookmarks = StorageService.getBookmarks();
    final history = StorageService.getHistory();
    
    return {
      'profile': profile,
      'bookmarks': bookmarks,
      'history': history,
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }
  
  static Future<void> importUserData(Map<String, dynamic> data) async {
    try {
      // Import profile
      if (data['profile'] != null) {
        await StorageService.setSetting('user_profile', jsonEncode(data['profile']));
      }
      
      // Import bookmarks
      if (data['bookmarks'] != null) {
        final bookmarks = List<Map<String, dynamic>>.from(data['bookmarks']);
        for (final bookmark in bookmarks) {
          await StorageService.addBookmark(
            bookmark['url'],
            bookmark['title'],
            folder: bookmark['folder'],
          );
        }
      }
      
      // Import history
      if (data['history'] != null) {
        final history = List<Map<String, dynamic>>.from(data['history']);
        for (final item in history) {
          await StorageService.addToHistory(item['url'], item['title']);
        }
      }
    } catch (e) {
      throw Exception('Failed to import user data: $e');
    }
  }
}