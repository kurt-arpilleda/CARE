import 'package:flutter/material.dart';
import 'package:care/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:care/findShop/reportUserDialog.dart';
import '../../firebase/firebase_service.dart';
import 'userVehicleDialog.dart';
import 'googleMapUserDialog.dart';

class ShopOwnerMessagingScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  const ShopOwnerMessagingScreen({Key? key, required this.customer}) : super(key: key);

  @override
  _ShopOwnerMessagingScreenState createState() => _ShopOwnerMessagingScreenState();
}

class _ShopOwnerMessagingScreenState extends State<ShopOwnerMessagingScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _isAppInForeground = true;
  Timer? _pollingTimer;
  Map<String, Uint8List> _imageCache = {};
  List<String> _receiverFcmTokens = [];
  Map<String, bool> _acceptedRequests = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _loadReceiverFcmTokens();
    _startPolling();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
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

  bool _isLocationMessage(String message) {
    return message.startsWith('LOCATION:') && message.contains(',');
  }

  List<double> _extractCoordinates(String message) {
    final coords = message.replaceFirst('LOCATION:', '').split(',');
    return [double.parse(coords[0].trim()), double.parse(coords[1].trim())];
  }

  bool _isLocationRequestExpired(String timestamp) {
    try {
      DateTime messageTime = DateTime.parse(timestamp);
      DateTime currentTime = DateTime.now();
      Duration difference = currentTime.difference(messageTime);
      return difference.inHours >= 6;
    } catch (e) {
      return true;
    }
  }

  String _getMessageId(Map<String, dynamic> message) {
    return message['id']?.toString() ?? '';
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isAppInForeground) {
        _pollMessages();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollMessages() async {
    if (!_isAppInForeground || _loading) return;

    try {
      final response = await ApiService().fetchShopOwnerMessages(
        shopId: int.parse(widget.customer['shopId'].toString()),
        customerId: int.parse(widget.customer['accountId'].toString()),
      );

      if (response['success']) {
        final newMessages = List<Map<String, dynamic>>.from(
            response['messages']);

        if (mounted) {
          _updateMessages(newMessages);
        }
      }
    } catch (e) {}
  }

  void _updateMessages(List<Map<String, dynamic>> newMessages) {
    final oldMessageIds = _messages
        .map((m) => m['id']?.toString() ?? '')
        .toSet();
    final newMessageIds = newMessages
        .map((m) => m['id']?.toString() ?? '')
        .toSet();

    final addedMessages = newMessages.where((m) {
      final id = m['id']?.toString() ?? '';
      return id.isNotEmpty && !oldMessageIds.contains(id);
    }).toList();

    if (addedMessages.isNotEmpty) {
      final wasAtBottom = _scrollController.hasClients &&
          (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100);

      setState(() {
        _messages = newMessages;
      });

      if (wasAtBottom) {
        _scrollToBottom();
      }
    } else if (newMessages.length != _messages.length) {
      setState(() {
        _messages = newMessages;
      });
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _loading = true;
      });

      final response = await ApiService().fetchShopOwnerMessages(
        shopId: int.parse(widget.customer['shopId'].toString()),
        customerId: int.parse(widget.customer['accountId'].toString()),
      );

      if (response['success']) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response['messages']);
          _loading = false;
        });

        _scrollToBottom(animate: false);
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

  Future<void> _loadReceiverFcmTokens() async {
    try {
      final accountId = int.tryParse(widget.customer['accountId'].toString());
      if (accountId == null) {
        print('Invalid account ID: ${widget.customer['accountId']}');
        return;
      }

      final response = await ApiService().getFcmTokensByAccountId(accountId);
      if (response['success']) {
        setState(() {
          _receiverFcmTokens = List<String>.from(response['fcmTokens']);
        });
        print('Loaded FCM tokens for receiver: $_receiverFcmTokens');
      }
    } catch (e) {
      print('Error loading FCM tokens: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text
        .trim()
        .isEmpty) return;
    final String messageText = _messageController.text.trim();
    _messageController.clear();
    try {
      final response = await ApiService().sendShopOwnerMessage(
        shopId: int.parse(widget.customer['shopId'].toString()),
        customerId: int.parse(widget.customer['accountId'].toString()),
        message: messageText,
      );
      if (response['success']) {
        await _pollMessages();
        _scrollToBottom();

        final userResponse = await ApiService().getUserData();
        if (userResponse['success']) {
          final user = userResponse['user'];
          final shopOwnerName = '${user['firstName']} ${user['surName']}';

          for (String token in _receiverFcmTokens) {
            await FirebaseService.sendPushNotification(
              receiverToken: token,
              title: 'Shop Owner: $shopOwnerName',
              body: messageText,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to send message'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _messageController.text = messageText;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _messageController.text = messageText;
    }
  }

  void _showServiceRequestDialog(Map<String, dynamic> messageData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.location_on,
                color: const Color(0xFF1A3D63),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Service Request',
                style: TextStyle(
                  color: Color(0xFF1A3D63),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you accepting ${messageData['firstName']} ${messageData['surName']}\'s request for your service?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Once accepted, you\'ll be able to view the customer\'s location.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Decline',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await ApiService().acceptLocationRequest(
                    messageId: int.parse(messageData['id'].toString()),
                  );

                  if (response['success']) {
                    setState(() {
                      _acceptedRequests[_getMessageId(messageData)] = true;
                    });
                    Navigator.of(context).pop();

                    // Send acceptance message
                    final userResponse = await ApiService().getUserData();
                    if (userResponse['success']) {
                      final user = userResponse['user'];
                      final acceptMessage = 'Shop Owner Accept';

                      final sendResponse = await ApiService().sendShopOwnerMessage(
                        shopId: int.parse(widget.customer['shopId'].toString()),
                        customerId: int.parse(widget.customer['accountId'].toString()),
                        message: acceptMessage,
                      );

                      if (sendResponse['success']) {
                        await _pollMessages();
                      }
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Service request accepted!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message'] ?? 'Failed to accept request'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error accepting request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3D63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageContent(String text, bool isMe,
      Map<String, dynamic> messageData, bool isLocationMsg, bool isExpired,
      bool isAccepted) {
    if (isLocationMsg && !isMe) {
      if (isExpired) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                color: Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Request Expired',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      } else if (isAccepted || messageData['isAccept'] == 1) {
        return GestureDetector(
          onTap: () {
            final coords = _extractCoordinates(text);
            showDialog(
              context: context,
              builder: (context) =>
                  GoogleMapUserDialog(
                    latitude: coords[0],
                    longitude: coords[1],
                    userName: '${messageData['firstName']} ${messageData['surName']}',
                    photoUrl: messageData['photoUrl'],
                    accountId: int.parse(messageData['accountId'].toString()),
                  ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: isMe ? Colors.white : const Color(0xFF1A3D63),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Location Shared',
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF1A3D63),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return GestureDetector(
          onTap: () {
            _showServiceRequestDialog(messageData);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.handyman,
                  color: isMe ? Colors.white : const Color(0xFF1A3D63),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'User sent formal request',
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF1A3D63),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Text(
      isLocationMsg && isMe ? 'Location Shared' : text,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black,
        fontSize: 16,
      ),
    );
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
            'Start a conversation with ${widget.customer['firstName'] ??
                ''} ${widget.customer['surName'] ?? ''}',
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildCustomerProfileImage(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.customer['firstName'] ?? ''} ${widget
                        .customer['surName'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.customer['shopName'] ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1A3D63),
                ),
              )
                  : _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery
                      .of(context)
                      .viewInsets
                      .bottom > 0 ? 16 : 16,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(
                    text: message['message'],
                    isMe: message['isMe'],
                    time: _formatMessageTime(message['stamp']),
                    isCustomer: !message['isMe'],
                    messageData: message,
                  );
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildCustomerProfileImage() {
    final photoUrl = widget.customer['photoUrl'];
    final cacheKey = photoUrl ?? 'default_${widget.customer['accountId']}';

    Widget buildImage(Uint8List? imageBytes) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
        backgroundColor: const Color(0xFF1A3D63),
        child: imageBytes == null
            ? Text(
          _getInitials(
              widget.customer['firstName'], widget.customer['surName']),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        )
            : null,
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

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    required String time,
    required bool isCustomer,
    required Map<String, dynamic> messageData,
  }) {
    final messageId = _getMessageId(messageData);
    final isLocationMsg = _isLocationMessage(text);
    final isExpired = _isLocationRequestExpired(messageData['stamp']);
    final isAccepted = _acceptedRequests[messageId] == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && isCustomer)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _buildCachedCustomerImage(messageData),
            ),
          if (!isMe && isCustomer) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && isCustomer)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${messageData['firstName']} ${messageData['surName']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF1A3D63) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : Radius
                          .zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(
                          16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(
                      text, isMe, messageData, isLocationMsg, isExpired,
                      isAccepted),
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
    );
  }

  Widget _buildCachedCustomerImage(Map<String, dynamic> messageData) {
    final photoUrl = messageData['photoUrl'];
    final cacheKey = photoUrl ?? 'default';

    if (_imageCache.containsKey(cacheKey)) {
      final imageBytes = _imageCache[cacheKey];
      return GestureDetector(
        onTap: () {
          _showReportUserDialog(messageData);
        },
        child: CircleAvatar(
          radius: 20,
          backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
          backgroundColor: const Color(0xFF1A3D63),
          child: imageBytes == null
              ? Text(
            _getInitials(messageData['firstName'], messageData['surName']),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _getProfileImage(photoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _imageCache[cacheKey] = snapshot.data!;
        }

        final imageBytes = snapshot.data;
        return GestureDetector(
          onTap: () {
            _showReportUserDialog(messageData);
          },
          child: CircleAvatar(
            radius: 20,
            backgroundImage: imageBytes != null
                ? MemoryImage(imageBytes)
                : null,
            backgroundColor: const Color(0xFF1A3D63),
            child: imageBytes == null
                ? Text(
              _getInitials(messageData['firstName'], messageData['surName']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
        );
      },
    );
  }

  void _showReportUserDialog(Map<String, dynamic> messageData) {
    final reportedId = int.tryParse(messageData['accountId'].toString()) ?? 0;
    final userName = '${messageData['firstName']} ${messageData['surName']}';

    if (reportedId > 0) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: _imageCache.containsKey(
                            messageData['photoUrl'] ?? 'default')
                            ? MemoryImage(
                            _imageCache[messageData['photoUrl'] ?? 'default']!)
                            : null,
                        backgroundColor: const Color(0xFF1A3D63),
                        child: _imageCache.containsKey(
                            messageData['photoUrl'] ?? 'default')
                            ? null
                            : Text(
                          _getInitials(
                              messageData['firstName'], messageData['surName']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3D63),
                              ),
                            ),
                            Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3D63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_car_outlined,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    title: const Text(
                      'View Vehicles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('View customer\'s active vehicles'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) =>
                            UserVehicleDialog(
                              userId: reportedId,
                              userName: userName,
                            ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.report_outlined,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Report User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Report inappropriate behavior'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) =>
                            ReportUserDialog(
                              reportedId: reportedId,
                              userName: userName,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
      );
    }
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

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery
            .of(context)
            .padding
            .bottom + 8,
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
              focusNode: _focusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
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