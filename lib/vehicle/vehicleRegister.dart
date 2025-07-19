import 'package:flutter/material.dart';

class VehicleRegisterScreen extends StatefulWidget {
  final String vehicleType;

  const VehicleRegisterScreen({Key? key, required this.vehicleType}) : super(key: key);

  @override
  _VehicleRegisterScreenState createState() => _VehicleRegisterScreenState();
}

class _VehicleRegisterScreenState extends State<VehicleRegisterScreen> {
  List<Map<String, String>> vehicles = [
    {'model': '', 'plateNumber': ''}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.vehicleType} Information',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A3D63),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFF6FAFD),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: vehicles.length == 1
              ? Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: _buildVehicleCard(0),
            ),
          )
              : ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildVehicleCard(index),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            vehicles.add({'model': '', 'plateNumber': ''});
          });
        },
        backgroundColor: const Color(0xFF4A7FA7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildVehicleCard(int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        constraints: vehicles.length == 1
            ? const BoxConstraints(maxWidth: 500)
            : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1A3D63),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Vehicle ${index + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Vehicle Model',
                        hintStyle: TextStyle(color: Color(0xFF0A1931)),
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        vehicles[index]['model'] = value;
                      },
                      style: const TextStyle(
                        color: Color(0xFF0A1931),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Plate Number',
                        hintStyle: TextStyle(color: Color(0xFF0A1931)),
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        vehicles[index]['plateNumber'] = value;
                      },
                      style: const TextStyle(
                        color: Color(0xFF0A1931),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (vehicles.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      vehicles.removeAt(index);
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF1A3D63),
                      size: 20,
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
