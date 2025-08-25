import 'package:flutter/material.dart';
import 'package:care/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:async';
import 'shopOwnerMessaging.dart';

class ShopOwnerMessageListScreen extends StatefulWidget {
  const ShopOwnerMessageListScreen({Key? key}) : super(key: key);

  @override
  _ShopOwnerMessageListScreenState createState() => _ShopOwnerMessageListScreenState();
}

class _ShopOwnerMessageListScreenState extends State<ShopOwnerMessageListScreen>
    with WidgetsBindingObserver {

  List<Map<String, dynamic>> _messageList = [];
  bool _loading = true;
  bool _isAppInForeground = true;
  Timer? _pollingTimer;
  Map<String, Uint8List> _imageCache = {};
  bool _isLocationMessage(String message) {
    return message.startsWith('LOCATION:') && message.contains(',');
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessageList();
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppInForeground = state == AppLifecycleState.resumed;
    });

    if (_isAppInForeground) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isAppInForeground) {
        _pollMessageList();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollMessageList() async {
    if (!_isAppInForeground || _loading) return;

    try {
      final response = await ApiService().fetchShopOwnerMessageList();

      if (response['success'] && mounted) {
        final newMessageList = List<Map<String, dynamic>>.from(response['messageList']);
        setState(() {
          _messageList = newMessageList;
        });
      }
    } catch (e) {}
  }

  Future<void> _loadMessageList() async {
    try {
      setState(() {
        _loading = true;
      });

      final response = await ApiService().fetchShopOwnerMessageList();

      if (response['success']) {
        setState(() {
          _messageList = List<Map<String, dynamic>>.from(response['messageList']);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to load messages'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatMessageTime(String dateString) {
    try {
      DateTime messageDate = DateTime.parse(dateString);
      Duration diff = DateTime.now().difference(messageDate);

      if (diff.inSeconds < 60) {
        return "just now";
      } else if (diff.inMinutes < 60) {
        return "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        return "${diff.inHours}h ago";
      } else if (diff.inDays == 1) {
        return "yesterday";
      } else if (diff.inDays < 7) {
        return "${diff.inDays}d ago";
      } else {
        return "${messageDate.month}/${messageDate.day}/${messageDate.year}";
      }
    } catch (e) {
      return 'just now';
    }
  }

  String _formatUnreadCount(int count) {
    if (count >= 100) {
      return '99+';
    }
    return count.toString();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3D63).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: const Color(0xFF1A3D63).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer messages will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
        title: const Center(
          child: Text(
            'Shop Messages',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF1A3D63),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          Container(width: 48),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A3D63),
        ),
      )
          : _messageList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messageList.length,
        itemBuilder: (context, index) {
          final messageData = _messageList[index];
          return _buildMessageItem(messageData);
        },
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> messageData) {
    final unreadCount = messageData['unreadCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopOwnerMessagingScreen(
                  customer: messageData,
                ),
              ),
            ).then((_) => _loadMessageList());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    _buildCachedProfileImage(messageData),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0, // moved inside so not cut
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4757), Color(0xFFFF3742)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4757).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              _formatUnreadCount(unreadCount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${messageData['firstName']} ${messageData['surName']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                color: const Color(0xFF1A3D63),
                              ),
                            ),
                          ),
                          Text(
                            _formatMessageTime(messageData['stamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3D63).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          messageData['shopName'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1A3D63),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLocationMessage(messageData['message'])
                            ? 'User Shared Location'
                            : messageData['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: unreadCount > 0 ? Colors.grey[800] : Colors.grey[600],
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildCachedProfileImage(Map<String, dynamic> messageData) {
    final photoUrl = messageData['photoUrl'];
    final cacheKey = photoUrl ?? 'default_${messageData['accountId']}';

    Widget buildImage(Uint8List? imageBytes) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A3D63).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: imageBytes != null
              ? Image.memory(
            imageBytes,
            fit: BoxFit.cover,
          )
              : Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A3D63), Color(0xFF2A5A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(messageData['firstName'], messageData['surName']),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_imageCache.containsKey(cacheKey)) {
      return buildImage(_imageCache[cacheKey]);
    }

    return FutureBuilder<Uint8List?>(
      future: _getProfileImage(photoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _imageCache[cacheKey] = snapshot.data!;
        }
        return buildImage(snapshot.data);
      },
    );
  }


  Future<Uint8List?> _getProfileImage(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) {
      final ByteData data =
      await rootBundle.load('assets/images/profilePlaceHolder.png');
      return data.buffer.asUint8List();
    }
    try {
      final String imageUrl = photoUrl.contains('http')
          ? photoUrl
          : '${ApiService.apiUrl}profilePicture/$photoUrl';
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    final ByteData data =
    await rootBundle.load('assets/images/profilePlaceHolder.png');
    return data.buffer.asUint8List();
  }

  String _getInitials(String? firstName, String? surName) {
    String firstInitial = firstName != null && firstName.isNotEmpty
        ? firstName[0].toUpperCase()
        : '';
    String surInitial =
    surName != null && surName.isNotEmpty ? surName[0].toUpperCase() : '';
    return '$firstInitial$surInitial';
  }
}