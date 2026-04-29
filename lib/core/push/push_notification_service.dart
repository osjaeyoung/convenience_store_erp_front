import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart'
    show Firebase, FirebaseException;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/screens/account_inquiry_detail_screen.dart';
import '../../features/job_seeker/screens/worker_contract_chat_detail_screen.dart';
import '../../features/job_seeker/screens/worker_recruitment_chat_screen.dart';
import '../../features/manager/screens/recruitment_application_detail_screen.dart';
import '../../features/manager/screens/recruitment_inquiry_chat_screen.dart';
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
  final StreamController<Map<String, dynamic>>
  _foregroundNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  GlobalKey<NavigatorState>? _navigatorKey;
  Future<void> Function(String token)? _onTokenReceived;
  Future<void> Function()? _onNotificationReceived;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  String? _pendingRoute;
  Map<String, dynamic>? _pendingData;
  bool _initialized = false;

  Stream<Map<String, dynamic>> get foregroundNotifications =>
      _foregroundNotificationController.stream;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required Future<void> Function(String token) onTokenReceived,
    Future<void> Function()? onNotificationReceived,
  }) async {
    _navigatorKey = navigatorKey;
    _onTokenReceived = onTokenReceived;
    _onNotificationReceived = onNotificationReceived;

    if (_initialized) {
      flushPendingNavigation();
      return;
    }
    _initialized = true;

    // 앱 시작 시점에 푸시 권한을 요청하여 iOS에서 APNs 토큰이 생성되도록 유도 (Firebase Phone Auth silent verification 등에서 필요)
    await requestFcmPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Foreground 알림은 아래 onMessage에서 local notification으로만 표시한다.
    // iOS의 FCM foreground presentation까지 켜면 같은 푸시가 2번 보일 수 있다.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
    await _initializeLocalNotifications();
    await _requestPlatformLocalNotificationPermission();

    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _onOpenedMessage,
    );
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
    final data = _pendingData ?? {};
    _pendingRoute = null;
    _pendingData = null;
    _navigate(route, data);
  }

  void handleNotificationPayload(Map<String, dynamic> data) {
    _handleTapData(data);
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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
    final payload = <String, dynamic>{...message.data};
    final isRecruitmentChat = _isRecruitmentChatPayload(payload);
    final route = resolveRoute(payload);
    if (route != null) {
      payload['target_route'] = route;
    }

    _foregroundNotificationController.add(Map<String, dynamic>.from(payload));
    await _safeNotifyNotificationReceived();

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        (isRecruitmentChat ? '새 채팅 메시지' : null);
    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        (isRecruitmentChat ? '구인채용 채팅에 새 메시지가 도착했습니다.' : null);
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
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
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payload),
    );
  }

  void _onOpenedMessage(RemoteMessage message) {
    _handleTapData(message.data);
  }

  bool _isRecruitmentChatPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase();
    final entityType = data['entity_type']?.toString().toLowerCase();
    final targetRoute = data['target_route']?.toString().toLowerCase();
    final chatId = data['chat_id']?.toString();
    return type == 'recruitment_chat' ||
        type == 'chat' ||
        type == 'chat_message' ||
        entityType == 'recruitment_chat' ||
        entityType == 'chat' ||
        (chatId != null && chatId.isNotEmpty) ||
        (targetRoute != null &&
            (targetRoute.contains('chat') || targetRoute.contains('tab=3')));
  }

  void _handleTapData(Map<String, dynamic> data) {
    final route = resolveRoute(data);
    if (route == null) return;
    _navigate(route, data);
  }

  void _navigate(String route, Map<String, dynamic> data) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      _pendingRoute = route;
      _pendingData = data;
      return;
    }

    try {
      GoRouter.of(context).go(route);

      // 상세 화면 진입은 라우팅 직후 (다음 프레임) 시도
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryPushDetailScreen(context, data);
      });
    } catch (_) {
      _pendingRoute = route;
      _pendingData = data;
    }
  }

  void _tryPushDetailScreen(BuildContext context, Map<String, dynamic> data) {
    final entityType = (data['entity_type'] ?? data['type'])
        ?.toString()
        .toLowerCase();
    final entityIdStr = (data['entity_id'] ?? data['chat_id'])?.toString();
    final branchIdStr = data['branch_id']?.toString();

    if (entityType == null || entityType.isEmpty) return;
    if (entityIdStr == null || entityIdStr.isEmpty) return;

    final entityId = int.tryParse(entityIdStr);
    if (entityId == null) return;
    final branchId = branchIdStr != null ? int.tryParse(branchIdStr) : null;

    final targetRole = data['target_role']?.toString().toLowerCase() ?? '';
    final isManagerOrOwner = targetRole == 'manager' || targetRole == 'owner';
    final isJobSeeker = targetRole == 'job_seeker' || targetRole == 'worker';

    final chatId = _parseInt(data['chat_id']) ?? entityId;

    if (entityType == 'contract_chat') {
      if (isJobSeeker) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                WorkerContractChatDetailScreen(contractId: entityId),
          ),
        );
      }
    } else if (entityType == 'recruitment_chat' || entityType == 'chat') {
      if (chatId <= 0) return;
      if (isManagerOrOwner) {
        Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => ManagerRecruitmentInquiryChatScreen(
              chatId: chatId,
              branchId: _parseInt(data['branch_id']) ?? 0,
              employeeId: _parseInt(data['employee_id']) ?? 0,
              employeeName: data['employee_name']?.toString(),
              profileImageUrl: data['profile_image_url']?.toString(),
            ),
          ),
        );
        return;
      }
      if (isJobSeeker) {
        final title = data['counterparty_name']?.toString().trim();
        Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => WorkerRecruitmentChatScreen(
              chatId: chatId,
              title: title == null || title.isEmpty ? '채팅' : title,
              profileImageUrl: data['profile_image_url']?.toString(),
            ),
          ),
        );
        return;
      }
    } else if (entityType == 'recruitment_application') {
      if (isManagerOrOwner) {
        if (branchId == null) return; // branch_id 필수
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RecruitmentApplicationDetailScreen(
              branchId: branchId,
              applicationId: entityId,
            ),
          ),
        );
      }
    } else if (entityType == 'inquiry') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountInquiryDetailScreen(inquiryId: entityId),
        ),
      );
    }
  }

  Future<void> _safeUpsertToken(String token) async {
    try {
      await _onTokenReceived?.call(token);
    } catch (_) {}
  }

  Future<void> _safeNotifyNotificationReceived() async {
    try {
      await _onNotificationReceived?.call();
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
      case 'recruitment_chat':
      case 'chat_message':
        final targetRole = rawData['target_role']?.toString().toLowerCase();
        if (targetRole == 'manager' || targetRole == 'owner') {
          return '/manager?tab=4&recruitmentTab=3';
        }
        return '/job-seeker?tab=3';
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
