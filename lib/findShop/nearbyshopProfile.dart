import 'dart:async';

import 'package:flutter/material.dart';
import 'package:care/api_service.dart';
import 'reportDialog.dart';
import 'shopMessaging.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NearbyShopProfileScreen extends StatefulWidget {
  final dynamic shop;

  const NearbyShopProfileScreen({Key? key, required this.shop}) : super(key: key);

  @override
  _NearbyShopProfileScreenState createState() => _NearbyShopProfileScreenState();
}

class _NearbyShopProfileScreenState extends State<NearbyShopProfileScreen>
    with WidgetsBindingObserver {
  bool _showFullServices = false;
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;
  int _totalReviews = 0;
  int _currentLimit = 5;
  Map<String, Uint8List> _profileImages = {};
  int _unreadMessagesCount = 0;
  Timer? _messagePollingTimer;
  bool _isAppInForeground = true;
  DateTime? _lastMessageCountUpdate;
  bool _isOpen = false;
  Timer? _statusTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReviews();
    _loadUnreadMessagesCount();
    _startMessagePolling();
    _updateStatus();
    _startStatusTimer();
  }
  bool _isShopOpen(dynamic shop) {
    try {
      DateTime now = DateTime.now();
      int currentDay = now.weekday - 1;
      if (!shop['day_index'].contains(currentDay.toString())) return false;

      List<String> startParts = shop['start_time'].split(':');
      List<String> closeParts = shop['close_time'].split(':');

      TimeOfDay startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );

      TimeOfDay closeTime = TimeOfDay(
        hour: int.parse(closeParts[0]),
        minute: int.parse(closeParts[1]),
      );

      TimeOfDay currentTime = TimeOfDay.fromDateTime(now);

      int startInMinutes = startTime.hour * 60 + startTime.minute;
      int closeInMinutes = closeTime.hour * 60 + closeTime.minute;
      int currentInMinutes = currentTime.hour * 60 + currentTime.minute;

      if (closeInMinutes < startInMinutes) {
        return currentInMinutes >= startInMinutes || currentInMinutes <= closeInMinutes;
      } else {
        return currentInMinutes >= startInMinutes && currentInMinutes <= closeInMinutes;
      }
    } catch (e) {
      return false;
    }
  }

  void _startStatusTimer() {
    _statusTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        setState(() {
          _isOpen = _isShopOpen(widget.shop);
        });
      }
    });
  }

  void _updateStatus() {
    setState(() {
      _isOpen = _isShopOpen(widget.shop);
    });
  }
  Future<void> _loadUnreadMessagesCount() async {
    try {
      final response = await ApiService().getUnreadMessagesCount(
        shopId: widget.shop['shopId'],
      );
      if (response['success'] && mounted) {
        setState(() {
          _unreadMessagesCount = response['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  String _formatUnreadCount(int count) {
    if (count >= 100) {
      return '99+';
    }
    return count.toString();
  }

  Future<void> _loadReviews({int? limit}) async {
    try {
      setState(() {
        _loadingReviews = true;
      });

      final response = await ApiService().fetchShopReviews(
        shopId: widget.shop['shopId'],
        limit: limit ?? _currentLimit,
      );

      if (response['success']) {
        List<dynamic> reviews = response['reviews'];

        for (var review in reviews) {
          String accountId = review['accountId'].toString();
          if (!_profileImages.containsKey(accountId)) {
            await _loadProfileImage(accountId, review['photoUrl']);
          }
        }

        setState(() {
          _reviews = reviews;
          _totalReviews = response['total'] ?? 0;
          _loadingReviews = false;
        });
      } else {
        setState(() {
          _loadingReviews = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingReviews = false;
      });
    }
  }

  Future<void> _loadProfileImage(String accountId, String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) return;

    try {
      final String imageUrl = photoUrl.contains('http')
          ? photoUrl
          : '${ApiService.apiUrl}profilePicture/$photoUrl';

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        _profileImages[accountId] = response.bodyBytes;
      }
    } catch (_) {}
  }

  double _getOverallRating() {
    if (_reviews.isEmpty) return 0.0;

    double totalRating = 0.0;
    for (var review in _reviews) {
      totalRating += (review['rating'] ?? 0).toDouble();
    }

    return totalRating / _reviews.length;
  }

  String _formatReviewDate(String dateString) {
    try {
      DateTime reviewDate = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      Duration difference = now.difference(reviewDate);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMessagePolling();
    _feedbackController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppInForeground = state == AppLifecycleState.resumed;
    });
    if (_isAppInForeground) {
      _startMessagePolling();
    } else {
      _stopMessagePolling();
    }
  }
  void _startMessagePolling() {
    _stopMessagePolling();
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isAppInForeground) {
        _updateMessageCount();
      }
    });
  }

  void _stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
  }

  Future<void> _updateMessageCount() async {
    final now = DateTime.now();
    if (_lastMessageCountUpdate != null &&
        now.difference(_lastMessageCountUpdate!).inSeconds < 2) {
      return;
    }
    _lastMessageCountUpdate = now;
    await _loadUnreadMessagesCount();
  }
  List<String> _getOperatingDays() {
    try {
      List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      List<String> selectedDays = [];

      String dayIndex = widget.shop['day_index'] ?? '';
      for (int i = 0; i < dayIndex.length; i++) {
        if (int.tryParse(dayIndex[i]) != null) {
          int index = int.parse(dayIndex[i]);
          if (index >= 0 && index < dayNames.length) {
            selectedDays.add(dayNames[index]);
          }
        }
      }

      return selectedDays.isNotEmpty ? selectedDays : ['Not specified'];
    } catch (e) {
      return ['Not specified'];
    }
  }

  String _formatTime(String time24) {
    try {
      List<String> parts = time24.split(':');
      if (parts.length < 2) return time24;
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      String period = hour >= 12 ? 'pm' : 'am';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      String minuteStr = minute.toString().padLeft(2, '0');

      return '$hour:$minuteStr $period';
    } catch (e) {
      return time24;
    }
  }

  String _getOperatingTime() {
    try {
      String startTime = widget.shop['start_time'] ?? '00:00:00';
      String closeTime = widget.shop['close_time'] ?? '23:59:59';

      return '${_formatTime(startTime)} - ${_formatTime(closeTime)}';
    } catch (e) {
      return 'Time not available';
    }
  }

  List<String> _getServicesList() {
    String services = widget.shop['services'] ?? '';
    if (services.isEmpty) return ['No services listed'];

    List<String> serviceList = services
        .split(RegExp(r'[,;\n]'))
        .map((service) => service.trim())
        .where((service) => service.isNotEmpty)
        .toList();

    return serviceList.isNotEmpty ? serviceList : [services];
  }

  List<String> _getDisplayedServices() {
    List<String> allServices = _getServicesList();
    if (_showFullServices || allServices.length <= 3) {
      return allServices;
    }
    return allServices.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A3D63),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A3D63), Color(0xFF2A5A8A)],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: widget.shop['shopLogo'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        '${ApiService.apiUrl}shopLogo/${widget.shop['shopLogo']}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.car_repair,
                          color: Color(0xFF1A3D63),
                          size: 50,
                        ),
                      ),
                    )
                        : const Icon(
                      Icons.car_repair,
                      color: Color(0xFF1A3D63),
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.message_outlined, color: Colors.white),
                    onPressed: () async {
                      await ApiService().markMessagesAsRead(
                        shopId: widget.shop['shopId'],
                      );
                      setState(() {
                        _unreadMessagesCount = 0;
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopMessagingScreen(shop: widget.shop),
                        ),
                      );
                    },
                  ),
                  if (_unreadMessagesCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _formatUnreadCount(_unreadMessagesCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.report_outlined, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ReportDialog(shopId: widget.shop['shopId']),
                  );
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shop['shop_name'] ?? 'Unknown Shop',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF1A3D63), size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.shop['location'] ?? 'Location not specified',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isOpen
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              color: _isOpen ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionCard(
                      title: 'Operating Hours',
                      icon: Icons.schedule,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF1A3D63).withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF1A3D63),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Operating Days',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A3D63),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: _getOperatingDays().map((day) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A3D63),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF1A3D63).withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Color(0xFF1A3D63),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Operating Time',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A3D63),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF1A3D63).withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    _getOperatingTime(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A3D63),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Services Offered',
                      icon: Icons.build,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF1A3D63).withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.miscellaneous_services,
                                      color: Color(0xFF1A3D63),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Available Services',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A3D63),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: _getDisplayedServices().map((service) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A3D63),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      service,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                          if (_getServicesList().length > 3)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showFullServices = !_showFullServices;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                              ),
                              child: Text(
                                _showFullServices ? 'See less' : 'See more',
                                style: const TextStyle(
                                  color: Color(0xFF1A3D63),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.contact_phone,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.shop['phoneNum'] != null && widget.shop['phoneNum'].toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone, color: Color(0xFF1A3D63), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final phoneNumber = widget.shop['phoneNum'].toString().trim();
                                        bool? confirmCall = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Call Shop'),
                                            content: Text('Do you want to call $phoneNumber?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Call'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmCall == true) {
                                          final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                                          if (await canLaunchUrl(phoneUri)) {
                                            await launchUrl(phoneUri);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Could not make the call')),
                                            );
                                          }
                                        }
                                      },
                                      child: Text(
                                        widget.shop['phoneNum'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF1A3D63),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Color(0xFF1A3D63), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Phone not available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          if (widget.shop['home_page'] != null && widget.shop['home_page'].toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.web, color: Color(0xFF1A3D63), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        String urlString = widget.shop['home_page'].trim();
                                        if (!urlString.startsWith('http')) {
                                          urlString = 'https://$urlString';
                                        }
                                        final Uri url = Uri.parse(urlString);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open the link')),
                                          );
                                        }
                                      },
                                      child: Text(
                                        widget.shop['home_page'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF1A3D63),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionCard(
                      title: 'Submit Review',
                      icon: Icons.star_rate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rate this shop:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A3D63),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onHorizontalDragUpdate: (details) {
                                  final box = context.findRenderObject() as RenderBox?;
                                  if (box == null) return;

                                  final localPosition = box.globalToLocal(details.globalPosition);
                                  final ratingWidth = box.size.width;
                                  final rawRating = localPosition.dx / ratingWidth * 5;
                                  final ratingValue = rawRating < 0
                                      ? 0
                                      : rawRating.ceil().clamp(0, 5);

                                  if (ratingValue != _selectedRating) {
                                    setState(() {
                                      _selectedRating = ratingValue;
                                    });
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedRating = _selectedRating == index + 1 ? 0 : index + 1;
                                        });
                                      },
                                      child: Icon(
                                        index < _selectedRating ? Icons.star : Icons.star_border,
                                        color: const Color(0xFFFFB300),
                                        size: 30,
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Write your feedback here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF1A3D63)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF1A3D63), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: (_selectedRating > 0 || _feedbackController.text.isNotEmpty)
                                ? ElevatedButton(
                              onPressed: () async {
                                try {
                                  final response = await ApiService().submitShopReview(
                                    shopId: widget.shop['shopId'],
                                    rating: _selectedRating,
                                    feedback: _feedbackController.text.trim(),
                                  );

                                  if (response['success']) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Review submitted successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    setState(() {
                                      _selectedRating = 0;
                                      _feedbackController.clear();
                                    });
                                    _loadReviews();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(response['message'] ?? 'Failed to submit review'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A3D63),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionCard(
                      title: 'Customer Reviews',
                      icon: Icons.reviews,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_loadingReviews && _reviews.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFF1A3D63), Color(0xFF2A5A8A)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                    child: Text(
                                      _getOverallRating().toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 33,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < _getOverallRating().round()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: const Color(0xFFFFB300),
                                        size: 28,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          _loadingReviews
                              ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: Color(0xFF1A3D63),
                              ),
                            ),
                          )
                              : _reviews.isEmpty
                              ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No reviews yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                              : Column(
                            children: [
                              ..._reviews.map((review) => Column(
                                children: [
                                  _buildReviewItem(
                                    name: '${review['firstName']} ${review['surName']}'.trim(),
                                    rating: review['rating'] ?? 0,
                                    comment: review['feedback'] ?? '',
                                    date: _formatReviewDate(review['stamp']),
                                    accountId: review['accountId'].toString(),
                                  ),
                                  if (_reviews.indexOf(review) != _reviews.length - 1)
                                    const Divider(),
                                ],
                              )).toList(),
                              if (_totalReviews > _currentLimit)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: TextButton(
                                    onPressed: () async {
                                      if (_currentLimit >= _totalReviews) {
                                        setState(() {
                                          _currentLimit = 5;
                                        });
                                        await _loadReviews(limit: 5);
                                      } else {
                                        await _loadReviews(limit: _totalReviews);
                                        setState(() {
                                          _currentLimit = _totalReviews;
                                        });
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A3D63),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      _currentLimit >= _totalReviews
                                          ? 'Show Less'
                                          : 'See More Reviews ($_totalReviews total)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1A3D63), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3D63),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required int rating,
    required String comment,
    required String date,
    required String accountId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1A3D63),
                backgroundImage: _profileImages.containsKey(accountId)
                    ? MemoryImage(_profileImages[accountId]!)
                    : null,
                child: _profileImages.containsKey(accountId)
                    ? null
                    : Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
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
                      name.isNotEmpty ? name : 'Anonymous User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3D63),
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: const Color(0xFFFFB300),
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (comment.isNotEmpty)
            Text(
              comment,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}