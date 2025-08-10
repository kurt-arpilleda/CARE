import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:care/api_service.dart';

class NearestShopDialog extends StatefulWidget {
  final List<String> selectedServices;
  final ApiService apiService;

  const NearestShopDialog({
    Key? key,
    required this.selectedServices,
    required this.apiService,
  }) : super(key: key);

  @override
  _NearestShopDialogState createState() => _NearestShopDialogState();
}

class _NearestShopDialogState extends State<NearestShopDialog> {
  Position? _currentPosition;
  bool _isLoading = true;
  List<dynamic> _shops = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permissions are denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      _fetchNearbyShops();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchNearbyShops() async {
    if (_currentPosition == null) return;

    try {
      final response = await widget.apiService.getShops();
      if (response['success']) {
        final now = DateTime.now();
        final currentDay = now.weekday - 1;
        final currentTime = DateFormat('HH:mm').format(now);

        List<dynamic> filteredShops = response['shops'].where((shop) {
          bool hasService = widget.selectedServices.any((service) =>
          shop['services']?.toLowerCase().contains(service.toLowerCase()) ?? false);

          bool isValidated = shop['isValidated'] == 1;
          bool isNotArchived = shop['isArchive'] == 0;
          bool isOpenToday = shop['day_index']?.contains(currentDay.toString()) ?? false;

          bool isOpenNow = false;
          if (isOpenToday) {
            try {
              final startTime = shop['start_time'] ?? '00:00';
              final closeTime = shop['close_time'] ?? '23:59';
              isOpenNow = currentTime.compareTo(startTime) >= 0 &&
                  currentTime.compareTo(closeTime) <= 0;
            } catch (e) {}
          }

          return hasService && isValidated && isNotArchived;
        }).toList();

        filteredShops.sort((a, b) {
          double distanceA = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            double.parse(a['latitude'] ?? '0'),
            double.parse(a['longitude'] ?? '0'),
          );
          double distanceB = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            double.parse(b['latitude'] ?? '0'),
            double.parse(b['longitude'] ?? '0'),
          );
          return distanceA.compareTo(distanceB);
        });

        setState(() {
          _shops = filteredShops;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'Failed to load shops';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch shops: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Repair Shops',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3D63),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Services: ${widget.selectedServices.join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.withOpacity(0.7)),
            const SizedBox(height: 8),
            Text(
              'No shops found matching your criteria',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _shops.length,
      itemBuilder: (context, index) {
        final shop = _shops[index];
        final now = DateTime.now();
        final currentDay = now.weekday - 1;
        final currentTime = DateFormat('HH:mm').format(now);

        bool isOpenToday = shop['day_index']?.contains(currentDay.toString()) ?? false;
        bool isOpenNow = false;

        if (isOpenToday) {
          try {
            final startTime = shop['start_time'] ?? '00:00';
            final closeTime = shop['close_time'] ?? '23:59';
            isOpenNow = currentTime.compareTo(startTime) >= 0 &&
                currentTime.compareTo(closeTime) <= 0;
          } catch (e) {}
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: shop['shopLogo'] != null
                      ? Image.network(
                    '${ApiService.apiUrl}shopLogo/${shop['shopLogo']}',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.store, color: Colors.grey),
                      );
                    },
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.store, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop['shop_name'] ?? 'Unknown Shop',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop['location'] ?? 'Unknown Location',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpenNow
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOpenNow ? 'Open' : 'Closed',
                              style: TextStyle(
                                color: isOpenNow
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isOpenToday && !isOpenNow)
                            Text(
                              'Opens at ${shop['start_time']}',
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
          ),
        );
      },
    );
  }
}