import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.imageUrl,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'isRead': isRead,
    };
  }
}

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentChatId;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentChatId => _currentChatId;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Get or create a chat room between two users
  Future<String?> getChatRoomId(String otherUserId) async {
    if (currentUserId == null) return null;
    
    try {
      // Sort user IDs to ensure consistent chat room IDs
      final List<String> userIds = [currentUserId!, otherUserId];
      userIds.sort(); // Sort to ensure same ID regardless of who initiates
      
      // Check if chat room already exists
      final chatQuery = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContainsAny: [currentUserId])
          .get();
      
      for (var doc in chatQuery.docs) {
        final List<dynamic> participants = doc['participants'] ?? [];
        if (participants.contains(otherUserId) && participants.contains(currentUserId)) {
          return doc.id;
        }
      }
      
      // Create new chat room if none exists
      final newChatRoom = await _firestore.collection('chatRooms').add({
        'participants': userIds,
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      return newChatRoom.id;
    } catch (e) {
      print('Error creating/getting chat room: $e');
      return null;
    }
  }
  
  // Get or create meet chat room
  Future<String?> getMeetChatRoomId(String meetId) async {
    try {
      // Check if meet chat already exists
      final chatDoc = await _firestore
          .collection('meetChats')
          .doc(meetId)
          .get();
      
      if (chatDoc.exists) {
        return chatDoc.id;
      }
      
      // Create new meet chat if it doesn't exist
      await _firestore.collection('meetChats').doc(meetId).set({
        'meetId': meetId,
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      return meetId;
    } catch (e) {
      print('Error creating/getting meet chat room: $e');
      return null;
    }
  }
  
  // Load messages for a specific chat
  Future<void> loadMessages(String chatId, {bool isMeetChat = false}) async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      _currentChatId = chatId;
      notifyListeners();
      
      final collection = isMeetChat ? 'meetChats' : 'chatRooms';
      final messagesQuery = await _firestore
          .collection(collection)
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      _messages = messagesQuery.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
          
      // Update read status for unread messages
      if (currentUserId != null) {
        for (var doc in messagesQuery.docs) {
          if (doc['senderId'] != currentUserId && doc['isRead'] == false) {
            _firestore
                .collection(collection)
                .doc(chatId)
                .collection('messages')
                .doc(doc.id)
                .update({'isRead': true});
          }
        }
      }
      
      // Set up listener for future messages
      _setupMessageListener(chatId, isMeetChat);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading messages: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Setup real-time listener for new messages
  void _setupMessageListener(String chatId, bool isMeetChat) {
    final collection = isMeetChat ? 'meetChats' : 'chatRooms';
    
    _firestore
        .collection(collection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _messages = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
      
      // Mark new messages as read if they're not from current user
      if (currentUserId != null) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added &&
              change.doc['senderId'] != currentUserId &&
              change.doc['isRead'] == false) {
            _firestore
                .collection(collection)
                .doc(chatId)
                .collection('messages')
                .doc(change.doc.id)
                .update({'isRead': true});
          }
        }
      }
      
      notifyListeners();
    });
  }
  
  // Send a message
  Future<bool> sendMessage(String content, {String? imageUrl}) async {
    if (_currentChatId == null || currentUserId == null) return false;
    
    try {
      final String senderName = _auth.currentUser?.displayName ?? 'User';
      
      final message = ChatMessage(
        id: '', // Will be assigned by Firestore
        senderId: currentUserId!,
        senderName: senderName,
        content: content,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        isRead: false,
      );
      
      // Determine if this is a meet chat or direct chat
      final collection = _currentChatId!.startsWith('meet_') ? 'meetChats' : 'chatRooms';
      
      // Add message
      await _firestore
          .collection(collection)
          .doc(_currentChatId)
          .collection('messages')
          .add(message.toMap());
      
      // Update last message in chat room
      await _firestore.collection(collection).doc(_currentChatId).update({
        'lastMessage': content,
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
  
  // Get all user chats
  Future<List<Map<String, dynamic>>> getUserChats() async {
    if (currentUserId == null) return [];
    
    try {
      final chatRooms = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTimestamp', descending: true)
          .get();
      
      final List<Map<String, dynamic>> chats = [];
      
      for (var doc in chatRooms.docs) {
        final List<dynamic> participants = doc['participants'] ?? [];
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => null,
        );
        
        if (otherUserId == null) continue;
        
        // Get other user's details
        final userDoc = await _firestore
            .collection('users')
            .doc(otherUserId)
            .get();
        
        if (userDoc.exists) {
          chats.add({
            'chatId': doc.id,
            'userId': otherUserId,
            'displayName': userDoc['displayName'] ?? 'User',
            'photoURL': userDoc['photoURL'] ?? '',
            'lastMessage': doc['lastMessage'] ?? '',
            'lastMessageTimestamp': doc['lastMessageTimestamp'] ?? Timestamp.now(),
          });
        }
      }
      
      return chats;
    } catch (e) {
      print('Error getting user chats: $e');
      return [];
    }
  }
  
  // Get all meet chats where user is a participant
  Future<List<Map<String, dynamic>>> getUserMeetChats() async {
    if (currentUserId == null) return [];
    
    try {
      // Get meets where user is a participant
      final meets = await _firestore
          .collection('meets')
          .where('participantIds', arrayContains: currentUserId)
          .get();
      
      final List<Map<String, dynamic>> meetChats = [];
      
      for (var meetDoc in meets.docs) {
        final meetId = meetDoc.id;
        final meetData = meetDoc.data();
        
        // Check if meet chat exists
        final chatDoc = await _firestore
            .collection('meetChats')
            .doc(meetId)
            .get();
        
        if (chatDoc.exists) {
          meetChats.add({
            'chatId': chatDoc.id,
            'meetId': meetId,
            'meetTitle': meetData['title'] ?? 'Meet Chat',
            'meetImageUrl': meetData['displayImageUrl'] ?? '',
            'lastMessage': chatDoc['lastMessage'] ?? '',
            'lastMessageTimestamp': chatDoc['lastMessageTimestamp'] ?? Timestamp.now(),
            'participantCount': (meetData['participantIds'] as List<dynamic>?)?.length ?? 0,
          });
        }
      }
      
      return meetChats;
    } catch (e) {
      print('Error getting meet chats: $e');
      return [];
    }
  }
  
  // Clear current chat data when leaving a chat
  void clearCurrentChat() {
    _currentChatId = null;
    _messages = [];
    notifyListeners();
  }
}