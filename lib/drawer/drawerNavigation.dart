import 'package:flutter/material.dart';
import '../api_service.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        drawerTheme: const DrawerThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
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
                          accountName: const Text("John Doe"),
                          accountEmail: const Text("john@example.com"),
                          currentAccountPicture: const CircleAvatar(
                            backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text("Profile"),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: const Text("Activate Vehicle"),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.store),
                          title: const Text("Register Shop"),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text("Logout", style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        final apiService = ApiService();
                        await apiService.clearAuthToken();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
