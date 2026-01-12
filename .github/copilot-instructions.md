# SyncUp - AI Agent Instructions

## Project Overview
**SyncUp** is a Flutter 3.9.2 social media app (TikTok/Instagram hybrid) with Supabase backend. Feature-based architecture with core infrastructure separation.

**Last Updated**: January 2026

## Critical Architectural Patterns

### 1. Supabase as Single Source of Truth
- **Authentication**: `Supabase.instance.client.auth` with PKCE flow
- **Database**: Direct table access via `.from('table_name')` queries (NOT Firestore)
- **Storage**: Buckets defined in `lib/core/config/supabase_config.dart`
- **Migration Status**: ✅ Firebase to Supabase migration complete. All features now use Supabase exclusively.

```dart
// CORRECT - Supabase query pattern
final result = await Supabase.instance.client
    .from('users')
    .select()
    .eq('username', username.toLowerCase())
    .maybeSingle();

// WRONG - Don't use Firestore patterns
// FirebaseFirestore.instance.collection('users')...
```

### 2. State Management: Provider + Global Keys
- **Provider**: Used for app-wide state (`AuthProvider`, `PostProvider` in `main.dart`)
- **Global Keys**: Cross-feature communication pattern for pages needing external state access

**Global Key Pattern (CRITICAL):**
```dart
// 1. Declare global key at file top (outside class)
final GlobalKey<_ReelsPageNewState> reelsPageKey = GlobalKey<_ReelsPageNewState>();

// 2. Attach to widget
ReelsPageNew(key: reelsPageKey)

// 3. Access state from anywhere
reelsPageKey.currentState?.refreshReels()
```

**Current Global Keys:**
- `reelsPageKey` → `ReelsPageNew` (active implementation)
- `reelFeedPageKey` → `ReelFeedPage` (legacy, not routed)
- `_rootNavigatorKey` → Router navigation

**When to use:**
- Double-tap refresh from nav bar
- External navigation with state initialization
- Cross-feature method calls

### 3. Navigation: GoRouter + ShellRoute
**Structure:**
```dart
// lib/core/app_router.dart
GoRouter(
  navigatorKey: _rootNavigatorKey,
  routes: [
    // Standalone pages (auth, chat, edit profile)
    GoRoute(path: '/signin', builder: ...),
    
    // Pages WITH nav bar (wrapped in ScaffoldWithNavBar)
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/home', builder: ...),
        GoRoute(path: '/reels', builder: (_, __) => ReelsPageNew(key: reelsPageKey)),
      ],
    ),
  ],
)
```

**Navigation Methods:**
- `context.go('/path')` - Replace current page
- `context.push('/path')` - Stack navigation
- `Navigator.push(context, MaterialPageRoute(...))` - For pages needing return values

### 4. Dynamic Nav Bar Visibility
**Pattern for immersive experiences (reels, stories, post viewers):**
```dart
// 1. Get notifier from context
final navVisibility = NavBarVisibilityScope.maybeOf(context);

// 2. Hide nav bar
navVisibility?.value = false;

// 3. Restore on dispose/pop
@override
void dispose() {
  navVisibility?.value = true;
  super.dispose();
}
```

**Where:** `ReelsPageNew`, post viewers, story viewers, profile scroll handlers

### 5. Feature Module Structure
```
lib/features/<feature_name>/
  <feature_name>_page.dart       # Main page
  widgets/                        # Feature-specific widgets
  pages/                          # Sub-pages
  models/                         # Local models (if any)
```

**Shared Resources:**
- `lib/core/models/` - Data models (`UserModel`, `ReelModel`)
- `lib/core/services/` - Business logic (`DatabaseService`, `ReelService`, `PostService`)
- `lib/core/providers/` - Global state
- `lib/core/widgets/` - Reusable UI components

### 6. Database Service Pattern
```dart
// lib/core/services/<entity>_service.dart
class ReelService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<List<ReelModel>> getReels() async {
    final data = await _supabase
        .from('reels')
        .select('*, users(username, photo_url)')  // Join users table
        .order('created_at', ascending: false)
        .limit(20);
    
    return data.map((json) => ReelModel.fromMap(json)).toList();
  }
}
```

**Join Pattern:** Use Supabase's `select('*, related_table(columns)')` for foreign keys.

### 7. Model Conventions
**Field Naming (IMPORTANT):**
- **Supabase DB:** `snake_case` (e.g., `user_id`, `created_at`)
- **Dart Models:** `camelCase` (e.g., `userId`, `createdAt`)
- **fromMap():** Handle BOTH naming conventions for backward compatibility

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

### 8. Media Handling Workflow
**Video Upload (Reels):**
1. Pick video → `ImagePickerService.pickVideo()`
2. Compress → `VideoService.compressVideo()`
3. Generate thumbnail → `VideoService.generateThumbnail()`
4. Upload to Supabase Storage → `SupabaseStorageService.uploadVideo()`
5. Save metadata → `ReelService.createReel()`

**Storage Buckets (see `lib/core/config/supabase_config.dart`):**
- `profile-photos` - User profile/cover photos
- `posts` - Post images/videos
- `stories` - Story media

### 9. Theme System
- Dark/Light modes via `ThemeMode.system`
- Glassmorphism: `BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20))`
- App colors: `AppColors.primary`, `AppColors.secondary` (defined in `lib/core/theme.dart`)

## Common Pitfalls

### ❌ DON'T:
1. Use Firestore patterns (`collection()`, `doc()`, `get()`, `set()`)
2. Create features outside `lib/features/` or core logic outside `lib/core/`
3. Mutate state directly - use `notifyListeners()` in providers
4. Forget to handle both `camelCase` and `snake_case` in `fromMap()`
5. Use `context.go()` for pages needing return values (use `Navigator.push()`)

### ✅ DO:
1. Use Supabase client: `Supabase.instance.client.from('table')`
2. Check for existing services before creating new ones
3. Use global keys for cross-feature state access (pattern above)
4. Handle `maybeOf()` null returns for `NavBarVisibilityScope`
5. Follow service pattern: one service per entity (`UserService`, `PostService`)

## Key Files to Reference

### Core Infrastructure
- `lib/main.dart` - App entry, Supabase init, providers
- `lib/core/app_router.dart` - All routes, ShellRoute pattern
- `lib/core/scaffold_with_nav_bar.dart` - Nav bar wrapper, visibility scope
- `lib/core/theme.dart` - Theme configuration

### Services (Business Logic)
- `lib/core/services/database_service.dart` - User CRUD operations
- `lib/core/services/reel_service.dart` - Reel fetching/creation
- `lib/core/services/post_service.dart` - Post operations
- `lib/core/services/supabase_storage_service.dart` - File uploads

### Active Feature Implementations
- `lib/features/reels/reels_page_new.dart` - PRIMARY reel feed (global key: `reelsPageKey`)
  - **Creator Mode**: Automatically detects when user views their own reel
  - Shows "Your Reel" badge, insights, edit/delete controls
  - Uses `_isOwnReel()` to check: `reel.userId == currentUser.id`
- `lib/features/reels/widgets/creator_control_bar.dart` - Creator controls (edit, insights, share, delete)
- `lib/features/reels/widgets/creator_insights_sheet.dart` - Analytics dashboard for own reels
- `lib/features/reels/widgets/edit_reel_sheet.dart` - Edit caption, cover, privacy settings
- `lib/features/home/widgets/animated_nav_bar.dart` - Bottom nav bar
- `lib/features/profile/profile_page.dart` - User profile with posts/reels grid
  - Navigates to ReelsPageNew with `isOwnProfile: true` for own reels

### Models
- `lib/core/models/user_model.dart` - User entity
- `lib/core/models/reel_model.dart` - Reel/video entity

## Development Commands

```powershell
# Run app
flutter run

# Build
flutter build apk --release

# Clean build
flutter clean ; flutter pub get

# Generate code (if using freezed/json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Supabase Database Schema (Key Tables)

**users**: `uid`, `username`, `usernameDisplay`, `email`, `photo_url`, `cover_photo_url`, `bio`, `followers_count`, `following_count`, `created_at`

**reels**: `id`, `user_id`, `video_url`, `thumbnail_url`, `caption`, `likes_count`, `comments_count`, `views_count`, `duration`, `created_at`

**posts**: Similar to reels but for standard feed posts (images/videos)

## Authentication Flow
1. Sign up → `SignUpPage` → OTP verification → Profile setup
2. Auth state → `AuthProvider` listens to `Supabase.instance.client.auth.onAuthStateChange`
3. User data → Fetched from `users` table via `DatabaseService.getUserByUid()`

## Project-Specific Conventions

1. **Lowercase Usernames:** Store `username` as lowercase, `usernameDisplay` for original casing
2. **Global Key Naming:** `<feature>PageKey` pattern (e.g., `reelsPageKey`)
3. **Service Singletons:** Services don't need providers, instantiate directly in widgets
4. **Error Handling:** Print errors with context: `print('Error creating user: $e')`
5. **Widget Keys:** Use `key: reelsPageKey` in route definitions for stateful pages needing external access
6. **Creator Mode Detection:** Check `reel.userId == Supabase.instance.client.auth.currentUser?.id` to enable owner features
7. **Reel Navigation:** Profile → ReelsPageNew with `isOwnProfile: true, userId: userId, initialUserReels: reels`

---

**When in doubt:**
- Check existing service implementations in `lib/core/services/`
- Reference `ReelsPageNew` for complex page patterns (global keys, nav bar hiding, gestures)
- Look at `DatabaseService` for Supabase query patterns
- Review `app_router.dart` for navigation structure
