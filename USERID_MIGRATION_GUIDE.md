# PostModel userId Migration Guide

## Overview
The PostModel now requires a `userId` field to identify the post owner. This enables proper authentication checks like "isOwnPost" functionality.

## Files That Need Updates

### 1. `lib/features/explore/explore_page.dart`
**Line 1013** and **Line 1448** - Two PostModel instantiations

### 2. `lib/features/explore/explore_search_page.dart`
**Line 831** - One PostModel instantiation

### 3. `lib/features/home/widgets/post_card.dart`
**Line 383** - One PostModel instantiation

### 4. `lib/features/profile/other_user_profile_page.dart`
**Line 769** - One PostModel instantiation

### 5. `lib/features/profile/pages/profile_posts_grid_demo.dart`
**Line 34** - One PostModel instantiation

### 6. `lib/features/profile/profile_page.dart`
**Line 852** - One PostModel instantiation

---

## Quick Fix Pattern

### Before:
```dart
PostModel(
  id: 'post123',
  type: PostType.image,
  mediaUrls: ['url'],
  thumbnailUrl: 'url',
  username: 'john_doe',
  userAvatar: 'avatar_url',
  timestamp: DateTime.now(),
  // ... other fields
)
```

### After:
```dart
PostModel(
  id: 'post123',
  userId: 'user123', // ADD THIS - use actual user ID
  type: PostType.image,
  mediaUrls: ['url'],
  thumbnailUrl: 'url',
  username: 'john_doe',
  userAvatar: 'avatar_url',
  timestamp: DateTime.now(),
  // ... other fields
)
```

---

## Where to Get userId

### Option 1: From AuthProvider (Current User)
```dart
import 'package:provider/provider.dart';
import 'package:sync_up/core/providers/auth_provider.dart';

// In build method or where you have context:
final authProvider = context.read<AuthProvider>();
final userId = authProvider.currentUserId ?? 'anonymous';

PostModel(
  id: postId,
  userId: userId, // Use current user's ID
  // ...
)
```

### Option 2: From Existing User Data
If you already have user information:
```dart
PostModel(
  id: postId,
  userId: currentUser.uid, // From UserModel
  // ...
)
```

### Option 3: From Post Data (When Converting)
If converting from another post model:
```dart
// In post_card.dart example:
final profilePost = profile_post.PostModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  userId: 'user_${post.userHandle}', // Generate or extract from existing data
  // ...
);
```

### Option 4: Placeholder for Demo Data
For sample/demo posts:
```dart
PostModel(
  id: 'demo_post_$i',
  userId: 'demo_user_$i', // Use consistent demo IDs
  // ...
)
```

---

## Automated Fix Command

Run this to find all locations:
```bash
grep -n "PostModel(" lib/**/*.dart | grep -v "userId:"
```

---

## Example Fixes

### For profile_page.dart:
```dart
// Around line 852
PostModel(
  id: 'user-post-$i',
  userId: widget.userId, // Use the profile owner's ID
  type: PostType.image,
  // ...
)
```

### For explore_page.dart:
```dart
// Around line 1013
PostModel(
  id: 'explore-${DateTime.now().millisecondsSinceEpoch}',
  userId: trendingPosts[widget.initialIndex].userId, // From source data
  type: PostType.image,
  // ...
)
```

### For post_card.dart (home feed):
```dart
// Around line 383
final profilePost = profile_post.PostModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  userId: post.userHandle, // Or fetch from backend
  // ...
)
```

---

## Testing After Migration

1. **Check compilation:**
   ```bash
   flutter analyze
   ```

2. **Test in post viewer:**
   - Your own posts should show "Edit", "Delete", "Archive" options
   - Others' posts should show "Follow", "Report", "Block" options

3. **Test authentication:**
   - Sign in and create a post
   - View post in viewer - should see owner options
   - Sign out and view same post - should see visitor options

---

## Helper Function (Optional)

Add this to your widget/service to make it easier:

```dart
String _getUserIdForPost(String username, String userHandle) {
  // TODO: Replace with actual user lookup
  // For now, generate consistent ID from handle
  return 'user_${userHandle.replaceAll('@', '')}';
}

// Usage:
PostModel(
  id: postId,
  userId: _getUserIdForPost(post.userName, post.userHandle),
  // ...
)
```

---

## Recommendation

**Best approach for now:**
1. For user's own posts: Use `AuthProvider.currentUserId`
2. For other users' posts: Use a consistent ID based on their username/handle
3. Update to real user IDs when backend user system is implemented

This will make the app work correctly now and be easy to update later!
