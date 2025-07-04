import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String apiUrl = "https://126.209.7.246/";
  static const Duration requestTimeout = Duration(seconds: 5);
  static const int maxRetries = 6;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  late http.Client httpClient;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final Uuid _uuid = const Uuid();

  ApiService() {
    httpClient = _createHttpClient();
  }

  http.Client _createHttpClient() {
    final HttpClient client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(client);
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await _prefs;
    String? deviceId = prefs.getString('deviceId');

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await prefs.setString('deviceId', deviceId);
    }

    return deviceId;
  }

  Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String surName,
    required int gender,
    required String email,
    required String phoneNum,
    required int userType,
    required String password,
    required int signupType,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_signup.php");
        final response = await httpClient.post(
          uri,
          body: {
            'firstName': firstName,
            'surName': surName,
            'gender': gender.toString(),
            'email': email,
            'phoneNum': phoneNum,
            'userType': userType.toString(),
            'password': password,
            'signupType': signupType.toString(),
          },
        ).timeout(requestTimeout);

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
        throw Exception("HTTP ${response.statusCode}");
      } catch (e) {
        print("Attempt $attempt failed: $e");
        if (attempt < maxRetries) {
          final delay = initialRetryDelay * (1 << (attempt - 1));
          await Future.delayed(delay);
        }
      }
    }
    throw Exception("API is unreachable after $maxRetries attempts");
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _getOrCreateDeviceId();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_login.php");
        final response = await httpClient.post(
          uri,
          body: {
            'email': email,
            'password': password,
            'deviceId': deviceId,
          },
        ).timeout(requestTimeout);

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
        throw Exception("HTTP ${response.statusCode}");
      } catch (e) {
        print("Attempt $attempt failed: $e");
        if (attempt < maxRetries) {
          final delay = initialRetryDelay * (1 << (attempt - 1));
          await Future.delayed(delay);
        }
      }
    }
    throw Exception("API is unreachable after $maxRetries attempts");
  }

  Future<void> saveAuthToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString('authToken', token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await _prefs;
    return prefs.getString('authToken');
  }

  Future<void> clearAuthToken() async {
    final prefs = await _prefs;
    await prefs.remove('authToken');
  }

  Future<String?> getDeviceId() async {
    final prefs = await _prefs;
    return prefs.getString('deviceId');
  }

  static void setupHttpOverrides() {
    HttpOverrides.global = MyHttpOverrides();
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}