import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/music_track_model.dart';

/// Service for fetching and managing music tracks from Supabase
class MusicService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch music tracks with search and pagination
  Future<List<MusicTrack>> fetchTracks({
    String? query,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      PostgrestFilterBuilder request = _supabase.from('music_tracks').select();

      // Apply search filter if query provided
      if (query != null && query.isNotEmpty) {
        request = request.or('title.ilike.%$query%,artist.ilike.%$query%');
      }

      final response = await request
          .range(offset, offset + limit - 1)
          .order('title', ascending: true);

      return (response as List)
          .map((json) => MusicTrack.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching music tracks: $e');
      return [];
    }
  }

  /// Fetch a single track by ID
  Future<MusicTrack?> fetchTrackById(String id) async {
    try {
      final response = await _supabase
          .from('music_tracks')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return MusicTrack.fromJson(response);
    } catch (e) {
      print('Error fetching track by ID: $e');
      return null;
    }
  }

  /// Fetch trending/popular tracks
  Future<List<MusicTrack>> fetchTrendingTracks({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('music_tracks')
          .select()
          .limit(limit);

      return (response as List)
          .map((json) => MusicTrack.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching trending tracks: $e');
      return [];
    }
  }
}
