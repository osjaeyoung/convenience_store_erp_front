import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/enums/user_role.dart';
import '../../features/auth/exceptions/auth_exception.dart';
import '../../core/models/user.dart';
import '../../core/storage/token_storage.dart';
import '../models/auth_user.dart';
import '../models/branch.dart';
import '../models/login_response.dart';
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

  User? _user;
  bool _isSignupInProgress = false;
  String? _rawRole;
  String? _signupStep;
  String? _approvalStatus;

  User? get user => _user;

  bool get isLoggedIn => _tokenStorage.getAccessToken() != null;

  UserRole? get role => _user?.role;

  bool get hasBottomBar => _user?.role.hasBottomBar ?? false;

  bool get isJobSeeker => _user?.role.isJobSeeker ?? false;
  bool get isSignupInProgress => _isSignupInProgress;
  String? get signupStep => _signupStep;
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
      data: {
        'role': 'manager',
        'requested_branch_id': requestedBranchId,
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
    return items.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 이메일 로그인
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
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

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
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

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
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

  /// 전화번호 인증 코드 발송 (Firebase) - 회원가입 시 사용
  /// [phoneNumber] 전화번호 (E.164 형식, 예: +821012345678)
  /// [codeSent] SMS 발송 시 콜백 (verificationId, resendToken)
  /// [verificationCompleted] 자동 검증 완료 시 (예: 같은 기기)
  /// [verificationFailed] 인증 실패 시
  /// [codeAutoRetrievalTimeout] 자동 재시도 타임아웃 시
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    void Function(PhoneAuthCredential credential)? verificationCompleted,
    void Function(FirebaseAuthException e)? verificationFailed,
    void Function(String verificationId)? codeAutoRetrievalTimeout,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted ?? (_) {},
      verificationFailed: verificationFailed ?? (_) {},
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout ?? (_) {},
    );
  }

  /// 내 정보 조회
  Future<AuthUser> getMe() async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>('/auth/me');
    final user = AuthUser.fromJson(res.data!);
    _syncAuthUser(user);
    notifyListeners();
    return user;
  }

  /// 로그인 성공 후 상태 저장
  Future<void> setAuthenticated(LoginResponse response) async {
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
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _isSignupInProgress = true;
    notifyListeners();
  }

  /// 로그아웃
  Future<void> logout() async {
    await _tokenStorage.clearAll();
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
}
