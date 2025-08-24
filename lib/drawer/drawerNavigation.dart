import 'package:flutter/material.dart';
import 'package:care/api_service.dart';
import 'profile.dart';
import 'package:care/google_signin_service.dart';
import 'vehicle/vehicleOptions.dart';
import 'package:care/anim/shimmer_profile.dart';
import 'vehicle/activateVehicle.dart';
import 'shop/registerShop_basicInfo.dart';
import 'shopProfile/shopList.dart';
import 'shopMessaging/shopOwnerMessageList.dart';

class DashboardDrawer extends StatefulWidget {
  const DashboardDrawer({Key? key}) : super(key: key);

  @override
  _DashboardDrawerState createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer> {
  final ApiService _apiService = ApiService();
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String? _userPhotoUrl;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _apiService.getUserData();
      if (response['success'] == true && response['user'] != null) {
        final user = response['user'];
        setState(() {
          _userName = "${user['firstName']} ${user['surName']}";
          _userEmail = user['email'] ?? '';
          _userPhotoUrl = user['photoUrl'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = "Unknown User";
          _userEmail = "No email";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = "Error loading";
        _userEmail = "Error loading";
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFF6FAFD),
          title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3D63))),
          content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.black87)),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoggingOut = true);

    try {
      await _apiService.logout();
      await _apiService.clearAuthToken();
      await GoogleSignInService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      await _apiService.clearAuthToken();
      await GoogleSignInService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Widget _buildProfileImage() {
    final imageUrl = _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
        ? _userPhotoUrl!.contains('http')
        ? _userPhotoUrl
        : '${ApiService.apiUrl}profilePicture/$_userPhotoUrl'
        : null;

    if (imageUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {},
      );
    } else {
      return const CircleAvatar(
        backgroundImage: AssetImage('assets/images/profilePlaceHolder.png'),
      );
    }
  }

  Widget _buildUserHeader() {
    if (_isLoading) {
      return const ShimmerProfile();
    }

    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFF1A3D63)),
      accountName: Text(_userName),
      accountEmail: Text(_userEmail),
      currentAccountPicture: _buildProfileImage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.of(context).size.width * 0.75;

    return Theme(
      data: Theme.of(context).copyWith(drawerTheme: const DrawerThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero))),
      child: SizedBox(
        width: drawerWidth,
        child: Drawer(
          backgroundColor: const Color(0xFFF6FAFD),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildUserHeader(),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text("Profile"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.check_circle),
                            title: const Text("Activate Vehicle"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ActivateVehicleScreen()
                                  )
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.car_repair),
                            title: const Text("Shop Profile"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ShopListScreen()),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.store),
                            title: const Text("Register Shop"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterShopBasicInfo(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.directions_car_filled),
                            title: const Text("Register Vehicle"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleOptionsScreen()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.message),
                            title: Row(
                              children: [
                                const Text("Shop Messages"),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    "99+",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShopOwnerMessageListScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const Divider(),
                      ListTile(
                        leading: _isLoggingOut
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.red)))
                            : const Icon(Icons.logout, color: Colors.red),
                        title: Text(_isLoggingOut ? "Logging out..." : "Logout", style: const TextStyle(color: Colors.red)),
                        onTap: _isLoggingOut ? null : _handleLogout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}