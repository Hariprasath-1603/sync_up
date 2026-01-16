/// User Model - Core User Data Structure
/// 
/// Represents a user in the SyncUp social media application.
/// This model maps to the 'users' table in Supabase and contains
/// all user profile information, social metrics, and privacy settings.
/// 
/// Key Features:
/// - Complete user profile data (bio, photos, contact info)
/// - Social graph information (followers, following)
/// - Privacy and notification settings
/// - Activity tracking (last active, creation date)
/// - Story availability status
/// 
/// Database Integration:
/// - Primary key: uid (matches Supabase auth.users.id)
/// - Username stored in lowercase for case-insensitive searches
/// - Separate usernameDisplay field preserves original casing
/// - Follow relationships stored as UID arrays
/// 
/// Privacy Settings:
/// - [isPrivate]: Controls profile visibility and follow requests
/// - [showActivityStatus]: Shows/hides "last active" timestamp
/// - [allowMessagesFromEveryone]: DM permissions (everyone vs followers only)
/// 
/// Usage Example:
/// ```dart
/// final user = UserModel(
///   uid: authUser.id,
///   username: 'john_doe',
///   email: 'john@example.com',
///   createdAt: DateTime.now(),
///   lastActive: DateTime.now(),
/// );
/// await databaseService.createUser(user);
/// ```
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? coverPhotoUrl; // Cover/banner photo
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
  final bool hasStories; // New field for stories status

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.displayName,
    this.photoURL,
    this.coverPhotoUrl,
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
    this.hasStories = false,
  });

  /// Convert UserModel to Map for Supabase Database
  /// 
  /// This method prepares the user data for storage in Supabase.
  /// 
  /// Special Handling:
  /// - Username is stored in TWO fields:
  ///   1. 'username': Lowercase version for case-insensitive searches and uniqueness
  ///   2. 'usernameDisplay': Original casing for UI display
  ///   
  /// - Email is also normalized to lowercase for consistency
  /// 
  /// This dual-field approach allows:
  /// - Fast case-insensitive username lookups in queries
  /// - Preserving user's preferred username capitalization in UI
  /// - Preventing duplicate usernames like "JohnDoe" and "johndoe"
  /// 
  /// Example:
  /// ```dart
  /// final userData = user.toMap();
  /// await supabase.from('users').insert(userData);
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username
          .toLowerCase(), // Store lowercase for case-insensitive search
      'usernameDisplay': username, // Original casing for display
      'email': email.toLowerCase(),
      'displayName': displayName,
      'photoURL': photoURL,
      'coverPhotoUrl': coverPhotoUrl,
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
      'hasStories': hasStories,
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
      coverPhotoUrl: map['coverPhotoUrl'] ?? map['cover_photo_url'],
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
      showActivityStatus:
          map['showActivityStatus'] ?? map['show_activity_status'] ?? true,
      allowMessagesFromEveryone:
          map['allowMessagesFromEveryone'] ??
          map['allow_messages_from_everyone'] ??
          false,
      hasStories: map['hasStories'] ?? map['has_stories'] ?? false,
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
    String? coverPhotoUrl,
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
    bool? hasStories,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
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
      allowMessagesFromEveryone:
          allowMessagesFromEveryone ?? this.allowMessagesFromEveryone,
      hasStories: hasStories ?? this.hasStories,
    );
  }
}
