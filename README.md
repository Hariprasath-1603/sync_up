# 🎬 SyncUp - Social Media Application

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue.svg)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()
[![Last Updated](https://img.shields.io/badge/Last%20Updated-January%202026-brightgreen.svg)]()

A modern, feature-rich social media application built with Flutter, combining the best aspects of TikTok and Instagram. SyncUp offers an immersive video-sharing experience with reels, stories, posts, live streaming, and real-time messaging.

---

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Core Concepts](#core-concepts)
- [Database Schema](#database-schema)
- [Development Guidelines](#development-guidelines)

---

## 🎯 Overview

**SyncUp** is a hybrid social media platform that enables users to:
- Create and share short-form video content (Reels)
- Post photos and videos to their feed
- Share temporary stories (24-hour content)
- Follow and interact with other users
- Live stream to their audience
- Send direct messages
- Explore trending content

### Current Status
- ✅ Core architecture established
- ✅ Supabase backend integration
- ✅ Migration from Firebase to Supabase complete
- ✅ Authentication system with PKCE flow
- ✅ Reel creation and viewing system
- ✅ Enhanced story viewer with gesture controls
- ✅ Dynamic story row with real-time updates
- ✅ User profiles and social features
- ✅ Storage optimization for reels and stories
- 🔄 Actively developing live streaming features

---

## ✨ Features

### User Features
- **Authentication**
  - Email/Password signup with OTP verification
  - Google Sign-In integration
  - Password reset functionality
  - Secure PKCE authentication flow

- **Content Creation**
  - 📹 Reels: Short-form vertical videos with editing tools
  - 📸 Posts: Photo and video sharing with captions
  - 📱 Stories: Temporary 24-hour content
  - 🎥 Live Streaming: Real-time broadcasting
  - Camera integration with filters and effects

- **Social Interactions**
  - Follow/Unfollow users
  - Like, comment, and share content
  - Save favorite posts and reels
  - View counts and engagement metrics
  - Real-time notifications

- **User Profiles**
  - Customizable profile and cover photos
  - Bio and personal information
  - Grid view of posts and reels
  - Follower/Following management
  - Activity status and privacy settings

- **Discovery**
  - Explore page with trending content
  - Search users, posts, and reels
  - Algorithmic content recommendations
  - Hashtag and topic-based discovery

- **Communication**
  - Direct messaging
  - Group chats (planned)
  - Message notifications

### Creator Features
- **Reel Analytics**
  - View counts and engagement metrics
  - Viewer insights
  - Performance tracking
  - Edit and delete own reels

- **Content Management**
  - Draft saving
  - Post scheduling (planned)
  - Content moderation tools
  - Archive functionality

---

## 🏗️ Architecture

SyncUp follows a **feature-based architecture** with clear separation of concerns:

### Core Principles

#### 1. **Supabase as Single Source of Truth**
All data operations flow through Supabase:
- **Authentication**: `Supabase.instance.client.auth` with PKCE flow
- **Database**: PostgreSQL with direct table queries
- **Storage**: Object storage for media files
- **Real-time**: WebSocket subscriptions for live updates

```dart
// Example: Supabase query pattern
final result = await Supabase.instance.client
    .from('users')
    .select()
    .eq('username', username.toLowerCase())
    .maybeSingle();
```

#### 2. **State Management: Provider + Global Keys**
- **Provider**: App-wide state management (`AuthProvider`, `PostProvider`)
- **Global Keys**: Cross-feature communication for complex widgets

```dart
// Global key pattern for external state access
final GlobalKey<_ReelsPageNewState> reelsPageKey = GlobalKey();

// Usage in router
ReelsPageNew(key: reelsPageKey)

// External access
reelsPageKey.currentState?.refreshReels()
```

#### 3. **Navigation: GoRouter with ShellRoute**
Declarative routing with nested navigation:
- Standalone pages (auth, chat, settings)
- Pages with navigation bar (home, reels, explore, profile)
- Dynamic route parameters
- Deep linking support

#### 4. **Service Pattern**
Business logic separated into dedicated services:
- One service per domain entity
- Supabase client integration
- Error handling and validation
- Caching where appropriate

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.9.2
- **Language**: Dart 3.9.2
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI Libraries**:
  - Google Fonts
  - Lottie (animations)
  - Shimmer (loading effects)
  - Flutter Animate

### Backend
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth (PKCE flow)
- **Storage**: Supabase Storage
- **Real-time**: Supabase Real-time subscriptions

### Media Processing
- **Camera**: `camera` package
- **Image**: `image_picker`, `image_cropper`, `cached_network_image`
- **Video**: `video_player`, `video_compress`, `video_thumbnail`, `chewie`
- **Audio**: `just_audio`

### Additional Services
- Google Sign-In
- Push Notifications
- Haptic Feedback
- Share functionality
- Local Persistence (SharedPreferences)

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point, providers, Supabase initialization
│
├── core/                          # Core infrastructure and shared code
│   ├── app_router.dart           # GoRouter configuration
│   ├── scaffold_with_nav_bar.dart # Navigation bar wrapper
│   ├── theme.dart                # App theming (dark/light mode)
│   │
│   ├── config/                   # Configuration files
│   │   └── supabase_config.dart  # Supabase credentials and settings
│   │
│   ├── models/                   # Data models
│   │   ├── user_model.dart       # User entity
│   │   ├── reel_model.dart       # Reel/video entity
│   │   └── reel_draft.dart       # Draft reel storage
│   │
│   ├── services/                 # Business logic layer
│   │   ├── database_service.dart           # User CRUD operations
│   │   ├── reel_service.dart              # Reel operations
│   │   ├── post_service.dart              # Post operations
│   │   ├── story_service.dart             # Story operations
│   │   ├── follow_service.dart            # Follow/unfollow logic
│   │   ├── comment_service.dart           # Comment management
│   │   ├── interaction_service.dart       # Likes, saves, shares
│   │   ├── search_service.dart            # Search functionality
│   │   ├── supabase_storage_service.dart  # File uploads
│   │   ├── video_service.dart             # Video processing
│   │   ├── image_picker_service.dart      # Image selection
│   │   └── ...
│   │
│   ├── providers/                # Global state management
│   │   ├── auth_provider.dart    # Authentication state
│   │   └── post_provider.dart    # Post state
│   │
│   ├── widgets/                  # Reusable UI components
│   │   └── ...
│   │
│   └── utils/                    # Helper functions and utilities
│       └── ...
│
└── features/                     # Feature modules
    ├── auth/                     # Authentication (sign in, sign up, OTP)
    ├── home/                     # Home feed with posts
    ├── reels/                    # Reels feed and creation
    │   ├── reels_page_new.dart   # Primary reel feed (with global key)
    │   └── widgets/              # Reel-specific widgets
    ├── stories/                  # Story creation and viewing
    ├── profile/                  # User profiles
    ├── explore/                  # Discovery and trending
    ├── chat/                     # Direct messaging
    ├── notifications/            # Notification center
    ├── settings/                 # App settings
    ├── add/                      # Content creation hub
    ├── live/                     # Live streaming
    ├── posts/                    # Post creation and viewing
    ├── onboarding/               # First-time user experience
    └── splash/                   # Splash screen
```

### Feature Module Structure
Each feature follows a consistent pattern:
```
feature/
├── feature_page.dart             # Main entry point
├── widgets/                      # Feature-specific widgets
└── pages/                        # Sub-pages
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK (3.9.2 or higher)
- Android Studio / Xcode (for mobile development)
- Supabase account and project

### Installation

1. **Clone the repository**
   ```powershell
   git clone <repository-url>
   cd sync_up
   ```

2. **Install dependencies**
   ```powershell
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project
   - Update `lib/core/config/supabase_config.dart` with your credentials:
     ```dart
     class SupabaseConfig {
       static const String supabaseUrl = 'YOUR_SUPABASE_URL';
       static const String supabaseAnonKey = 'YOUR_ANON_KEY';
     }
     ```

4. **Set up database**
   - Run migrations in `database_migrations/` directory
   - Configure storage buckets (profile-photos, posts, stories, reels)

5. **Configure Android**
   - Add `google-services.json` to `android/app/`
   - Update `key.properties` (see `key.properties.example`)

6. **Run the app**
   ```powershell
   flutter run
   ```

### Build Commands
```powershell
# Run in debug mode
flutter run

# Build APK
flutter build apk --release

# Clean build
flutter clean
flutter pub get

# Run tests
flutter test
```

---

## 💡 Core Concepts

### 1. Supabase Query Pattern
All database queries follow this pattern:
```dart
// Select with join
final data = await Supabase.instance.client
    .from('reels')
    .select('*, users(username, photo_url)')  // Join users table
    .order('created_at', ascending: false)
    .limit(20);
```

### 2. Model Naming Conventions
- **Database columns**: `snake_case` (e.g., `user_id`, `created_at`)
- **Dart properties**: `camelCase` (e.g., `userId`, `createdAt`)
- **fromMap()**: Must handle BOTH conventions for compatibility

```dart
factory UserModel.fromMap(Map<String, dynamic> map) {
  return UserModel(
    username: map['usernameDisplay'] ?? map['username_display'] ?? map['username'],
    createdAt: map['createdAt'] != null 
        ? DateTime.parse(map['createdAt'])
        : map['created_at'] != null
        ? DateTime.parse(map['created_at'])
        : DateTime.now(),
  );
}
```

### 3. Authentication Flow
1. User signs up → OTP verification
2. Profile setup (photo, bio)
3. `AuthProvider` listens to `onAuthStateChange`
4. User data fetched from `users` table

### 4. Media Upload Workflow
**Video (Reels):**
1. Pick video → `ImagePickerService.pickVideo()`
2. Compress → `VideoService.compressVideo()`
3. Generate thumbnail → `VideoService.generateThumbnail()`
4. Upload to Supabase Storage → `SupabaseStorageService.uploadVideo()`
5. Save metadata → `ReelService.createReel()`

### 5. Navigation Bar Visibility
For immersive experiences (reels, stories), dynamically hide nav bar:
```dart
final navVisibility = NavBarVisibilityScope.maybeOf(context);
navVisibility?.value = false; // Hide

@override
void dispose() {
  navVisibility?.value = true; // Restore
  super.dispose();
}
```

### 6. Creator Mode Detection
Reels automatically detect when viewing own content:
```dart
bool _isOwnReel() {
  return reel.userId == Supabase.instance.client.auth.currentUser?.id;
}
```
Shows: "Your Reel" badge, insights, edit/delete controls

---

## 🗄️ Database Schema

### Key Tables

#### **users**
```sql
- uid: UUID (primary key)
- username: TEXT (lowercase, unique)
- usernameDisplay: TEXT (original casing)
- email: TEXT (unique)
- photo_url: TEXT
- cover_photo_url: TEXT
- bio: TEXT
- followers_count: INTEGER
- following_count: INTEGER
- posts_count: INTEGER
- created_at: TIMESTAMP
```

#### **reels**
```sql
- id: UUID (primary key)
- user_id: UUID (foreign key → users)
- video_url: TEXT
- thumbnail_url: TEXT
- caption: TEXT
- likes_count: INTEGER
- comments_count: INTEGER
- views_count: INTEGER
- shares_count: INTEGER
- duration: INTEGER (seconds)
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

#### **posts**
```sql
- id: UUID (primary key)
- user_id: UUID (foreign key → users)
- media_url: TEXT
- media_type: TEXT (image/video)
- caption: TEXT
- likes_count: INTEGER
- comments_count: INTEGER
- shares_count: INTEGER
- created_at: TIMESTAMP
- is_archived: BOOLEAN
```

#### **stories**
```sql
- id: UUID (primary key)
- user_id: UUID (foreign key → users)
- media_url: TEXT
- media_type: TEXT
- duration: INTEGER
- views_count: INTEGER
- created_at: TIMESTAMP
- expires_at: TIMESTAMP
```

### Storage Buckets
- **profile-photos**: User profile and cover images
- **posts**: Post media files
- **stories**: Story media files
- **reels**: Reel video files

---

## 📝 Development Guidelines

### Code Style
- Follow Dart style guidelines
- Use meaningful variable names
- Comment complex logic
- Keep functions small and focused

### Common Patterns

#### ❌ DON'T:
- Use Firestore patterns (`collection()`, `doc()`)
- Create features outside `lib/features/`
- Mutate state without `notifyListeners()`
- Use `context.go()` for pages needing return values

#### ✅ DO:
- Use Supabase client for all database operations
- Check for existing services before creating new ones
- Use global keys for cross-feature state access
- Handle both `camelCase` and `snake_case` in models
- Follow the service pattern (one service per entity)

### Testing
- Write unit tests for services
- Test authentication flows
- Validate data models
- Test edge cases

### Error Handling
```dart
try {
  // Operation
} catch (e) {
  print('Error context: $e');
  // User feedback
}
```

---

## 📚 Additional Resources

### Key Files Reference
- [main.dart](lib/main.dart) - App initialization
- [app_router.dart](lib/core/app_router.dart) - Route configuration
- [reels_page_new.dart](lib/features/reels/reels_page_new.dart) - Primary reel feed
- [database_service.dart](lib/core/services/database_service.dart) - User operations

### Documentation
- [Copilot Instructions](.github/copilot-instructions.md) - AI agent guidelines
- [Story Viewer Documentation](STORY_VIEWER_V2_COMPLETE.md)
- [Database Migrations](database_migrations/)

---

## 🤝 Contributing

This is a private project. For authorized contributors:
1. Follow the architectural patterns
2. Test thoroughly before committing
3. Update documentation for new features
4. Follow the code style guidelines

---

## 📄 License

Private - All rights reserved

---

## 🔮 Roadmap

### In Progress
- [x] Complete Firebase → Supabase migration
- [x] Enhanced reel analytics
- [ ] Live streaming features
- [ ] Group messaging

### Planned
- [ ] Content monetization
- [ ] Advanced video editing
- [ ] AI-powered recommendations
- [ ] Multi-language support
- [ ] Web platform support

---

## 📞 Support

For issues or questions:
- Check existing documentation
- Review [Copilot Instructions](.github/copilot-instructions.md)
- Contact the development team

---

**Built with ❤️ using Flutter and Supabase**
