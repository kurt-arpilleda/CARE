import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class ShopLocationPicker extends StatefulWidget {
  const ShopLocationPicker({Key? key}) : super(key: key);

  @override
  _ShopLocationPickerState createState() => _ShopLocationPickerState();
}

class _ShopLocationPickerState extends State<ShopLocationPicker> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  final Location _locationService = Location();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _locationService.getLocation();
      setState(() {
        _selectedLocation = LatLng(locationData.latitude!, locationData.longitude!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Shop Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedLocation == null
                ? null
                : () {
              Navigator.pop(context, {
                'latitude': _selectedLocation!.latitude,
                'longitude': _selectedLocation!.longitude,
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: CameraPosition(
          target: _selectedLocation ?? const LatLng(14.5995, 120.9842),
          zoom: 14.0,
        ),
        markers: _selectedLocation == null
            ? {}
            : {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation!,
          ),
        },
        onTap: (LatLng location) {
          setState(() {
            _selectedLocation = location;
          });
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}