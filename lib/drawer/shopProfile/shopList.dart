import 'package:flutter/material.dart';
import 'package:care/dashboard.dart';
import 'package:care/api_service.dart';
import 'shopDetails.dart';
import 'package:care/anim/dotLoading.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({Key? key}) : super(key: key);

  @override
  _ShopListScreenState createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _shopsFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _shopsFuture = _fetchShops();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchShops() async {
    try {
      final response = await _apiService.getShops();
      setState(() {
        _isLoading = false;
      });
      return response;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _shopsFuture,
                  builder: (context, snapshot) {
                    if (_isLoading) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const DotLoading(),
                          const SizedBox(height: 20),
                          const Text(
                            'Loading shops...',
                            style: TextStyle(
                              color: Color(0xFF1A3D63),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    }

                    if (snapshot.hasError || !snapshot.data!['success']) {
                      return Center(
                        child: Text(
                          'Failed to load shops: ${snapshot.hasError ? snapshot.error.toString() : snapshot.data!['message']}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final shops = List<Map<String, dynamic>>.from(
                        snapshot.data!['shops'] ?? []);

                    if (shops.isEmpty) {
                      return const Center(
                        child: Text(
                          'No shops registered yet',
                          style: TextStyle(
                            color: Color(0xFF1A3D63),
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    final bool useCenteredLayout = shops.length <= 4;

                    return useCenteredLayout
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: shops.map((shop) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: _buildShopCard(
                              context,
                              {
                                'name': shop['shop_name'] ?? 'No Name',
                                'location': shop['location'] ?? 'No Location',
                                'icon': 'directions_car',
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: shops.length,
                      itemBuilder: (context, index) {
                        final shop = shops[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _buildShopCard(
                            context,
                            {
                              'name': shop['shop_name'] ?? 'No Name',
                              'location': shop['location'] ?? 'No Location',
                              'icon': 'directions_car',
                            },
                          ),
                        );
                      },
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

  Widget _buildShopCard(BuildContext context, Map<String, String> shop) {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopDetailsScreen(),
            ),
          );
        },
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
                  child: const Icon(
                    Icons.directions_car,
                    color: Color(0xFF1A3D63),
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
}