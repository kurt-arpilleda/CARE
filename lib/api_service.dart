import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:unique_identifier/unique_identifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String apiUrl = "http://126.209.7.246/";
  static const Duration requestTimeout = Duration(seconds: 5);
  static const int maxRetries = 6;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  late http.Client httpClient;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  ApiService() {
    httpClient = _createHttpClient();
  }

  http.Client _createHttpClient() {
    final HttpClient client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(client);
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<Map<String, dynamic>> fetchProfile(String idNumber) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_fetchProfile.php?idNumber=$idNumber");
        final response = await httpClient.get(uri).timeout(requestTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["success"] == true) {
            return data;
          } else {
            throw Exception(data["message"] ?? "Profile fetch failed");
          }
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

  Future<void> updateLanguageFlag(String idNumber, int languageFlag) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse("${apiUrl}V4/Others/Kurt/CareAPI/kurt_updateLanguage.php");
        final response = await httpClient.post(
          uri,
          body: {
            'idNumber': idNumber,
            'languageFlag': languageFlag.toString(),
          },
        ).timeout(requestTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["success"] == true) {
            return;
          } else {
            throw Exception(data["message"] ?? "Update failed");
          }
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