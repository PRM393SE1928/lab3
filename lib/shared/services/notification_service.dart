import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _started = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> start() async {
    if (_started || !_supported || Firebase.apps.isEmpty) return;
    _started = true;
    try {
      final messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _subscriptions.add(FirebaseMessaging.onMessage.listen(_showMessage));
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen(_showMessage),
      );
      _subscriptions.add(
        messaging.onTokenRefresh.listen((token) {
          unawaited(_saveToken(token));
        }),
      );
      _subscriptions.add(
        FirebaseAuth.instance.authStateChanges().listen((user) {
          if (user != null) unawaited(_register());
        }),
      );
      await messaging.requestPermission();
      await _register();
      final initial = await messaging.getInitialMessage();
      if (initial != null) _showMessage(initial);
    } catch (error) {
      debugPrint('Không thể khởi tạo thông báo: $error');
    }
  }

  Future<void> _register() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
    } catch (error) {
      debugPrint('Không thể đăng ký thông báo: $error');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final id = sha256.convert(utf8.encode(token)).toString();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(id)
          .set({
            'token': token,
            'platform': defaultTargetPlatform.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (error) {
      debugPrint('Không thể lưu token thông báo: $error');
    }
  }

  Future<void> removeCurrentToken() async {
    if (!_supported || Firebase.apps.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await FirebaseMessaging.instance.getToken();
      if (user == null || token == null) return;
      final id = sha256.convert(utf8.encode(token)).toString();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(id)
          .delete();
    } catch (error) {
      debugPrint('Không thể xóa token thông báo khi đăng xuất: $error');
    }
  }

  void _showMessage(RemoteMessage message) {
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    final text = [
      title,
      body,
    ].whereType<String>().where((s) => s.isNotEmpty).join(': ');
    if (text.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
    });
  }
}
