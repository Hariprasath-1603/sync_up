# 🔄 Static to Dynamic Migration Guide

## 📅 Plan: Replace Static Data with Dynamic Backend Integration

This guide will help you systematically replace all static posts, reels, stories, and other content with real backend data.

---

## 🎯 Current Static Components to Replace

### **1. Posts (Feed)**
- Currently using mock/static post data
- Need to fetch from API
- Real-time updates needed

### **2. Reels**
- Static reel list
- Need video URLs from backend
- User interactions (likes, comments, views)

### **3. Stories**
- Mock story data
- Need real user stories
- View tracking

### **4. User Profiles**
- Static user information
- Need authentication integration

### **5. Comments & Interactions**
- Like/unlike actions
- Comment posting
- Share functionality

---

## 🏗️ Recommended Architecture

### **State Management Options:**

1. **Provider** (already in pubspec.yaml) ✅
2. **Riverpod** (modern alternative)
3. **Bloc** (enterprise-grade)
4. **GetX** (simple & fast)

**Recommendation:** Stick with **Provider** since it's already installed.

---

## 📦 Required Packages

Add these to `pubspec.yaml`:

```yaml
dependencies:
  # HTTP Client
  http: ^1.1.0  # For API calls
  dio: ^5.4.0   # Alternative (better error handling)
  
  # State Management (already have provider)
  provider: ^6.1.2  # ✅ Already installed
  
  # Local Storage
  shared_preferences: ^2.2.2  # Cache & tokens
  hive: ^2.2.3  # Local database
  hive_flutter: ^1.1.0
  
  # Image Handling
  cached_network_image: ^3.3.1  # Cache images
  
  # Video Player (already have)
  video_player: ^2.8.2  # ✅ Already installed
  
  # Pull to Refresh
  pull_to_refresh: ^2.0.0
  
  # Infinite Scroll
  infinite_scroll_pagination: ^4.0.0
  
  # Loading Indicators
  shimmer: ^3.0.0  # Skeleton loaders
  
  # Error Handling
  flutter_easyloading: ^3.0.5
```

---

## 📡 API Integration Strategy

### **Step 1: Create API Service Layer**

Create `lib/core/services/api_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://your-api.com/api';
  
  // Headers with auth token
  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthService.token}',
    };
  }
  
  // GET request
  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
    );
    return _handleResponse(response);
  }
  
  // POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
      body: json.encode(body),
    );
    return _handleResponse(response);
  }
  
  // PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
      body: json.encode(body),
    );
    return _handleResponse(response);
  }
  
  // DELETE request
  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
    );
    return _handleResponse(response);
  }
  
  // Handle response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
```

---

### **Step 2: Create Data Models**

#### **Post Model** (`lib/features/home/models/post_model.dart`):

```dart
class Post {
  final String id;
  final User user;
  final String? caption;
  final List<String> mediaUrls;
  final String mediaType; // 'image', 'video', 'carousel'
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;
  final String? location;
  final List<String> tags;
  
  Post({
    required this.id,
    required this.user,
    this.caption,
    required this.mediaUrls,
    required this.mediaType,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLiked,
    required this.isSaved,
    required this.createdAt,
    this.location,
    required this.tags,
  });
  
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      user: User.fromJson(json['user']),
      caption: json['caption'],
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      mediaType: json['media_type'] ?? 'image',
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      location: json['location'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'caption': caption,
      'media_urls': mediaUrls,
      'media_type': mediaType,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'is_liked': isLiked,
      'is_saved': isSaved,
      'created_at': createdAt.toIso8601String(),
      'location': location,
      'tags': tags,
    };
  }
  
  Post copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Post(
      id: id,
      user: user,
      caption: caption,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt,
      location: location,
      tags: tags,
    );
  }
}

class User {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  
  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.isVerified,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
      isVerified: json['is_verified'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
    };
  }
}
```

#### **Reel Model** (`lib/features/reels/models/reel_model.dart`):

```dart
class Reel {
  final String id;
  final User user;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final String? audioName;
  final String? audioId;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;
  final String? location;
  final List<String> tags;
  final Duration duration;
  
  Reel({
    required this.id,
    required this.user,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    this.audioName,
    this.audioId,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.viewsCount,
    required this.isLiked,
    required this.isSaved,
    required this.createdAt,
    this.location,
    required this.tags,
    required this.duration,
  });
  
  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      id: json['id'] ?? '',
      user: User.fromJson(json['user']),
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      caption: json['caption'],
      audioName: json['audio_name'],
      audioId: json['audio_id'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      location: json['location'],
      tags: List<String>.from(json['tags'] ?? []),
      duration: Duration(seconds: json['duration'] ?? 0),
    );
  }
  
  Reel copyWith({
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Reel(
      id: id,
      user: user,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      audioName: audioName,
      audioId: audioId,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt,
      location: location,
      tags: tags,
      duration: duration,
    );
  }
}
```

#### **Story Model** (`lib/features/stories/models/story_model.dart`):

```dart
class Story {
  final String id;
  final User user;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime createdAt;
  final Duration? duration;
  final bool isViewed;
  final int viewsCount;
  
  Story({
    required this.id,
    required this.user,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    this.duration,
    required this.isViewed,
    required this.viewsCount,
  });
  
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? '',
      user: User.fromJson(json['user']),
      mediaUrl: json['media_url'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      createdAt: DateTime.parse(json['created_at']),
      duration: json['duration'] != null 
          ? Duration(seconds: json['duration']) 
          : null,
      isViewed: json['is_viewed'] ?? false,
      viewsCount: json['views_count'] ?? 0,
    );
  }
}
```

---

### **Step 3: Create Provider Classes**

#### **Post Provider** (`lib/features/home/providers/post_provider.dart`):

```dart
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../../../core/services/api_service.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;
  
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  
  // Fetch posts (with pagination)
  Future<void> fetchPosts({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _page = 1;
      _posts.clear();
      _hasMore = true;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.get('posts?page=$_page&limit=10');
      final List<dynamic> data = response['data'];
      
      if (data.isEmpty) {
        _hasMore = false;
      } else {
        final newPosts = data.map((json) => Post.fromJson(json)).toList();
        _posts.addAll(newPosts);
        _page++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Like/Unlike post
  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    
    final post = _posts[index];
    final newLikeStatus = !post.isLiked;
    
    // Optimistic update
    _posts[index] = post.copyWith(
      isLiked: newLikeStatus,
      likesCount: post.likesCount + (newLikeStatus ? 1 : -1),
    );
    notifyListeners();
    
    try {
      if (newLikeStatus) {
        await ApiService.post('posts/$postId/like', {});
      } else {
        await ApiService.delete('posts/$postId/like');
      }
    } catch (e) {
      // Revert on error
      _posts[index] = post;
      notifyListeners();
    }
  }
  
  // Save/Unsave post
  Future<void> toggleSave(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    
    final post = _posts[index];
    final newSaveStatus = !post.isSaved;
    
    _posts[index] = post.copyWith(isSaved: newSaveStatus);
    notifyListeners();
    
    try {
      if (newSaveStatus) {
        await ApiService.post('posts/$postId/save', {});
      } else {
        await ApiService.delete('posts/$postId/save');
      }
    } catch (e) {
      _posts[index] = post;
      notifyListeners();
    }
  }
  
  // Create new post
  Future<bool> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await ApiService.post('posts', postData);
      final newPost = Post.fromJson(response['data']);
      _posts.insert(0, newPost);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
```

#### **Reel Provider** (`lib/features/reels/providers/reel_provider.dart`):

```dart
import 'package:flutter/foundation.dart';
import '../models/reel_model.dart';
import '../../../core/services/api_service.dart';

class ReelProvider with ChangeNotifier {
  List<Reel> _reels = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  
  List<Reel> get reels => _reels;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  
  Future<void> fetchReels({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _page = 1;
      _reels.clear();
      _hasMore = true;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await ApiService.get('reels?page=$_page&limit=10');
      final List<dynamic> data = response['data'];
      
      if (data.isEmpty) {
        _hasMore = false;
      } else {
        final newReels = data.map((json) => Reel.fromJson(json)).toList();
        _reels.addAll(newReels);
        _page++;
      }
    } catch (e) {
      debugPrint('Error fetching reels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> toggleLike(String reelId) async {
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index == -1) return;
    
    final reel = _reels[index];
    final newLikeStatus = !reel.isLiked;
    
    _reels[index] = reel.copyWith(
      isLiked: newLikeStatus,
      likesCount: reel.likesCount + (newLikeStatus ? 1 : -1),
    );
    notifyListeners();
    
    try {
      if (newLikeStatus) {
        await ApiService.post('reels/$reelId/like', {});
      } else {
        await ApiService.delete('reels/$reelId/like');
      }
    } catch (e) {
      _reels[index] = reel;
      notifyListeners();
    }
  }
  
  Future<void> incrementViews(String reelId) async {
    try {
      await ApiService.post('reels/$reelId/view', {});
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }
}
```

---

### **Step 4: Update Main App with Providers**

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/home/providers/post_provider.dart';
import 'features/reels/providers/reel_provider.dart';
import 'features/stories/providers/story_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ReelProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
      ],
      child: const App(),
    ),
  );
}
```

---

### **Step 5: Update UI to Use Providers**

#### **Example: Home Page with Dynamic Posts**

```dart
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Fetch posts on init
    Future.microtask(() =>
      Provider.of<PostProvider>(context, listen: false).fetchPosts()
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (postProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${postProvider.error}'),
                  ElevatedButton(
                    onPressed: () => postProvider.fetchPosts(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => postProvider.fetchPosts(refresh: true),
            child: ListView.builder(
              itemCount: postProvider.posts.length + 1,
              itemBuilder: (context, index) {
                if (index == postProvider.posts.length) {
                  if (postProvider.hasMore) {
                    postProvider.fetchPosts();
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                
                return PostCard(post: postProvider.posts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
```

---

## 📋 Migration Checklist

### **Phase 1: Setup (Day 1 Morning)**
- [ ] Add required packages to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Create API service layer
- [ ] Set up base URL and authentication

### **Phase 2: Models (Day 1 Afternoon)**
- [ ] Create Post model with JSON serialization
- [ ] Create Reel model
- [ ] Create Story model
- [ ] Create User model
- [ ] Create Comment model

### **Phase 3: Providers (Day 1 Evening)**
- [ ] Create PostProvider
- [ ] Create ReelProvider
- [ ] Create StoryProvider
- [ ] Add providers to main.dart

### **Phase 4: API Integration (Day 2 Morning)**
- [ ] Implement GET posts endpoint
- [ ] Implement POST/DELETE like endpoints
- [ ] Implement comment endpoints
- [ ] Implement reel endpoints
- [ ] Implement story endpoints

### **Phase 5: UI Updates (Day 2 Afternoon)**
- [ ] Update HomePage to use PostProvider
- [ ] Update ReelsPage to use ReelProvider
- [ ] Update Stories to use StoryProvider
- [ ] Add pull-to-refresh
- [ ] Add infinite scroll
- [ ] Add loading states

### **Phase 6: Features (Day 2 Evening)**
- [ ] Implement like/unlike animation
- [ ] Implement save/unsave
- [ ] Implement comment posting
- [ ] Implement share functionality
- [ ] Add optimistic updates

### **Phase 7: Polish (Day 3)**
- [ ] Add error handling
- [ ] Add retry mechanisms
- [ ] Add offline caching
- [ ] Add shimmer loading
- [ ] Test all flows

---

## 🎯 API Endpoints You'll Need

```
# Posts
GET    /api/posts                     # List posts
POST   /api/posts                     # Create post
GET    /api/posts/:id                 # Get single post
DELETE /api/posts/:id                 # Delete post
POST   /api/posts/:id/like            # Like post
DELETE /api/posts/:id/like            # Unlike post
POST   /api/posts/:id/save            # Save post
DELETE /api/posts/:id/save            # Unsave post

# Reels
GET    /api/reels                     # List reels
POST   /api/reels                     # Create reel
GET    /api/reels/:id                 # Get single reel
POST   /api/reels/:id/like            # Like reel
POST   /api/reels/:id/view            # Increment view

# Stories
GET    /api/stories                   # List stories
POST   /api/stories                   # Create story
POST   /api/stories/:id/view          # Mark as viewed

# Comments
GET    /api/posts/:id/comments        # Get comments
POST   /api/posts/:id/comments        # Add comment
DELETE /api/comments/:id              # Delete comment

# Users
GET    /api/users/:id                 # Get user profile
GET    /api/users/:id/posts           # Get user posts
POST   /api/users/:id/follow          # Follow user
```

---

## 💡 Pro Tips

1. **Use Dio instead of http** - Better error handling and interceptors
2. **Implement caching** - Use Hive or SharedPreferences
3. **Add retry logic** - Handle network failures gracefully
4. **Use shimmer loading** - Better UX than spinners
5. **Implement optimistic updates** - Update UI before API response
6. **Add error boundaries** - Graceful error handling
7. **Cache images** - Use `cached_network_image`
8. **Debounce API calls** - Prevent duplicate requests
9. **Use pagination** - Don't load everything at once
10. **Add offline mode** - Show cached data when offline

---

## 🚀 Quick Start Tomorrow

1. Open VS Code
2. Add packages to `pubspec.yaml`
3. Create folder structure:
   ```
   lib/
     core/
       services/
         api_service.dart
     features/
       home/
         models/
         providers/
       reels/
         models/
         providers/
   ```
4. Start with API service
5. Create models
6. Create providers
7. Update UI

---

## 📚 Resources

- [Provider Documentation](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)
- [Dio Package](https://pub.dev/packages/dio)
- [Cached Network Image](https://pub.dev/packages/cached_network_image)
- [Flutter State Management](https://docs.flutter.dev/data-and-backend/state-mgmt)

---

Good luck with your migration tomorrow! 🎉 Feel free to ask questions as you implement this. The guide covers everything you need to go from static to dynamic! 💪
