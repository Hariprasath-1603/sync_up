# Stories Feature - Quick Reference

## 🎯 How to Access

### Option 1: Stories Demo Page
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const StoryDemoPage()),
);
```
**Via UI**: Tap `+` button → Select "Stories Demo"

### Option 2: Create Story Directly
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const CreateStoryPage()),
);
```
**Via UI**: Tap `+` button → Select "Create Story"

## 📱 Story Viewer Controls

### Gestures
| Gesture | Action |
|---------|--------|
| Tap Left Third | Previous story |
| Tap Right Third | Next story |
| Hold | Pause playback |
| Swipe Down | Close viewer |
| Swipe Up (own story) | Show viewers list |

### Buttons
| Button | Location | Action |
|--------|----------|--------|
| ❤️ | Bottom right | Open reactions menu |
| "Send message..." | Bottom left | Open reply dialog |
| ⋮ | Top right | Open options menu |
| ✕ | Top right | Close viewer |

## 🎨 Story Bar Widget

### Integration in Your Feed
```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // Add Story Bar at top
      StoryBar(
        currentUserId: currentUserId,
        currentUsername: currentUsername,
        hasYourStory: hasYourStory,
        friendStories: friendStories,
        onAddStory: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateStoryPage()),
        ),
        onViewStory: (userId) => _openStoryViewer(userId),
      ),
      
      // Your feed content
      Expanded(
        child: ListView(
          children: feedItems,
        ),
      ),
    ],
  );
}
```

### Friend Story Data Structure
```dart
final friendStories = [
  StorySummary(
    userId: 'user_1',
    username: 'Ava Martinez',
    avatarUrl: 'https://...',  // Optional
    isVerified: true,
    hasNewStory: true,  // Gradient ring
    storyCount: 3,
    latestStoryTime: DateTime.now().subtract(Duration(hours: 2)),
  ),
  // Add more...
];
```

## 🎬 Story Viewer Integration

### Opening the Viewer
```dart
void _openStoryViewer(String userId) {
  // Fetch stories for this user
  final stories = await _fetchStoriesForUser(userId);
  final isOwnStory = userId == currentUserId;
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => StoryViewerPage(
        userId: userId,
        stories: stories,
        initialStoryIndex: 0,
        isOwnStory: isOwnStory,
      ),
    ),
  );
}
```

### Story Model Example
```dart
StoryModel(
  id: 'story_123',
  userId: 'user_1',
  username: 'Ava Martinez',
  userAvatarUrl: 'https://...',
  isUserVerified: true,
  mediaUrl: 'https://example.com/story.jpg',
  mediaType: StoryMediaType.image,  // or .video
  caption: 'Beautiful sunset! 🌅',
  duration: 5,  // seconds
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(Duration(hours: 24)),
  status: StoryStatus.active,
  viewCount: 42,
  audience: StoryAudience.public,
  musicTrack: 'Summer Vibes',
  allowReplies: true,
  allowSharing: true,
  // ... other fields
)
```

## 🎯 Common Use Cases

### 1. Integrate Story Bar in Home Feed
```dart
// In your home_page.dart
StoryBar(
  currentUserId: authService.currentUserId,
  currentUsername: authService.currentUsername,
  hasYourStory: _hasActiveStory,
  friendStories: _friendStoriesFromAPI,
  onAddStory: _createNewStory,
  onViewStory: _viewUserStories,
)
```

### 2. Handle Story Creation
```dart
Future<void> _createNewStory() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => CreateStoryPage()),
  );
  
  if (result == true) {
    // Story was created successfully
    setState(() {
      _hasActiveStory = true;
    });
    _refreshStories();
  }
}
```

### 3. View User Stories
```dart
Future<void> _viewUserStories(String userId) async {
  // Show loading
  showDialog(
    context: context,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );
  
  // Fetch stories
  final stories = await api.getStoriesForUser(userId);
  Navigator.pop(context); // Close loading
  
  if (stories.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerPage(
          userId: userId,
          stories: stories,
          isOwnStory: userId == currentUserId,
        ),
      ),
    );
  }
}
```

### 4. Track Story Views
```dart
// In story_viewer_page.dart, the view is automatically tracked:
void _markStoryAsViewed() {
  final story = widget.stories[_currentStoryIndex];
  // This is where you'd call your API
  api.markStoryAsViewed(story.id);
}
```

## 🎨 Customization

### Colors
```dart
// Story ring gradient (unseen)
LinearGradient(
  colors: [Color(0xFF4A6CF7), Color(0xFF9D50BB)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Seen story ring
Colors.grey.withOpacity(0.3)

// Primary action color
Color(0xFF4A6CF7)
```

### Durations
```dart
// Image stories
const Duration(seconds: 5)

// Video stories
Duration(seconds: video.duration)

// Story expiry
const Duration(hours: 24)
```

### Sizes
```dart
// Story Bar
height: 120px

// Avatar in Story Bar
width: 70px, height: 70px

// Story tile
width: 80px

// Plus icon
width: 24px, height: 24px

// Progress bars
height: 3px
```

## 🔧 API Endpoints to Implement

### Required Endpoints
```dart
// Get friend stories
GET /api/v1/stories/friends
Response: List<StorySummary>

// Get user's stories
GET /api/v1/stories/:userId
Response: List<StoryModel>

// Mark as viewed
POST /api/v1/stories/:storyId/view
Body: { viewedAt: timestamp }

// Send reaction
POST /api/v1/stories/:storyId/react
Body: { emoji: "❤️" }

// Send reply
POST /api/v1/stories/:storyId/reply
Body: { message: "Nice!" }

// Get viewers
GET /api/v1/stories/:storyId/viewers
Response: List<Viewer>

// Create story
POST /api/v1/stories
Body: FormData (media, caption, audience, etc.)
Response: StoryModel
```

## 🐛 Troubleshooting

### Story Bar Not Showing
✅ Check `friendStories` list is not empty
✅ Verify Story Bar height (should be 120px)
✅ Ensure parent widget has proper constraints

### Story Viewer Not Opening
✅ Verify `stories` list is not empty
✅ Check `userId` matches story owner
✅ Ensure proper navigation context

### Gestures Not Working
✅ Check GestureDetector is not blocked by other widgets
✅ Verify tap detection zones (left/right thirds)
✅ Ensure navigation context is valid

### Progress Bars Not Animating
✅ Check AnimationController is started
✅ Verify duration is set correctly
✅ Ensure `vsync` is provided (TickerProviderStateMixin)

## 📚 Additional Resources

- Full implementation guide: `STORIES_IMPLEMENTATION.md`
- Story creation: `lib/features/stories/create_story_page.dart`
- Story viewing: `lib/features/stories/story_viewer_page.dart`
- Demo example: `lib/features/stories/story_demo_page.dart`
- Story Bar widget: `lib/features/stories/widgets/story_bar_widget.dart`

## 🚀 Quick Test

1. Open app
2. Tap `+` button
3. Select "Stories Demo"
4. Explore all features:
   - View friend stories
   - Create your story
   - See reactions
   - Send replies
   - View analytics

**That's it!** 🎉 Your Stories feature is ready to use!
