import 'package:flutter/material.dart';
import 'create_post_page.dart';

class DraftsPage extends StatefulWidget {
  const DraftsPage({super.key});

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  // Theme helper methods
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B0E13)
        : const Color(0xFFF6F7FB);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1D24)
        : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.grey[600]!;
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.grey[300]!;
  }

  // Mock draft data - TODO: Load from local storage/server
  final List<Map<String, dynamic>> _drafts = [
    {
      'id': '1',
      'title': 'Summer Vacation Plans',
      'text': 'Thinking about visiting the beach this summer...',
      'audience': 'Friends',
      'hasMedia': true,
      'mediaCount': 3,
      'location': {'name': 'Miami Beach'},
      'savedAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': '2',
      'title': '',
      'text': 'Just finished reading an amazing book! #reading #books',
      'audience': 'Public',
      'hasMedia': false,
      'mediaCount': 0,
      'savedAt': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '3',
      'title': 'Weekend Workout',
      'text': 'Morning run completed! Feeling energized 💪',
      'audience': 'Public',
      'hasMedia': true,
      'mediaCount': 1,
      'feeling': '😊 Happy',
      'savedAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': '4',
      'title': 'Product Launch',
      'text': 'Excited to announce our new product line...',
      'audience': 'Public',
      'hasMedia': true,
      'mediaCount': 5,
      'scheduledDate': DateTime.now().add(const Duration(days: 3)),
      'savedAt': DateTime.now().subtract(const Duration(hours: 12)),
    },
    {
      'id': '5',
      'title': '',
      'text': 'Coffee time ☕',
      'audience': 'Only me',
      'hasMedia': false,
      'mediaCount': 0,
      'savedAt': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];

  String _sortBy = 'recent'; // 'recent', 'oldest', 'alphabetical'

  void _sortDrafts() {
    setState(() {
      if (_sortBy == 'recent') {
        _drafts.sort(
          (a, b) =>
              (b['savedAt'] as DateTime).compareTo(a['savedAt'] as DateTime),
        );
      } else if (_sortBy == 'oldest') {
        _drafts.sort(
          (a, b) =>
              (a['savedAt'] as DateTime).compareTo(b['savedAt'] as DateTime),
        );
      } else if (_sortBy == 'alphabetical') {
        _drafts.sort((a, b) {
          final aText = (a['title'] as String).isNotEmpty
              ? a['title']
              : a['text'];
          final bText = (b['title'] as String).isNotEmpty
              ? b['title']
              : b['text'];
          return aText.compareTo(bText);
        });
      }
    });
  }

  void _openDraft(Map<String, dynamic> draft) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage(draftData: draft)),
    );

    if (result == true) {
      // Draft was published, remove from list
      setState(() {
        _drafts.removeWhere((d) => d['id'] == draft['id']);
      });
    }
  }

  void _deleteDraft(Map<String, dynamic> draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(context),
        title: Text(
          'Delete Draft?',
          style: TextStyle(color: _getTextColor(context)),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: _getSubtitleColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _drafts.removeWhere((d) => d['id'] == draft['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Draft deleted'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteAllDrafts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(context),
        title: Text(
          'Delete All Drafts?',
          style: TextStyle(color: _getTextColor(context)),
        ),
        content: Text(
          'This will permanently delete all ${_drafts.length} drafts. This action cannot be undone.',
          style: TextStyle(color: _getSubtitleColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _drafts.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All drafts deleted'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sort By',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption(Icons.schedule, 'Most Recent', 'recent'),
            _buildSortOption(Icons.history, 'Oldest First', 'oldest'),
            _buildSortOption(
              Icons.sort_by_alpha,
              'Alphabetical',
              'alphabetical',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(IconData icon, String label, String sortType) {
    return ListTile(
      leading: Icon(icon, color: _getTextColor(context)),
      title: Text(label, style: TextStyle(color: _getTextColor(context))),
      trailing: _sortBy == sortType
          ? const Icon(Icons.check, color: Color(0xFF4A6CF7))
          : null,
      onTap: () {
        setState(() {
          _sortBy = sortType;
        });
        _sortDrafts();
        Navigator.pop(context);
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: _getCardColor(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Drafts', style: TextStyle(color: _getTextColor(context))),
        actions: [
          IconButton(
            icon: Icon(Icons.sort, color: _getTextColor(context)),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
          if (_drafts.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: _getTextColor(context)),
              onPressed: _deleteAllDrafts,
              tooltip: 'Delete all',
            ),
        ],
      ),
      body: _drafts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.drafts,
                    size: 80,
                    color: _getSubtitleColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No drafts',
                    style: TextStyle(
                      color: _getSubtitleColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your saved drafts will appear here',
                    style: TextStyle(
                      color: _getSubtitleColor(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Draft count
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: _getCardColor(context),
                  child: Text(
                    '${_drafts.length} ${_drafts.length == 1 ? 'draft' : 'drafts'}',
                    style: TextStyle(
                      color: _getSubtitleColor(context),
                      fontSize: 14,
                    ),
                  ),
                ),

                // Drafts list
                Expanded(
                  child: ListView.builder(
                    itemCount: _drafts.length,
                    itemBuilder: (context, index) {
                      final draft = _drafts[index];
                      return _buildDraftCard(draft);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> draft) {
    final hasTitle = (draft['title'] as String).isNotEmpty;
    final displayTitle = hasTitle ? draft['title'] : draft['text'];
    final displayText = hasTitle ? draft['text'] : null;

    return Dismissible(
      key: Key(draft['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteDraft(draft);
      },
      child: GestureDetector(
        onTap: () => _openDraft(draft),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.drafts,
                      size: 16,
                      color: _getSubtitleColor(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(draft['savedAt']),
                      style: TextStyle(
                        color: _getSubtitleColor(context),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getAudienceColor(draft['audience']),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAudienceIcon(draft['audience']),
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            draft['audience'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteDraft(draft),
                      child: Icon(
                        Icons.more_vert,
                        color: _getSubtitleColor(context),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: TextStyle(
                        color: _getTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displayText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        displayText,
                        style: TextStyle(
                          color: _getSubtitleColor(context),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Footer info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (draft['hasMedia'] == true)
                      _buildInfoChip(
                        Icons.image,
                        '${draft['mediaCount']} media',
                        Colors.blue,
                      ),
                    if (draft['location'] != null)
                      _buildInfoChip(
                        Icons.location_on,
                        draft['location']['name'],
                        Colors.red,
                      ),
                    if (draft['feeling'] != null)
                      _buildInfoChip(
                        Icons.emoji_emotions,
                        draft['feeling'],
                        Colors.orange,
                      ),
                    if (draft['scheduledDate'] != null)
                      _buildInfoChip(Icons.schedule, 'Scheduled', Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Color _getAudienceColor(String audience) {
    switch (audience) {
      case 'Public':
        return Colors.blue;
      case 'Friends':
        return Colors.green;
      case 'Only me':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData _getAudienceIcon(String audience) {
    switch (audience) {
      case 'Public':
        return Icons.public;
      case 'Friends':
        return Icons.people;
      case 'Only me':
        return Icons.lock;
      default:
        return Icons.settings;
    }
  }
}
