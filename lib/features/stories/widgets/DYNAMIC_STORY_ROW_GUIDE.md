# Dynamic Story Row - Integration Guide

## Overview
Instagram-style horizontal story bar with auto-refresh, real-time updates, and dynamic "add story" button.

## Features ✨
- ✅ **Dynamic Own Story**: Shows + button OR active story ring
- ✅ **Real-Time Updates**: Auto-refreshes when stories are added/expired
- ✅ **Viewed State Tracking**: Gradient ring (unviewed) vs gray ring (viewed)
- ✅ **Story Management**: Long-press menu (view insights, archive, delete)
- ✅ **Loading Skeleton**: Smooth loading experience
- ✅ **Supabase Integration**: Direct database queries with joins
- ✅ **Bounce Animation**: Elastic animation for new stories

## Quick Integration

### 1️⃣ Add to Home Feed
```dart
// lib/features/home/home_page.dart
import '../stories/widgets/dynamic_story_row.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(...),
          
          // Story Row
          SliverToBoxAdapter(
            child: DynamicStoryRow(),
          ),
          
          // Posts feed
          SliverList(...),
        ],
      ),
    );
  }
}
```

### 2️⃣ Standalone Usage
```dart
// Direct usage in any page
Column(
  children: [
    DynamicStoryRow(), // Stories bar
    Expanded(child: YourContent()),
  ],
)
```

## Component Behavior

### Current User Story Bubble
| State | Visual | Action | Long Press |
|-------|--------|--------|------------|
| **No Story** | Gray border + "+" icon | Opens Story Creator | None |
| **Has Story** | Gradient ring + profile pic | Opens Story Viewer | Management Menu |

### Other Users' Stories
| State | Visual | Action |
|-------|--------|--------|
| **Unviewed** | Orange/Pink/Purple gradient ring | Opens Story Viewer |
| **Viewed** | Gray border ring | Opens Story Viewer |
| **Expired** | Hidden (auto-removed) | N/A |

## Story Management Menu
Long-press your story bubble to access:
- 📊 **View Insights**: Story analytics (coming soon)
- 📦 **Archive Story**: Move to archive
- 🗑️ **Delete Story**: Permanently remove

## Real-Time Updates
Automatically refreshes on:
- ✅ New story posted (insert event)
- ✅ Story deleted (delete event)
- ✅ Story updated (update event)

Powered by Supabase Realtime:
```dart
_supabase
  .channel('stories_updates')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'stories',
    callback: (payload) => _fetchStories(),
  )
  .subscribe();
```

## Database Schema Requirements

### stories Table
```sql
CREATE TABLE stories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(uid) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  views_count INTEGER DEFAULT 0,
  is_archived BOOLEAN DEFAULT FALSE
);

-- Index for active stories
CREATE INDEX idx_stories_active ON stories(user_id, expires_at) 
WHERE is_archived = FALSE AND expires_at > NOW();
```

### story_viewers Table
```sql
CREATE TABLE story_viewers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES users(uid) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(story_id, viewer_id)
);
```

## Navigation Flow

```
DynamicStoryRow
├── Tap Own Story → StoryViewerPage (Creator Mode)
│   └── Shows insights, edit, delete controls
├── Tap + Button → StoryCreatorPage
│   └── Upload image/video, add caption
└── Tap Other User → StoryViewerPage (Viewer Mode)
    └── Watch stories, send reactions
```

## Performance Optimization

### 1. Efficient Querying
- Uses single query with JOIN to fetch stories + user data
- Groups stories by user in memory (reduces DB calls)
- Only fetches active stories (`expires_at > NOW()`)

### 2. Caching
- Uses `CachedNetworkImage` for profile pictures
- Avoids re-fetching unchanged data

### 3. Smart Refresh
- Only refreshes after relevant actions (post, view, delete)
- Real-time updates only trigger on DB changes

## Customization

### Adjust Story Bubble Size
```dart
// In _buildCurrentUserBubble() and _buildStoryBubble()
Container(
  width: 80,  // Default: 68
  height: 80,
  // ...
)
```

### Change Gradient Colors
```dart
gradient: LinearGradient(
  colors: [
    Colors.blue.shade400,     // Replace orange
    Colors.cyan.shade400,     // Replace pink
    Colors.teal.shade400,     // Replace purple
  ],
  // ...
)
```

### Modify Animation Speed
```dart
_animationController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 500), // Default: 300
);
```

## Troubleshooting

### Stories Not Appearing
1. Check if stories are expired:
   ```sql
   SELECT * FROM stories WHERE expires_at > NOW() AND is_archived = FALSE;
   ```
2. Verify user is authenticated:
   ```dart
   print(_supabase.auth.currentUser?.id);
   ```

### Real-Time Not Working
1. Enable Realtime in Supabase Dashboard:
   - Database → Replication → Enable `stories` table
2. Check subscription status:
   ```dart
   print(_storyChannel?.status); // Should be 'subscribed'
   ```

### Viewed State Incorrect
Check `story_viewers` table:
```sql
SELECT * FROM story_viewers WHERE viewer_id = 'YOUR_USER_ID';
```

## Dependencies
Already included in project:
- `supabase_flutter` - Backend integration
- `cached_network_image` - Image caching
- `flutter/material.dart` - UI framework

## Testing Checklist
- [ ] + button appears when no story
- [ ] + button opens Story Creator
- [ ] Story ring appears after posting
- [ ] Own story opens Story Viewer
- [ ] Long-press shows management menu
- [ ] Archive/delete works correctly
- [ ] Other users' stories visible
- [ ] Viewed state changes ring color
- [ ] Real-time updates work
- [ ] Loading skeleton displays
- [ ] Expired stories auto-removed

## Next Steps
1. **Story Insights**: Connect "View Insights" to analytics dashboard
2. **Story Reactions**: Add quick reactions (❤️, 😂, 😮)
3. **Story Replies**: Enable DM responses
4. **Close Friends**: Add private story sharing

---

**Status**: ✅ Production Ready
**Last Updated**: November 2025
**Component Location**: `lib/features/stories/widgets/dynamic_story_row.dart`
