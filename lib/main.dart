import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase/firebase_service.dart';
import 'splashScreen.dart';
import 'login.dart';
import 'dashboard.dart';
import 'checkAccount.dart';
import 'api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  ApiService.setupHttpOverrides();
  final prefs = await SharedPreferences.getInstance();
  final isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
  final apiService = ApiService();
  final authToken = await apiService.getAuthToken();
  runApp(MyApp(
    initialRoute: isFirstOpen
        ? '/splash'
        : authToken != null
        ? '/checkAccount'
        : '/login',
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({required this.initialRoute, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CARE',
      theme: ThemeData(
        fontFamily: 'Lato-Black',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/checkAccount': (context) => const CheckAccountScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}