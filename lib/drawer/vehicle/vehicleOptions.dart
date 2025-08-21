import 'package:flutter/material.dart';
import 'package:care/dashboard.dart';
import 'vehicleBrands.dart';

class VehicleOptionsScreen extends StatelessWidget {
  final bool fromLogin;

  const VehicleOptionsScreen({Key? key, this.fromLogin = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Your Vehicle',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A3D63),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (fromLogin)
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6FAFD),
              Color(0xFF1A3D63),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildVehicleCard(context, 'Car', 'assets/images/car.jpg'),
                _buildVehicleCard(context, 'Motorcycle', 'assets/images/motorcycle.jpg'),
                _buildVehicleCard(context, 'Van', 'assets/images/van.jpg'),
                _buildVehicleCard(context, 'Truck', 'assets/images/truck.jpg'),
                _buildVehicleCard(context, 'Bus', 'assets/images/bus.jpg'),
                _buildVehicleCard(context, 'Jeep', 'assets/images/jeep.jpg'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, String title, String imagePath) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleBrandsScreen(vehicleType: title),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.35),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black45,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}