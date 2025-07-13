import 'package:flutter/material.dart';
import '../api_service.dart';
import 'profile.dart';

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
    setState(() => _isLoggingOut = true);

    try {
      await _apiService.logout();
      await _apiService.clearAuthToken();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      await _apiService.clearAuthToken();
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
        : '${ApiService.apiUrl}V4/Others/Kurt/CareAPI/profilePicture/$_userPhotoUrl'
        : null;

    if (imageUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {},
        child: _isLoading
            ? const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : null,
      );
    } else {
      return CircleAvatar(
        backgroundImage: const AssetImage('assets/images/icon.png'),
        child: _isLoading
            ? const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : null,
      );
    }
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
                          UserAccountsDrawerHeader(
                            decoration: const BoxDecoration(color: Color(0xFF1A3D63)),
                            accountName: Text(_userName),
                            accountEmail: Text(_userEmail),
                            currentAccountPicture: _buildProfileImage(),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text("Profile"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.directions_car),
                            title: const Text("Activate Vehicle"),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.store),
                            title: const Text("Register Shop"),
                            onTap: () {
                              Navigator.pop(context);
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