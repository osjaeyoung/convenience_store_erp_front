import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: '중요 푸시 알림 채널',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  Future<void> Function(String token)? _onTokenReceived;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  String? _pendingRoute;
  bool _initialized = false;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required Future<void> Function(String token) onTokenReceived,
  }) async {
    _navigatorKey = navigatorKey;
    _onTokenReceived = onTokenReceived;

    if (_initialized) {
      await syncTokenToServer();
      flushPendingNavigation();
      return;
    }
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _initializeLocalNotifications();

    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedMessage);
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      await _safeUpsertToken(token);
    });

    await syncTokenToServer();

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTapData(initialMessage.data);
    }
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onOpenedSub = null;
    _onTokenRefreshSub = null;
    _initialized = false;
  }

  Future<void> syncTokenToServer() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _safeUpsertToken(token);
  }

  void flushPendingNavigation() {
    if (_pendingRoute == null) return;
    final route = _pendingRoute!;
    _pendingRoute = null;
    _navigate(route);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _handleTapData(decoded);
          }
        } catch (_) {}
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final payload = <String, dynamic>{...message.data};
    final route = resolveRoute(payload);
    if (route != null) {
      payload['target_route'] = route;
    }

    await _localNotifications.show(
      id: message.hashCode,
      title: title ?? '알림',
      body: body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payload),
    );
  }

  void _onOpenedMessage(RemoteMessage message) {
    _handleTapData(message.data);
  }

  void _handleTapData(Map<String, dynamic> data) {
    final route = resolveRoute(data);
    if (route == null) return;
    _navigate(route);
  }

  void _navigate(String route) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      _pendingRoute = route;
      return;
    }

    try {
      GoRouter.of(context).go(route);
    } catch (_) {
      _pendingRoute = route;
    }
  }

  Future<void> _safeUpsertToken(String token) async {
    try {
      await _onTokenReceived?.call(token);
    } catch (_) {}
  }

  static String get platformName {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  /// 서버가 `target_route`를 주면 해당 경로를 우선 사용한다.
  /// 미제공 시 type/role/tab 기반으로 fallback 라우팅한다.
  static String? resolveRoute(Map<String, dynamic> rawData) {
    final targetRoute = rawData['target_route']?.toString().trim();
    if (targetRoute != null && targetRoute.startsWith('/')) {
      return targetRoute;
    }

    final type = rawData['type']?.toString().toLowerCase();
    switch (type) {
      case 'manager_alert':
      case 'manager_contract':
      case 'manager_notice':
        return '/manager?tab=0';
      case 'manager_recruitment':
      case 'recruitment_application':
        return '/manager?tab=4&recruitmentTab=1';
      case 'job_seeker_recruitment':
        return '/job-seeker?tab=0';
      case 'job_seeker_application':
        return '/job-seeker?tab=1';
      case 'job_seeker_contract':
        return '/job-seeker?tab=3';
    }

    final targetRole = rawData['target_role']?.toString().toLowerCase();
    final tab = _parseInt(rawData['tab']);
    final recruitmentTab = _parseInt(rawData['recruitment_tab']);
    final laborCostTab = _parseInt(rawData['labor_cost_tab']);

    if (targetRole == 'job_seeker' || targetRole == 'worker') {
      final tabQuery = tab == null ? '' : '?tab=$tab';
      return '/job-seeker$tabQuery';
    }

    if (targetRole == 'manager' || targetRole == 'owner') {
      final query = <String>[
        if (tab != null) 'tab=$tab',
        if (recruitmentTab != null) 'recruitmentTab=$recruitmentTab',
        if (laborCostTab != null) 'laborCostTab=$laborCostTab',
      ];
      final suffix = query.isEmpty ? '' : '?${query.join('&')}';
      return '/manager$suffix';
    }

    return null;
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
