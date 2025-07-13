import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String apiUrl = "https://126.209.7.246/";
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration requestTimeoutUploadImage = Duration(seconds: 20);

  late http.Client httpClient;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
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
    String? deviceId = await _secureStorage.read(key: 'deviceId');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await _secureStorage.write(key: 'deviceId', value: deviceId);
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
    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_signup.php");
    try {
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
      throw Exception("Network error: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> signUpWithGoogle({
    required String firstName,
    required String surName,
    required String email,
    required String googleId,
    required int userType,
    required String photoUrl,
  }) async {
    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_signup.php");
    try {
      final response = await httpClient.post(
        uri,
        body: {
          'firstName': firstName,
          'surName': surName,
          'gender': '0',
          'email': email,
          'phoneNum': '',
          'userType': userType.toString(),
          'password': '',
          'signupType': '1',
          'googleId': googleId,
          'photoUrl': photoUrl,
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("HTTP ${response.statusCode}");
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_login.php");
    try {
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
      throw Exception("Network error: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String googleId,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_login.php");
    try {
      final response = await httpClient.post(
        uri,
        body: {
          'email': email,
          'googleId': googleId,
          'deviceId': deviceId,
          'isGoogleLogin': '1',
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("HTTP ${response.statusCode}");
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String emailOrPhone,
  }) async {
    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_reset_password.php");
    try {
      final response = await httpClient.post(
        uri,
        body: {'emailOrPhone': emailOrPhone},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("HTTP ${response.statusCode}");
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception("No auth token found");
    }

    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_get_user.php");
    try {
      final response = await httpClient.post(
        uri,
        body: {'token': token},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("HTTP ${response.statusCode}");
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }
  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String surName,
    required String email,
    required String phoneNum,
    required int gender,
  }) async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception("No auth token found");
    }

    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_updateProfile.php");
    try {
      final response = await httpClient.post(
        uri,
        body: {
          'token': token,
          'firstName': firstName,
          'surName': surName,
          'email': email,
          'phoneNum': phoneNum,
          'gender': gender.toString(),
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("HTTP ${response.statusCode}");
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }
  Future<Map<String, dynamic>> logout() async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception("No auth token found");
    }

    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_logout.php");
    try {
      final response = await httpClient.post(
        uri,
        body: {'token': token},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("HTTP ${response.statusCode}");
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception("No auth token found");
    }

    final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_uploadImageProfile.php");

    try {
      var request = http.MultipartRequest('POST', uri);
      request.fields['token'] = token;
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        imageFile.path,
      ));

      final response = await request.send().timeout(requestTimeoutUploadImage);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      }
      throw Exception("HTTP ${response.statusCode}");
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: 'authToken', value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'authToken');
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: 'authToken');
  }

  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: 'deviceId');
  }

  static void setupHttpOverrides() {
    HttpOverrides.global = MyHttpOverrides();
  }

  void dispose() {
    httpClient.close();
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}