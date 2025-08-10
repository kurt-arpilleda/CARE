import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'dashboard.dart';
import 'google_signin_service.dart';
import 'login.dart';
import 'drawer/vehicle/vehicleOptions.dart';

class CheckAccountScreen extends StatefulWidget {
  const CheckAccountScreen({Key? key}) : super(key: key);

  @override
  _CheckAccountScreenState createState() => _CheckAccountScreenState();
}

class _CheckAccountScreenState extends State<CheckAccountScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  bool _isBanned = false;
  bool _isSuspended = false;
  String _banMessage = 'Your account has been banned due to violations of our terms of service';
  String _suspensionMessage = '';
  DateTime? _suspendedUntil;

  @override
  void initState() {
    super.initState();
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    try {
      final response = await _apiService.getUserData();

      if (response['success'] == true) {
        final reportAction = response['user']['reportAction'] ?? 0;
        final suspendedUntil = response['user']['suspendedUntil'];

        if (reportAction == 2) {
          setState(() {
            _isBanned = true;
            _isLoading = false;
          });
        } else if (reportAction == 1 && suspendedUntil != null) {
          final now = DateTime.now();
          final suspensionEnd = DateTime.parse(suspendedUntil);

          if (now.isBefore(suspensionEnd)) {
            setState(() {
              _isSuspended = true;
              _isLoading = false;
              _suspendedUntil = suspensionEnd;
              _suspensionMessage = 'Your account is suspended until ${_formatDateTime(suspensionEnd)}';
            });
          } else {
            await _proceedToDashboard();
          }
        } else {
          await _proceedToDashboard();
        }
      } else {
        await _apiService.clearAuthToken();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error checking account status');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _proceedToDashboard() async {
    final vehicleStatus = await _apiService.checkVehicleStatus();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => vehicleStatus['hasVehicle'] == 1
              ? const DashboardScreen()
              : const VehicleOptionsScreen(fromLogin: true),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final month = monthNames[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$month $day, $year $hour:$minute';
  }

  Future<void> _logout() async {
    try {
      await _apiService.logout();
      await _apiService.clearAuthToken();
      await GoogleSignInService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error during logout');
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
        child: Center(
          child: _isLoading
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Checking account status...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          )
              : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isBanned ? Icons.block : Icons.timer,
                  size: 80,
                  color: _isBanned ? Colors.red : Colors.orange,
                ),
                const SizedBox(height: 30),
                Text(
                  _isBanned ? 'ACCOUNT BANNED' : 'ACCOUNT SUSPENDED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(1.5, 1.5),
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: _isBanned
                            ? Colors.red.withOpacity(0.5)
                            : Colors.orange.withOpacity(0.5)),
                  ),
                  child: Text(
                    _isBanned ? _banMessage : _suspensionMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBanned ? Colors.red : Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'LOG OUT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}