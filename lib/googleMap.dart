import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:care/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as Math;
import 'dart:async';
import 'findShop/nearbyshopProfile.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({Key? key}) : super(key: key);

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget>
    with WidgetsBindingObserver {
  GoogleMapController? _controller;
  LocationData? _currentLocation;
  Location _location = Location();
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _userData = {};
  BitmapDescriptor? _customMarkerIcon;
  List<dynamic> _shops = [];
  double _currentZoom = 14.0;
  MapType _currentMapType = MapType.normal;
  final CameraPosition _initialPosition =
  const CameraPosition(target: LatLng(12.8797, 121.7740), zoom: 5.5);

  Set<Marker> _markers = {};
  Map<int, int> _shopMessageCounts = {};
  Timer? _messagePollingTimer;
  bool _isAppInForeground = true;
  DateTime? _lastMessageCountUpdate;
  Set<int> _visibleShopIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initMap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messagePollingTimer?.cancel();
    _apiService.dispose();
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
      if (_isAppInForeground && _visibleShopIds.isNotEmpty) {
        _updateMessageCounts();
      }
    });
  }

  void _stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
  }

  Future<void> _updateMessageCounts() async {
    if (_shops.isEmpty || !_isAppInForeground) return;

    final now = DateTime.now();
    if (_lastMessageCountUpdate != null &&
        now.difference(_lastMessageCountUpdate!).inSeconds < 2) {
      return;
    }

    _lastMessageCountUpdate = now;

    List<Future<void>> futures = [];
    for (final shopId in _visibleShopIds.take(10)) {
      futures.add(_getShopMessageCount(shopId));
    }

    try {
      await Future.wait(futures);
    } catch (e) {}
  }

  Future<void> _getShopMessageCount(int shopId) async {
    try {
      final response = await _apiService.getUnreadMessagesCount(shopId: shopId);
      if (response['success'] && mounted) {
        final newCount = response['unreadCount'] ?? 0;
        final oldCount = _shopMessageCounts[shopId] ?? 0;

        if (newCount != oldCount) {
          setState(() {
            _shopMessageCounts[shopId] = newCount;
          });
          _updateShopMarker(shopId);
        }
      }
    } catch (e) {}
  }

  void _updateVisibleShops() {
    if (_controller == null) return;

    _controller!.getVisibleRegion().then((region) {
      Set<int> newVisibleShops = {};

      for (final shop in _shops) {
        final shopLat = double.parse(shop['latitude'].toString());
        final shopLng = double.parse(shop['longitude'].toString());
        final shopPosition = LatLng(shopLat, shopLng);

        if (shopPosition.latitude >= region.southwest.latitude &&
            shopPosition.latitude <= region.northeast.latitude &&
            shopPosition.longitude >= region.southwest.longitude &&
            shopPosition.longitude <= region.northeast.longitude) {
          newVisibleShops.add(shop['shopId']);
        }
      }

      if (newVisibleShops.length != _visibleShopIds.length ||
          !newVisibleShops.every((id) => _visibleShopIds.contains(id))) {
        _visibleShopIds = newVisibleShops;
        _updateMessageCounts();
      }
    });
  }

  Future<void> _updateShopMarker(int shopId) async {
    final shop = _shops.firstWhere((s) => s['shopId'] == shopId, orElse: () => null);

    if (shop == null) return;

    final double shopLat = double.parse(shop['latitude'].toString());
    final double shopLng = double.parse(shop['longitude'].toString());
    final bool isRightSide = _shouldShowTextOnRight(shopLat, shopLng);
    final bool isOpen = _isShopOpen(shop);
    final int messageCount = _shopMessageCounts[shopId] ?? 0;

    final BitmapDescriptor shopIcon = await _createShopMarkerWithName(
      shop['shopLogo'],
      shop['shop_name'] ?? 'Shop',
      isRightSide,
      isOpen,
      messageCount,
    );

    double anchorX = isRightSide ? 0.15 : 0.85;
    String shopStatus = isOpen ? 'Open' : 'Closed';

    final newMarker = Marker(
      markerId: MarkerId('shop_${shop['shopId']}'),
      position: LatLng(shopLat, shopLng),
      infoWindow: InfoWindow(
        title: shop['shop_name'],
        snippet: '${shop['location']} • $shopStatus',
      ),
      icon: shopIcon,
      anchor: Offset(anchorX, 1.0),
      zIndex: 1.0,
      onTap: () {
        _onShopMarkerTap(shop);
      },
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'shop_${shop['shopId']}');
      _markers.add(newMarker);
    });
  }

  Future<void> _initMap() async {
    await _getCurrentLocation();
    await _loadUserData();
    await _createCustomMarkerIcon();
    _moveToCurrentLocation();
    await _loadNearbyShops();
    await _addShopMarkers();
    _startMessagePolling();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _apiService.getUserData();
      if (response['success'] == true && response['user'] != null) {
        _userData = response['user'];
      }
    } catch (_) {}
  }

  bool _isShopSuspended(dynamic shop) {
    final reportAction = shop['reportAction'];
    final suspendedUntil = shop['suspendedUntil'];

    if (reportAction == 1 && suspendedUntil != null && suspendedUntil.toString().isNotEmpty) {
      try {
        final suspendedDate = DateTime.parse(suspendedUntil.toString());
        return DateTime.now().isBefore(suspendedDate);
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool _isShopBanned(dynamic shop) {
    return shop['reportAction'] == 2;
  }

  Future<void> _loadNearbyShops() async {
    try {
      final response = await _apiService.getAllShops();
      if (response['success']) {
        List<dynamic> allShops = response['shops'];

        if (_currentLocation != null) {
          const double maxDistance = 10000;
          List<dynamic> nearbyShops = allShops.where((shop) {
            bool isValidated = shop['isValidated'] == 1;
            bool isBanned = _isShopBanned(shop);
            bool isSuspended = _isShopSuspended(shop);

            double distance = Geolocator.distanceBetween(
              _currentLocation!.latitude!,
              _currentLocation!.longitude!,
              shop['latitude'],
              shop['longitude'],
            );

            return distance <= maxDistance && isValidated && !isBanned && !isSuspended;
          }).toList();

          _shops = nearbyShops;
        } else {
          _shops = allShops.where((shop) {
            bool isValidated = shop['isValidated'] == 1;
            bool isBanned = _isShopBanned(shop);
            bool isSuspended = _isShopSuspended(shop);
            return isValidated && !isBanned && !isSuspended;
          }).toList();
        }
      }
    } catch (_) {}
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

  Future<BitmapDescriptor> _createShopMarkerWithName(
      String? shopLogo, String shopName, bool isRightSide, bool isOpen, int messageCount) async {
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
        final ByteData data = await rootBundle.load('assets/images/shopLogo.jpg');
        imageBytes = data.buffer.asUint8List();
      }

      final ui.Codec codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 140,
        targetHeight: 140,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      double fontSize = _getFontSizeForZoom();

      final textPainter = TextPainter(
        text: TextSpan(
          text: shopName,
          style: TextStyle(
            color: Colors.black87,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                color: Colors.white,
                blurRadius: 4.0,
              ),
              Shadow(
                offset: Offset(-1.0, -1.0),
                color: Colors.white,
                blurRadius: 4.0,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );

      textPainter.layout(maxWidth: 180);

      final double pinSize = 150;
      final double pinRadius = 50;
      final double textPadding = 20;
      final double canvasWidth = pinSize + textPainter.width + textPadding + 30;
      final double canvasHeight = Math.max(pinSize + 30, textPainter.height + 50);

      final double pinCenterX = isRightSide ? pinSize / 2 : canvasWidth - pinSize / 2;
      final double pinCenterY = pinRadius + 15;

      final double textX = isRightSide ? pinSize + textPadding : 15;
      final double textY = (canvasHeight - textPainter.height) / 2;

      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5);

      final Paint borderPaint = Paint()
        ..color = isOpen ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;

      final Paint whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(pinCenterX + 2, pinCenterY + 2), pinRadius + 8, shadowPaint);
      canvas.drawCircle(Offset(pinCenterX, pinCenterY), pinRadius + 8, whitePaint);
      canvas.drawCircle(Offset(pinCenterX, pinCenterY), pinRadius + 4, borderPaint);

      final Path clipPath = Path()..addOval(Rect.fromCircle(center: Offset(pinCenterX, pinCenterY), radius: pinRadius));
      canvas.save();
      canvas.clipPath(clipPath);

      final Rect imageRect = Rect.fromCircle(center: Offset(pinCenterX, pinCenterY), radius: pinRadius);
      canvas.drawImageRect(
          image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), imageRect, Paint());
      canvas.restore();

      if (messageCount > 0) {
        final double badgeRadius = 26;
        final double badgeX = pinCenterX + pinRadius - 6;
        final double badgeY = pinCenterY - pinRadius + 20; // shifted down to avoid cut

        final Paint badgeShadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(Offset(badgeX + 1.5, badgeY + 1.5), badgeRadius, badgeShadowPaint);

        final Paint badgePaint = Paint()
          ..color = Color(0xFFFF4444)
          ..style = PaintingStyle.fill;

        final Paint badgeBorderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(badgeX, badgeY), badgeRadius + 4, badgeBorderPaint);
        canvas.drawCircle(Offset(badgeX, badgeY), badgeRadius, badgePaint);

        final String countText = messageCount > 99 ? '99+' : messageCount.toString();
        final TextPainter badgeTextPainter = TextPainter(
          text: TextSpan(
            text: countText,
            style: TextStyle(
              color: Colors.white,
              fontSize: messageCount > 99 ? 18 : 20, // balanced font size
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        badgeTextPainter.layout();
        final double badgeTextX = badgeX - badgeTextPainter.width / 2;
        final double badgeTextY = badgeY - badgeTextPainter.height / 2;
        badgeTextPainter.paint(canvas, Offset(badgeTextX, badgeTextY));
      }
      final Path pinPath = Path();
      pinPath.moveTo(pinCenterX - 10, pinRadius * 2 + 20);
      pinPath.lineTo(pinCenterX + 10, pinRadius * 2 + 20);
      pinPath.lineTo(pinCenterX, pinRadius * 2 + 40);
      pinPath.close();

      canvas.drawPath(pinPath, borderPaint);

      final RRect textBackground = RRect.fromRectAndRadius(
        Rect.fromLTWH(textX - 10, textY - 10, textPainter.width + 20, textPainter.height + 20),
        Radius.circular(12),
      );

      final Paint backgroundPaint = Paint()
        ..color = Colors.white.withOpacity(0.92)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(textBackground, backgroundPaint);

      final Paint strokePaint = Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(textBackground, strokePaint);

      textPainter.paint(canvas, Offset(textX, textY));

      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage =
      await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());

      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List finalImageBytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(finalImageBytes);
    } catch (_) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  double _getFontSizeForZoom() {
    if (_currentZoom < 10) return 16;
    if (_currentZoom < 12) return 18;
    if (_currentZoom < 14) return 20;
    if (_currentZoom < 16) return 22;
    return 24;
  }

  bool _shouldShowTextOnRight(double shopLat, double shopLng) {
    if (_currentLocation == null) return true;

    double userLat = _currentLocation!.latitude!;
    double userLng = _currentLocation!.longitude!;

    return shopLng < userLng;
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

  Future<void> _addShopMarkers() async {
    Set<Marker> newMarkers = {};

    for (int i = 0; i < _shops.length; i++) {
      final shop = _shops[i];
      final double shopLat = double.parse(shop['latitude'].toString());
      final double shopLng = double.parse(shop['longitude'].toString());
      final bool isRightSide = _shouldShowTextOnRight(shopLat, shopLng);
      final bool isOpen = _isShopOpen(shop);
      final int messageCount = _shopMessageCounts[shop['shopId']] ?? 0;

      final BitmapDescriptor shopIcon = await _createShopMarkerWithName(
        shop['shopLogo'],
        shop['shop_name'] ?? 'Shop',
        isRightSide,
        isOpen,
        messageCount,
      );

      double anchorX = isRightSide ? 0.15 : 0.85;
      String shopStatus = isOpen ? 'Open' : 'Closed';

      newMarkers.add(
        Marker(
          markerId: MarkerId('shop_${shop['shopId']}'),
          position: LatLng(shopLat, shopLng),
          infoWindow: InfoWindow(
            title: shop['shop_name'],
            snippet: '${shop['location']} • $shopStatus',
          ),
          icon: shopIcon,
          anchor: Offset(anchorX, 1.0),
          zIndex: 1.0,
          onTap: () {
            _onShopMarkerTap(shop);
          },
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

    _updateVisibleShops();
  }

  void _onShopMarkerTap(dynamic shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyShopProfileScreen(shop: shop),
      ),
    );
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

  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
  }

  void _onCameraIdle() async {
    if (_currentZoom != _getCurrentZoomLevel()) {
      await _addShopMarkers();
    }
    _updateVisibleShops();
  }

  double _getCurrentZoomLevel() {
    return _currentZoom;
  }

  Widget _mapTypeToggle() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 7.0, bottom: 100.0),
        child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          onPressed: () {
            setState(() {
              _currentMapType =
              _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
            });
          },
          child: Icon(
            _currentMapType == MapType.normal ? Icons.satellite : Icons.map,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
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
          mapType: _currentMapType,
          onCameraMove: _onCameraMove,
          onCameraIdle: _onCameraIdle,
        ),
        _mapTypeToggle(),
      ],
    );
  }
}