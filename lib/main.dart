import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splashScreen.dart';
import 'login.dart';
import 'dashboard.dart';
import 'api_service.dart';
import 'auto_update.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.setupHttpOverrides();

  final prefs = await SharedPreferences.getInstance();
  final isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

  // Check auth token from secure storage
  final apiService = ApiService();
  final authToken = await apiService.getAuthToken();

  runApp(MyApp(
    initialRoute: isFirstOpen
        ? '/splash'
        : authToken != null
        ? '/dashboard'
        : '/login',
  ));
}
class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AutoUpdate.checkForUpdate(context);
    });

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
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}