import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../api_service.dart';

class ActivateVehicleScreen extends StatefulWidget {
  const ActivateVehicleScreen({Key? key}) : super(key: key);

  @override
  _ActivateVehicleScreenState createState() => _ActivateVehicleScreenState();
}

class _ActivateVehicleScreenState extends State<ActivateVehicleScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  final Map<String, String> _vehicleTypeMap = {
    '0': 'Car',
    '1': 'Motorcycle',
    '2': 'Van',
    '3': 'Truck',
    '4': 'Bus',
    '5': 'Jeep',
  };

  // Animation controllers for the loading dots
  late AnimationController _loadingController;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();

    // Initialize loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dot1Animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _dot2Animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOut),
      ),
    );

    _dot3Animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
      ),
    );

    _loadVehicles();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  // Loading widget with three animated dots
  Widget _buildLoadingAnimation() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _dot1Animation,
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3D63),
                shape: BoxShape.circle,
              ),
            ),
          ),
          ScaleTransition(
            scale: _dot2Animation,
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3D63),
                shape: BoxShape.circle,
              ),
            ),
          ),
          ScaleTransition(
            scale: _dot3Animation,
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3D63),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVehicles() async {
    try {
      final response = await _apiService.getVehicles();
      if (response['success'] == true) {
        setState(() {
          _vehicles = response['vehicles'];
          _isLoading = false;
        });
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to load vehicles');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading vehicles: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVehicle(int vehicleId, bool isActive) async {
    try {
      final response = await _apiService.toggleVehicle(vehicleId: vehicleId, isActive: isActive);
      if (response['success'] != true) {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to update vehicle status');
        _loadVehicles();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating vehicle: ${e.toString()}');
      _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A3D63),
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFFF6FAFD)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Text(
                        'Activate Vehicle',
                        style: TextStyle(
                          color: Color(0xFFF6FAFD),
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingAnimation()
                : _vehicles.isEmpty
                ? const Center(child: Text('No vehicles found'))
                : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final vehicle = _vehicles[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildVehicleCard(vehicle),
                        );
                      },
                      childCount: _vehicles.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black.withOpacity(0.5),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _vehicleTypeMap[vehicle['vehicle_type'].toString()] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3D63),
                    ),
                  ),
                  Switch(
                    value: vehicle['isActivate'] == 1,
                    onChanged: (value) {
                      setState(() {
                        vehicle['isActivate'] = value ? 1 : 0;
                      });
                      _toggleVehicle(vehicle['id'], value);
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100, // Fixed width for labels
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Model',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        vehicle['vehicle_model'] ?? '',
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100, // Fixed width for labels (same as above)
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Plate Number',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        vehicle['plate_number'] ?? '',
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}