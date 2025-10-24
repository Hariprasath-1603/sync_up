import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper class to populate Firestore with sample posts for testing
/// Run this once to add sample data to your Firestore
class SampleDataPopulator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add sample posts to Firestore
  Future<void> addSamplePosts() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No user logged in. Please sign in first.');
      return;
    }

    print('📝 Adding sample posts to Firestore...');

    final samplePosts = [
      {
        'caption': 'Beautiful sunset at the beach! 🌅 #sunset #beach #nature',
        'imageUrl': 'https://picsum.photos/seed/sunset1/1080/1350',
        'tags': ['sunset', 'beach', 'nature'],
      },
      {
        'caption': 'Amazing coffee art ☕️ #coffee #art #morning',
        'imageUrl': 'https://picsum.photos/seed/coffee2/1080/1350',
        'tags': ['coffee', 'art', 'morning'],
      },
      {
        'caption': 'City lights at night 🌃 #city #urban #night #photography',
        'imageUrl': 'https://picsum.photos/seed/city3/1080/1350',
        'tags': ['city', 'urban', 'night', 'photography'],
      },
      {
        'caption': 'Fresh mountain air 🏔️ #mountains #hiking #adventure',
        'imageUrl': 'https://picsum.photos/seed/mountain4/1080/1350',
        'tags': ['mountains', 'hiking', 'adventure'],
      },
      {
        'caption': 'Delicious homemade pasta 🍝 #food #cooking #italian',
        'imageUrl': 'https://picsum.photos/seed/food5/1080/1350',
        'tags': ['food', 'cooking', 'italian'],
      },
      {
        'caption': 'Workout complete! 💪 #fitness #gym #health',
        'imageUrl': 'https://picsum.photos/seed/fitness6/1080/1350',
        'tags': ['fitness', 'gym', 'health'],
      },
      {
        'caption': 'Reading my favorite book 📚 #books #reading #relax',
        'imageUrl': 'https://picsum.photos/seed/books7/1080/1350',
        'tags': ['books', 'reading', 'relax'],
      },
      {
        'caption': 'Morning yoga session 🧘‍♀️ #yoga #meditation #wellness',
        'imageUrl': 'https://picsum.photos/seed/yoga8/1080/1350',
        'tags': ['yoga', 'meditation', 'wellness'],
      },
      {
        'caption': 'Street art discovery 🎨 #art #street #urban',
        'imageUrl': 'https://picsum.photos/seed/art9/1080/1350',
        'tags': ['art', 'street', 'urban'],
      },
      {
        'caption': 'Perfect weekend vibes ✨ #weekend #relax #happy',
        'imageUrl': 'https://picsum.photos/seed/weekend10/1080/1350',
        'tags': ['weekend', 'relax', 'happy'],
      },
    ];

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < samplePosts.length; i++) {
      try {
        final post = samplePosts[i];

        await _firestore.collection('posts').add({
          'userId': currentUser.uid,
          'username': currentUser.displayName ?? 'User',
          'userAvatar': currentUser.photoURL ?? 'https://i.pravatar.cc/150',
          'type': 'image',
          'mediaUrls': [post['imageUrl']],
          'thumbnailUrl': post['imageUrl'],
          'caption': post['caption'],
          'tags': post['tags'],
          'likes': (i + 1) * 100 + (i * 23), // Varied like counts
          'comments': (i + 1) * 20 + (i * 5),
          'shares': (i + 1) * 5,
          'saves': (i + 1) * 15,
          'views': (i + 1) * 500,
          'commentsEnabled': true,
          'isPinned': false,
          'isArchived': false,
          'hideLikeCount': false,
          'location': null,
          'musicName': null,
          'musicArtist': null,
          'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(Duration(hours: i * 3)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        });

        successCount++;
        print('✅ Post ${i + 1}/${samplePosts.length} added');
      } catch (e) {
        failCount++;
        print('❌ Failed to add post ${i + 1}: $e');
      }
    }

    print('\n📊 Summary:');
    print('✅ Successfully added: $successCount posts');
    if (failCount > 0) {
      print('❌ Failed: $failCount posts');
    }
    print('🎉 Done! You can now see these posts in your app.');
  }

  /// Add sample users (for testing Following feature)
  Future<void> addSampleUsers() async {
    print('👥 Adding sample users to Firestore...');

    final sampleUsers = [
      {
        'username': 'jane_doe',
        'displayName': 'Jane Doe',
        'bio': 'Photography enthusiast 📸',
        'photoURL': 'https://i.pravatar.cc/150?img=1',
      },
      {
        'username': 'john_smith',
        'displayName': 'John Smith',
        'bio': 'Travel blogger ✈️',
        'photoURL': 'https://i.pravatar.cc/150?img=2',
      },
      {
        'username': 'sarah_wilson',
        'displayName': 'Sarah Wilson',
        'bio': 'Food lover 🍕',
        'photoURL': 'https://i.pravatar.cc/150?img=3',
      },
    ];

    int successCount = 0;

    for (final user in sampleUsers) {
      try {
        // Check if user already exists
        final existing = await _firestore
            .collection('users')
            .where('username', isEqualTo: user['username'])
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await _firestore.collection('users').add({
            'uid': 'demo_${user['username']}',
            'username': user['username'],
            'usernameDisplay': user['username'],
            'email': '${user['username']}@demo.com',
            'displayName': user['displayName'],
            'photoURL': user['photoURL'],
            'bio': user['bio'],
            'followersCount': 0,
            'followingCount': 0,
            'postsCount': 0,
            'followers': [],
            'following': [],
            'createdAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
          });
          successCount++;
          print('✅ User ${user['username']} added');
        } else {
          print('ℹ️  User ${user['username']} already exists');
        }
      } catch (e) {
        print('❌ Failed to add user ${user['username']}: $e');
      }
    }

    print('\n📊 Added $successCount new users');
  }

  /// Clear all sample posts (use with caution!)
  Future<void> clearAllPosts() async {
    print('🗑️  Clearing all posts...');

    final snapshot = await _firestore.collection('posts').get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    print('✅ Cleared ${snapshot.docs.length} posts');
  }
}

/// Quick function to run the sample data populator
/// Call this from your app (e.g., from a debug menu button)
Future<void> populateSampleData() async {
  final populator = SampleDataPopulator();
  await populator.addSamplePosts();
  await populator.addSampleUsers();
}
