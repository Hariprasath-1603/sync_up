import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              post.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(post.userAvatarUrl)),
            title: Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post.userHandle, style: const TextStyle(color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildStatIcon(Icons.favorite_border, post.likes),
                const SizedBox(width: 24),
                _buildStatIcon(Icons.chat_bubble_outline, post.comments),
                const SizedBox(width: 24),
                _buildStatIcon(Icons.send_outlined, post.shares),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 6),
        Text(count, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
      ],
    );
  }
}