import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_meet_app/models/chat.dart';
import 'package:the_meet_app/models/meet.dart';
import 'package:the_meet_app/models/user_model.dart';
import 'package:the_meet_app/providers/config_provider.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigProvider _configProvider;
  
  ChatService(this._configProvider);
  
  // Demo data for chats
  final List<Chat> _demoMeetChats = [
    Chat(
      id: 'chat1',
      meetId: 'demo-meet-1',
      meetTitle: 'Coffee Chat at Student Union',
      meetType: 'Coffee',
      lastMessage: 'I\'ll be there in 5 minutes!',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      participantIds: ['demo-user-1', 'demo-user-2', 'demo-user-3', 'demo-user-4'],
    ),
    Chat(
      id: 'chat2',
      meetId: 'demo-meet-2',
      meetTitle: 'Study Group for Finals',
      meetType: 'Study',
      lastMessage: 'Does anyone have the notes from last week?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
      participantIds: ['demo-user-2', 'demo-user-3', 'demo-user-5'],
    ),
    Chat(
      id: 'chat3',
      meetId: 'demo-meet-4',
      meetTitle: 'Lunch Meetup',
      meetType: 'Meal',
      lastMessage: 'Looking forward to meeting everyone!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
      participantIds: ['demo-user-5', 'demo-user-6', 'demo-user-7'],
    ),
  ];
  
  // Demo data for direct messages
  final List<DirectMessage> _demoDirectMessages = [
    DirectMessage(
      id: 'dm1',
      userId: 'demo-user-2',
      userName: 'Emily Chen',
      userPhoto: 'https://i.pravatar.cc/150?img=5',
      lastMessage: 'Are you going to the coffee meetup tomorrow?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 1,
      online: true,
    ),
    DirectMessage(
      id: 'dm2',
      userId: 'demo-user-3',
      userName: 'Michael Brown',
      userPhoto: 'https://i.pravatar.cc/150?img=8',
      lastMessage: 'Thanks for the study materials!',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      online: false,
    ),
    DirectMessage(
      id: 'dm3',
      userId: 'demo-user-5',
      userName: 'Jessica Taylor',
      userPhoto: 'https://i.pravatar.cc/150?img=9',
      lastMessage: 'See you at the campus walk on Friday!',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 0,
      online: true,
    ),
  ];
  
  // Get all meet chats for a user
  Future<List<Chat>> getMeetChats(String userId) async {
    if (_configProvider.isDemo) {
      return _demoMeetChats.where((chat) => 
        chat.participantIds.contains(userId)).toList();
    } else {
      try {
        final snapshot = await _firestore
            .collection('chats')
            .where('participantIds', arrayContains: userId)
            .orderBy('lastMessageTime', descending: true)
            .get();
            
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Chat(
            id: doc.id,
            meetId: data['meetId'] ?? '',
            meetTitle: data['meetTitle'] ?? '',
            meetType: data['meetType'] ?? '',
            lastMessage: data['lastMessage'] ?? '',
            lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
            unreadCount: _getUnreadCount(data, userId),
            participantIds: List<String>.from(data['participantIds'] ?? []),
          );
        }).toList();
      } catch (e) {
        print('Error fetching meet chats: $e');
        return [];
      }
    }
  }
  
  // Get all direct messages for a user
  Future<List<DirectMessage>> getDirectMessages(String userId) async {
    if (_configProvider.isDemo) {
      return _demoDirectMessages;
    } else {
      try {
        final snapshot = await _firestore
            .collection('directChats')
            .where('participants', arrayContains: userId)
            .orderBy('lastMessageTime', descending: true)
            .get();
            
        final results = <DirectMessage>[];
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          
          // Get the other participant's ID
          final otherUserId = (data['participants'] as List<dynamic>)
              .firstWhere((id) => id != userId, orElse: () => '');
              
          if (otherUserId.isEmpty) continue;
          
          // Get the other user's data
          final userDoc = await _firestore.collection('users').doc(otherUserId).get();
          if (!userDoc.exists) continue;
          
          final userData = userDoc.data() ?? {};
          
          results.add(DirectMessage(
            id: doc.id,
            userId: otherUserId,
            userName: userData['displayName'] ?? 'Unknown User',
            userPhoto: userData['photoURL'] ?? '',
            lastMessage: data['lastMessage'] ?? '',
            lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
            unreadCount: _getUnreadCount(data, userId),
            online: userData['online'] ?? false,
          ));
        }
        
        return results;
      } catch (e) {
        print('Error fetching direct messages: $e');
        return [];
      }
    }
  }
  
  // Create a chat for a meet
  Future<String?> createMeetChat(Meet meet) async {
    if (_configProvider.isDemo) {
      return 'chat-demo-${DateTime.now().millisecondsSinceEpoch}';
    } else {
      try {
        // First check if a chat already exists for this meet
        final querySnapshot = await _firestore
            .collection('chats')
            .where('meetId', isEqualTo: meet.id)
            .limit(1)
            .get();
        
        // If a chat exists, return its ID
        if (querySnapshot.docs.isNotEmpty) {
          final existingChatId = querySnapshot.docs.first.id;
          
          // Update the existing chat with latest meet data
          await _firestore.collection('chats').doc(existingChatId).update({
            'meetTitle': meet.title,
            'meetType': meet.type,
            'participantIds': meet.participantIds,
          });
          
          return existingChatId;
        }
        
        // If no chat exists, create a new one
        final chatData = {
          'meetId': meet.id,
          'meetTitle': meet.title,
          'meetType': meet.type,
          'participantIds': meet.participantIds,
          'lastMessage': 'Chat created',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'messageCount': 0,
          'readStatus': {}
        };
        
        final docRef = await _firestore.collection('chats').add(chatData);
        
        // Send a welcome message
        await _firestore.collection('chats').doc(docRef.id).collection('messages').add({
          'senderId': 'system',
          'senderName': 'System',
          'senderPhoto': '',
          'text': 'Welcome to the meet chat! You can use this space to communicate with all participants.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        
        return docRef.id;
      } catch (e) {
        print('Error creating meet chat: $e');
        return null;
      }
    }
  }
  
  // Get messages for a chat
  Stream<List<Message>> getChatMessages(String chatId) {
    if (_configProvider.isDemo) {
      // Return mock messages for demo mode
      return Stream.value([
        Message(
          id: 'm1',
          chatId: chatId,
          senderId: 'demo-user-2',
          senderName: 'Emily Chen',
          senderPhoto: 'https://i.pravatar.cc/150?img=5',
          text: 'Is everyone still planning to meet at 3?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          isRead: true,
        ),
        Message(
          id: 'm2',
          chatId: chatId,
          senderId: 'demo-user-3',
          senderName: 'Michael Brown',
          senderPhoto: 'https://i.pravatar.cc/150?img=8',
          text: 'Yes, I\'ll be there!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
          isRead: true,
        ),
        Message(
          id: 'm3',
          chatId: chatId,
          senderId: 'demo-user-1',
          senderName: 'You',
          senderPhoto: '',
          text: 'I might be 5 minutes late, traffic is heavy today.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: true,
        ),
      ]);
    } else {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return Message(
                id: doc.id,
                chatId: chatId,
                senderId: data['senderId'] ?? '',
                senderName: data['senderName'] ?? '',
                senderPhoto: data['senderPhoto'] ?? '',
                text: data['text'] ?? '',
                timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isRead: data['isRead'] ?? false,
              );
            }).toList();
          });
    }
  }
  
  // Get messages for a direct chat
  Stream<List<Message>> getDirectChatMessages(String chatId) {
    // Implementation is similar to getChatMessages
    if (_configProvider.isDemo) {
      return Stream.value([
        Message(
          id: 'dm1',
          chatId: chatId,
          senderId: 'demo-user-2',
          senderName: 'Other User',
          senderPhoto: 'https://i.pravatar.cc/150?img=5',
          text: 'Hey there! Are you going to the coffee meetup tomorrow?',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: true,
        ),
        Message(
          id: 'dm2',
          chatId: chatId,
          senderId: 'demo-user-1',
          senderName: 'You',
          senderPhoto: '',
          text: 'Hi! Yes, I\'m planning to go. Are you?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
          isRead: true,
        ),
      ]);
    } else {
      return _firestore
          .collection('directChats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return Message(
                id: doc.id,
                chatId: chatId,
                senderId: data['senderId'] ?? '',
                senderName: data['senderName'] ?? '',
                senderPhoto: data['senderPhoto'] ?? '',
                text: data['text'] ?? '',
                timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isRead: data['isRead'] ?? false,
              );
            }).toList();
          });
    }
  }
  
  // Send a message to a meet chat
  Future<bool> sendChatMessage(String chatId, UserModel sender, String message) async {
    if (_configProvider.isDemo) {
      return true;
    } else {
      try {
        final messageData = {
          'senderId': sender.uid,
          'senderName': sender.displayName,
          'senderPhoto': sender.photoURL,
          'text': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        };
        
        // Add message to the subcollection
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(messageData);
        
        // Update the chat document with last message info
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'messageCount': FieldValue.increment(1),
        });
        
        return true;
      } catch (e) {
        print('Error sending chat message: $e');
        return false;
      }
    }
  }
  
  // Send a direct message
  Future<bool> sendDirectMessage(String chatId, UserModel sender, String recipientId, String message) async {
    if (_configProvider.isDemo) {
      return true;
    } else {
      try {
        final messageData = {
          'senderId': sender.uid,
          'senderName': sender.displayName,
          'senderPhoto': sender.photoURL,
          'text': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        };
        
        // Add message to the subcollection
        await _firestore
            .collection('directChats')
            .doc(chatId)
            .collection('messages')
            .add(messageData);
        
        // Update the chat document with last message info
        await _firestore.collection('directChats').doc(chatId).update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'messageCount': FieldValue.increment(1),
          'readStatus': {
            sender.uid: true,
            recipientId: false
          }
        });
        
        return true;
      } catch (e) {
        print('Error sending direct message: $e');
        return false;
      }
    }
  }
  
  // Mark a chat as read
  Future<bool> markChatAsRead(String chatId, String userId) async {
    if (_configProvider.isDemo) {
      return true;
    } else {
      try {
        await _firestore.collection('chats').doc(chatId).update({
          'readStatus.$userId': true
        });
        return true;
      } catch (e) {
        print('Error marking chat as read: $e');
        return false;
      }
    }
  }
  
  // Mark a direct chat as read
  Future<bool> markDirectChatAsRead(String chatId, String userId) async {
    if (_configProvider.isDemo) {
      return true;
    } else {
      try {
        await _firestore.collection('directChats').doc(chatId).update({
          'readStatus.$userId': true
        });
        return true;
      } catch (e) {
        print('Error marking direct chat as read: $e');
        return false;
      }
    }
  }
  
  // Helper method to calculate unread count
  int _getUnreadCount(Map<String, dynamic> data, String userId) {
    if (data['readStatus'] == null) return 0;
    
    final readStatus = data['readStatus'] as Map<String, dynamic>;
    final messageCount = data['messageCount'] ?? 0;
    final lastReadMessage = readStatus[userId] ?? 0;
    
    if (lastReadMessage is bool) {
      return lastReadMessage ? 0 : 1;
    }
    
    return (messageCount - lastReadMessage).clamp(0, messageCount);
  }
}