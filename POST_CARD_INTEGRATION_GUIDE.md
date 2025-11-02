// INTEGRATION GUIDE: Update Post Card to Use Real Interactions
// =============================================================
// This file shows how to update post_card.dart to use InteractionService
// Replace the hardcoded _toggleLike(), _toggleBookmark(), etc. with real database calls

import 'package:flutter/material.dart';
import '../../../core/services/interaction_service.dart';
import '../../../features/posts/widgets/post_actions_menu.dart';

// ===================================================================
// STEP 1: Add InteractionService to your PostCard state
// ===================================================================
class _PostCardState extends State<PostCard> {
  final InteractionService _interactionService = InteractionService();
  
  late bool _isLiked;
  late bool _isBookmarked;
  late int _likeCount;
  late int _commentCount;
  
  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked; // Get from PostModel
    _isBookmarked = widget.post.isSaved; // Get from PostModel
    _likeCount = widget.post.likes;
    _commentCount = widget.post.comments;
    
    // Load real like/save status from database
    _loadInteractionStatus();
  }
  
  Future<void> _loadInteractionStatus() async {
    // Check if user has liked this post
    final isLiked = await _interactionService.isPostLiked(widget.post.id);
    // Check if user has saved this post
    final isSaved = await _interactionService.isPostSaved(widget.post.id);
    
    if (mounted) {
      setState(() {
        _isLiked = isLiked;
        _isBookmarked = isSaved;
      });
    }
  }
  
  // ===================================================================
  // STEP 2: Update _toggleLike to use InteractionService
  // ===================================================================
  Future<void> _toggleLike() async {
    // Optimistic update (update UI immediately)
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount += 1;
      } else if (_likeCount > 0) {
        _likeCount -= 1;
      }
    });
    
    try {
      // Update database
      final newLikeStatus = await _interactionService.toggleLike(widget.post.id);
      
      // If database update failed, revert UI
      if (newLikeStatus != _isLiked) {
        setState(() {
          _isLiked = newLikeStatus;
          _likeCount = newLikeStatus ? _likeCount + 1 : _likeCount - 1;
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }
  
  // ===================================================================
  // STEP 3: Update _toggleBookmark to use InteractionService
  // ===================================================================
  Future<void> _toggleBookmark() async {
    // Optimistic update
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    try {
      // Update database
      final newSaveStatus = await _interactionService.toggleSave(widget.post.id);
      
      // If database update failed, revert UI
      if (newSaveStatus != _isBookmarked) {
        setState(() {
          _isBookmarked = newSaveStatus;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked ? 'Post saved' : 'Post removed from saved'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save post: $e')),
        );
      }
    }
  }
  
  // ===================================================================
  // STEP 4: Update _openPostOptions to use PostActionsMenu
  // ===================================================================
  void _openPostOptions(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;
    
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostActionsMenu(
        postId: widget.post.id,
        postOwnerId: widget.post.userId,
        currentUserId: currentUserId,
        isOwnPost: widget.post.userId == currentUserId,
        onPostDeleted: () {
          // Handle post deletion
          Navigator.pop(context); // Go back
          // Optionally: Call PostProvider to remove from feed
        },
        onUserBlocked: () {
          // Handle user blocked
          Navigator.pop(context); // Go back
          // Optionally: Call PostProvider to refresh feed
        },
        onPostReported: () {
          // Handle post reported
          // Optionally: Hide this post from feed
        },
      ),
    ).whenComplete(() => navVisibility?.value = true);
  }
  
  // ===================================================================
  // STEP 5: Add real comment functionality
  // ===================================================================
  void _openComments(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Load comments from database
      final comments = await _interactionService.getComments(widget.post.id);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // Show comments in bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => _CommentsSheet(
            postId: widget.post.id,
            comments: comments,
            onCommentAdded: () {
              // Refresh comment count
              setState(() {
                _commentCount += 1;
              });
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: $e')),
        );
      }
    }
  }
  
  // ===================================================================
  // STEP 6: Record post view when card is visible
  // ===================================================================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Record view when post card is built
    _interactionService.recordPostView(
      widget.post.id,
      durationSeconds: 0, // Can track actual view duration if needed
    );
  }
}

// ===================================================================
// EXAMPLE: Comments Sheet Widget
// ===================================================================
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final List<Map<String, dynamic>> comments;
  final VoidCallback onCommentAdded;
  
  const _CommentsSheet({
    required this.postId,
    required this.comments,
    required this.onCommentAdded,
  });
  
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final InteractionService _interactionService = InteractionService();
  bool _isPosting = false;
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    setState(() => _isPosting = true);
    
    try {
      final commentId = await _interactionService.addComment(
        postId: widget.postId,
        content: content,
      );
      
      if (commentId != null) {
        _commentController.clear();
        widget.onCommentAdded();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment posted'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Comments list
              Expanded(
                child: widget.comments.isEmpty
                    ? const Center(
                        child: Text('No comments yet. Be the first!'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: widget.comments.length,
                        itemBuilder: (context, index) {
                          final comment = widget.comments[index];
                          final user = comment['users'];
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                user['photo_url'] ?? '',
                              ),
                            ),
                            title: Text(
                              user['username'] ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(comment['content']),
                            trailing: Text(
                              '${comment['likes_count'] ?? 0} ❤️',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
              ),
              
              // Comment input
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                      onPressed: _isPosting ? null : _postComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===================================================================
// USAGE SUMMARY
// ===================================================================
/*
1. Replace _toggleLike() with the new async version
2. Replace _toggleBookmark() with the new async version
3. Replace _openPostOptions() with the new PostActionsMenu version
4. Add _loadInteractionStatus() call in initState()
5. Add _openComments() implementation
6. Add _interactionService.recordPostView() in didChangeDependencies()
7. Update PostModel to include real like/save status from database

That's it! Your post cards will now use real database interactions.
*/
