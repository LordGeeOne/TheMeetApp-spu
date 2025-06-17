import 'package:cloud_firestore/cloud_firestore.dart';

class Meet {
  final String id;
  final String title;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime time;
  final String type;
  final int maxParticipants;
  final String creatorId;
  final List<String> participantIds;
  final String imageUrl;
  final String chatId; // Added chatId field

  Meet({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.time,
    required this.type,
    required this.maxParticipants,
    required this.creatorId,
    required this.participantIds,
    required this.imageUrl,
    this.chatId = '', // Default to empty string
  });

  // Factory method to create Meet from Map (for Firestore data)
  factory Meet.fromMap(Map<String, dynamic> data, String id) {
    final Timestamp timestamp = data['time'] as Timestamp;
    
    return Meet(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      time: timestamp.toDate(),
      type: data['type'] ?? 'Custom',
      maxParticipants: data['maxParticipants'] ?? 10,
      creatorId: data['creatorId'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      chatId: data['chatId'] ?? '', // Added chatId retrieval
    );
  }
  
  // Factory method to create Meet from DocumentSnapshot
  factory Meet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meet.fromMap(data, doc.id);
  }

  // Create a copy of this Meet with some fields replaced
  Meet copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? time,
    String? type,
    int? maxParticipants,
    String? creatorId,
    List<String>? participantIds,
    String? imageUrl,
    String? chatId, // Added chatId parameter
  }) {
    return Meet(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      time: time ?? this.time,
      type: type ?? this.type,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      creatorId: creatorId ?? this.creatorId,
      participantIds: participantIds ?? this.participantIds,
      imageUrl: imageUrl ?? this.imageUrl,
      chatId: chatId ?? this.chatId, // Added chatId
    );
  }

  // Convert Meet object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'time': Timestamp.fromDate(time),
      'type': type,
      'maxParticipants': maxParticipants,
      'creatorId': creatorId,
      'participantIds': participantIds,
      'imageUrl': imageUrl,
      'chatId': chatId, // Added chatId to the map
    };
  }

  // Get formatted date (e.g., "Today, 3:00 PM" or "Apr 28, 3:00 PM")
  String getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final meetDate = DateTime(time.year, time.month, time.day);
    
    final timeStr = '${time.hour > 12 ? time.hour - 12 : time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
    
    if (meetDate.isAtSameMomentAs(today)) {
      return 'Today, $timeStr';
    } else if (meetDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow, $timeStr';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[time.month - 1]} ${time.day}, $timeStr';
    }
  }
  
  // Get number of participants
  int get participantCount => participantIds.length;
  
  // Check if a user is a participant
  bool isParticipant(String userId) => participantIds.contains(userId);
  
  // Check if a user is the creator
  bool isCreator(String userId) => creatorId == userId;

  // Add status getter (open/closed based on participant count)
  String get status =>
      participantIds.length >= maxParticipants ? 'Closed' : 'Open';

  // Helper getter to handle default cover
  String get displayImageUrl {
    // If imageUrl is empty or refers to a default cover, return the local asset path
    if (imageUrl == 'default_cover' || imageUrl.isEmpty || imageUrl.contains('default2.jpg')) {
      // Using a local asset instead of a remote URL
      return 'assets/images/meet_images/default.jpg';
    }
    return imageUrl;
  }
  
  // Helper to determine if this is an asset path or network image
  bool get isDefaultImage {
    return imageUrl == 'default_cover' || imageUrl.isEmpty || imageUrl.contains('default2.jpg') || imageUrl.startsWith('assets/');
  }
  
  // Getter for creator name (temporary until we have proper user data)
  String get creatorName => 'User $creatorId';

  // Check if meet has a chat
  bool get hasChat => chatId.isNotEmpty;
}
