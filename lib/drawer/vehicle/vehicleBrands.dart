import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'vehicleRegister.dart';
import 'package:care/anim/dotLoading.dart';

class VehicleBrandsScreen extends StatefulWidget {
  final String vehicleType;

  const VehicleBrandsScreen({Key? key, required this.vehicleType}) : super(key: key);

  @override
  _VehicleBrandsScreenState createState() => _VehicleBrandsScreenState();
}

class _VehicleBrandsScreenState extends State<VehicleBrandsScreen> {
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
        final brandList = results.map((item) => item['MakeName'].toString()).toList()
          ..sort((a, b) => a.compareTo(b));

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

  void _showCustomBrandDialog() {
    final TextEditingController customBrandController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Brand'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Can\'t find your brand? Enter it below:'),
            const SizedBox(height: 16),
            TextField(
              controller: customBrandController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Enter brand name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final customBrand = customBrandController.text.trim();
              if (customBrand.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleRegisterScreen(
                      vehicleType: widget.vehicleType,
                      vehicleBrand: customBrand,
                    ),
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCustomBrandDialog,
        backgroundColor: const Color(0xFF1A3D63),
        child: const Icon(
          Icons.help_outline,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _getBackgroundImage(),
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Column(
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
                color: Color(0xFFF6FAFD),
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
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleRegisterScreen(
                    vehicleType: widget.vehicleType,
                    vehicleBrand: brand,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    _getVehicleIcon(),
                    size: 32,
                    color: const Color(0xFF1A3D63),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      brand,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getBackgroundImage() {
    switch (widget.vehicleType.toLowerCase()) {
      case 'car':
        return 'assets/images/car.jpg';
      case 'motorcycle':
        return 'assets/images/motorcycle.jpg';
      case 'van':
        return 'assets/images/van.jpg';
      case 'truck':
        return 'assets/images/truck.jpg';
      case 'bus':
        return 'assets/images/bus.jpg';
      case 'jeep':
        return 'assets/images/jeep.jpg';
      default:
        return 'assets/images/car.jpg';
    }
  }

  IconData _getVehicleIcon() {
    switch (widget.vehicleType.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'van':
        return Icons.airport_shuttle;
      case 'truck':
        return Icons.local_shipping;
      case 'bus':
        return Icons.directions_bus;
      case 'jeep':
        return Icons.directions_bus_outlined;
      default:
        return Icons.directions_car;
    }
  }
}