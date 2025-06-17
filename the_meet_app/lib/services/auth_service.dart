import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_meet_app/models/user_model.dart';
import 'package:the_meet_app/providers/config_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigProvider _configProvider;
  
  AuthService(this._configProvider);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Convert Firebase User to our UserModel
  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) return null;
    
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoURL: user.photoURL ?? '',
    );
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = userCredential.user;
      
      if (user != null) {
        // Get complete user data from Firestore
        final userData = await getCurrentUser();
        
        // Check if the user is verified if they're not an SPU user
        if (userData != null) {
          final userType = userData.userType;
          final isVerified = userData.isVerified;
          
          if (!isVerified && userType != 'spu') {
            throw Exception('Account not verified. Please complete verification process.');
          }
        }
        
        return userData;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('Email sign-in failed: ${e.code} - ${e.message}');
      throw Exception(_getReadableAuthError(e.code));
    } catch (e) {
      print('Unexpected error during email sign-in: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = userCredential.user;
      
      if (user != null) {
        // Update the user's display name
        await user.updateDisplayName(name);
        
        // Create basic user model with the display name
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: name,
          photoURL: user.photoURL ?? '',
          // We'll update the rest in the ProfileSetupScreen
        );
        
        // Store basic user data in Firestore
        await _saveUserToFirestore(user, customDisplayName: name);
        
        return userModel;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('Email sign-up failed: ${e.code} - ${e.message}');
      throw Exception(_getReadableAuthError(e.code));
    } catch (e) {
      print('Unexpected error during email sign-up: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Get more user-friendly error messages
  String _getReadableAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Invalid password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Get current user as UserModel - needed for the messages screen
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    try {
      // Try to get additional user data from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(userData, user.uid);
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
    }
    
    // Fall back to basic user data if Firestore fetch fails
    return _userFromFirebaseUser(user);
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Determine if this is a new user by checking if they exist in Firestore
        bool isNewUser = false;
        
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          isNewUser = !doc.exists;
        } catch (e) {
          print('Error checking if user exists: $e');
          isNewUser = true; // Assume new user if there's an error checking
        }
        
        // For all users, save basic info to Firestore
        try {
          await _saveUserToFirestore(user);
        } catch (e) {
          print('Warning: Could not save user data to Firestore: $e');
          // Continue anyway since we have authenticated successfully
        }
        
        // Get complete user data
        final userData = await getCurrentUser();
        
        // If not a new user, check verification status for non-SPU users
        if (!isNewUser && userData != null) {
          final userType = userData.userType;
          final isVerified = userData.isVerified;
          
          if (!isVerified && userType != 'spu') {
            throw Exception('Account not verified. Please complete verification process.');
          }
        }
        
        return userData;
      }
      
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow; // Allow the caller to handle the error
    }
  }

  // Save user data to Firestore with optional custom display name
  Future<void> _saveUserToFirestore(User user, {String? customDisplayName}) async {
    try {
      // Check if the user already exists in Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // User already exists, just update login time if needed
        await docRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // New user - determine user type based on email domain
        String userType = 'other';
        bool isVerified = false;
        
        final email = user.email?.toLowerCase() ?? '';
        if (email.endsWith('@spu.ac.za')) {
          userType = 'spu';
          isVerified = true; // Auto-verify SPU users
        } else if (email.endsWith('@gmail.com')) {
          userType = 'gmail';
          isVerified = false; // Gmail users need verification
        }
        
        // Create basic user data
        final userData = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: customDisplayName ?? user.displayName ?? '',
          photoURL: user.photoURL ?? '',
          userType: userType,
          isVerified: isVerified,
          joinDate: DateTime.now(),
        ).toMap();

        // Store in Firestore
        await docRef.set(userData);
      }
    } catch (e) {
      print('Firestore write error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // First, check if the userId matches the current authenticated user
      final currentAuthUser = _auth.currentUser;
      if (currentAuthUser != null && currentAuthUser.uid == userId) {
        return await getCurrentUser(); // Use getCurrentUser to get full profile data
      }
      
      // If not current user, fetch from Firestore
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(userData, userId);
      }
      
      return null;
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != updatedUser.uid) {
        return false; // Can't update if not authenticated or not the same user
      }

      await _firestore.collection('users').doc(updatedUser.uid).set(
        updatedUser.toMap(), 
        SetOptions(merge: true)
      );
      
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
  
  // Update user verification status
  Future<bool> updateUserVerificationStatus(String userId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
      });
      return true;
    } catch (e) {
      print('Error updating verification status: $e');
      return false;
    }
  }

  // Change user password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Error changing password: ${e.code} - ${e.message}');
      // Consider throwing a more specific exception or returning a custom error object
      throw Exception(_getReadableAuthError(e.code)); 
    } catch (e) {
      print('Unexpected error changing password: $e');
      throw Exception('An unexpected error occurred while changing password.');
    }
  }

  // Delete user account
  Future<bool> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore (optional, implement as needed)
      // await _firestore.collection(\'users\').doc(user.uid).delete();

      // Delete user account
      await user.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Error deleting account: ${e.code} - ${e.message}');
      throw Exception(_getReadableAuthError(e.code));
    } catch (e) {
      print('Unexpected error deleting account: $e');
      throw Exception('An unexpected error occurred while deleting account.');
    }
  }
}
