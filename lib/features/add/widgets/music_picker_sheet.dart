import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music_track_model.dart';
import '../services/music_service.dart';

/// Music Picker Widget - Fetch and preview music from Supabase
class MusicPickerSheet extends StatefulWidget {
  final Function(MusicTrack) onTrackSelected;

  const MusicPickerSheet({super.key, required this.onTrackSelected});

  @override
  State<MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<MusicTrack> _tracks = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _playingTrackId;

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreTracks();
      }
    }
  }

  Future<void> _loadTracks({String? query}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _offset = 0;
      _tracks.clear();
    });

    final tracks = await _musicService.fetchTracks(
      query: query,
      offset: _offset,
      limit: _limit,
    );

    setState(() {
      _tracks = tracks;
      _hasMore = tracks.length == _limit;
      _offset = tracks.length;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreTracks() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final tracks = await _musicService.fetchTracks(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      offset: _offset,
      limit: _limit,
    );

    setState(() {
      _tracks.addAll(tracks);
      _hasMore = tracks.length == _limit;
      _offset += tracks.length;
      _isLoading = false;
    });
  }

  Future<void> _togglePreview(MusicTrack track) async {
    if (_playingTrackId == track.id) {
      await _audioPlayer.stop();
      setState(() => _playingTrackId = null);
    } else {
      final url = track.previewUrl ?? track.url;
      if (url.isEmpty) return;

      try {
        await _audioPlayer.setUrl(url);
        await _audioPlayer.play();
        setState(() => _playingTrackId = track.id);

        // Auto-stop after preview
        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() => _playingTrackId = null);
          }
        });
      } catch (e) {
        print('Error playing preview: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play preview')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1D24)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Add Music',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                hintStyle: GoogleFonts.poppins(fontSize: 14),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _loadTracks(query: value.isEmpty ? null : value);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Track List
          Expanded(
            child: _tracks.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No tracks found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _tracks.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _tracks.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final track = _tracks[index];
                      final isPlaying = _playingTrackId == track.id;

                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5B3FFF), Color(0xFF00E0FF)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.music_note,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          track.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${track.artist} • ${track.formattedDuration}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.stop : Icons.play_arrow,
                                color: const Color(0xFF5B3FFF),
                              ),
                              onPressed: () => _togglePreview(track),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          _audioPlayer.stop();
                          widget.onTrackSelected(track);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
