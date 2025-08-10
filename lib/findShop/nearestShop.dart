import 'package:flutter/material.dart';
import 'package:care/api_service.dart';
import 'package:geolocator/geolocator.dart';
import '../anim/dotLoading.dart';

class NearestShopScreen extends StatefulWidget {
  final List<String> selectedServices;

  const NearestShopScreen({Key? key, required this.selectedServices}) : super(key: key);

  @override
  _NearestShopScreenState createState() => _NearestShopScreenState();
}

class _NearestShopScreenState extends State<NearestShopScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _shops = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
      _loadNearbyShops();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyShops() async {
    try {
      final response = await _apiService.getAllShops();
      if (response['success']) {
        List<dynamic> allShops = response['shops'];
        DateTime now = DateTime.now();
        int currentDay = now.weekday - 1;
        String currentTime = "${now.hour}:${now.minute}";

        const double maxDistance = 10000;

        List<dynamic> filteredShops = allShops.where((shop) {
          bool isValidated = shop['isValidated'] == 1;
          bool isNotArchived = shop['isArchive'] == 0;
          bool hasSelectedServices = widget.selectedServices.any((service) => shop['services'].contains(service));
          bool isOpenToday = shop['day_index'].contains(currentDay.toString());

          if (_currentPosition != null) {
            double distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              shop['latitude'],
              shop['longitude'],
            );
            bool isWithinDistance = distance <= maxDistance;
            return isValidated && isNotArchived && hasSelectedServices && isWithinDistance;
          }

          return isValidated && isNotArchived && hasSelectedServices;
        }).toList();

        if (_currentPosition != null) {
          filteredShops.sort((a, b) {
            double distanceA = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              a['latitude'],
              a['longitude'],
            );
            double distanceB = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              b['latitude'],
              b['longitude'],
            );
            return distanceA.compareTo(distanceB);
          });
        }

        setState(() {
          _shops = filteredShops;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D63),
        title: const Text(
          'Nearby Shops',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: DotLoading(dotColor: Color(0xFF1A3D63), dotSize: 12),
      )
          : _shops.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.store_mall_directory_outlined,
                size: 72, color: Color(0xFF1A3D63)),
            SizedBox(height: 12),
            Text(
              'No nearby shops found',
              style: TextStyle(
                color: Color(0xFF1A3D63),
                fontSize: 18,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shops.length,
        itemBuilder: (context, index) {
          final shop = _shops[index];
          bool isOpen = _isShopOpen(shop);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: shop['shopLogo'] != null
                      ? DecorationImage(
                    image: NetworkImage(
                      '${ApiService.apiUrl}shopLogo/${shop['shopLogo']}',
                    ),
                    fit: BoxFit.cover,
                  )
                      : null,
                  color: const Color(0xFF1A3D63).withOpacity(0.1),
                ),
                child: shop['shopLogo'] == null
                    ? const Icon(
                  Icons.store,
                  color: Color(0xFF1A3D63),
                  size: 28,
                )
                    : null,
              ),
              title: Text(
                shop['shop_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3D63),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    shop['location'],
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOpen ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            color: isOpen ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_currentPosition != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${(Geolocator.distanceBetween(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                              shop['latitude'],
                              shop['longitude'],
                            ) / 1000)
                                .toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF1A3D63),
              ),
            ),
          );
        },
      ),
    );
  }
}