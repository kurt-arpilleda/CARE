import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:care/anim/dotLoading.dart';

class VehicleBrandSelectionScreen extends StatefulWidget {
  final String vehicleType;

  const VehicleBrandSelectionScreen({Key? key, required this.vehicleType}) : super(key: key);

  @override
  _VehicleBrandSelectionScreenState createState() => _VehicleBrandSelectionScreenState();
}

class _VehicleBrandSelectionScreenState extends State<VehicleBrandSelectionScreen> {
  List<String> brands = [];
  List<String> filteredBrands = [];
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBrands();
    _searchController.addListener(_filterBrands);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBrands() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      String apiUrl;
      switch (widget.vehicleType.toLowerCase()) {
        case 'car':
          apiUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/car?format=json';
          break;
        case 'motorcycle':
          apiUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/motorcycle?format=json';
          break;
        case 'van':
          apiUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/mpv?format=json';
          break;
        case 'truck':
          apiUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/truck?format=json';
          break;
        case 'bus':
          apiUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/bus?format=json';
          break;
        case 'jeep':
          apiUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/mpv?format=json';
          break;
        default:
          apiUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/car?format=json';
      }

      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['Results']);
        final brandList = results.map((item) => item['MakeName'].toString()).toList();

        setState(() {
          brands = brandList;
          filteredBrands = brandList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _filterBrands() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredBrands = brands
          .where((brand) => brand.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        title: Text(
          'Select ${widget.vehicleType} Brand',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A3D63),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ${widget.vehicleType} brands...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _buildBrandList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DotLoading(),
            SizedBox(height: 16),
            Text(
              'Loading brands...',
              style: TextStyle(
                color: Color(0xFF1A3D63),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please check your internet connection',
              style: TextStyle(
                color: Color(0xFF1A3D63),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchBrands,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3D63),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (filteredBrands.isEmpty) {
      return const Center(
        child: Text(
          'No brands found',
          style: TextStyle(
            color: Color(0xFF1A3D63),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredBrands.length,
      itemBuilder: (context, index) {
        final brand = filteredBrands[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(brand),
            onTap: () {
              // Return the selected brand instead of navigating
              Navigator.pop(context, brand);
            },
          ),
        );
      },
    );
  }
}