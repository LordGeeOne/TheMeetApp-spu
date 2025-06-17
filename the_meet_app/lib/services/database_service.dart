import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/config_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConfigProvider _configProvider;
  
  DatabaseService(this._configProvider);

  // Get all available meets
  Future<List<Meet>> getAvailableMeets() async {
    if (_configProvider.isDemo) {
      return [];
    } else {
      try {
        final snapshot = await _firestore
            .collection('meets')
            .where('time', isGreaterThan: Timestamp.fromDate(DateTime.now()))
            .orderBy('time')
            .limit(20)
            .get();
            
        return snapshot.docs.map((doc) => Meet.fromFirestore(doc)).toList();
      } catch (e) {
        print('Error fetching available meets: $e');
        return [];
      }
    }
  }

  // Create a new meet - using the same approach as user creation in AuthService
  Future<String?> createMeet({
    required String type,
    required String title,
    required String description,
    required DateTime meetTime,
    required Map<String, dynamic> location,
    required int maxParticipants,
    required Map<String, dynamic> requirements,
    Map<String, dynamic>? additionalDetails,
    required String creatorId,
  }) async {
    if (_configProvider.isDemo) {
      return 'demo-meet-${DateTime.now().millisecondsSinceEpoch}';
    } else {
      try {
        // Check if user is authenticated
        final user = _auth.currentUser;
        if (user == null) {
          print('User not authenticated. Cannot create meet.');
          return null;
        }
        
        // Extract location details
        final String address = location['address'] ?? '';
        final double latitude = location['latitude'] ?? 0.0;
        final double longitude = location['longitude'] ?? 0.0;
        
        // Create a simple map first without nested objects
        final meetData = {
          'title': title,
          'description': description,
          'location': address,
          'latitude': latitude,
          'longitude': longitude,
          'time': Timestamp.fromDate(meetTime),
          'type': type,
          'maxParticipants': maxParticipants,
          'creatorId': user.uid, // Use current user's ID to ensure it matches auth
          'participantIds': [user.uid], // Creator is automatically a participant
          'imageUrl': additionalDetails?['imageUrl'] ?? '',
          'created_at': FieldValue.serverTimestamp(),
        };
        
        // Use document() to get a reference with an auto-generated ID
        final docRef = _firestore.collection('meets').doc();
        
        // Set the data using set() instead of add() for more control
        await docRef.set(meetData);
        
        print('Meet created successfully with ID: ${docRef.id}');
        return docRef.id;
      } catch (e) {
        print('Error creating meet: $e');
        
        // If it's a permission error, try a more minimal approach
        if (e.toString().contains('PERMISSION_DENIED')) {
          try {
            final user = _auth.currentUser;
            if (user == null) return null;
            
            // Create minimal meet data
            final minimalMeetData = {
              'title': title,
              'description': description,
              'time': Timestamp.fromDate(meetTime),
              'creatorId': user.uid,
              'participantIds': [user.uid],
              'created_at': FieldValue.serverTimestamp()
            };
            
            // Try using a subcollection of the user document instead
            final userMeetRef = _firestore
                .collection('users')
                .doc(user.uid)
                .collection('user_meets')
                .doc();
                
            await userMeetRef.set(minimalMeetData);
            
            // Now try to copy to the main meets collection
            final meetRef = _firestore.collection('meets').doc(userMeetRef.id);
            await meetRef.set(minimalMeetData);
            
            print('Meet created via user subcollection with ID: ${meetRef.id}');
            return meetRef.id;
          } catch (subError) {
            print('Even alternative meet creation failed: $subError');
            return null;
          }
        }
        return null;
      }
    }
  }

  // Join a meet
  Future<bool> joinMeet(String meetId, String userId) async {
    if (_configProvider.isDemo) {
      return true;
    } else {
      try {
        await _firestore.collection('meets').doc(meetId).update({
          'participantIds': FieldValue.arrayUnion([userId])
        });
        return true;
      } catch (e) {
        print('Error joining meet: $e');
        return false;
      }
    }
  }

  // Leave a meet
  Future<bool> leaveMeet(String meetId, String userId) async {
    if (_configProvider.isDemo) {
      return true;
    } else {
      try {
        await _firestore.collection('meets').doc(meetId).update({
          'participantIds': FieldValue.arrayRemove([userId])
        });
        return true;
      } catch (e) {
        print('Error leaving meet: $e');
        return false;
      }
    }
  }

  // Get user's created and participating meets
  Future<Map<String, List<Meet>>> getUserMeetsObjects(String userId) async {
    if (_configProvider.isDemo) {
      return {'created': [], 'participating': []};
    } else {
      try {
        final createdSnapshot = await _firestore
            .collection('meets')
            .where('creatorId', isEqualTo: userId)
            .where('time', isGreaterThan: Timestamp.fromDate(DateTime.now()))
            .orderBy('time')
            .get();
            
        final participatingSnapshot = await _firestore
            .collection('meets')
            .where('participantIds', arrayContains: userId)
            .where('creatorId', isNotEqualTo: userId) // Exclude meets the user created
            .where('time', isGreaterThan: Timestamp.fromDate(DateTime.now()))
            .orderBy('time')
            .get();
            
        final created = createdSnapshot.docs.map((doc) => Meet.fromFirestore(doc)).toList();
        final participating = participatingSnapshot.docs.map((doc) => Meet.fromFirestore(doc)).toList();
        
        return {'created': created, 'participating': participating};
      } catch (e) {
        print('Error fetching user meets: $e');
        return {'created': [], 'participating': []};
      }
    }
  }
  
  // Helper method to check if a collection exists
  Future<bool> _collectionExists(String collectionPath) async {
    final query = await _firestore.collection(collectionPath).limit(1).get();
    return query.docs.isNotEmpty;
  }

  Future<void> updateMeetImage(String meetId, String imageUrl) async {
    await FirebaseFirestore.instance
        .collection('meets')
        .doc(meetId)
        .update({'imageUrl': imageUrl});
  }
}
