import 'package:flutter/material.dart';
import 'package:care/dashboard.dart';

class ShopListScreen extends StatelessWidget {
  const ShopListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int visibleCardCount = 2;
    final List<Map<String, String>> shops = [
      {
        'name': 'AutoCare Masters',
        'location': '123 Main Street, City Center',
        'icon': 'garage',
      },
      {
        'name': 'Premium Auto Servicesssssssssssssssssssssssssssssssssssssssssssssssssss',
        'location': '456 Oak Avenue, Downtownssssssssssssssssszsssssssssssssssssssssssss',
        'icon': 'car_repair',
      },
      {
        'name': 'Speedy Fix Garage',
        'location': '789 Pine Road, Business District',
        'icon': 'directions_car',
      },
      {
        'name': 'Elite Vehicle Solutions',
        'location': '321 Elm Boulevard, Westside',
        'icon': 'local_shipping',
      },
      {
        'name': 'Pro Auto Workshop',
        'location': '654 Maple Lane, Uptown',
        'icon': 'two_wheeler',
      },
      {
        'name': 'Total Car Care',
        'location': '987 Cedar Street, Riverside',
        'icon': 'airport_shuttle',
      },
    ];

    final visibleShops = shops.take(visibleCardCount).toList();

    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              Container(
                color: const Color(0xFF1A3D63),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DashboardScreen()),
                          );
                        },
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Shop List',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleShops.length < 5
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: visibleShops.map((shop) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        width: MediaQuery.of(context).size.width * 0.85,
                        child: _buildShopCard(shop),
                      );
                    }).toList(),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleShops.length,
                  itemBuilder: (context, index) {
                    final shop = visibleShops[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _buildShopCard(shop),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(Map<String, String> shop) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: SizedBox(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3D63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconData(shop['icon']!),
                    color: const Color(0xFF1A3D63),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop['name']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3D63),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop['location']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF1A3D63),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'garage':
        return Icons.garage;
      case 'car_repair':
        return Icons.car_repair;
      case 'directions_car':
        return Icons.directions_car;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      default:
        return Icons.business;
    }
  }
}