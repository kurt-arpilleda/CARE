import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ActivateVehicleScreen extends StatefulWidget {
  const ActivateVehicleScreen({Key? key}) : super(key: key);

  @override
  _ActivateVehicleScreenState createState() => _ActivateVehicleScreenState();
}

class _ActivateVehicleScreenState extends State<ActivateVehicleScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  bool _hasInternet = true;
  bool _isEditing = false;
  bool _isSaving = false;
  final Map<String, String> _vehicleTypeMap = {
    '0': 'Car',
    '1': 'Motorcycle',
    '2': 'Van',
    '3': 'Truck',
    '4': 'Bus',
    '5': 'Jeep',
  };
  late AnimationController _loadingController;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;
  List<TextEditingController> _modelControllers = [];
  List<TextEditingController> _plateControllers = [];

  @override
  void initState() {
    super.initState();
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
        _checkInternetAndLoadVehicles();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _apiService.dispose();
    for (var controller in _modelControllers) {
      controller.dispose();
    }
    for (var controller in _plateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkInternetAndLoadVehicles() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = connectivityResult != ConnectivityResult.none;
    });
    if (_hasInternet) {
      _loadVehicles();
    } else {
      setState(() => _isLoading = false);
    }
  }

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
          _modelControllers = _vehicles.map((v) => TextEditingController(text: v['vehicle_model'])).toList();
          _plateControllers = _vehicles.map((v) => TextEditingController(text: v['plate_number'])).toList();
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

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      final token = await _apiService.getAuthToken();
      if (token == null) throw Exception("No auth token found");

      final response = await _apiService.deleteVehicle(token: token, vehicleId: vehicleId);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: response['message']);
        _loadVehicles();
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to delete vehicle');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting vehicle: ${e.toString()}');
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final token = await _apiService.getAuthToken();
      if (token == null) throw Exception("No auth token found");

      List<Map<String, dynamic>> updatedVehicles = [];
      for (int i = 0; i < _vehicles.length; i++) {
        updatedVehicles.add({
          'id': _vehicles[i]['id'],
          'vehicle_model': _modelControllers[i].text,
          'plate_number': _plateControllers[i].text,
        });
      }

      final response = await _apiService.updateVehicles(token: token, vehicles: updatedVehicles);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: response['message']);
        setState(() => _isEditing = false);
        _loadVehicles();
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to update vehicles');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error saving changes: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasInternet ? Icons.directions_car_outlined : Icons.wifi_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            _hasInternet ? 'No vehicles found' : 'No Internet Connection',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A3D63),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _hasInternet
                ? 'You don\'t have any vehicles registered yet'
                : 'Please check your internet connection and try again',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!_hasInternet)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3D63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _checkInternetAndLoadVehicles,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveChanges,
        backgroundColor: const Color(0xFF1A3D63),
        label: _isSaving
            ? _buildLoadingAnimation()
            : const Text('Save', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.save, color: Colors.white),
      )
          : null,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                              _isEditing ? Icons.close : Icons.edit,
                              color: const Color(0xFFF6FAFD)),
                          onPressed: () {
                            setState(() {
                              _isEditing = !_isEditing;
                            });
                          },
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
                ? _buildNoDataView()
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
                          child: _buildVehicleCard(vehicle, index),
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

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, int index) {
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
                  _isEditing
                      ?
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Vehicle'),
                          content: const Text('Are you sure you want to delete this vehicle?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteVehicle(vehicle['id']);
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                      : Switch(
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
              _isEditing
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Model',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _modelControllers[index],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Plate Number',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _plateControllers[index],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              )
                  : Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
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
                        width: 100,
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
            ],
          ),
        ),
      ),
    );
  }
}