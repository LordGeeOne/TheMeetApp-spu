import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String meetId;
  final String meetTitle;
  final String meetType;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<String> participantIds;
  
  Chat({
    required this.id,
    required this.meetId,
    required this.meetTitle,
    required this.meetType,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.participantIds,
  });
  
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      meetId: data['meetId'] ?? '',
      meetTitle: data['meetTitle'] ?? '',
      meetType: data['meetType'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      participantIds: List<String>.from(data['participantIds'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'meetId': meetId,
      'meetTitle': meetTitle,
      'meetType': meetType,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'participantIds': participantIds,
    };
  }
}

class DirectMessage {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool online;
  
  DirectMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.online,
  });
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderPhoto;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  
  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderPhoto,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });
  
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhoto: data['senderPhoto'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}