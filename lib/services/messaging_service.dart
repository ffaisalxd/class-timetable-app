import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

class MessagingService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await refreshToken();

    _messaging.onTokenRefresh.listen(
          (newToken) async {
        await _saveToken(newToken);
      },
    );

    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) async {
        final notification =
            message.notification;

        if (notification == null) {
          return;
        }

        await NotificationService.showRemoteAlert(
          title:
          notification.title ??
              'Class Timetable',
          message:
          notification.body ?? '',
        );
      },
    );
  }

  static Future<void> refreshToken() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final token =
    await _messaging.getToken();

    if (token == null) {
      return;
    }

    await _saveToken(token);
  }

  static Future<void> _saveToken(
      String token,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'fcmToken': token,
        },
        SetOptions(
          merge: true,
        ),
      );
    } catch (_) {
      // Token failure should not interrupt login.
    }
  }
}