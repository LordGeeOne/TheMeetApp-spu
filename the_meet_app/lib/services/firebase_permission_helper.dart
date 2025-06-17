import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebasePermissionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Verify permissions by attempting a test write
  static Future<bool> verifyWritePermissions() async {
    // Check if user is logged in
    final user = _auth.currentUser;
    if (user == null) {
      print('Permission check failed: No user logged in');
      return false;
    }
    
    try {
      // Try to write to a test document
      final testDocRef = _firestore.collection('permission_tests').doc(user.uid);
      await testDocRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'test': 'Permission check'
      });
      
      // If we get here, write succeeded
      print('Permission check passed: Write to Firestore successful');
      
      // Clean up
      await testDocRef.delete();
      return true;
    } catch (e) {
      print('Permission check failed with error: $e');
      return false;
    }
  }
  
  // Try to fix permission issues by ensuring user is properly initialized
  static Future<bool> fixPermissions() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Cannot fix permissions: No user logged in');
      return false;
    }
    
    try {
      // Ensure user collection exists with proper document
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'lastActive': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
      
      // Verify permissions again
      return await verifyWritePermissions();
    } catch (e) {
      print('Error fixing permissions: $e');
      return false;
    }
  }
  
  // Get detailed auth and user information for debugging
  static Map<String, dynamic> getAuthDiagnostics() {
    final user = _auth.currentUser;
    
    return {
      'isLoggedIn': user != null,
      'userId': user?.uid ?? 'null',
      'email': user?.email ?? 'null',
      'isEmailVerified': user?.emailVerified ?? false,
      'providerIds': user?.providerData.map((info) => info.providerId).toList() ?? [],
      'lastSignInTime': user?.metadata.lastSignInTime?.toString() ?? 'null'
    };
  }
}