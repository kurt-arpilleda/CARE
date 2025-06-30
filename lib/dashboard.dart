import 'package:flutter/material.dart';
import 'api_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final apiService = ApiService();
              await apiService.clearAuthToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome! You have successfully signed in.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}