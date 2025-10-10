import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              kPrimary.withOpacity(0.8),
                              kPrimary.withOpacity(0.4),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(post.userAvatarUrl),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              post.userHandle,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Post Image
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: Stack(
                    children: [
                      Image.network(
                        post.imageUrl,
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildGlassActionButton(
                        Icons.favorite_border,
                        post.likes,
                        isDark,
                        isLike: true,
                      ),
                      const SizedBox(width: 16),
                      _buildGlassActionButton(
                        Icons.chat_bubble_outline,
                        post.comments,
                        isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildGlassActionButton(
                        Icons.send_outlined,
                        post.shares,
                        isDark,
                      ),
                      const Spacer(),
                      _buildGlassActionButton(
                        Icons.bookmark_border,
                        '',
                        isDark,
                        showCount: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassActionButton(
    IconData icon,
    String count,
    bool isDark, {
    bool isLike = false,
    bool showCount = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isLike
                    ? Colors.red.shade400
                    : (isDark ? Colors.white70 : Colors.black87),
                size: 20,
              ),
              if (showCount && count.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  count,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}