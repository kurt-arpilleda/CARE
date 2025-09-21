import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  static FirebaseMessaging? _messaging;
  static auth.AutoRefreshingAuthClient? _authClient;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;
  static String? _pendingRoute;
  static bool _isAppReady = false;

  static Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    navigatorKey = navKey;
    _messaging = FirebaseMessaging.instance;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title,
          message.notification!.body,
          payload: message.notification!.title,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.notification?.title);
    });

    final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.notification?.title);
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging!.requestPermission(alert: true, badge: true, sound: true);
    await _initializeAuthClient();
  }

  static void setAppReady() {
    _isAppReady = true;
    if (_pendingRoute != null && navigatorKey?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey!.currentState?.pushNamed(_pendingRoute!);
        _pendingRoute = null;
      });
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    _handleNotificationClick(response.payload);
  }

  static void _handleNotificationClick(String? title) {
    if (title != null && title.contains("Customer:")) {
      if (_isAppReady && navigatorKey?.currentContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey!.currentState?.pushNamed('/shopMessages');
        });
      } else {
        _pendingRoute = '/shopMessages';
      }
    }
  }

  static Future<void> _showLocalNotification(String? title, String? body, {String? payload}) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_default_channel',
      'FCM Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> _initializeAuthClient() async {
    try {
      final jsonString = await rootBundle.loadString('assets/service_account.json');
      final jsonData = json.decode(jsonString);
      final credentials = auth.ServiceAccountCredentials.fromJson(jsonData);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      _authClient = await auth.clientViaServiceAccount(credentials, scopes);
    } catch (e) {
      print('Error initializing auth client: $e');
    }
  }

  static Future<String?> getFCMToken() async {
    if (_messaging == null) {
      await initialize();
    }
    return await _messaging!.getToken();
  }

  static Future<void> sendPushNotification({
    required String receiverToken,
    required String title,
    required String body,
  }) async {
    if (_authClient == null) {
      return;
    }

    try {
      const url = 'https://fcm.googleapis.com/v1/projects/cares-464807/messages:send';
      final message = {
        'message': {
          'token': receiverToken,
          'notification': {
            'title': title,
            'body': body
          },
          'data': {
            'title': title,
            'body': body,
          },
          'android': {'priority': 'high'},
          'apns': {
            'payload': {'aps': {'contentAvailable': true}},
            'headers': {'apns-priority': '10'}
          }
        }
      };

      final response = await _authClient!.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(message),
      );
      print('Send response: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.notification?.title} - ${message.notification?.body}');
}