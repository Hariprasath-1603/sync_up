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
  final bool isPrivate;
  final bool showActivityStatus;
  final bool allowMessagesFromEveryone;

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
    this.isPrivate = false,
    this.showActivityStatus = true,
    this.allowMessagesFromEveryone = false,
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
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'followers': followers,
      'following': following,
      'isPrivate': isPrivate,
      'showActivityStatus': showActivityStatus,
      'allowMessagesFromEveryone': allowMessagesFromEveryone,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username:
          map['usernameDisplay'] ??
          map['username_display'] ??
          map['username'] ??
          '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['display_name'],
      photoURL: map['photoURL'] ?? map['photo_url'],
      bio: map['bio'],
      dateOfBirth: map['dateOfBirth'] ?? map['date_of_birth'],
      gender: map['gender'],
      phone: map['phone'],
      location: map['location'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      lastActive: map['lastActive'] != null
          ? DateTime.parse(map['lastActive'] as String)
          : map['last_active'] != null
          ? DateTime.parse(map['last_active'] as String)
          : DateTime.now(),
      followersCount: map['followersCount'] ?? map['followers_count'] ?? 0,
      followingCount: map['followingCount'] ?? map['following_count'] ?? 0,
      postsCount: map['postsCount'] ?? map['posts_count'] ?? 0,
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      isPrivate: map['isPrivate'] ?? map['is_private'] ?? false,
      showActivityStatus: map['showActivityStatus'] ?? map['show_activity_status'] ?? true,
      allowMessagesFromEveryone: map['allowMessagesFromEveryone'] ?? map['allow_messages_from_everyone'] ?? false,
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
    bool? isPrivate,
    bool? showActivityStatus,
    bool? allowMessagesFromEveryone,
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
      isPrivate: isPrivate ?? this.isPrivate,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      allowMessagesFromEveryone: allowMessagesFromEveryone ?? this.allowMessagesFromEveryone,
    );
  }
}
