import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/enums/user_role.dart';
import '../../features/auth/exceptions/auth_exception.dart';
import '../../core/models/user.dart';
import '../../core/storage/token_storage.dart';
import '../models/account_profile.dart';
import '../models/account_notification_models.dart';
import '../models/account_support_models.dart';
import '../models/auth_user.dart';
import '../models/branch.dart';
import '../models/login_response.dart';
import '../models/manager_registration_lookup_item.dart';
import '../models/signup_response.dart';
import '../network/api_client.dart';

/// 인증 관련 API 및 토큰 관리
/// go_router refreshListenable로 사용
class AuthRepository extends ChangeNotifier {
  AuthRepository(this._apiClient, this._tokenStorage) {
    _user = _cachedUser;
  }

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  static const _signupDraftKey = 'signup_draft';
  static const _phoneVerificationSessionKey = 'phone_verification_session';

  User? _user;
  AuthUser? _authUser;
  bool _isSignupInProgress = false;
  String? _rawRole;
  String? _signupStep;
  String? _approvalStatus;
  int _notificationUnreadCount = 0;
  bool _notificationUnreadCountLoaded = false;

  User? get user => _user;

  bool get isLoggedIn => _tokenStorage.getAccessToken() != null;

  UserRole? get role => _user?.role;

  bool get hasBottomBar => _user?.role.hasBottomBar ?? false;

  bool get isJobSeeker => _user?.role.isJobSeeker ?? false;
  bool get isSignupInProgress => _isSignupInProgress;
  bool get hasSignupDraft => signupDraft != null;
  int get notificationUnreadCount => _notificationUnreadCount;
  bool get hasUnreadNotifications => _notificationUnreadCount > 0;
  bool get hasLoadedNotificationUnreadCount => _notificationUnreadCountLoaded;
  String? get signupStep => _signupStep;
  Map<String, dynamic>? get signupDraft => _readJson(_signupDraftKey);
  Map<String, dynamic>? get phoneVerificationSession =>
      _readJson(_phoneVerificationSessionKey);
  String? get currentEmail {
    final value = _authUser?.email?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get currentFullName {
    final value = _authUser?.fullName?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get currentPhoneNumber {
    final value = _authUser?.phoneNumber?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool get needsSignupCompletion {
    final roleMissing = _rawRole == null || _rawRole!.trim().isEmpty;
    final step1Completed = (_signupStep ?? '').trim() == 'step1_completed';
    final pendingRoleSelection =
        (_approvalStatus ?? '').trim() == 'pending_role_selection';
    return roleMissing || step1Completed || pendingRoleSelection;
  }

  User? get _cachedUser => null; // 앱 재시작 시 /auth/me로 복원

  /// 회원가입 1차
  Future<SignupResponse> signup({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required bool agreeTermsRequired,
    required bool agreeAgeRequired,
    required bool agreePrivacyRequired,
    bool agreeMarketingOptional = false,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'agree_terms_required': agreeTermsRequired,
        'agree_age_required': agreeAgeRequired,
        'agree_privacy_required': agreePrivacyRequired,
        'agree_marketing_optional': agreeMarketingOptional,
      },
    );
    return SignupResponse.fromJson(res.data!);
  }

  /// 소셜 로그인 후 추가 정보 입력
  Future<LoginResponse> signupSocialProfile({
    String? fullName,
    String? phoneNumber,
    required bool agreeTermsRequired,
    required bool agreeAgeRequired,
    required bool agreePrivacyRequired,
    bool agreeMarketingOptional = false,
  }) async {
    final body = <String, dynamic>{
      'agree_terms_required': agreeTermsRequired,
      'agree_age_required': agreeAgeRequired,
      'agree_privacy_required': agreePrivacyRequired,
      'agree_marketing_optional': agreeMarketingOptional,
    };
    final normalizedFullName = fullName?.trim();
    final normalizedPhoneNumber = phoneNumber?.trim();
    if (normalizedFullName != null && normalizedFullName.isNotEmpty) {
      body['full_name'] = normalizedFullName;
    }
    if (normalizedPhoneNumber != null && normalizedPhoneNumber.isNotEmpty) {
      body['phone_number'] = normalizedPhoneNumber;
    }

    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/signup/social/profile',
      data: body,
    );
    final response = LoginResponse.fromJson(res.data!);
    await setAuthenticated(response);
    return response;
  }

  /// 회원가입 2차 - 경영주
  /// 토큰은 1차 완료 시 이미 저장됨
  Future<AuthUser> signupCompleteOwner({
    required List<Map<String, String?>> branches,
  }) async {
    final normalizedBranches = branches
        .map((branch) {
          final name = (branch['branch_name'] ?? '').trim();
          final business = (branch['business_number'] ?? '').trim();
          if (name.isEmpty) return null;
          return <String, dynamic>{
            'branch_name': name,
            if (business.isNotEmpty) 'business_number': business,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (normalizedBranches.isEmpty) {
      throw Exception('점포 정보를 입력해주세요.');
    }

    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/signup/complete',
      data: {
        'role': 'owner',
        // legacy 단건 필드(하위 호환)
        'branch_name': normalizedBranches.first['branch_name'],
        // 최신 멀티 지점 필드
        'branches': normalizedBranches,
      },
    );
    final userData = res.data!['user'] ?? res.data;
    final user = AuthUser.fromJson(userData as Map<String, dynamic>);
    _syncAuthUser(user);
    notifyListeners();
    return user;
  }

  /// 회원가입 2차 - 점장 (선택한 사전등록 지점들 인증)
  Future<AuthUser> signupCompleteManager({
    required List<int> registrationIds,
    required String managerPhoneNumber,
  }) async {
    final normalizedIds = registrationIds.toSet().toList();
    if (normalizedIds.isEmpty) {
      throw Exception('점장으로 등록할 지점을 선택해주세요.');
    }

    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/signup/complete',
      data: {
        'role': 'manager',
        'registrations': [
          for (final id in normalizedIds)
            {
              'manager_registration_id': id,
              'manager_phone_number': managerPhoneNumber.trim(),
            },
        ],
      },
    );
    final userData = res.data!['user'] ?? res.data;
    final user = AuthUser.fromJson(userData as Map<String, dynamic>);
    _syncAuthUser(user);
    notifyListeners();
    return user;
  }

  /// 회원가입 2차 - 점장 (사전등록 + 전화번호)
  Future<AuthUser> signupCompleteManagerPreRegistered({
    required int managerRegistrationId,
    required String managerPhoneNumber,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/signup/complete',
      data: {
        'role': 'manager',
        'manager_registration_id': managerRegistrationId,
        'manager_phone_number': managerPhoneNumber,
      },
    );
    final userData = res.data!['user'] ?? res.data;
    final user = AuthUser.fromJson(userData as Map<String, dynamic>);
    _syncAuthUser(user);
    notifyListeners();
    return user;
  }

  /// 회원가입 2차 - 근무자
  Future<AuthUser> signupCompleteWorker() async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/signup/complete',
      data: {'role': 'worker'},
    );
    final userData = res.data!['user'] ?? res.data;
    final user = AuthUser.fromJson(userData as Map<String, dynamic>);
    _syncAuthUser(user);
    notifyListeners();
    return user;
  }

  /// 지점 검색
  Future<List<Branch>> searchBranches(String query) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/auth/signup/branches/search',
      queryParameters: {'q': query},
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => Branch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ManagerRegistrationLookupItem>> lookupManagerRegistrations({
    required String managerName,
    required String managerPhoneNumber,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/signup/manager-registrations/lookup',
      data: {
        'manager_name': managerName.trim(),
        'manager_phone_number': managerPhoneNumber.trim(),
      },
    );
    final items = res.data!['items'] as List<dynamic>? ?? [];
    return items
        .map(
          (e) =>
              ManagerRegistrationLookupItem.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// 이메일 로그인
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return LoginResponse.fromJson(res.data!);
  }

  /// 구글 로그인 (Firebase Auth)
  Future<LoginResponse> loginWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw AuthException('구글 로그인이 취소되었습니다.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) throw AuthException('구글 로그인에 실패했습니다.');

    final display = firebaseUser.displayName?.trim();
    // 서버 스키마상 `email` 필수 — UI에서 받지 않고 구글/Firebase가 준 주소만 전달
    final email = (firebaseUser.email ?? googleUser.email).trim();
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login/google',
      data: {
        'firebase_uid': firebaseUser.uid,
        'email': email,
        'full_name': (display != null && display.isNotEmpty) ? display : '',
      },
    );
    return LoginResponse.fromJson(res.data!);
  }

  /// 애플 로그인 (Firebase Auth)
  Future<LoginResponse> loginWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      oauthCredential,
    );
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) throw AuthException('애플 로그인에 실패했습니다.');

    final gn = appleCredential.givenName?.trim() ?? '';
    final fn = appleCredential.familyName?.trim() ?? '';
    final fromApple = '$gn $fn'.trim();
    final display = firebaseUser.displayName?.trim();
    final fullName = fromApple.isNotEmpty
        ? fromApple
        : ((display != null && display.isNotEmpty) ? display : '');

    // 서버 스키마상 `email` 필수 — 입력 필드 없이 Firebase·애플이 준 값만 전달
    final email = (firebaseUser.email ?? appleCredential.email ?? '').trim();

    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login/apple',
      data: {
        'firebase_uid': firebaseUser.uid,
        'email': email,
        'full_name': fullName,
      },
    );
    return LoginResponse.fromJson(res.data!);
  }

  /// 전화번호 인증 코드 발송 (Firebase SMS) — 비밀번호 찾기·계정 전화 인증 등
  /// [phoneNumber] E.164 (예: +821012345678)
  /// [forceResendingToken] [codeSent]에서 받은 값으로 재전송 시 전달
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneCodeSent codeSent,
    PhoneVerificationCompleted? verificationCompleted,
    PhoneVerificationFailed? verificationFailed,
    PhoneCodeAutoRetrievalTimeout? codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 120),
    int? forceResendingToken,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS: Firebase Auth가 APNs 토큰 수신 전에 verifyPhoneNumber를 호출하면
      // reCAPTCHA 도중 APNs 토큰이 도착하여 콜백이 무시되는 등 예측할 수 없는 동작이 발생할 수 있음.
      // 따라서 APNs 토큰이 정상적으로 발급될 때까지 최대 5초 대기.
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null && apns.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
      verificationCompleted: verificationCompleted ?? (_) {},
      verificationFailed: verificationFailed ?? (_) {},
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout ?? (_) {},
    );
  }

  /// 예전 회원가입 중간 저장(로컬) 키 제거. 더 이상 회원가입 진행 상태를 로컬에 두지 않음.
  Future<void> clearSignupDraft({bool notify = true}) async {
    await _tokenStorage.remove(_signupDraftKey);
    await _tokenStorage.remove(_phoneVerificationSessionKey);
    if (notify) notifyListeners();
  }

  Future<void> saveSignupDraft(
    Map<String, dynamic> draft, {
    bool notify = false,
  }) async {
    await _tokenStorage.saveString(_signupDraftKey, jsonEncode(draft));
    if (notify) notifyListeners();
  }

  Future<void> savePhoneVerificationSession(
    Map<String, dynamic> session, {
    bool notify = false,
  }) async {
    await _tokenStorage.saveString(
      _phoneVerificationSessionKey,
      jsonEncode(session),
    );
    if (notify) notifyListeners();
  }

  Future<void> clearPhoneVerificationSession({bool notify = false}) async {
    await _tokenStorage.remove(_phoneVerificationSessionKey);
    if (notify) notifyListeners();
  }

  /// 내 정보 조회
  Future<AuthUser> getMe() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>('/auth/me');
    final user = AuthUser.fromJson(res.data!);
    _syncAuthUser(user);
    notifyListeners();
    return user;
  }

  /// 계정·설정 UI용 (`GET /me/account`)
  Future<AccountProfile> getAccountProfile() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>('/me/account');
    return AccountProfile.fromJson(res.data!);
  }

  Future<AccountNotificationPage> getNotifications({
    bool onlyUnread = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/push/notifications',
      queryParameters: {
        'only_unread': onlyUnread,
        'page': page,
        'page_size': pageSize,
      },
    );
    final notificationPage = AccountNotificationPage.fromJson(res.data!);
    _setNotificationUnreadCount(notificationPage.unreadCount);
    return notificationPage;
  }

  Future<int> refreshNotificationUnreadCount() async {
    final notificationPage = await getNotifications(
      onlyUnread: true,
      pageSize: 20,
    );
    return notificationPage.unreadCount;
  }

  Future<AccountNotificationReadResult> setNotificationRead({
    required int notificationId,
    required bool isRead,
    required bool wasRead,
  }) async {
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/push/notifications/$notificationId/read',
      data: {'is_read': isRead},
    );
    final result = AccountNotificationReadResult.fromJson(res.data!);
    if (_notificationUnreadCountLoaded && wasRead != isRead) {
      _setNotificationUnreadCount(_notificationUnreadCount + (isRead ? -1 : 1));
    }
    return result;
  }

  Future<void> deleteNotification({
    required int notificationId,
    required bool wasUnread,
  }) async {
    await _apiClient.dio.delete<Map<String, dynamic>>(
      '/push/notifications/$notificationId',
    );
    if (_notificationUnreadCountLoaded && wasUnread) {
      _setNotificationUnreadCount(_notificationUnreadCount - 1);
    }
  }

  Future<PhoneNumberExistsResult> checkPhoneNumberExists({
    required String phoneNumber,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/auth/phone-number-exists',
      queryParameters: {'phone_number': phoneNumber.trim()},
    );
    return PhoneNumberExistsResult.fromJson(res.data!);
  }

  /// 회원가입 전 이메일 가입 여부 (인증 불필요). 서버는 trim 후 소문자로 정규화해 비교.
  Future<EmailExistsResult> checkEmailExists({required String email}) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/auth/email-exists',
      queryParameters: {'email': email.trim()},
    );
    return EmailExistsResult.fromJson(res.data!);
  }

  /// 이름·전화번호 부분 갱신 (`PATCH /me/account`)
  Future<AccountProfile> patchAccount({
    String? email,
    String? fullName,
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? gender,
    String? phoneNumber,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    final normalizedEmail = email?.trim();
    final normalizedFullName = fullName?.trim();
    final normalizedGender = gender?.trim();
    final normalizedPhoneNumber = phoneNumber?.trim();
    final normalizedAddress = address?.trim();
    if (normalizedEmail != null) body['email'] = normalizedEmail;
    if (normalizedFullName != null) body['full_name'] = normalizedFullName;
    if (birthYear != null) body['birth_year'] = birthYear;
    if (birthMonth != null) body['birth_month'] = birthMonth;
    if (birthDay != null) body['birth_day'] = birthDay;
    if (normalizedGender != null && normalizedGender.isNotEmpty) {
      body['gender'] = normalizedGender;
    }
    if (normalizedPhoneNumber != null) {
      body['phone_number'] = normalizedPhoneNumber;
    }
    if (normalizedAddress != null) body['address'] = normalizedAddress;
    final res = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/me/account',
      data: body,
    );
    final profile = AccountProfile.fromJson(res.data!);
    await getMe();
    return profile;
  }

  /// 로그인 상태 비밀번호 변경 (`POST /me/account/password`)
  Future<void> changeAccountPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      '/me/account/password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }

  Future<PasswordResetByPhoneResult> resetPasswordByPhone({
    required String phoneNumber,
    required String newPassword,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/password/reset/by-phone',
      data: {'phone_number': phoneNumber.trim(), 'new_password': newPassword},
    );
    return PasswordResetByPhoneResult.fromJson(res.data!);
  }

  /// 회원 탈퇴 (`POST /me/account/withdraw`)
  Future<void> withdrawAccount() async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      '/me/account/withdraw',
      data: {'confirm': true},
    );
  }

  Future<AccountNoticePage> getNotices({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/me/notices',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return AccountNoticePage.fromJson(res.data!);
  }

  Future<AccountNotice> getNoticeDetail({required int noticeId}) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/me/notices/$noticeId',
    );
    return AccountNotice.fromJson(res.data!);
  }

  Future<AccountSupportCenterData> getSupportCenter() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/me/support-center',
    );
    return AccountSupportCenterData.fromJson(res.data!);
  }

  Future<AccountPolicyList> getPolicies() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>('/policies');
    return AccountPolicyList.fromJson(res.data!);
  }

  Future<AccountPolicyDetail> getPolicyDetail({
    required String policyType,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/policies/${policyType.trim()}',
    );
    return AccountPolicyDetail.fromJson(res.data!);
  }

  Future<AccountInquiryPage> getInquiries({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/me/inquiries',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return AccountInquiryPage.fromJson(res.data!);
  }

  Future<AccountInquiry> createInquiry({
    required String inquiryType,
    required String title,
    required String content,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/me/inquiries',
      data: {
        'inquiry_type': inquiryType.trim(),
        'title': title.trim(),
        'content': content.trim(),
      },
    );
    return AccountInquiry.fromJson(res.data!);
  }

  Future<AccountInquiry> getInquiryDetail({required int inquiryId}) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/me/inquiries/$inquiryId',
    );
    return AccountInquiry.fromJson(res.data!);
  }

  Future<void> checkInquiryAnswer({required int inquiryId}) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      '/me/inquiries/$inquiryId/answer-check',
    );
  }

  /// 로그인 성공 후 상태 저장
  Future<void> setAuthenticated(LoginResponse response) async {
    await clearSignupDraft(notify: false);
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    _syncAuthUser(response.user);
    _clearNotificationUnreadCount(notify: false);
    notifyListeners();
  }

  /// 회원가입 1차 후 토큰 저장 및 사용자 상태 반영 (2차 완료 전)
  Future<void> setSignupStep1Token({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    await clearSignupDraft(notify: false);
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _syncAuthUser(user);
    _clearNotificationUnreadCount(notify: false);
    notifyListeners();
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await _apiClient.dio.post<Map<String, dynamic>>('/auth/logout');
    } catch (_) {
      // 서버에 엔드포인트가 없거나 실패해도 로컬 로그아웃은 진행
    }
    await _tokenStorage.clearAll();
    await clearSignupDraft(notify: false);
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    _user = null;
    _authUser = null;
    _isSignupInProgress = false;
    _rawRole = null;
    _signupStep = null;
    _approvalStatus = null;
    _clearNotificationUnreadCount(notify: false);
    notifyListeners();
  }

  /// 토큰 만료(401) 등으로 강제 로그아웃 처리
  Future<void> handleUnauthorized() async {
    await _tokenStorage.clearAll();
    await clearSignupDraft(notify: false);
    _user = null;
    _authUser = null;
    _isSignupInProgress = false;
    _rawRole = null;
    _signupStep = null;
    _approvalStatus = null;
    _clearNotificationUnreadCount(notify: false);
    notifyListeners();
  }

  User _authUserToUser(AuthUser auth) {
    return User(
      id: auth.id.toString(),
      email: auth.email ?? '',
      role: auth.appRole ?? UserRole.jobSeeker,
      name: auth.fullName,
    );
  }

  void _syncAuthUser(AuthUser auth) {
    _authUser = auth;
    _user = _authUserToUser(auth);
    _rawRole = auth.role;
    _signupStep = auth.signupStep;
    _approvalStatus = auth.approvalStatus;
    _isSignupInProgress = needsSignupCompletion;
  }

  void _setNotificationUnreadCount(int value, {bool notify = true}) {
    final normalized = value < 0 ? 0 : value;
    final changed =
        _notificationUnreadCount != normalized ||
        !_notificationUnreadCountLoaded;
    _notificationUnreadCount = normalized;
    _notificationUnreadCountLoaded = true;
    if (notify && changed) {
      notifyListeners();
    }
  }

  void _clearNotificationUnreadCount({bool notify = true}) {
    final changed =
        _notificationUnreadCount != 0 || _notificationUnreadCountLoaded;
    _notificationUnreadCount = 0;
    _notificationUnreadCountLoaded = false;
    if (notify && changed) {
      notifyListeners();
    }
  }

  Map<String, dynamic>? _readJson(String key) {
    final raw = _tokenStorage.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
