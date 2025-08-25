import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:care/api_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class GoogleMapDialog extends StatefulWidget {
  final dynamic shop;

  const GoogleMapDialog({Key? key, required this.shop}) : super(key: key);

  @override
  _GoogleMapDialogState createState() => _GoogleMapDialogState();
}

class _GoogleMapDialogState extends State<GoogleMapDialog> {
  GoogleMapController? _controller;
  LocationData? _currentLocation;
  Location _location = Location();
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _userData = {};
  BitmapDescriptor? _customMarkerIcon;
  BitmapDescriptor? _shopMarkerIcon;
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
    await _createCustomMarkerIcon();
    await _createShopMarker();
    await _addMarkers();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _apiService.getUserData();
      if (response['success'] == true && response['user'] != null) {
        _userData = response['user'];
      }
    } catch (_) {}
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

  Future<void> _createCustomMarkerIcon() async {
    try {
      final String? photoUrl = _userData['photoUrl'];
      Uint8List? imageBytes;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        final String imageUrl =
        photoUrl.contains('http') ? photoUrl : '${ApiService.apiUrl}profilePicture/$photoUrl';

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
        targetWidth: 120,
        targetHeight: 120,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final double size = 140;
      final double radius = 45;
      final Offset center = Offset(size / 2, radius + 15);

      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawCircle(Offset(center.dx + 3, center.dy + 3), radius + 9, shadowPaint);

      final Paint borderPaint = Paint()..color = Color(0xFF4285F4)..style = PaintingStyle.fill;
      final Paint whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius + 9, whitePaint);
      canvas.drawCircle(center, radius + 5, borderPaint);

      final Path clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.save();
      canvas.clipPath(clipPath);

      final Rect imageRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawImageRect(
          image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), imageRect, Paint());
      canvas.restore();

      final Path pinPath = Path();
      pinPath.moveTo(size / 2 - 12, radius * 2 + 20);
      pinPath.lineTo(size / 2 + 12, radius * 2 + 20);
      pinPath.lineTo(size / 2, radius * 2 + 40);
      pinPath.close();

      canvas.drawPath(pinPath, borderPaint);

      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(size.toInt(), (radius * 2 + 50).toInt());

      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List finalImageBytes = byteData!.buffer.asUint8List();

      _customMarkerIcon = BitmapDescriptor.fromBytes(finalImageBytes);
    } catch (_) {
      _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<void> _createShopMarker() async {
    try {
      Uint8List? imageBytes;
      if (widget.shop['shopLogo'] != null && widget.shop['shopLogo'].isNotEmpty) {
        final String imageUrl = '${ApiService.apiUrl}shopLogo/${widget.shop['shopLogo']}';
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          }
        } catch (_) {}
      }

      if (imageBytes == null) {
        final ByteData data = await rootBundle.load('assets/images/shopLogo.jpg');
        imageBytes = data.buffer.asUint8List();
      }

      final ui.Codec codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 120,
        targetHeight: 120,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final double size = 140;
      final double radius = 45;
      final Offset center = Offset(size / 2, radius + 15);

      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawCircle(Offset(center.dx + 3, center.dy + 3), radius + 9, shadowPaint);

      final Paint borderPaint = Paint()..color = Color(0xFF1A3D63)..style = PaintingStyle.fill;
      final Paint whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius + 9, whitePaint);
      canvas.drawCircle(center, radius + 5, borderPaint);

      final Path clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.save();
      canvas.clipPath(clipPath);

      final Rect imageRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawImageRect(
          image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), imageRect, Paint());
      canvas.restore();

      final Path pinPath = Path();
      pinPath.moveTo(size / 2 - 12, radius * 2 + 20);
      pinPath.lineTo(size / 2 + 12, radius * 2 + 20);
      pinPath.lineTo(size / 2, radius * 2 + 40);
      pinPath.close();

      canvas.drawPath(pinPath, borderPaint);

      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(size.toInt(), (radius * 2 + 50).toInt());

      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List finalImageBytes = byteData!.buffer.asUint8List();

      _shopMarkerIcon = BitmapDescriptor.fromBytes(finalImageBytes);
    } catch (_) {
      _shopMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  Future<void> _addMarkers() async {
    Set<Marker> newMarkers = {};

    final double shopLat = double.parse(widget.shop['latitude'].toString());
    final double shopLng = double.parse(widget.shop['longitude'].toString());

    if (_shopMarkerIcon != null) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('shop_${widget.shop['shopId']}'),
          position: LatLng(shopLat, shopLng),
          infoWindow: InfoWindow(
            title: widget.shop['shop_name'],
            snippet: widget.shop['location'],
          ),
          icon: _shopMarkerIcon!,
          anchor: Offset(0.5, 1.0),
          zIndex: 1.0,
        ),
      );
    }

    if (_currentLocation != null && _customMarkerIcon != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: '${_userData['firstName'] ?? ''} ${_userData['surName'] ?? ''}',
          ),
          icon: _customMarkerIcon!,
          anchor: Offset(0.5, 1.0),
          zIndex: 1000.0,
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });

    if (_controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _currentLocation != null
                  ? (_currentLocation!.latitude! < shopLat ? _currentLocation!.latitude! : shopLat) - 0.001
                  : shopLat - 0.001,
              _currentLocation != null
                  ? (_currentLocation!.longitude! < shopLng ? _currentLocation!.longitude! : shopLng) - 0.001
                  : shopLng - 0.001,
            ),
            northeast: LatLng(
              _currentLocation != null
                  ? (_currentLocation!.latitude! > shopLat ? _currentLocation!.latitude! : shopLat) + 0.001
                  : shopLat + 0.001,
              _currentLocation != null
                  ? (_currentLocation!.longitude! > shopLng ? _currentLocation!.longitude! : shopLng) + 0.001
                  : shopLng + 0.001,
            ),
          ),
          100.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double shopLat = double.parse(widget.shop['latitude'].toString());
    final double shopLng = double.parse(widget.shop['longitude'].toString());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A3D63),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: widget.shop['shopLogo'] != null
                        ? ClipOval(
                      child: Image.network(
                        '${ApiService.apiUrl}shopLogo/${widget.shop['shopLogo']}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.car_repair,
                          color: Color(0xFF1A3D63),
                          size: 20,
                        ),
                      ),
                    )
                        : const Icon(
                      Icons.car_repair,
                      color: Color(0xFF1A3D63),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shop['shop_name'] ?? 'Unknown Shop',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.shop['location'] ?? 'Location not specified',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                    if (_markers.isNotEmpty) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _addMarkers();
                      });
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(shopLat, shopLng),
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}