import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/providers/config_provider.dart';
import 'package:the_meet_app/services/firebase_permission_helper.dart';
import 'package:the_meet_app/services/chat_service.dart';
import 'package:the_meet_app/services/service_locator.dart';

class MeetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigProvider _configProvider;
  
  MeetService(this._configProvider);
  
  // Get all meets for regular display
  Future<List<Meet>> getMeets() async {
    try {
      final snapshot = await _firestore
          .collection('meets')
          .where('time', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('time')
          .get();
          
      return snapshot.docs.map((doc) => Meet.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching meets: $e');
      return [];
    }
  }
  
  // Get upcoming meets
  Future<List<Meet>> getUpcomingMeets() async {
    try {
      final snapshot = await _firestore
          .collection('meets')
          .where('time', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('time')
          .limit(10)
          .get();
          
      return snapshot.docs.map((doc) => Meet.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching upcoming meets: $e');
      return [];
    }
  }
  
  // Get nearby meets - now returns all meets since we no longer track distance
  Future<List<Meet>> getNearbyMeets() async {
    try {
      final snapshot = await _firestore
          .collection('meets')
          .where('time', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('time')
          .get();
          
      final meets = snapshot.docs.map((doc) => Meet.fromFirestore(doc)).toList();
      return meets.take(10).toList();
    } catch (e) {
      print('Error fetching nearby meets: $e');
      return [];
    }
  }
  
  // Get meets by type
  Future<List<Meet>> getMeetsByType(String type) async {
    try {
      final snapshot = await _firestore
          .collection('meets')
          .where('type', isEqualTo: type)
          .where('time', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('time')
          .limit(10)
          .get();
          
      return snapshot.docs.map((doc) => Meet.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching meets by type: $e');
      return [];
    }
  }
  
  // Get meet details by id
  Future<Meet?> getMeetById(String meetId) async {
    try {
      final doc = await _firestore.collection('meets').doc(meetId).get();
      if (doc.exists) {
        return Meet.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching meet by id: $e');
      return null;
    }
  }
  
  // Create a new meet with permission checks and retries
  Future<String?> createMeet({
    required String type,
    required String title,
    required String description,
    required DateTime meetTime,
    required Map<String, dynamic> location,
    required int maxParticipants,
    required Map<String, dynamic> requirements,
    required Map<String, dynamic> additionalDetails,
    required String creatorId,
  }) async {
    try {
      // Create the meet data
      final meetData = {
        'title': title,
        'description': description,
        'location': location['address'] ?? '',
        'latitude': location['latitude'] ?? 0.0,
        'longitude': location['longitude'] ?? 0.0,
        'time': Timestamp.fromDate(meetTime),
        'type': type,
        'maxParticipants': maxParticipants,
        'creatorId': creatorId,
        'participantIds': [creatorId], // Creator is first participant
        'imageUrl': '',
        'requirements': requirements,
        'additionalDetails': additionalDetails,
        'createdAt': Timestamp.now(),
        'chatId': '', // Initialize with empty chatId, will be updated after creation
        'leftUsers': [], // Add leftUsers array to track users who left
        'notificationRequests': [], // Add notificationRequests array for availability notifications
      };

      // First attempt to create meet
      try {
        // Create the meet first
        final docRef = await _firestore.collection('meets').add(meetData);
        print('Meet created successfully with ID: ${docRef.id}');
        
        // Now create a chat for this meet
        final meetInstance = Meet(
          id: docRef.id,
          title: title,
          description: description,
          location: location['address'] ?? '',
          latitude: location['latitude'] ?? 0.0,
          longitude: location['longitude'] ?? 0.0,
          time: meetTime,
          type: type,
          maxParticipants: maxParticipants,
          creatorId: creatorId,
          participantIds: [creatorId],
          imageUrl: '',
        );
        
        // Create a chat for the meet
        final chatId = await chatService.createMeetChat(meetInstance);
        
        if (chatId != null && chatId.isNotEmpty) {
          // Update the meet with the chatId
          await _firestore.collection('meets').doc(docRef.id).update({
            'chatId': chatId
          });
          print('Chat created and linked to meet: $chatId');
        }
        
        return docRef.id;
      } catch (e) {
        print('Initial attempt to create meet failed: $e');
        
        // Check if this is a permission issue
        if (e.toString().contains('PERMISSION_DENIED')) {
          // Try to fix permissions
          print('Attempting to fix Firestore permissions...');
          final permissionsFixed = await FirebasePermissionHelper.fixPermissions();
          
          if (permissionsFixed) {
            // Try again with the meet creation
            print('Permissions fixed! Trying again to create meet...');
            final docRef = await _firestore.collection('meets').add(meetData);
            print('Meet created successfully after fixing permissions, ID: ${docRef.id}');
            return docRef.id;
          } else {
            // Permissions couldn't be fixed, try with simplified map
            print('Could not fix permissions. Trying with simplified data...');
            final Map<String, dynamic> simplifiedMap = {
              'title': title,
              'description': description,
              'type': type,
              'time': Timestamp.fromDate(meetTime),
              'creatorId': creatorId,
              'participantIds': [creatorId],
              'maxParticipants': maxParticipants
            };
            
            try {
              final docRef = await _firestore.collection('meets').add(simplifiedMap);
              print('Meet created with simplified data, ID: ${docRef.id}');
              return docRef.id;
            } catch (innerError) {
              print('Even simplified creation failed: $innerError');
              return null;
            }
          }
        } else {
          // It's not a permissions issue
          print('Error is not permission-related: $e');
          return null;
        }
      }
    } catch (e) {
      print('Error creating meet: $e');
      return null;
    }
  }
  
  // Join a meet (add user to participants)
  Future<bool> joinMeet(String meetId, String userId) async {
    try {
      // Add user to meet participants
      await _firestore.collection('meets').doc(meetId).update({
        'participantIds': FieldValue.arrayUnion([userId])
      });
      
      // Get meet details to update chat participants
      final meetDoc = await _firestore.collection('meets').doc(meetId).get();
      if (meetDoc.exists) {
        final meet = Meet.fromFirestore(meetDoc);
        
        // If the meet has a chat, add the user to chat participants
        if (meet.chatId.isNotEmpty) {
          // Add user to chat participants
          await _firestore.collection('chats').doc(meet.chatId).update({
            'participantIds': FieldValue.arrayUnion([userId])
          });
          
          // Get user details to create a personalized welcome message
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final userName = userData['displayName'] ?? 'New participant';
            
            // Add a system message about the new participant
            await _firestore.collection('chats').doc(meet.chatId).collection('messages').add({
              'senderId': 'system',
              'senderName': 'System',
              'senderPhoto': '',
              'text': '$userName has joined the meet. Say hello!',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
            
            // Update the last message for the chat
            await _firestore.collection('chats').doc(meet.chatId).update({
              'lastMessage': '$userName has joined the meet',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'messageCount': FieldValue.increment(1),
            });
          }
        } else {
          // If no chat exists, create one
          final chatService = ChatService(_configProvider);
          final chatId = await chatService.createMeetChat(meet);
          
          // Update the meet with the new chatId
          if (chatId != null && chatId.isNotEmpty) {
            await _firestore.collection('meets').doc(meetId).update({
              'chatId': chatId
            });
            
            // Add a welcome message to the new chat
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final userName = userData['displayName'] ?? 'New participant';
              
              await _firestore.collection('chats').doc(chatId).collection('messages').add({
                'senderId': 'system',
                'senderName': 'System',
                'senderPhoto': '',
                'text': 'Welcome to the meet chat! $userName has joined the conversation.',
                'timestamp': FieldValue.serverTimestamp(),
                'isRead': false,
              });
            }
          }
        }
      }
      
      return true;
    } catch (e) {
      print('Error joining meet: $e');
      
      if (e.toString().contains('PERMISSION_DENIED')) {
        // Try to fix permissions
        final permissionsFixed = await FirebasePermissionHelper.fixPermissions();
        if (permissionsFixed) {
          // Try again
          try {
            await _firestore.collection('meets').doc(meetId).update({
              'participantIds': FieldValue.arrayUnion([userId])
            });
            return true;
          } catch (retryError) {
            print('Even after fixing permissions, joining meet failed: $retryError');
            return false;
          }
        }
      }
      
      return false;
    }
  }
  
  // Leave a meet (remove user from participants)
  Future<bool> leaveMeet(String meetId, String userId) async {
    try {
      await _firestore.collection('meets').doc(meetId).update({
        'participantIds': FieldValue.arrayRemove([userId])
      });
      
      // Get meet details to update chat participants (don't remove from chat)
      final meetDoc = await _firestore.collection('meets').doc(meetId).get();
      if (meetDoc.exists) {
        final meet = Meet.fromFirestore(meetDoc);
        
        // For chat, we don't remove the user so they can still access chat history
        // This is intentional - they've left the meet but can still see past messages
      }
      
      return true;
    } catch (e) {
      print('Error leaving meet: $e');
      
      if (e.toString().contains('PERMISSION_DENIED')) {
        // Try to fix permissions
        final permissionsFixed = await FirebasePermissionHelper.fixPermissions();
        if (permissionsFixed) {
          // Try again
          try {
            await _firestore.collection('meets').doc(meetId).update({
              'participantIds': FieldValue.arrayRemove([userId])
            });
            return true;
          } catch (retryError) {
            print('Even after fixing permissions, leaving meet failed: $retryError');
            return false;
          }
        }
      }
      
      return false;
    }
  }
  
  // Delete a meet
  Future<bool> deleteMeet(String meetId) async {
    try {
      // Get the meet to find the associated chat
      final meetDoc = await _firestore.collection('meets').doc(meetId).get();
      if (meetDoc.exists) {
        final meet = Meet.fromFirestore(meetDoc);
        
        // If the meet has a chat, delete it
        if (meet.hasChat) {
          try {
            await _firestore.collection('chats').doc(meet.chatId).delete();
            
            // Also delete messages subcollection
            final chatMessages = await _firestore
                .collection('chats')
                .doc(meet.chatId)
                .collection('messages')
                .get();
                
            for (final doc in chatMessages.docs) {
              await doc.reference.delete();
            }
          } catch (e) {
            print('Error deleting meet chat: $e');
            // Continue anyway to delete the meet
          }
        }
      }
      
      // Delete the meet document
      await _firestore.collection('meets').doc(meetId).delete();
      return true;
    } catch (e) {
      print('Error deleting meet: $e');
      return false;
    }
  }
}