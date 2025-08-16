import 'package:flutter/material.dart';
import 'package:care/api_service.dart';
import 'reportDialog.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class NearbyShopProfileScreen extends StatefulWidget {
  final dynamic shop;

  const NearbyShopProfileScreen({Key? key, required this.shop}) : super(key: key);

  @override
  _NearbyShopProfileScreenState createState() => _NearbyShopProfileScreenState();
}

class _NearbyShopProfileScreenState extends State<NearbyShopProfileScreen> {
  bool _showFullServices = false;
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;
  int _totalReviews = 0;
  int _currentLimit = 5;
  Map<String, Uint8List> _profileImages = {};
  @override
  void initState() {
    super.initState();
    _loadReviews();
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
    _feedbackController.dispose();
    super.dispose();
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
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Color(0xFF1A3D63), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                widget.shop['phoneNum'] ?? 'Phone not available',
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
                                    child: Text(
                                      widget.shop['home_page'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1A3D63),
                                        decoration: TextDecoration.underline,
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
                            child:
                            ElevatedButton(
                              onPressed: _selectedRating == 0
                                  ? null
                                  : () async {
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
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionCard(
                      title: 'Customer Reviews',
                      icon: Icons.reviews,
                      child: _loadingReviews
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