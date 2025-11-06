## 🎬 Dynamic Story Row - Quick Reference

### Component Location
`lib/features/stories/widgets/dynamic_story_row.dart`

### Usage
```dart
const DynamicStoryRow()
```

### Features at a Glance

| Feature | Status | Description |
|---------|--------|-------------|
| **Own Story** | ✅ | Shows + button OR gradient ring |
| **Other Stories** | ✅ | Scrollable horizontal list |
| **Real-Time** | ✅ | Auto-updates on insert/delete/update |
| **Viewed State** | ✅ | Gradient (new) vs Gray (viewed) |
| **Management** | ✅ | Long-press for insights/archive/delete |
| **Creator Flow** | ✅ | Opens StoryCreatorPage on + tap |
| **Viewer Flow** | ✅ | Opens StoryViewerPage on story tap |
| **Loading State** | ✅ | Skeleton with shimmer |
| **Animations** | ✅ | Elastic bounce for new stories |
| **Theming** | ✅ | Dark/Light mode support |

### Key Methods

```dart
// Fetch stories from Supabase
Future<void> _fetchStories()

// Check if user viewed a story segment
Future<bool> _hasViewedSegment(String storyId, String viewerId)

// Subscribe to real-time updates
void _subscribeToRealtimeUpdates()

// Open story viewer
void _openStoryViewer(StoryItem storyItem, int initialSegmentIndex)

// Open story creator
void _openStoryCreator()

// Show management menu (long-press)
void _showStoryManagementOptions()
```

### Database Tables Used

**stories**
- `id`, `user_id`, `media_url`, `thumbnail_url`
- `media_type`, `caption`, `created_at`, `expires_at`
- `views_count`, `is_archived`

**story_viewers**
- `id`, `story_id`, `viewer_id`, `viewed_at`

**users** (joined)
- `uid`, `username`, `usernameDisplay`, `photo_url`

### Real-Time Events

```dart
PostgresChangeEvent.insert  → New story posted
PostgresChangeEvent.delete  → Story deleted
PostgresChangeEvent.update  → Story archived/modified
```

### Visual States

**Own Story:**
- No story: Gray border + + icon → "Add Story"
- Has story: Gradient ring → "Your Story"

**Other Stories:**
- Unviewed: 🟠🟣 Gradient ring (orange → pink → purple)
- Viewed: ⚪ Gray border

### Navigation Flows

```
Tap + Button → StoryCreatorPage
Tap Own Story → StoryViewerPage (creator mode)
Tap Other Story → StoryViewerPage (viewer mode)
Long-press Own Story → Management Sheet
```

### Management Options

1. **View Insights** - Placeholder (coming soon)
2. **Archive Story** - Moves to archive (working)
3. **Delete Story** - Permanent deletion (working)

### Performance

- ⚡ Single query with JOIN
- ⚡ In-memory grouping
- ⚡ Cached images
- ⚡ Smart refresh
- ⚡ Real-time push updates

### Customization

**Change bubble size:**
```dart
Container(width: 80, height: 80, ...) // Default: 68
```

**Change gradient colors:**
```dart
gradient: LinearGradient(
  colors: [
    Colors.blue.shade400,
    Colors.cyan.shade400,
    Colors.teal.shade400,
  ],
)
```

**Adjust animation:**
```dart
duration: const Duration(milliseconds: 500) // Default: 300
```

### Testing Commands

```powershell
# Run app
flutter run

# Check for errors
flutter analyze

# Hot reload after changes
r (in terminal)
```

### Common Issues

**Stories not showing:**
- Check `expires_at > NOW()` in database
- Verify user is authenticated
- Check `is_archived = false`

**Real-time not working:**
- Enable Realtime in Supabase Dashboard
- Check subscription status
- Verify table replication enabled

**Viewed state wrong:**
- Check `story_viewers` table
- Verify viewer_id matches current user

### Next Steps

1. ✅ Component is production-ready
2. ✅ Integrated in Home Page
3. 🔵 Test with real users and stories
4. 🟡 Connect insights to analytics dashboard
5. 🟡 Add story reactions/replies
6. 🟡 Implement close friends feature

---

**Status:** ✅ Production Ready  
**Last Updated:** November 6, 2025  
**Version:** 1.0.0
