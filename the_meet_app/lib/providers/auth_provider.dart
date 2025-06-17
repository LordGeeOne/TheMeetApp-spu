import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:the_meet_app/models/user_model.dart';
import 'package:the_meet_app/services/auth_service.dart';
import 'package:the_meet_app/providers/config_provider.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final ConfigProvider _configProvider;
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  StreamSubscription<User?>? _authStateSubscription;

  // Add these properties to track if user needs profile setup
  bool _needsProfileSetup = false;
  Map<String, dynamic> _profileSetupData = {};
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  
  // Get the verification status of the current user
  bool get isVerified => _user?.isVerified ?? false;
  bool get needsProfileSetup => _needsProfileSetup;
  Map<String, dynamic> get profileSetupData => _profileSetupData;

  AuthProvider(this._configProvider, {bool delayInit = false}) : 
    _authService = AuthService(_configProvider) {
    // Don't initialize in constructor if delayInit is true
    if (!delayInit) {
      // Schedule initialization on next frame to avoid blocking the UI
      Future.microtask(() => initialize());
    }
  }
  
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
    
  // This is the method expected by main.dart
  Future<void> initializeAsync() async {
    await initialize();
  }
  
  // Make initialization explicit and async
  Future<void> initialize() async {
    // Guard against multiple initializations running at once
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    
    try {
      // Initialize basic user info from current auth state
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = UserModel(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName ?? '',
          photoURL: currentUser.photoURL ?? '',
        );
      }
      
      // Listen for auth state changes using a properly managed subscription
      _authStateSubscription?.cancel(); // Cancel any existing subscription
      
      _authStateSubscription = _authService.userStream.listen((User? firebaseUser) {
        if (firebaseUser == null) {
          _user = null;
        } else {
          _user = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? '',
            photoURL: firebaseUser.photoURL ?? '',
          );
          
          // Refresh user data in a non-blocking way
          Future.microtask(() => refreshUserData());
        }
        notifyListeners();
      });
      
      // If we have a user, refresh their data immediately but don't block
      if (_user != null) {
        // Use microtask to avoid blocking the UI thread during initialization
        Future.microtask(() => refreshUserData());
      }
      
      _isInitialized = true;
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing AuthProvider: $e');
      _isInitialized = false;
      _isInitializing = false;
      // Notify listeners about the failure
      notifyListeners();
    }
  }

  // Determine user type based on email domain
  String determineUserType(String email) {
    final lowercasedEmail = email.toLowerCase();
    
    if (lowercasedEmail.endsWith('@spu.ac.za')) {
      return 'spu';
    } else if (lowercasedEmail.endsWith('@gmail.com')) {
      return 'gmail';
    } else {
      return 'other';
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithEmail(email, password);
      
      _isLoading = false;
      
      if (user != null) {
        // Check if user is verified
        final userData = await _authService.getCurrentUser();
        final isVerified = userData?.isVerified ?? false;
        
        if (!isVerified) {
          // User is not verified, navigate to pending verification screen
          throw Exception('Account not verified. Please complete verification process.');
        }
      }
      
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signUpWithEmail(email, password, name);
      
      _isLoading = false;
      notifyListeners();
      
      if (user != null) {
        // Determine user type from email
        final userType = determineUserType(email);
        
        // Navigate to profile setup screen for additional information
        navigateToProfileSetup(user.uid, email, name, userType);
      }
      
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Helper method to navigate to profile setup
  void navigateToProfileSetup(String userId, String email, String name, String userType) {
    // This will be called from login_screen.dart
    // We'll pass a BuildContext later to perform the navigation
  }

  // Update profile info for new user
  Future<bool> updateProfileForNewUser({
    required UserModel updatedUser,
    required String userType,
    required bool isVerified,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Add user type and verification status to the user model
      final userWithMetadata = updatedUser.copyWith(
        userType: userType,
        isVerified: isVerified,
      );
      
      // Update the user profile in Firestore
      final result = await _authService.updateUserProfile(userWithMetadata);
      
      if (result) {
        _user = userWithMetadata;
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Error updating profile for new user: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        // Determine user type from email
        final userType = determineUserType(user.email);
        
        // Check if this is a new user (no interests or bio)
        if (user.interests.isEmpty && (user.bio.isEmpty || user.bio == '')) {
          // This is likely a new user, handle profile setup
          _needsProfileSetup = true;
          _profileSetupData = {
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName,
            'userType': userType,
          };
        } else {
          _needsProfileSetup = false;
          
          // Existing user, check verification status for non-SPU users
          final isVerified = user.isVerified;
          
          if (!isVerified && userType != 'spu') {
            // Non-SPU user needs verification
            throw Exception('Account not verified. Please complete verification process.');
          }
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Reset profile setup state after navigation
  void clearProfileSetupState() {
    _needsProfileSetup = false;
    _profileSetupData = {};
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.signOut();
    
    _isLoading = false;
    notifyListeners();
  }

  // Get the current user with complete profile data
  Future<void> refreshUserData() async {
    if (_user == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final updatedUser = await _authService.getCurrentUser();
      if (updatedUser != null) {
        _user = updatedUser;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error refreshing user data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update the user's profile information
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    List<String>? interests,
    String? school,
    String? major,
    String? graduationYear,
  }) async {
    if (_user == null) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final updatedUser = _user!.copyWith(
        displayName: displayName,
        photoURL: photoURL,
        bio: bio,
        interests: interests,
        school: school,
        major: major,
        graduationYear: graduationYear,
      );
      
      final result = await _authService.updateUserProfile(updatedUser);
      if (result) {
        _user = updatedUser;
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Error updating profile: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Method to change the user's password
  Future<bool> changeUserPassword(String currentPassword, String newPassword) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _authService.changePassword(currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error changing password in AuthProvider: $e');
      _isLoading = false;
      notifyListeners();
      // Rethrow the exception so it can be caught in the UI
      rethrow; 
    }
  }

  // Method to delete the user's account
  Future<bool> deleteUserAccount(String password) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _authService.deleteAccount(password);
      if (success) {
        _user = null; // Clear user data on successful deletion
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error deleting account in AuthProvider: $e');
      _isLoading = false;
      notifyListeners();
      // Rethrow the exception so it can be caught in the UI
      rethrow; 
    }
  }
}