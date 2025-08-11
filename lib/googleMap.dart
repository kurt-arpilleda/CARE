import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:care/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({Key? key}) : super(key: key);

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _controller;
  LocationData? _currentLocation;
  Location _location = Location();
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _userData = {};
  BitmapDescriptor? _customMarkerIcon;
  List<dynamic> _shops = [];

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(12.8797, 121.7740),
    zoom: 5.5,
  );

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _initMap() async {
    await _getCurrentLocation();
    await _loadUserData();
    await _loadNearbyShops();
    _addCurrentLocationMarker();
    _addShopMarkers();
    _moveToCurrentLocation();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _apiService.getUserData();
      if (response['success'] == true && response['user'] != null) {
        _userData = response['user'];
        await _createCustomMarkerIcon();
      }
    } catch (_) {}
  }

  Future<void> _loadNearbyShops() async {
    try {
      final response = await _apiService.getAllShops();
      if (response['success']) {
        List<dynamic> allShops = response['shops'];

        if (_currentLocation != null) {
          const double maxDistance = 10000;
          List<dynamic> nearbyShops = allShops.where((shop) {
            double distance = Geolocator.distanceBetween(
              _currentLocation!.latitude!,
              _currentLocation!.longitude!,
              shop['latitude'],
              shop['longitude'],
            );
            return distance <= maxDistance;
          }).toList();

          _shops = nearbyShops;
        } else {
          _shops = allShops;
        }
      }
    } catch (_) {}
  }

  Future<BitmapDescriptor> _createShopMarkerIcon(String? shopLogo) async {
    try {
      Uint8List? imageBytes;

      if (shopLogo != null && shopLogo.isNotEmpty) {
        final String imageUrl = '${ApiService.apiUrl}shopLogo/$shopLogo';
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          }
        } catch (_) {}
      }

      if (imageBytes == null) {
        final ByteData data = await rootBundle.load('assets/images/profilePlaceHolder.png');
        imageBytes = data.buffer.asUint8List();
      }

      final ui.Codec codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 100,
        targetHeight: 100,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final double size = 120;
      final double radius = 40;
      final Offset center = Offset(size / 2, radius + 10);

      final Paint borderPaint = Paint()..color = Color(0xFFFF6B35)..style = PaintingStyle.fill;
      final Paint whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius + 6, whitePaint);
      canvas.drawCircle(center, radius + 3, borderPaint);

      final Path clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.save();
      canvas.clipPath(clipPath);

      final Rect imageRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), imageRect, Paint());
      canvas.restore();

      final Path pinPath = Path();
      pinPath.moveTo(size / 2 - 10, radius * 2 + 15);
      pinPath.lineTo(size / 2 + 10, radius * 2 + 15);
      pinPath.lineTo(size / 2, radius * 2 + 35);
      pinPath.close();
      canvas.drawPath(pinPath, borderPaint);

      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(size.toInt(), (radius * 2 + 40).toInt());
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List finalImageBytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(finalImageBytes);
    } catch (_) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  Future<void> _createCustomMarkerIcon() async {
    try {
      final String? photoUrl = _userData['photoUrl'];
      Uint8List? imageBytes;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        final String imageUrl = photoUrl.contains('http')
            ? photoUrl
            : '${ApiService.apiUrl}profilePicture/$photoUrl';

        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          }
        } catch (_) {}
      }

      if (imageBytes == null) {
        final ByteData data = await rootBundle.load('assets/images/profilePlaceHolder.png');
        imageBytes = data.buffer.asUint8List();
      }

      final ui.Codec codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 100,
        targetHeight: 100,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final double size = 120;
      final double radius = 40;
      final Offset center = Offset(size / 2, radius + 10);

      final Paint borderPaint = Paint()..color = Color(0xFF00C853)..style = PaintingStyle.fill;
      final Paint whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius + 6, whitePaint);
      canvas.drawCircle(center, radius + 3, borderPaint);

      final Path clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.save();
      canvas.clipPath(clipPath);

      final Rect imageRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), imageRect, Paint());
      canvas.restore();

      final Path pinPath = Path();
      pinPath.moveTo(size / 2 - 10, radius * 2 + 15);
      pinPath.lineTo(size / 2 + 10, radius * 2 + 15);
      pinPath.lineTo(size / 2, radius * 2 + 35);
      pinPath.close();
      canvas.drawPath(pinPath, borderPaint);

      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(size.toInt(), (radius * 2 + 40).toInt());
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List finalImageBytes = byteData!.buffer.asUint8List();

      _customMarkerIcon = BitmapDescriptor.fromBytes(finalImageBytes);
    } catch (_) {
      _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _currentLocation = await _location.getLocation();
  }

  void _addCurrentLocationMarker() {
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: '${_userData['firstName'] ?? ''} ${_userData['surName'] ?? ''}',
          ),
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: Offset(0.5, 1.0),
        ),
      );
      setState(() {});
    }
  }

  void _addShopMarkers() async {
    for (int i = 0; i < _shops.length; i++) {
      final shop = _shops[i];
      final BitmapDescriptor shopIcon = await _createShopMarkerIcon(shop['shopLogo']);

      _markers.add(
        Marker(
          markerId: MarkerId('shop_${shop['shopId']}'),
          position: LatLng(
            double.parse(shop['latitude'].toString()),
            double.parse(shop['longitude'].toString()),
          ),
          infoWindow: InfoWindow(
            title: shop['shop_name'],
            snippet: shop['location'],
          ),
          icon: shopIcon,
          anchor: Offset(0.5, 1.0),
        ),
      );
    }
    setState(() {});
  }

  void _moveToCurrentLocation() {
    if (_controller != null && _currentLocation != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 14.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
        if (_currentLocation != null) {
          _moveToCurrentLocation();
        }
      },
      initialCameraPosition: _initialPosition,
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapType: MapType.normal,
    );
  }
}