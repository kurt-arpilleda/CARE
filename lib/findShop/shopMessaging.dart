import 'package:flutter/material.dart';
import 'package:care/api_service.dart';

class ShopMessagingScreen extends StatefulWidget {
  final dynamic shop;
  const ShopMessagingScreen({Key? key, required this.shop}) : super(key: key);

  @override
  _ShopMessagingScreenState createState() => _ShopMessagingScreenState();
}

class _ShopMessagingScreenState extends State<ShopMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _loading = true;
      });

      final response = await ApiService().fetchShopMessages(
        shopId: widget.shop['shopId'],
      );

      if (response['success']) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response['messages']);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final response = await ApiService().sendMessageToShop(
        shopId: widget.shop['shopId'],
        message: messageText,
      );

      if (response['success']) {
        await _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
        _messageController.text = messageText;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _messageController.text = messageText;
    }
  }

  String _formatMessageTime(String dateString) {
    try {
      DateTime messageDate = DateTime.parse(dateString);
      return '${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Now';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            widget.shop['shopLogo'] != null
                ? CircleAvatar(
              backgroundImage: NetworkImage(
                '${ApiService.apiUrl}shopLogo/${widget.shop['shopLogo']}',
              ),
              radius: 20,
              onBackgroundImageError: (_, __) {},
            )
                : CircleAvatar(
              backgroundColor: const Color(0xFF1A3D63),
              radius: 20,
              child: Text(
                widget.shop['shop_name'] != null &&
                    widget.shop['shop_name'].isNotEmpty
                    ? widget.shop['shop_name'][0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.shop['shop_name'] ?? 'Shop',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A3D63),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A3D63),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(
                  text: message['message'],
                  isMe: message['isMe'],
                  time: _formatMessageTime(message['stamp']),
                  isShopOwner: !message['isMe'],
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    required String time,
    required bool isShopOwner,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: isMe ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (!isMe && isShopOwner)
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(
                  '${ApiService.apiUrl}shopLogo/${widget.shop['shopLogo']}',
                ),
                onBackgroundImageError: (_, __) {},
                backgroundColor: const Color(0xFF1A3D63),
                child: widget.shop['shopLogo'] == null
                    ? Text(
                  widget.shop['shop_name'] != null &&
                      widget.shop['shop_name'].isNotEmpty
                      ? widget.shop['shop_name'][0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
            if (!isMe && isShopOwner) const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF1A3D63)
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                        isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight:
                        isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A3D63),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}