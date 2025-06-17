import 'package:flutter/foundation.dart';
import 'package:the_meet_app/models/user_model.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoaded = false;
  List<Meet> _createdMeets = [];
  List<Meet> _participatingMeets = [];
  bool _isInitializing = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  List<Meet> get createdMeets => _createdMeets;
  List<Meet> get participatingMeets => _participatingMeets;

  // Initialize the provider when explicitly called, not automatically
  Future<void> initialize() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await loadUserData(currentUser.uid);
    }
  }

  // Load user data from Firestore
  Future<void> loadUserData(String userId) async {
    // Guard against concurrent loading operations
    if (_isLoading || _isInitializing) return;
    
    _isInitializing = true;
    _isLoading = true;
    // Notify on next frame to avoid blocking UI
    Future.microtask(() => notifyListeners());
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(userData, userId);
        _isLoaded = true;
      } else {
        print('No user found with ID: $userId');
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
      
      // Preload user meets in the background after user data is loaded
      // This avoids blocking the UI thread
      if (_currentUser != null) {
        Future.microtask(() => loadUserMeets());
      }
    }
  }

  // Load user's created and participating meets
  Future<void> loadUserMeets() async {
    if (_currentUser == null || _isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load created meets
      final createdMeetsQuery = await FirebaseFirestore.instance
          .collection('meets')
          .where('creatorId', isEqualTo: _currentUser!.uid)
          .get();
      
      _createdMeets = createdMeetsQuery.docs
          .map((doc) => Meet.fromFirestore(doc))
          .toList();
      
      // Load participating meets
      final participatingMeetsQuery = await FirebaseFirestore.instance
          .collection('meets')
          .where('participantIds', arrayContains: _currentUser!.uid)
          .get();
      
      _participatingMeets = participatingMeetsQuery.docs
          .where((doc) => doc['creatorId'] != _currentUser!.uid) // Exclude created meets
          .map((doc) => Meet.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading user meets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user data in memory and Firestore
  Future<bool> updateUserData(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.uid)
          .set(updatedUser.toMap(), SetOptions(merge: true));
      
      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Clear user data on logout
  void clearUserData() {
    _currentUser = null;
    _createdMeets = [];
    _participatingMeets = [];
    _isLoaded = false;
    notifyListeners();
  }
}