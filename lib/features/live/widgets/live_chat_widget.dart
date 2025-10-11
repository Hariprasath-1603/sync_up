import 'package:flutter/material.dart';
import '../models/live_chat_message.dart';

class LiveChatWidget extends StatefulWidget {
  final String streamId;
  final List<LiveChatMessage> messages;
  final Function(String) onSendMessage;

  const LiveChatWidget({
    super.key,
    required this.streamId,
    required this.messages,
    required this.onSendMessage,
  });

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.messages.isEmpty
          ? Center(
              child: Text(
                'Chat is empty. Be the first to comment!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                return _buildMessage(message);
              },
            ),
    );
  }

  Widget _buildMessage(LiveChatMessage message) {
    switch (message.type) {
      case MessageType.join:
        return _buildSystemMessage(message, Icons.login, Colors.green);
      case MessageType.leave:
        return _buildSystemMessage(message, Icons.logout, Colors.orange);
      case MessageType.gift:
        return _buildGiftMessage(message);
      default:
        return _buildChatMessage(message);
    }
  }

  Widget _buildChatMessage(LiveChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              if (message.isAuthorVerified)
                const WidgetSpan(
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.verified,
                      color: Color(0xFF4A6CF7),
                      size: 14,
                    ),
                  ),
                ),
              TextSpan(
                text: '${message.authorUsername}: ',
                style: const TextStyle(
                  color: Color(0xFF4A6CF7),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: message.message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(
    LiveChatMessage message,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.message,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftMessage(LiveChatMessage message) {
    final giftValue = message.metadata?['value'] ?? 0.0;
    final giftName = message.metadata?['gift_name'] ?? 'Gift';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${message.authorUsername} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: 'sent $giftName (\$$giftValue)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
