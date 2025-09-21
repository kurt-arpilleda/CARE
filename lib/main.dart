import 'package:flutter/material.dart';
import 'firebase/firebase_service.dart';
import 'location_service.dart';
import 'splashScreen.dart';
import 'login.dart';
import 'dashboard.dart';
import 'checkAccount.dart';
import 'drawer/shopMessaging/shopOwnerMessageList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize(navKey: navigatorKey);
  ApiService.setupHttpOverrides();
  final prefs = await SharedPreferences.getInstance();
  final isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
  final apiService = ApiService();
  final authToken = await apiService.getAuthToken();

  final locationService = LocationService();
  if (authToken != null) {
    locationService.startLocationTracking();
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseService.setAppReady();
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
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
        '/shopMessages': (context) => const ShopOwnerMessageListScreen(),
      },
    );
  }
}