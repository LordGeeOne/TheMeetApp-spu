import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String bio;
  final List<String> interests;
  final String school;
  final String major;
  final String graduationYear;
  final DateTime joinDate;
  final int meetsCreated;
  final int meetsJoined;
  final bool isVerified; // Whether the user has been verified
  final String userType; // 'spu', 'gmail', or 'other'

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    this.bio = '',
    this.interests = const [],
    this.school = '',
    this.major = '',
    this.graduationYear = '',
    DateTime? joinDate,
    this.meetsCreated = 0,
    this.meetsJoined = 0,
    this.isVerified = false,
    this.userType = 'other',
  }) : joinDate = joinDate ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      bio: map['bio'] ?? '',
      interests: map['interests'] != null 
          ? List<String>.from(map['interests']) 
          : [],
      school: map['school'] ?? '',
      major: map['major'] ?? '',
      graduationYear: map['graduationYear'] ?? '',
      joinDate: map['joinDate'] != null 
          ? (map['joinDate'] as Timestamp).toDate() 
          : DateTime.now(),
      meetsCreated: map['meetsCreated'] ?? 0,
      meetsJoined: map['meetsJoined'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      userType: map['userType'] ?? 'other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'interests': interests,
      'school': school,
      'major': major,
      'graduationYear': graduationYear,
      'joinDate': joinDate,
      'meetsCreated': meetsCreated,
      'meetsJoined': meetsJoined,
      'isVerified': isVerified,
      'userType': userType,
    };
  }
  
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    List<String>? interests,
    String? school,
    String? major,
    String? graduationYear,
    DateTime? joinDate,
    int? meetsCreated,
    int? meetsJoined,
    bool? isVerified,
    String? userType,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      school: school ?? this.school,
      major: major ?? this.major,
      graduationYear: graduationYear ?? this.graduationYear,
      joinDate: joinDate ?? this.joinDate,
      meetsCreated: meetsCreated ?? this.meetsCreated,
      meetsJoined: meetsJoined ?? this.meetsJoined,
      isVerified: isVerified ?? this.isVerified,
      userType: userType ?? this.userType,
    );
  }
}