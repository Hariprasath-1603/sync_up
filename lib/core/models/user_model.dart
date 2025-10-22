import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? bio;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? location;
  final DateTime createdAt;
  final DateTime lastActive;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final List<String> followers;
  final List<String> following;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.displayName,
    this.photoURL,
    this.bio,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.location,
    required this.createdAt,
    required this.lastActive,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.followers = const [],
    this.following = const [],
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username
          .toLowerCase(), // Store lowercase for case-insensitive search
      'usernameDisplay': username, // Original casing for display
      'email': email.toLowerCase(),
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phone': phone,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'followers': followers,
      'following': following,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['usernameDisplay'] ?? map['username'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      bio: map['bio'],
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'],
      phone: map['phone'],
      location: map['location'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );
  }

  // Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser({
    required String uid,
    required String username,
    required String email,
    String? displayName,
    String? photoURL,
    String? dateOfBirth,
    String? gender,
    String? phone,
    String? location,
  }) {
    return UserModel(
      uid: uid,
      username: username,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      dateOfBirth: dateOfBirth,
      gender: gender,
      phone: phone,
      location: location,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  // Copy with method for updating specific fields
  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    String? dateOfBirth,
    String? gender,
    String? phone,
    String? location,
    DateTime? createdAt,
    DateTime? lastActive,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<String>? followers,
    List<String>? following,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }
}
