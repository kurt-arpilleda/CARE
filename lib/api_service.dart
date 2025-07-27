import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String apiUrl = "https://cares-webapp.online/API/CaresAPI/";
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration requestTimeoutUploadImage = Duration(seconds: 45);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  late http.Client httpClient;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  ApiService() {
    httpClient = _createHttpClient();
  }

  http.Client _createHttpClient() {
    final HttpClient client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = requestTimeout;
    client.idleTimeout = const Duration(seconds: 30);
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

  Future<Map<String, dynamic>> _executeWithRetry(Future<Map<String, dynamic>> Function() fn) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay * attempt);
      }
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String surName,
    required int gender,
    required String email,
    required String phoneNum,
    required String password,
    required int signupType,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_signup.php");
      final response = await httpClient.post(
        uri,
        body: {
          'firstName': firstName,
          'surName': surName,
          'gender': gender.toString(),
          'email': email,
          'phoneNum': phoneNum,
          'password': password,
          'signupType': signupType.toString(),
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> signUpWithGoogle({
    required String firstName,
    required String surName,
    required String email,
    required String googleId,
    required String photoUrl,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_signup.php");
      final response = await httpClient.post(
        uri,
        body: {
          'firstName': firstName,
          'surName': surName,
          'gender': '0',
          'email': email,
          'phoneNum': '',
          'password': '',
          'signupType': '1',
          'googleId': googleId,
          'photoUrl': photoUrl,
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _executeWithRetry(() async {
      final deviceId = await _getOrCreateDeviceId();
      final uri = Uri.parse("${apiUrl}cares_login.php");
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
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String googleId,
  }) async {
    return _executeWithRetry(() async {
      final deviceId = await _getOrCreateDeviceId();
      final uri = Uri.parse("${apiUrl}cares_login.php");
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
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String emailOrPhone,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_reset_password.php");
      final response = await httpClient.post(
        uri,
        body: {'emailOrPhone': emailOrPhone},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> getUserData() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_get_user.php");
      final response = await httpClient.post(
        uri,
        body: {'token': token},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String surName,
    required String email,
    required String phoneNum,
    required int gender,
  }) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_updateProfile.php");
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
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> logout() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_logout.php");
      final response = await httpClient.post(
        uri,
        body: {'token': token},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_uploadImageProfile.php");
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
      throw HttpException("HTTP ${response.statusCode}");
    });
  }
  Future<Map<String, dynamic>> addVehicles({
    required String token,
    required List<Map<String, dynamic>> vehicles,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_addVehicle.php");
      final response = await httpClient.post(
        uri,
        body: {
          'token': token,
          'vehicles': jsonEncode(vehicles),
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }
  Future<Map<String, dynamic>> getVehicles() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_getVehicles.php");
      final response = await httpClient.post(
        uri,
        body: {'token': token},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> toggleVehicle({
    required int vehicleId,
    required bool isActive,
  }) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_toggleVehicle.php");
      final response = await httpClient.post(
        uri,
        body: {
          'token': token,
          'vehicleId': vehicleId.toString(),
          'isActive': isActive ? '1' : '0',
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }
  Future<Map<String, dynamic>> updateVehicles({
    required String token,
    required List<Map<String, dynamic>> vehicles,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_updateVehicles.php");
      final response = await httpClient.post(
        uri,
        body: {
          'token': token,
          'vehicles': jsonEncode(vehicles),
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> deleteVehicle({
    required String token,
    required int vehicleId,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_deleteVehicles.php");
      final response = await httpClient.post(
        uri,
        body: {
          'token': token,
          'vehicleId': vehicleId.toString(),
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }

  Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String location,
    required String expertise,
    String? homePage,
    required String services,
    String? startTime,
    String? closeTime,
    String? dayIndex,
    required File businessDocu,
    required File validId,
  }) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_registerShop.php");
      var request = http.MultipartRequest('POST', uri);

      request.fields['token'] = token;
      request.fields['shopName'] = shopName;
      request.fields['location'] = location;
      request.fields['expertise'] = expertise;
      if (homePage != null) request.fields['homePage'] = homePage;
      request.fields['services'] = services;
      if (startTime != null) request.fields['startTime'] = startTime;
      if (closeTime != null) request.fields['closeTime'] = closeTime;
      if (dayIndex != null) request.fields['dayIndex'] = dayIndex;

      request.files.add(await http.MultipartFile.fromPath(
        'businessDocu',
        businessDocu.path,
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'validId',
        validId.path,
      ));

      final response = await request.send().timeout(requestTimeoutUploadImage);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }
  Future<Map<String, dynamic>> getShops() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_getShops.php");
      final response = await httpClient.post(
        uri,
        body: {'token': token},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }
  Future<Map<String, dynamic>> updateShop({
    required int shopId,
    required String shopName,
    required String location,
    required String expertise,
    String? homePage,
    required String services,
    required String startTime,
    required String closeTime,
    required String dayIndex,
    File? shopLogoFile,
    File? businessDocuFile,
    File? validIdFile,
  }) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_updateShop.php");
      var request = http.MultipartRequest('POST', uri);

      request.fields['token'] = token;
      request.fields['shopId'] = shopId.toString();
      request.fields['shopName'] = shopName;
      request.fields['location'] = location;
      request.fields['expertise'] = expertise;
      if (homePage != null) request.fields['homePage'] = homePage;
      request.fields['services'] = services;
      request.fields['startTime'] = startTime;
      request.fields['closeTime'] = closeTime;
      request.fields['dayIndex'] = dayIndex;

      if (shopLogoFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'shopLogo',
          shopLogoFile.path,
        ));
      }

      if (businessDocuFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'businessDocu',
          businessDocuFile.path,
        ));
      }

      if (validIdFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'validId',
          validIdFile.path,
        ));
      }

      final response = await request.send().timeout(requestTimeoutUploadImage);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
  }
  Future<Map<String, dynamic>> deleteShops({
    required List<int> shopIds,
  }) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${apiUrl}cares_deleteShops.php");
      final response = await httpClient.post(
        uri,
        body: {
          'token': token,
          'shopIds': shopIds.join(','),
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw HttpException("HTTP ${response.statusCode}");
    });
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
    final HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = ApiService.requestTimeout;
    client.idleTimeout = const Duration(seconds: 30);
    return client;
  }
}