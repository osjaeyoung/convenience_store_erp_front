import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseException;
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
      flushPendingNavigation();
      return;
    }
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }
      final token = await _getFcmTokenWithIosRetry();
      if (token == null || token.isEmpty) return;
      await _safeUpsertToken(token);
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set' || e.code == 'missing-apns-token') {
        return;
      }
    } catch (_) {}
  }

  /// iOS: 권한 직후에도 APNS 토큰이 늦게 올 수 있어 짧게 대기한다.
  Future<void> _waitForApnsToken({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<String?> _getFcmTokenWithIosRetry() async {
    const maxAttempts = 6;
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final t = await _messaging.getToken();
        if (t != null && t.isNotEmpty) return t;
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set' && e.code != 'missing-apns-token') {
          rethrow;
        }
      }
      await Future<void>.delayed(Duration(milliseconds: 350 * (i + 1)));
    }
    try {
      return await _messaging.getToken();
    } on FirebaseException {
      return null;
    }
  }

  /// 로그인 성공 후 호출: FCM·로컬 알림 권한 요청 → 토큰 발급/서버 등록
  Future<void> onUserAuthenticated() async {
    if (!_initialized || kIsWeb) return;

    await requestFcmPermission();
    await _requestPlatformLocalNotificationPermission();
    await syncTokenToServer();
  }

  /// FCM 푸시 권한 (iOS 시스템 다이얼로그, Android는 주로 no-op)
  Future<NotificationSettings> requestFcmPermission() {
    return _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void flushPendingNavigation() {
    if (_pendingRoute == null) return;
    final route = _pendingRoute!;
    _pendingRoute = null;
    _navigate(route);
  }

  Future<void> _requestPlatformLocalNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    }
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
