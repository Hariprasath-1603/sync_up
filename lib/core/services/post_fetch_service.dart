import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/post_model.dart';

/// Simplified PostFetchService - Firestore features temporarily disabled during migration
/// TODO: Full migration from Firestore to Supabase pending
class PostFetchService {
  static final PostFetchService _instance = PostFetchService._internal();
  factory PostFetchService() => _instance;
  PostFetchService._internal();

  // ignore: unused_field
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stub methods - return empty data to prevent errors
  Stream<List<PostModel>> getForYouPosts({int limit = 20}) async* {
    print('TODO: Implement getForYouPosts with Supabase');
    yield [];
  }

  Stream<List<PostModel>> getFollowingPosts({int limit = 20}) async* {
    print('TODO: Implement getFollowingPosts with Supabase');
    yield [];
  }

  Stream<List<PostModel>> getUserPosts(String userId, {int limit = 20}) async* {
    print('TODO: Implement getUserPosts with Supabase');
    yield [];
  }

  Future<List<PostModel>> searchPosts(String query) async {
    print('TODO: Implement searchPosts with Supabase');
    return [];
  }

  Stream<List<PostModel>> getExplorePosts({int limit = 20}) async* {
    print('TODO: Implement getExplorePosts with Supabase');
    yield [];
  }

  Future<PostModel?> getPostById(String postId) async {
    print('TODO: Implement getPostById with Supabase');
    return null;
  }
}
