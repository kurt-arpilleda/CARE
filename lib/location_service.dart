import 'dart:async';

import 'package:location/location.dart';
import 'api_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  final Location _location = Location();
  final ApiService _apiService = ApiService();
  Timer? _locationTimer;
  bool _isRunning = false;

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<void> startLocationTracking() async {
    if (_isRunning) return;

    _isRunning = true;
    await _requestPermission();

    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _updateCurrentLocation();
    });
  }

  void stopLocationTracking() {
    _locationTimer?.cancel();
    _isRunning = false;
  }

  Future<void> _requestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final LocationData locationData = await _location.getLocation();
      final token = await _apiService.getAuthToken();

      if (token != null && locationData.latitude != null && locationData.longitude != null) {
        await _apiService.updateCurrentLocation(
          token: token,
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
        );
      }
    } catch (e) {
    }
  }

  void dispose() {
    stopLocationTracking();
  }
}