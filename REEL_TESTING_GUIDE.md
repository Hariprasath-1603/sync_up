# 🚀 Quick Start Guide - Testing Reel System

## Prerequisites Checklist

Before testing, ensure:
- ✅ All packages installed (`flutter pub get`)
- ✅ Supabase tables created (reels, reel_likes, reel_comments, reel_shares)
- ✅ Storage bucket `reels` exists with public read access
- ✅ User authenticated in the app

---

## 1. Test Reel Upload ✅

**Current Status:** Already working! You confirmed reels upload successfully.

**What happens:**
1. Record video using camera
2. Video uploads to Supabase storage
3. Thumbnail generated automatically
4. Metadata saved to `reels` table
5. Success message displayed

**Files involved:**
- `lib/features/add/reel_create_page.dart` (upload UI)
- `lib/core/services/reel_service.dart` (upload logic)

---

## 2. Test Reel Feed 🎥

### A. Open Global Feed

**Navigation:**
```dart
// From anywhere in app
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ReelFeedPage(),
  ),
);
```

**Expected behavior:**
- ✅ Shows vertical scrolling feed
- ✅ Reels auto-play when visible
- ✅ Swipe up/down to navigate
- ✅ Like, comment, share buttons visible
- ✅ Back button in top-left corner

**Test steps:**
1. Open app
2. Navigate to Reels tab (if available) OR use the navigation code above
3. Should see uploaded reels in vertical feed
4. Swipe up to next reel
5. Tap video to pause/play
6. Double-tap to like (heart animation appears)

### B. Test Video Playback

**Expected behavior:**
- ✅ Video starts playing immediately
- ✅ Progress indicator at bottom
- ✅ Pauses when scrolled away
- ✅ Resumes when scrolled back
- ✅ Loops automatically
- ✅ Tap to pause/play

**Troubleshooting:**
- If video doesn't play: Check video URL is publicly accessible
- If error appears: Tap "Retry" button
- If loading forever: Check network connection

---

## 3. Test Profile Reels Tab 👤

### A. Navigate to Profile

**Steps:**
1. Tap Profile icon in bottom navigation
2. Should see 3 tabs: "Posts", "Reels", "Media"
3. Tap "Reels" tab

**Expected behavior:**
- ✅ Shows grid of 3 columns
- ✅ Each reel has:
  - Thumbnail image
  - "REEL" badge (gradient) at bottom center
  - Play icon with duration at top-left
  - View count at bottom-right
- ✅ Empty state if no reels: "No reels yet" message

### B. Open Reel from Profile

**Steps:**
1. Tap any reel in grid
2. Should open `ReelFeedPage`
3. Starts playing from tapped reel
4. Can swipe to see other reels from this user

**Expected behavior:**
- ✅ Smooth transition to full-screen
- ✅ Video starts playing immediately
- ✅ Shows only this user's reels
- ✅ Can navigate back to profile

---

## 4. Test Like Feature ❤️

### A. Single Tap Like

**Steps:**
1. Open reel feed
2. Tap heart button on right side
3. Heart should turn red
4. Like count increases by 1

**Expected behavior:**
- ✅ Immediate UI update (optimistic)
- ✅ Heart icon turns red
- ✅ Count increments instantly
- ✅ Backend sync happens in background

**Verify in Supabase:**
```sql
SELECT * FROM reel_likes WHERE user_id = 'YOUR_USER_ID';
```

### B. Double Tap Like

**Steps:**
1. Open reel feed
2. Double-tap center of video
3. Large heart animation appears
4. Reel is liked

**Expected behavior:**
- ✅ Heart animation scales up and fades out
- ✅ Like button turns red
- ✅ Count increments
- ✅ Animation lasts ~600ms

### C. Unlike

**Steps:**
1. Tap heart button again
2. Heart turns white
3. Count decreases by 1

**Expected behavior:**
- ✅ Immediate UI update
- ✅ Heart icon turns white
- ✅ Count decrements
- ✅ Backend removes like

---

## 5. Test Comments System 💬

### A. Open Comments

**Steps:**
1. Tap comment button on right side
2. Bottom sheet appears

**Expected behavior:**
- ✅ Sheet slides up from bottom
- ✅ Shows "Comments" title
- ✅ Shows list of existing comments
- ✅ Shows "No comments yet" if empty
- ✅ Input field at bottom

### B. Add Comment

**Steps:**
1. Tap input field
2. Type comment text
3. Tap send button

**Expected behavior:**
- ✅ Comment appears at top of list
- ✅ Shows your avatar and username
- ✅ Shows "just now" timestamp
- ✅ Comment count increments on reel

**Verify in Supabase:**
```sql
SELECT * FROM reel_comments WHERE reel_id = 'REEL_ID';
```

### C. Delete Comment

**Steps:**
1. Tap delete icon on your comment
2. Confirmation dialog appears
3. Tap "Delete"

**Expected behavior:**
- ✅ Comment removed from list
- ✅ Comment count decrements
- ✅ Backend deletes record

---

## 6. Test Share Feature ↗️

### A. Open Share Options

**Steps:**
1. Tap share button on right side
2. Bottom sheet appears

**Expected behavior:**
- ✅ Sheet slides up
- ✅ Shows "Share Reel" title
- ✅ Shows options:
  - Copy Link
  - Share via...
  - Save Video (coming soon)

### B. Copy Link

**Steps:**
1. Tap "Copy Link"
2. Should see "Link copied" message

**Expected behavior:**
- ✅ Sheet closes
- ✅ SnackBar appears
- ✅ Link in clipboard
- ✅ Share count increments

### C. External Share

**Steps:**
1. Tap "Share via..."
2. System share sheet appears
3. Select app to share

**Expected behavior:**
- ✅ Native share dialog opens
- ✅ Shows reel URL
- ✅ Can share to any app
- ✅ Share count increments

---

## 7. Test Real-time Updates 🔄

### A. Multi-device Test

**Setup:**
1. Open app on Device A
2. Open same reel on Device B

**Test like sync:**
1. Like reel on Device A
2. Like count should update on Device B automatically

**Expected behavior:**
- ✅ Count updates within 1-2 seconds
- ✅ No page refresh needed
- ✅ Works across all devices

### B. Comment Sync

**Steps:**
1. Open comments on Device A and B
2. Add comment on Device A

**Expected behavior:**
- ✅ Comment appears on Device B instantly
- ✅ Count updates in real-time

---

## 8. Test Navigation 🧭

### A. Profile Navigation

**Steps:**
1. View reel in feed
2. Tap user's avatar (top of action buttons)

**Expected behavior:**
- ✅ Navigates to user's profile
- ✅ Shows `OtherUserProfilePage`
- ✅ Can view user's posts/reels

### B. Back Navigation

**Steps:**
1. Tap back button (top-left)
2. Returns to previous screen

**Expected behavior:**
- ✅ Exits reel feed
- ✅ Returns to profile/home
- ✅ Video stops playing
- ✅ System UI restored

---

## 9. Test Edge Cases 🔧

### A. No Internet

**Steps:**
1. Disable WiFi/data
2. Try to load reels

**Expected behavior:**
- ✅ Shows error message
- ✅ Retry button available
- ✅ Doesn't crash

### B. Empty Feed

**Steps:**
1. Delete all reels from database
2. Open reel feed

**Expected behavior:**
- ✅ Shows "No reels available" message
- ✅ Shows icon and text
- ✅ Suggests creating first reel

### C. Video Load Error

**Steps:**
1. Corrupt video URL in database
2. Try to play reel

**Expected behavior:**
- ✅ Shows error icon
- ✅ Shows error message
- ✅ Retry button available
- ✅ Can skip to next reel

### D. Long Captions

**Steps:**
1. Upload reel with very long caption (500+ chars)
2. View in feed

**Expected behavior:**
- ✅ Caption truncated with "..." 
- ✅ Max 3 lines shown
- ✅ Scrollable if needed
- ✅ Doesn't overlap buttons

---

## 10. Performance Tests 🏎️

### A. Scroll Performance

**Steps:**
1. Load 20+ reels
2. Rapidly swipe through feed

**Expected behavior:**
- ✅ Smooth 60fps scrolling
- ✅ No lag or stuttering
- ✅ Videos load quickly
- ✅ Memory usage stable

### B. Memory Usage

**Steps:**
1. Open feed
2. Scroll through 50+ reels
3. Check memory usage

**Expected behavior:**
- ✅ Memory doesn't keep growing
- ✅ Old videos disposed
- ✅ App doesn't slow down

---

## Common Issues & Solutions

### Issue: "No reels available"

**Possible causes:**
1. No reels in database
2. Wrong user_id filter
3. Fetch query error

**Solution:**
```sql
-- Check if reels exist
SELECT * FROM reels ORDER BY created_at DESC;

-- Check RLS policies
-- Ensure public read access enabled
```

### Issue: Videos not playing

**Possible causes:**
1. Invalid video URL
2. Storage permissions
3. Network error

**Solution:**
1. Verify URL in browser
2. Check Supabase storage bucket is public
3. Check app has internet permission

### Issue: Likes not saving

**Possible causes:**
1. User not authenticated
2. RLS policies blocking
3. Table doesn't exist

**Solution:**
```sql
-- Check reel_likes table
SELECT * FROM reel_likes LIMIT 10;

-- Check RLS policies
-- Allow insert for authenticated users
```

### Issue: Comments not showing

**Possible causes:**
1. Table doesn't exist
2. Join query error
3. RLS blocking

**Solution:**
```sql
-- Create table if missing
CREATE TABLE reel_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  reel_id UUID REFERENCES reels(id),
  text TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE reel_comments ENABLE ROW LEVEL SECURITY;

-- Allow public read
CREATE POLICY "Comments are viewable by everyone"
ON reel_comments FOR SELECT
USING (true);
```

---

## Database Setup Commands

If tables don't exist, run in Supabase SQL Editor:

```sql
-- Create reel_likes table
CREATE TABLE IF NOT EXISTS reel_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, reel_id)
);

-- Create reel_comments table
CREATE TABLE IF NOT EXISTS reel_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create reel_shares table
CREATE TABLE IF NOT EXISTS reel_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
  shared_to TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE reel_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reel_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reel_shares ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Likes are viewable by everyone"
ON reel_likes FOR SELECT USING (true);

CREATE POLICY "Users can like reels"
ON reel_likes FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike their likes"
ON reel_likes FOR DELETE
USING (auth.uid() = user_id);

CREATE POLICY "Comments are viewable by everyone"
ON reel_comments FOR SELECT USING (true);

CREATE POLICY "Users can comment"
ON reel_comments FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their comments"
ON reel_comments FOR DELETE
USING (auth.uid() = user_id);

CREATE POLICY "Shares are viewable by everyone"
ON reel_shares FOR SELECT USING (true);

CREATE POLICY "Users can share"
ON reel_shares FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

---

## Success Criteria ✅

Your reel system is working if:

- [x] Upload reel → Success message
- [x] Open Reels feed → See uploaded reel
- [x] Swipe up/down → Navigate between reels
- [x] Tap heart → Like count increases
- [x] Double-tap → Heart animation appears
- [x] Tap comment → Bottom sheet opens
- [x] Add comment → Appears in list
- [x] Tap share → Options appear
- [x] Open Profile → See Reels tab
- [x] Tap reel in grid → Opens in feed
- [x] Real-time updates working

---

## Next Steps

1. **Test thoroughly** using this guide
2. **Fix any bugs** found during testing
3. **Optimize performance** if needed
4. **Add analytics** tracking
5. **Implement Phase 2 features** (music, filters, etc.)

---

**Happy Testing! 🎬✨**

If you find any issues, check:
1. Console logs (errors in red)
2. Supabase logs (Database tab)
3. Network requests (DevTools)
4. File paths and imports
