import 'package:flutter/material.dart';
import 'package:care/api_service.dart';

class UserVehicleDialog extends StatefulWidget {
  final int userId;
  final String userName;

  const UserVehicleDialog({Key? key, required this.userId, required this.userName}) : super(key: key);

  @override
  _UserVehicleDialogState createState() => _UserVehicleDialogState();
}

class _UserVehicleDialogState extends State<UserVehicleDialog> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  final Map<String, String> _vehicleTypeMap = {
    '0': 'Car',
    '1': 'Motorcycle',
    '2': 'Van',
    '3': 'Truck',
    '4': 'Bus',
    '5': 'Jeep',
  };

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

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

  Future<void> _loadVehicles() async {
    try {
      final response = await _apiService.getUserVehicles(userId: widget.userId);
      if (response['success'] == true) {
        setState(() {
          _vehicles = List<Map<String, dynamic>>.from(response['vehicles']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getVehicleIcon(vehicle['vehicle_type'].toString()),
                  color: const Color(0xFF1A3D63),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _vehicleTypeMap[vehicle['vehicle_type'].toString()] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3D63),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Brand', vehicle['vehicle_brand'] ?? ''),
            const SizedBox(height: 12),
            _buildInfoRow('Model', vehicle['vehicle_model'] ?? ''),
            const SizedBox(height: 12),
            _buildInfoRow('Plate Number', vehicle['plate_number'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3D63).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_outlined,
                      color: Color(0xFF1A3D63),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Vehicles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3D63),
                          ),
                        ),
                        Text(
                          widget.userName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: Color(0xFF1A3D63),
                  ),
                ),
              )
                  : _vehicles.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Active Vehicles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3D63),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This user has no active vehicles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildVehicleCard(_vehicles[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}