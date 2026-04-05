import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/enums/user_role.dart';
import '../../features/auth/exceptions/auth_exception.dart';
import '../../core/models/user.dart';
import '../../core/storage/token_storage.dart';
import '../models/account_profile.dart';
import '../models/account_support_models.dart';
import '../models/auth_user.dart';
import '../models/branch.dart';
import '../models/login_response.dart';
import '../models/signup_response.dart';
import '../network/api_client.dart';

class SignupDraft {
  const SignupDraft({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.agreeTerms,
    required this.agreeAge,
    required this.agreePrivacy,
    required this.agreeThirdParty,
    required this.agreeMarketing,
    required this.currentStep,
    required this.phoneVerified,
  });

  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final bool agreeTerms;
  final bool agreeAge;
  final bool agreePrivacy;
  final bool agreeThirdParty;
  final bool agreeMarketing;
  final String currentStep;
  final bool phoneVerified;

  SignupDraft copyWith({
    String? email,
    String? password,
    String? fullName,
    String? phoneNumber,
    bool? agreeTerms,
    bool? agreeAge,
    bool? agreePrivacy,
    bool? agreeThirdParty,
    bool? agreeMarketing,
    String? currentStep,
    bool? phoneVerified,
  }) {
    return SignupDraft(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      agreeTerms: agreeTerms ?? this.agreeTerms,
      agreeAge: agreeAge ?? this.agreeAge,
      agreePrivacy: agreePrivacy ?? this.agreePrivacy,
      agreeThirdParty: agreeThirdParty ?? this.agreeThirdParty,
      agreeMarketing: agreeMarketing ?? this.agreeMarketing,
      currentStep: currentStep ?? this.currentStep,
      phoneVerified: phoneVerified ?? this.phoneVerified,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'agreeTerms': agreeTerms,
    'agreeAge': agreeAge,
    'agreePrivacy': agreePrivacy,
    'agreeThirdParty': agreeThirdParty,
    'agreeMarketing': agreeMarketing,
    'currentStep': currentStep,
    'phoneVerified': phoneVerified,
  };

  factory SignupDraft.fromJson(Map<String, dynamic> json) {
    return SignupDraft(
      email: (json['email'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      agreeTerms: json['agreeTerms'] == true,
      agreeAge: json['agreeAge'] == true,
      agreePrivacy: json['agreePrivacy'] == true,
      agreeThirdParty: json['agreeThirdParty'] == true,
      agreeMarketing: json['agreeMarketing'] == true,
      currentStep: (json['currentStep'] ?? 'terms').toString(),
      phoneVerified: json['phoneVerified'] == true,
    );
  }
}

class PhoneVerificationSession {
  const PhoneVerificationSession({
    required this.verificationId,
    required this.phoneE164,
    required this.expiresAtMillis,
    this.forceResendingToken,
  });

  final String verificationId;
  final String phoneE164;
  final int expiresAtMillis;
  final int? forceResendingToken;

  Map<String, dynamic> toJson() => {
    'verificationId': verificationId,
    'phoneE164': phoneE164,
    'expiresAtMillis': expiresAtMillis,
    'forceResendingToken': forceResendingToken,
  };

  factory PhoneVerificationSession.fromJson(Map<String, dynamic> json) {
    return PhoneVerificationSession(
      verificationId: (json['verificationId'] ?? '').toString(),
      phoneE164: (json['phoneE164'] ?? '').toString(),
      expiresAtMillis: (json['expiresAtMillis'] as num?)?.toInt() ?? 0,
      forceResendingToken: (json['forceResendingToken'] as num?)?.toInt(),
    );
  }
}

/// Firebase 세션의 E.164(+8210…)를 입력란 표시용 `010-…` 형태로 바꿉니다.
String _krMobileDisplayFromE164(String e164) {
  var digits = e164.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('82') && digits.length >= 10) {
    digits = '0${digits.substring(2)}';
  }
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  return e164.trim();
}

/// 인증 관련 API 및 토큰 관리
/// go_router refreshListenable로 사용
class AuthRepository extends ChangeNotifier {
  AuthRepository(this._apiClient, this._tokenStorage) {
    _user = _cachedUser;
    _signupDraft = _loadSignupDraft();
    _phoneVerificationSession = _loadPhoneVerificationSession();
  }

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  static const _signupDraftKey = 'signup_draft';
  static const _phoneVerificationSessionKey = 'phone_verification_session';

  User? _user;
  bool _isSignupInProgress = false;
  String? _rawRole;
  String? _signupStep;
  String? _approvalStatus;
  SignupDraft? _signupDraft;
  PhoneVerificationSession? _phoneVerificationSession;

  User? get user => _user;

  bool get isLoggedIn => _tokenStorage.getAccessToken() != null;

  UserRole? get role => _user?.role;

  bool get hasBottomBar => _user?.role.hasBottomBar ?? false;

  bool get isJobSeeker => _user?.role.isJobSeeker ?? false;
  bool get isSignupInProgress => _isSignupInProgress;
  String? get signupStep => _signupStep;
  SignupDraft? get signupDraft => _signupDraft;
  PhoneVerificationSession? get phoneVerificationSession =>
      _phoneVerificationSession;
  bool get hasPendingPhoneVerification =>
      _signupDraft != null && _phoneVerificationSession != null;
  bool get shouldShowPhoneVerification {
    final currentStep = (_signupDraft?.currentStep ?? '').trim();
    return currentStep == 'phone_verification' || hasPendingPhoneVerification;
  }

  bool get shouldStartAtRoleSelection =>
      (_signupStep ?? '').trim() == 'step1_completed';
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

  /// 회원가입 2차 - 점장 (지점 선택)
  Future<AuthUser> signupCompleteManager({
    required int requestedBranchId,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/signup/complete',
      data: {'role': 'manager', 'requested_branch_id': requestedBranchId},
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

    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login/google',
      data: {
        'firebase_uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'full_name': firebaseUser.displayName ?? firebaseUser.email ?? '',
      },
    );
    return LoginResponse.fromJson(res.data!);
  }

  /// 애플 로그인 (Firebase Auth)
  Future<LoginResponse> loginWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
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

    final fullName = appleCredential.givenName != null
        ? '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim()
        : firebaseUser.displayName ?? firebaseUser.email ?? '';

    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login/apple',
      data: {
        'firebase_uid': firebaseUser.uid,
        'email': firebaseUser.email ?? appleCredential.email ?? '',
        'full_name': fullName,
      },
    );
    return LoginResponse.fromJson(res.data!);
  }

  /// 전화번호 인증 코드 발송 (Firebase SMS) - 회원가입 시 사용
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

  Future<void> saveSignupDraft(SignupDraft draft) async {
    _signupDraft = draft;
    await _tokenStorage.saveString(_signupDraftKey, jsonEncode(draft.toJson()));
    notifyListeners();
  }

  Future<void> savePhoneVerificationSession(
    PhoneVerificationSession session,
  ) async {
    _phoneVerificationSession = session;
    await _tokenStorage.saveString(
      _phoneVerificationSessionKey,
      jsonEncode(session.toJson()),
    );
    notifyListeners();
  }

  Future<void> completePhoneVerification({String? verifiedPhoneNumber}) async {
    if (_signupDraft != null) {
      final session = _phoneVerificationSession;
      var phone = (verifiedPhoneNumber ?? '').trim();
      if (phone.isEmpty) {
        phone = _signupDraft!.phoneNumber.trim();
      }
      if (phone.isEmpty &&
          session != null &&
          session.phoneE164.trim().isNotEmpty) {
        phone = _krMobileDisplayFromE164(session.phoneE164);
      }
      _signupDraft = _signupDraft!.copyWith(
        phoneVerified: true,
        currentStep: 'basicInfo',
        phoneNumber: phone.isNotEmpty ? phone : _signupDraft!.phoneNumber,
      );
      await _tokenStorage.saveString(
        _signupDraftKey,
        jsonEncode(_signupDraft!.toJson()),
      );
    }
    await clearPhoneVerificationSession(notify: false);
    notifyListeners();
  }

  Future<void> clearPhoneVerificationSession({bool notify = true}) async {
    _phoneVerificationSession = null;
    await _tokenStorage.remove(_phoneVerificationSessionKey);
    if (notify) notifyListeners();
  }

  Future<void> clearSignupDraft({bool notify = true}) async {
    _signupDraft = null;
    await _tokenStorage.remove(_signupDraftKey);
    await clearPhoneVerificationSession(notify: false);
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

  Future<PhoneNumberExistsResult> checkPhoneNumberExists({
    required String phoneNumber,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/auth/phone-number-exists',
      queryParameters: {'phone_number': phoneNumber.trim()},
    );
    return PhoneNumberExistsResult.fromJson(res.data!);
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
      data: {
        'phone_number': phoneNumber.trim(),
        'new_password': newPassword,
      },
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

  Future<AccountNotice> getNoticeDetail({
    required int noticeId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/me/notices/$noticeId',
    );
    return AccountNotice.fromJson(res.data!);
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

  Future<AccountInquiry> getInquiryDetail({
    required int inquiryId,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/me/inquiries/$inquiryId',
    );
    return AccountInquiry.fromJson(res.data!);
  }

  Future<void> checkInquiryAnswer({
    required int inquiryId,
  }) async {
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
    notifyListeners();
  }

  /// 회원가입 1차 후 토큰만 저장 (2차 완료 전)
  Future<void> setSignupStep1Token({
    required String accessToken,
    required String refreshToken,
  }) async {
    await clearSignupDraft(notify: false);
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _isSignupInProgress = true;
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
    _isSignupInProgress = false;
    _rawRole = null;
    _signupStep = null;
    _approvalStatus = null;
    notifyListeners();
  }

  /// 토큰 만료(401) 등으로 강제 로그아웃 처리
  Future<void> handleUnauthorized() async {
    await _tokenStorage.clearAll();
    await clearSignupDraft(notify: false);
    _user = null;
    _isSignupInProgress = false;
    _rawRole = null;
    _signupStep = null;
    _approvalStatus = null;
    notifyListeners();
  }

  User _authUserToUser(AuthUser auth) {
    return User(
      id: auth.id.toString(),
      email: auth.email,
      role: auth.appRole ?? UserRole.jobSeeker,
      name: auth.fullName,
    );
  }

  void _syncAuthUser(AuthUser auth) {
    _user = _authUserToUser(auth);
    _rawRole = auth.role;
    _signupStep = auth.signupStep;
    _approvalStatus = auth.approvalStatus;
    _isSignupInProgress = needsSignupCompletion;
  }

  SignupDraft? _loadSignupDraft() {
    final raw = _tokenStorage.getString(_signupDraftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SignupDraft.fromJson(decoded);
      }
      if (decoded is Map) {
        return SignupDraft.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  PhoneVerificationSession? _loadPhoneVerificationSession() {
    final raw = _tokenStorage.getString(_phoneVerificationSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return PhoneVerificationSession.fromJson(decoded);
      }
      if (decoded is Map) {
        return PhoneVerificationSession.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }
}
