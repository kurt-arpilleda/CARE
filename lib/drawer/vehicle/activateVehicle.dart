import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:care/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:care/anim/dotLoading.dart';
import 'vehicleBrandSelectionScreen.dart';
import 'package:care/dashboard.dart';

class ActivateVehicleScreen extends StatefulWidget {
  const ActivateVehicleScreen({Key? key}) : super(key: key);

  @override
  _ActivateVehicleScreenState createState() => _ActivateVehicleScreenState();
}

class _ActivateVehicleScreenState extends State<ActivateVehicleScreen> {
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
  List<TextEditingController> _modelControllers = [];
  List<TextEditingController> _plateControllers = [];
  List<String> _brands = [];

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case '0': return Icons.directions_car;
      case '1': return Icons.motorcycle;
      case '2': return Icons.airport_shuttle;
      case '3': return Icons.local_shipping;
      case '4': return Icons.directions_bus;
      case '5': return Icons.directions_bus_outlined;
      default: return Icons.directions_car;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkInternetAndLoadVehicles();
  }

  @override
  void dispose() {
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

  Future<void> _loadVehicles() async {
    try {
      final response = await _apiService.getVehicles();
      if (response['success'] == true) {
        setState(() {
          _vehicles = response['vehicles'];
          _modelControllers = _vehicles.map((v) => TextEditingController(text: v['vehicle_model'])).toList();
          _plateControllers = _vehicles.map((v) => TextEditingController(text: v['plate_number'])).toList();
          _brands = _vehicles.map((v) => v['vehicle_brand'].toString()).toList();
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
        Fluttertoast.showToast(msg: response['message'] ?? 'Vehicle archived successfully');
        _loadVehicles();
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to archive vehicle');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error archiving vehicle: ${e.toString()}');
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
          'vehicle_brand': _brands[i],
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

  Future<void> _selectBrand(int index) async {
    final selectedBrand = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleBrandSelectionScreen(
          vehicleType: _vehicleTypeMap[_vehicles[index]['vehicle_type'].toString()] ?? 'Car',
        ),
      ),
    );
    if (selectedBrand != null) {
      setState(() {
        _brands[index] = selectedBrand;
      });
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
                  Row(
                    children: [
                      Icon(
                        _getVehicleIcon(vehicle['vehicle_type'].toString()),
                        color: const Color(0xFF1A3D63),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _vehicleTypeMap[vehicle['vehicle_type'].toString()] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3D63),
                        ),
                      ),
                    ],
                  ),
                  _isEditing
                      ? IconButton(
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
                    'Brand',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectBrand(index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _brands[index],
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            'Brand',
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
                            _brands[index],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveChanges,
        backgroundColor: const Color(0xFF1A3D63),
        label: _isSaving
            ? const DotLoading()
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
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                  (Route<dynamic> route) => false,
                            );
                          },
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
                ? const DotLoading()
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
}