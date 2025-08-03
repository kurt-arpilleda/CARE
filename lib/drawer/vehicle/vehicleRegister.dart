import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:care/api_service.dart';
import 'vehicleBrandSelectionScreen.dart';

class VehicleRegisterScreen extends StatefulWidget {
  final String vehicleType;
  final String? vehicleBrand;

  const VehicleRegisterScreen({
    Key? key,
    required this.vehicleType,
    this.vehicleBrand,
  }) : super(key: key);

  @override
  _VehicleRegisterScreenState createState() => _VehicleRegisterScreenState();
}

class _VehicleRegisterScreenState extends State<VehicleRegisterScreen> {
  List<Map<String, dynamic>> vehicles = [
    {
      'brand': '',
      'model': '',
      'plateNumber': '',
      'hasError': false,
      'errorMessage': ''
    }
  ];
  final _apiService = ApiService();
  bool _isSaving = false;
  List<TextEditingController> modelControllers = [TextEditingController()];
  List<TextEditingController> plateControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    if (widget.vehicleBrand != null) {
      vehicles[0]['brand'] = widget.vehicleBrand;
    }
  }

  @override
  void dispose() {
    for (var controller in modelControllers) {
      controller.dispose();
    }
    for (var controller in plateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveVehicles() async {
    for (int i = 0; i < vehicles.length; i++) {
      vehicles[i]['model'] = modelControllers[i].text;
      vehicles[i]['plateNumber'] = plateControllers[i].text;
    }

    bool hasEmptyFields = false;
    List<Map<String, dynamic>> validVehicles = [];

    for (int i = 0; i < vehicles.length; i++) {
      final vehicle = vehicles[i];
      if (vehicle['brand'].toString().trim().isEmpty ||
          vehicle['model'].toString().trim().isEmpty ||
          vehicle['plateNumber'].toString().trim().isEmpty) {
        setState(() {
          vehicles[i]['hasError'] = true;
          vehicles[i]['errorMessage'] = 'Please fill all fields';
        });
        hasEmptyFields = true;
      } else {
        validVehicles.add({
          'vehicleType': widget.vehicleType,
          'brand': vehicle['brand'],
          'model': vehicle['model'],
          'plateNumber': vehicle['plateNumber']
        });
      }
    }

    if (hasEmptyFields || validVehicles.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill all required fields');
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: Text('Are you sure you want to save ${validVehicles.length} vehicle(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    setState(() => _isSaving = true);

    try {
      final token = await _apiService.getAuthToken();
      if (token == null) throw Exception("No auth token found");

      final response = await _apiService.addVehicles(
        token: token,
        vehicles: validVehicles,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: response['message']);
        setState(() {
          vehicles = [
            {
              'brand': '',
              'model': '',
              'plateNumber': '',
              'hasError': false,
              'errorMessage': ''
            }
          ];
          for (var controller in modelControllers) {
            controller.dispose();
          }
          for (var controller in plateControllers) {
            controller.dispose();
          }
          modelControllers = [TextEditingController()];
          plateControllers = [TextEditingController()];
        });
      } else if (response['duplicates'] != null) {
        for (var error in response['duplicates']) {
          final index = error['index'];
          if (index < vehicles.length) {
            setState(() {
              vehicles[index]['hasError'] = true;
              vehicles[index]['errorMessage'] = error['message'];
            });
          }
        }
        Fluttertoast.showToast(msg: 'Some vehicles already exist');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Failed to save vehicles');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addNewVehicle() async {
    // Navigate to brand selection and wait for result
    final selectedBrand = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleBrandSelectionScreen(vehicleType: widget.vehicleType),
      ),
    );

    // If a brand was selected, add it to the vehicles list
    if (selectedBrand != null) {
      setState(() {
        vehicles.add({
          'brand': selectedBrand,
          'model': '',
          'plateNumber': '',
          'hasError': false,
          'errorMessage': ''
        });
        modelControllers.add(TextEditingController());
        plateControllers.add(TextEditingController());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveVehicles,
        backgroundColor: const Color(0xFF1A3D63),
        label: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text('Save', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.save, color: Colors.white),
      ),
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
                      Text(
                        '${widget.vehicleType} Registration',
                        style: TextStyle(
                          color: const Color(0xFFF6FAFD),
                          fontSize: widget.vehicleType.length > 9 ? 22 : 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF6FAFD), size: 30),
                          tooltip: 'Add Vehicle',
                          onPressed: _addNewVehicle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (vehicles.length == 1)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildVehicleCard(0),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildVehicleCard(index),
                          );
                        },
                        childCount: vehicles.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(int index) {
    final vehicle = vehicles[index];
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
          color: vehicle['hasError'] ? Colors.red[50] : Colors.white,
          border: vehicle['hasError']
              ? Border.all(color: Colors.red, width: 1)
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vehicle['hasError'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        vehicle['errorMessage'],
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final selectedBrand = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleBrandSelectionScreen(vehicleType: widget.vehicleType),
                        ),
                      );
                      if (selectedBrand != null) {
                        setState(() {
                          vehicles[index]['brand'] = selectedBrand;
                        });
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brand',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: vehicle['hasError']
                                  ? Colors.red
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    vehicle['brand'].isEmpty ? 'Select Brand' : vehicle['brand'],
                                    style: TextStyle(
                                      color: vehicle['brand'].isEmpty ? Colors.grey : Colors.black87,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Model',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: vehicle['hasError']
                            ? Colors.red
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: modelControllers[index],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Enter vehicle model',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          vehicles[index]['model'] = value;
                          vehicles[index]['hasError'] = false;
                          vehicles[index]['errorMessage'] = '';
                        });
                      },
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Plate Number',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: vehicle['hasError']
                            ? Colors.red
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: plateControllers[index],
                      decoration: const InputDecoration(
                        hintText: 'Enter plate number',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          vehicles[index]['plateNumber'] = value;
                          vehicles[index]['hasError'] = false;
                          vehicles[index]['errorMessage'] = '';
                        });
                      },
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (vehicles.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      vehicles.removeAt(index);
                      modelControllers[index].dispose();
                      plateControllers[index].dispose();
                      modelControllers.removeAt(index);
                      plateControllers.removeAt(index);
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[700],
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}