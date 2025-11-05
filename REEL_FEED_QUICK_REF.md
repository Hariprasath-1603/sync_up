# 🎬 Reel Feed Dual Mode - Quick Reference

## 🚀 Quick Start

### Open Global Feed
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ReelFeedPage(),
));
```

### Open Profile Reels
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ReelFeedPage(
    isOwnProfile: true,
    userId: currentUser.id,
  ),
));
```

---

## 🎮 Controls Comparison

| Feature | Global Feed | Profile Mode |
|---------|-------------|--------------|
| **Data Source** | All reels | User's reels only |
| **Top Tabs** | For You / Following | None |
| **Right Controls** | ❤️ 💬 🔗 | ✏️ 📊 🗂️ 🗑️ ⋮ |
| **Double Tap** | Like with animation | None |
| **Single Tap** | Pause/play | Pause/play |
| **Swipe** | Up/down scroll | Up/down scroll |
| **Exit** | Back button | Back button |

---

## 🎨 UI Components

### Profile Mode Buttons

```dart
✏️ Edit      → _editReel(reel)
📊 Insights  → _showInsights(reel)
🗂️ Archive   → _archiveReel(reel)
🗑️ Delete    → _deleteReel(reel)
⋮  More      → _showMoreOptions(reel)
```

### More Options Menu

```dart
✏️ Edit Caption
🖼️ Change Thumbnail
🚫 Hide Likes & Comments
🔁 Allow Remix
```

---

## 📊 Analytics Display

**Insights Sheet Shows:**
- 👁️ **Views**: Total view count
- ❤️ **Likes**: Total likes
- 💬 **Comments**: Total comments  
- 🔗 **Shares**: Total shares
- 📈 **Engagement**: `(likes + comments) / views * 100`

---

## 🔧 Backend Methods

```dart
// Fetch
await _reelService.fetchFeedReels(limit: 10, offset: 0);
await _reelService.fetchUserReels(userId: id, limit: 10, offset: 0);

// Interactions
await _reelService.likeReel(reelId);
await _reelService.unlikeReel(reelId);
await _reelService.recordView(reelId);

// Profile Actions
await _reelService.updateReelCaption(reelId: id, caption: text);
await _reelService.deleteReel(reelId);
```

---

## 🎯 Key Features

### Both Modes
- ✅ Auto-play video when visible
- ✅ Vertical swipe navigation
- ✅ Real-time stat updates
- ✅ Pagination (loads more on scroll)
- ✅ Loading states
- ✅ Error handling

### Global Mode Only
- ✅ Like/comment/share
- ✅ Double-tap to like
- ✅ Heart animation
- ✅ Profile navigation
- ✅ Use audio button

### Profile Mode Only
- ✅ Edit caption
- ✅ View analytics
- ✅ Delete reel
- ✅ More options menu
- ⚠️ Archive (coming soon)

---

## 🐛 Troubleshooting

### Videos Not Playing?
```bash
# Run in Supabase SQL Editor
REEL_STORAGE_FIX.sql
```

### Reels Not Fetching?
```bash
# Check foreign key exists
REEL_DATABASE_FIX.sql
```

### Debug Video URL
```dart
// Check reel_video_player.dart logs
🎬 Initializing video: <URL>
✅ Video initialized successfully
▶️ Auto-playing video...
```

---

## 📱 Integration Example

```dart
// In profile page grid
GridView.builder(
  itemBuilder: (context, index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReelFeedPage(
              isOwnProfile: true,
              userId: currentUser.id,
              initialReels: _reels,
              initialIndex: index,
            ),
          ),
        );
      },
      child: VideoThumbnail(reel: _reels[index]),
    );
  },
)
```

---

## 🎉 Status

**Implementation:** ✅ Complete
**Video Player:** ✅ Working (with debug logs)
**Database:** ✅ Fixed (foreign key + storage permissions)
**Real-time:** ✅ Enabled
**Production Ready:** ✅ Yes

---

**Last Updated:** November 4, 2025
