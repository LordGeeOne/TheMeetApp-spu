import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/config_provider.dart';
import 'package:the_meet_app/services/service_locator.dart';

class MeetProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigProvider _configProvider;
  
  MeetProvider({required ConfigProvider configProvider}) : _configProvider = configProvider;
  
  List<Meet> _upcomingMeets = [];
  List<Meet> _nearbyMeets = [];
  List<Meet> _allMeets = [];
  bool _isLoading = false;
  
  // Map to track meet availability notifications
  final Map<String, List<String>> _notificationRequests = {};
  
  // Getters
  List<Meet> get upcomingMeets => _upcomingMeets;
  List<Meet> get nearbyMeets => _nearbyMeets;
  List<Meet> get allMeets => _allMeets;
  bool get isLoading => _isLoading;
  
  // Get all meets, both upcoming and past
  Future<void> refreshMeets() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get all meets from the database
      final List<Meet> fetchedMeets = await meetService.getMeets();
      
      if (fetchedMeets.isEmpty) {
        _allMeets = [];
        _upcomingMeets = [];
        _nearbyMeets = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Process all meets
      _allMeets = fetchedMeets;
      
      // Filter upcoming meets (today and future)
      final now = DateTime.now();
      _upcomingMeets = _allMeets
          .where((meet) => meet.time.isAfter(now))
          .toList();
      
      // Sort upcoming meets by date (soonest first)
      _upcomingMeets.sort((a, b) => a.time.compareTo(b.time));
      
      // Get nearby meets (within 10 miles)
      _nearbyMeets = _upcomingMeets.toList();
      
      // Check if any meets that were previously full now have space
      _checkForAvailableSpots();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Check if any meets that users were waiting for now have available spots
  void _checkForAvailableSpots() {
    for (final meetId in _notificationRequests.keys) {
      final meet = _upcomingMeets.firstWhere(
        (m) => m.id == meetId,
        orElse: () => _nearbyMeets.firstWhere(
          (m) => m.id == meetId,
          orElse: () => Meet(
            id: '',
            title: '',
            description: '',
            location: '',
            latitude: 0,
            longitude: 0,
            time: DateTime.now(),
            type: '',
            maxParticipants: 0,
            creatorId: '',
            participantIds: [],
            imageUrl: '',
          ),
        ),
      );
      
      // If the meet exists and is no longer full
      if (meet.id.isNotEmpty && meet.participantIds.length < meet.maxParticipants) {
        // This meet now has space
        final usersToNotify = _notificationRequests[meetId]!;
        
        // Send notifications to users
        _sendNotificationsForAvailableMeet(meet, usersToNotify);
        
        // Remove this meet from notification requests
        _notificationRequests.remove(meetId);
      }
    }
  }
  
  // Send notifications to users when a meet has available spots
  Future<void> _sendNotificationsForAvailableMeet(Meet meet, List<String> userIds) async {
    // In a real app, this would send actual notifications using Firebase Cloud Messaging
    // For now, we'll just print to the console and store in Firestore
    print('Sending notifications to ${userIds.length} users about available spots in meet: ${meet.title}');
    
    try {
      // Add notification to each user's notifications collection
      for (final userId in userIds) {
        await _firestore.collection('users').doc(userId).collection('notifications').add({
          'type': 'meet_available',
          'meetId': meet.id,
          'meetTitle': meet.title,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'message': 'A spot has opened up in ${meet.title}!',
        });
      }
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }
  
  // Register a user for notifications when a meet has available spots
  Future<bool> registerForAvailabilityNotification(String meetId, String userId) async {
    try {
      // Add to local tracking
      if (!_notificationRequests.containsKey(meetId)) {
        _notificationRequests[meetId] = [];
      }
      _notificationRequests[meetId]!.add(userId);
      
      // Add to Firestore for persistence
      await _firestore.collection('meets').doc(meetId).update({
        'notificationRequests': FieldValue.arrayUnion([userId]),
      });
      
      return true;
    } catch (e) {
      print('Error registering for notification: $e');
      return false;
    }
  }
  
  // Unregister a user from notifications
  Future<bool> unregisterFromAvailabilityNotification(String meetId, String userId) async {
    try {
      // Remove from local tracking
      if (_notificationRequests.containsKey(meetId)) {
        _notificationRequests[meetId]!.remove(userId);
        if (_notificationRequests[meetId]!.isEmpty) {
          _notificationRequests.remove(meetId);
        }
      }
      
      // Remove from Firestore
      await _firestore.collection('meets').doc(meetId).update({
        'notificationRequests': FieldValue.arrayRemove([userId]),
      });
      
      return true;
    } catch (e) {
      print('Error unregistering from notification: $e');
      return false;
    }
  }
  
  // Fetch a single meet by ID
  Future<Meet?> fetchMeetById(String meetId) async {
    try {
      final doc = await _firestore.collection('meets').doc(meetId).get();
      
      if (doc.exists) {
        return Meet.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching meet by ID: $e');
      return null;
    }
  }
  
  // Create a new meet
  Future<String?> createMeet(Meet meet) async {
    try {
      // Initialize with empty arrays for left users and notification requests
      final meetMap = meet.toMap();
      meetMap['leftUsers'] = [];
      meetMap['notificationRequests'] = [];
      
      final docRef = await _firestore.collection('meets').add(meetMap);
      
      // Create chat collection for this meet
      await _firestore.collection('meetChats').doc(docRef.id).set({
        'createdAt': FieldValue.serverTimestamp(),
        'meetId': docRef.id,
      });
      
      // Add the new meet to local lists
      final newMeet = meet.copyWith(id: docRef.id);
      
      if (meet.time.isAfter(DateTime.now())) {
        _upcomingMeets.add(newMeet);
        _upcomingMeets.sort((a, b) => a.time.compareTo(b.time));
      }
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error creating meet: $e');
      return null;
    }
  }
  
  // Update an existing meet
  Future<bool> updateMeet(Meet meet) async {
    try {
      await _firestore.collection('meets').doc(meet.id).update(meet.toMap());
      
      // Update local lists
      final upcomingIndex = _upcomingMeets.indexWhere((m) => m.id == meet.id);
      if (upcomingIndex >= 0) {
        _upcomingMeets[upcomingIndex] = meet;
        _upcomingMeets.sort((a, b) => a.time.compareTo(b.time));
      }
      
      final nearbyIndex = _nearbyMeets.indexWhere((m) => m.id == meet.id);
      if (nearbyIndex >= 0) {
        _nearbyMeets[nearbyIndex] = meet;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating meet: $e');
      return false;
    }
  }
  
  // Update the chatId for a meet
  Future<bool> updateMeetChatId(String meetId, String chatId) async {
    try {
      // Update the meet document in Firestore with the chat ID
      await _firestore.collection('meets').doc(meetId).update({
        'chatId': chatId,
      });
      
      // Update local lists
      final upcomingIndex = _upcomingMeets.indexWhere((m) => m.id == meetId);
      if (upcomingIndex >= 0) {
        _upcomingMeets[upcomingIndex] = _upcomingMeets[upcomingIndex].copyWith(
          chatId: chatId,
        );
      }
      
      final nearbyIndex = _nearbyMeets.indexWhere((m) => m.id == meetId);
      if (nearbyIndex >= 0) {
        _nearbyMeets[nearbyIndex] = _nearbyMeets[nearbyIndex].copyWith(
          chatId: chatId,
        );
      }
      
      final allIndex = _allMeets.indexWhere((m) => m.id == meetId);
      if (allIndex >= 0) {
        _allMeets[allIndex] = _allMeets[allIndex].copyWith(
          chatId: chatId,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating meet chatId: $e');
      return false;
    }
  }
  
  // Delete a meet
  Future<bool> deleteMeet(String meetId) async {
    try {
      // Delete meet document
      await _firestore.collection('meets').doc(meetId).delete();
      
      // Delete meet chat collection
      await _firestore.collection('meetChats').doc(meetId).delete();
      
      // Delete meet chat messages
      final chatMessages = await _firestore
          .collection('meetChats')
          .doc(meetId)
          .collection('messages')
          .get();
      
      final batch = _firestore.batch();
      for (final doc in chatMessages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Update local lists
      _upcomingMeets.removeWhere((meet) => meet.id == meetId);
      _nearbyMeets.removeWhere((meet) => meet.id == meetId);
      notifyListeners();
      
      return true;
    } catch (e) {
      print('Error deleting meet: $e');
      return false;
    }
  }
  
  // Join a meet
  Future<bool> joinMeet(String meetId, String userId) async {
    try {
      // First check if user was in the leftUsers array and remove them
      await _firestore.collection('meets').doc(meetId).update({
        'leftUsers': FieldValue.arrayRemove([userId]),
        'participantIds': FieldValue.arrayUnion([userId]),
      });
      
      // Update local lists
      final upcomingIndex = _upcomingMeets.indexWhere((m) => m.id == meetId);
      if (upcomingIndex >= 0) {
        final updatedMeet = _upcomingMeets[upcomingIndex].copyWith(
          participantIds: [..._upcomingMeets[upcomingIndex].participantIds, userId],
        );
        _upcomingMeets[upcomingIndex] = updatedMeet;
      }
      
      final nearbyIndex = _nearbyMeets.indexWhere((m) => m.id == meetId);
      if (nearbyIndex >= 0) {
        final updatedMeet = _nearbyMeets[nearbyIndex].copyWith(
          participantIds: [..._nearbyMeets[nearbyIndex].participantIds, userId],
        );
        _nearbyMeets[nearbyIndex] = updatedMeet;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error joining meet: $e');
      return false;
    }
  }
  
  // Add user to left field
  Future<bool> addUserToLeftField(String meetId, String userId) async {
    try {
      // Add user to leftUsers array
      await _firestore.collection('meets').doc(meetId).update({
        'leftUsers': FieldValue.arrayUnion([userId]),
      });
      
      return true;
    } catch (e) {
      print('Error adding user to leftUsers: $e');
      return false;
    }
  }
  
  // Leave a meet
  Future<bool> leaveMeet(String meetId, String userId) async {
    try {
      // Get the current meet to check if the user is the creator
      final meetDoc = await _firestore.collection('meets').doc(meetId).get();
      if (!meetDoc.exists) return false;
      
      final meetData = meetDoc.data()!;
      if (meetData['creatorId'] == userId) {
        // If the user is the creator, delete the meet
        return await deleteMeet(meetId);
      } else {
        // If not the creator, just remove from participants
        await _firestore.collection('meets').doc(meetId).update({
          'participantIds': FieldValue.arrayRemove([userId]),
        });
        
        // Update local lists
        final upcomingIndex = _upcomingMeets.indexWhere((m) => m.id == meetId);
        if (upcomingIndex >= 0) {
          final updatedParticipants = _upcomingMeets[upcomingIndex].participantIds
              .where((id) => id != userId)
              .toList();
          final updatedMeet = _upcomingMeets[upcomingIndex].copyWith(
            participantIds: updatedParticipants,
          );
          _upcomingMeets[upcomingIndex] = updatedMeet;
          
          // Check if this meet was previously full and now has space
          if (updatedMeet.participantIds.length == updatedMeet.maxParticipants - 1) {
            _checkForAvailableSpots();
          }
        }
        
        final nearbyIndex = _nearbyMeets.indexWhere((m) => m.id == meetId);
        if (nearbyIndex >= 0) {
          final updatedParticipants = _nearbyMeets[nearbyIndex].participantIds
              .where((id) => id != userId)
              .toList();
          final updatedMeet = _nearbyMeets[nearbyIndex].copyWith(
            participantIds: updatedParticipants,
          );
          _nearbyMeets[nearbyIndex] = updatedMeet;
        }
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error leaving meet: $e');
      return false;
    }
  }
}