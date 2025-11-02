# 🚀 App Improvement Implementation Plan

## ✅ Completed Tasks

### 1. Cleanup
- ✅ Removed 34 tutorial/guide MD files
- ✅ Cleaned up project root directory

---

## 🔄 In Progress / To Do

### 2. Remove All Hardcoded Data
**Priority: HIGH** 🔥

**What to Remove:**
- Hardcoded posts in home feed
- Hardcoded stories
- Hardcoded comments
- Hardcoded likes/replies
- Sample user data

**Files to Update:**
- `lib/features/home/pages/for_you_page.dart`
- `lib/features/home/pages/following_page.dart`
- `lib/features/home/pages/trending_page.dart`
- `lib/features/home/pages/live_page.dart`
- Any component with sample data

---

### 3. Fix Post Persistence
**Priority: CRITICAL** 🔥🔥🔥

**Issue:** Posts don't show properly after closing and reopening app

**Root Cause Analysis Needed:**
- Check PostProvider state management
- Verify database queries
- Check stream subscriptions
- Verify data loading on app start

**Files to Check:**
- `lib/core/providers/post_provider.dart`
- `lib/core/services/post_fetch_service.dart`
- `lib/features/home/home_page.dart`

---

### 4. Hide Own Posts from Home Feed
**Priority: HIGH** 🔥

**Implementation:**
```dart
// In post_fetch_service.dart
Stream<List<PostModel>> getForYouPosts(String currentUserId) {
  return _firestore
    .collection('posts')
    .where('userId', isNotEqualTo: currentUserId) // Filter out own posts
    .orderBy('timestamp', descending: true)
    .snapshots();
}
```

**Reason:** Users shouldn't see their own posts in discover feeds (can't block/report self)

---

### 5. Implement Real Interactions
**Priority: HIGH** 🔥

**Features to Implement:**

#### A. Like Button
- Real-time like count
- Toggle like/unlike
- Update database
- Optimistic UI updates

#### B. Comment Button
- Open comment sheet
- Add new comments
- Display comment count
- Real-time updates

#### C. Follow Button
- Show in other user profiles
- Toggle follow/unfollow
- Update follower counts
- Hide on own profile

**Files to Update:**
- Post viewer components
- Profile pages
- Database services

---

### 6. Implement Search
**Priority: MEDIUM** 🟡

**Search Types:**

#### A. User Search
- Search by username
- Search by full name
- Show profile preview
- Navigate to profile

#### B. Post Search
- Search by caption/hashtags
- Filter by post type
- Show grid view
- Tap to view full post

#### C. Reels Search
- Search reel captions
- Video thumbnails
- Play on tap

**Implementation:**
```dart
// Search page with tabs
- Users tab
- Posts tab
- Reels tab
```

---

### 7. User Actions Menu
**Priority: HIGH** 🔥

**Features in Post Viewer:**

#### A. Report User
- Report options (spam, inappropriate, etc.)
- Submit to moderation
- Confirm dialog

#### B. Block User
- Hide all their content
- Prevent interactions
- Update database
- Confirm dialog

#### C. Mute User
- Hide posts temporarily
- Can unmute later
- No notification to them

#### D. Unfollow
- Stop following
- Update counts
- Quick action

#### E. "Why am I seeing this?"
- Explain algorithm
- "You follow this person"
- "Based on your interests"
- "Popular in your area"

**UI:** Three-dot menu in post viewer

---

### 8. Live Now Feature
**Priority: MEDIUM** 🟡

**Changes:**

#### A. Story Labels
```dart
// Add "Live Now" label to stories
if (story.isLive) {
  // Show pulsing red badge
  // "LIVE" text
  // Animate border
}
```

#### B. Remove Lives Section
- Remove entire live feed tab/section
- Clean up navigation
- Remove live-related imports

#### C. Add Create Live Button
```dart
// Add + icon in RED color
- Position: Near stories
- Icon: Add icon with red background
- Tap: Navigate to create_live_page.dart
- Style: Pulsing animation
```

---

## 📁 Files to Create

### New Features

1. **`lib/features/search/search_page.dart`**
   - Tabbed search interface
   - Users, Posts, Reels tabs

2. **`lib/features/search/widgets/user_search_result.dart`**
   - User search result item

3. **`lib/features/search/widgets/post_search_result.dart`**
   - Post search result grid

4. **`lib/features/posts/widgets/post_actions_menu.dart`**
   - Report, Block, Mute, Unfollow options

5. **`lib/features/live/create_live_page.dart`**
   - Create/start live stream

### Services

6. **`lib/core/services/search_service.dart`**
   - Search logic for users/posts/reels

7. **`lib/core/services/moderation_service.dart`**
   - Report/block/mute logic

---

## 🗄️ Database Changes

### New Tables/Fields

```sql
-- Add to users table
ALTER TABLE users ADD COLUMN blocked_users TEXT[];
ALTER TABLE users ADD COLUMN muted_users TEXT[];

-- Create reports table
CREATE TABLE reports (
  id TEXT PRIMARY KEY,
  reporter_id TEXT NOT NULL,
  reported_user_id TEXT,
  reported_post_id TEXT,
  reason TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for search
CREATE INDEX idx_users_username_search ON users USING gin(username gin_trgm_ops);
CREATE INDEX idx_users_display_name_search ON users USING gin(display_name gin_trgm_ops);
CREATE INDEX idx_posts_caption_search ON posts USING gin(caption gin_trgm_ops);
```

---

## 🎯 Implementation Order

### Phase 1: Critical Fixes (Do First)
1. ✅ Fix post persistence issue
2. ✅ Remove hardcoded data
3. ✅ Hide own posts from feed

### Phase 2: Core Features
4. ✅ Implement real like/comment/follow
5. ✅ Add user actions menu

### Phase 3: Enhancement
6. ✅ Implement search
7. ✅ Add Live Now feature

---

## 📝 Testing Checklist

### Post Persistence
- [ ] Create post
- [ ] Close app completely
- [ ] Reopen app
- [ ] Posts should appear immediately
- [ ] No blank screen
- [ ] Loading indicator shows properly

### Own Posts Hidden
- [ ] Create some posts
- [ ] Go to home feed
- [ ] Should NOT see own posts
- [ ] Profile page should show own posts

### Real Interactions
- [ ] Like post (updates count)
- [ ] Unlike post (count decreases)
- [ ] Comment on post (shows in list)
- [ ] Follow user (button changes)
- [ ] Unfollow user (button reverts)

### Search
- [ ] Search for username (finds users)
- [ ] Search for full name (finds users)
- [ ] Search for post caption (finds posts)
- [ ] Search for reel (finds videos)
- [ ] Tap result navigates correctly

### User Actions
- [ ] Report user (submits successfully)
- [ ] Block user (hides content)
- [ ] Mute user (temporarily hides)
- [ ] Unfollow works
- [ ] "Why am I seeing this" shows info

### Live Now
- [ ] Stories show "LIVE" badge when active
- [ ] Lives section removed from home
- [ ] + icon appears in red
- [ ] Tapping + opens create live page

---

## ⚠️ Important Notes

1. **Data Cleanup**: Remove ALL hardcoded arrays of posts, stories, users
2. **State Management**: Ensure proper Provider usage
3. **Error Handling**: Add try-catch blocks
4. **Loading States**: Show spinners while loading
5. **Empty States**: Show helpful messages when no data
6. **Optimistic Updates**: Update UI immediately, then sync with DB
7. **Offline Support**: Cache data for better UX

---

## 🚀 Let's Start Implementation!

This file serves as the master plan. Each task will be implemented systematically.
