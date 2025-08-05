import 'package:flutter/material.dart';
import 'package:care/dashboard.dart';
import 'package:care/api_service.dart';
import 'shopDetails.dart';
import 'package:care/anim/dotLoading.dart';
import '../shop/registerShop_basicInfo.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({Key? key}) : super(key: key);

  @override
  _ShopListScreenState createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _shopsFuture;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isEditMode = false;
  Set<int> _selectedShopIds = {};

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

  Future<void> _refreshShops() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(Duration(milliseconds: 300));

    setState(() {
      _isLoading = true;
      _shopsFuture = _fetchShops();
      _selectedShopIds.clear();
    });

    await _shopsFuture;

    setState(() {
      _isRefreshing = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selectedShopIds.clear();
    });
  }

  void _toggleShopSelection(int shopId) {
    setState(() {
      if (_selectedShopIds.contains(shopId)) {
        _selectedShopIds.remove(shopId);
      } else {
        _selectedShopIds.add(shopId);
      }
    });
  }

  Future<void> _deleteSelectedShops() async {
    if (_selectedShopIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${_selectedShopIds.length} shop(s)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final response = await _apiService.deleteShops(shopIds: _selectedShopIds.toList());
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Shops deleted successfully')),
          );
          _toggleEditMode();
          _refreshShops();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete shops: ${response['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildBackgroundImage(String? shopLogo) {
    if (shopLogo != null && shopLogo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          '${ApiService.apiUrl}shopLogo/$shopLogo',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultBackground();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          },
        ),
      );
    } else {
      return _buildDefaultBackground();
    }
  }

  Widget _buildDefaultBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/carService.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Color _getValidationBorderColor(int isValidated) {
    switch (isValidated) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Icon _getValidationIcon(int isValidated) {
    switch (isValidated) {
      case 1:
        return Icon(Icons.check_circle, color: Colors.green);
      case 2:
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.access_time, color: Colors.orange);
    }
  }

  String _getValidationText(int isValidated) {
    switch (isValidated) {
      case 1:
        return 'Validated';
      case 2:
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isEditMode ? Colors.red : Color(0xFF4A7FA7),
        child: Icon(
          _isEditMode ? Icons.delete : Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          if (_isEditMode) {
            _deleteSelectedShops();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegisterShopBasicInfo(),
              ),
            );
          }
        },
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          _isEditMode ? Icons.close : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: _toggleEditMode,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isRefreshing)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const DotLoading(),
                      const SizedBox(height: 8),
                      const Text(
                        'Refreshing...',
                        style: TextStyle(
                          color: Color(0xFF1A3D63),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _shopsFuture,
                  builder: (context, snapshot) {
                    if (_isLoading && !_isRefreshing) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const DotLoading(),
                          const SizedBox(height: 20),
                          const Text(
                            'Loading shops...',
                            style: TextStyle(
                              color: Color(0xFFF6FAFD),
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
                            child: _buildShopCard(context, shop),
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
                          child: _buildShopCard(context, shop),
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

  Widget _buildShopCard(BuildContext context, Map<String, dynamic> shop) {
    final int isValidated = shop['isValidated'] ?? 0;
    final borderColor = _getValidationBorderColor(isValidated);
    final int shopId = shop['id'] ?? 0;
    final bool isSelected = _selectedShopIds.contains(shopId);

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (_isEditMode) {
            _toggleShopSelection(shopId);
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopDetailsScreen(shopData: shop),
              ),
            );

            if (result == true) {
              _refreshShops();
            }
          }
        },
        child: SizedBox(
          height: 110,
          child: Stack(
            children: [
              _buildBackgroundImage(shop['shopLogo']),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _getValidationIcon(isValidated),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shop['shop_name'] ?? 'No Name',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shop['location'] ?? 'No Location',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getValidationText(isValidated),
                            style: TextStyle(
                              fontSize: 12,
                              color: borderColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isEditMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleShopSelection(shopId);
                        },
                        activeColor: Colors.white,
                        checkColor: Colors.blue,
                        side: BorderSide(color: Colors.white, width: 2),
                      )
                    else
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}