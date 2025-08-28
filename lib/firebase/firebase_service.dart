import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static FirebaseMessaging? _messaging;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<String?> getFCMToken() async {
    try {
      if (_messaging == null) {
        await initialize();
      }
      return await _messaging!.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
}