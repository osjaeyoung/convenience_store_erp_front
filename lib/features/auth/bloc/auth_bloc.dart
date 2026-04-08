import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/user.dart';
import '../../../data/models/branch.dart';
import '../exceptions/auth_exception.dart';
import '../../../data/models/signup_response.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupStep1Requested>(_onSignupStep1Requested);
    on<AuthSignupStep2OwnerRequested>(_onSignupStep2OwnerRequested);
    on<AuthSignupStep2ManagerRequested>(_onSignupStep2ManagerRequested);
    on<AuthSignupStep2ManagerPreRegisteredRequested>(
      _onSignupStep2ManagerPreRegisteredRequested,
    );
    on<AuthSignupStep2WorkerRequested>(_onSignupStep2WorkerRequested);
    on<AuthBranchesSearchRequested>(_onBranchesSearchRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthAppleLoginRequested>(_onAppleLoginRequested);
  }

  final AuthRepository _repository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!_repository.isLoggedIn) {
      emit(const AuthState.unauthenticated());
      return;
    }
    if (_repository.user != null) {
      emit(AuthState.authenticated(_repository.user!));
      return;
    }
    try {
      await _repository.getMe();
      emit(AuthState.authenticated(_repository.user!));
    } catch (_) {
      await _repository.logout();
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final response = await _repository.login(
        email: event.email,
        password: event.password,
      );
      await _repository.setAuthenticated(response);
      emit(AuthState.authenticated(_repository.user!));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      emit(AuthState.failure(msg));
    } catch (e) {
      emit(AuthState.failure('로그인에 실패했습니다.'));
    }
  }

  Future<void> _onSignupStep1Requested(
    AuthSignupStep1Requested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final response = await _repository.signup(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
        agreeTermsRequired: event.agreeTermsRequired,
        agreeAgeRequired: event.agreeAgeRequired,
        agreePrivacyRequired: event.agreePrivacyRequired,
        agreeMarketingOptional: event.agreeMarketingOptional,
      );
      await _repository.setSignupStep1Token(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        user: response.user,
      );
      emit(AuthState.signupStep1Completed(response));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } on DioException catch (e) {
      emit(AuthState.failure(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthState.failure('회원가입에 실패했습니다.'));
    }
  }

  Future<void> _onSignupStep2OwnerRequested(
    AuthSignupStep2OwnerRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _repository.signupCompleteOwner(branches: event.branches);
      emit(AuthState.authenticated(_repository.user!));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } on DioException catch (e) {
      emit(AuthState.failure(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthState.failure('회원가입 완료에 실패했습니다.'));
    }
  }

  Future<void> _onSignupStep2ManagerRequested(
    AuthSignupStep2ManagerRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _repository.signupCompleteManager(
        registrationIds: event.registrationIds,
        managerPhoneNumber: event.managerPhoneNumber,
      );
      emit(AuthState.authenticated(_repository.user!));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } on DioException catch (e) {
      emit(AuthState.failure(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthState.failure('회원가입 완료에 실패했습니다.'));
    }
  }

  Future<void> _onSignupStep2ManagerPreRegisteredRequested(
    AuthSignupStep2ManagerPreRegisteredRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _repository.signupCompleteManagerPreRegistered(
        managerRegistrationId: event.managerRegistrationId,
        managerPhoneNumber: event.managerPhoneNumber,
      );
      emit(AuthState.authenticated(_repository.user!));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } on DioException catch (e) {
      emit(AuthState.failure(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthState.failure('회원가입 완료에 실패했습니다.'));
    }
  }

  Future<void> _onSignupStep2WorkerRequested(
    AuthSignupStep2WorkerRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _repository.signupCompleteWorker();
      emit(AuthState.authenticated(_repository.user!));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } on DioException catch (e) {
      emit(AuthState.failure(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthState.failure('회원가입 완료에 실패했습니다.'));
    }
  }

  Future<void> _onBranchesSearchRequested(
    AuthBranchesSearchRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final branches = await _repository.searchBranches(event.query);
      emit(AuthState.branchesLoaded(branches));
    } catch (_) {
      emit(AuthState.branchesLoaded([]));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final response = await _repository.loginWithGoogle();
      await _repository.setAuthenticated(response);
      emit(AuthState.authenticated(_repository.user!));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } on DioException catch (e) {
      emit(AuthState.failure(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthState.failure('구글 로그인에 실패했습니다.'));
    }
  }

  Future<void> _onAppleLoginRequested(
    AuthAppleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final response = await _repository.loginWithApple();
      await _repository.setAuthenticated(response);
      emit(AuthState.authenticated(_repository.user!));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } on DioException catch (e) {
      emit(AuthState.failure(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthState.failure('애플 로그인에 실패했습니다.'));
    }
  }

  String _extractErrorMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String rawMessage;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) {
          final loc = (first['loc'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .join('.');
          if (loc.contains('email')) return '이메일 정보를 다시 확인해주세요.';
          if (loc.contains('phone_number')) return '휴대폰 번호를 다시 확인해주세요.';
          if (loc.contains('password')) return '비밀번호를 다시 확인해주세요.';
        }
      }
      rawMessage =
          (data['message'] ?? data['detail'] ?? data['error'])?.toString() ??
          '요청에 실패했습니다.';
    } else {
      rawMessage = e.message ?? '요청에 실패했습니다.';
    }

    final normalized = rawMessage.toLowerCase();
    if (normalized.contains('email already registered')) {
      return '이미 가입된 이메일입니다.';
    }
    if (normalized.contains('invalid') &&
        (normalized.contains('credential') ||
            normalized.contains('password') ||
            normalized.contains('login'))) {
      return '이메일 또는 비밀번호를 다시 확인해주세요.';
    }
    if (normalized.contains('manager') &&
        (normalized.contains('registration') ||
            normalized.contains('pre-registered') ||
            normalized.contains('not registered'))) {
      return '사업주가 사전 등록한 점장 정보와 일치하지 않습니다.';
    }
    if (normalized.contains('phone')) {
      return '휴대폰 번호를 다시 확인해주세요.';
    }
    if (RegExp(r'[가-힣]').hasMatch(rawMessage)) {
      return rawMessage;
    }

    switch (statusCode) {
      case 400:
        return '입력한 정보를 다시 확인해주세요.';
      case 401:
        return '인증 정보가 올바르지 않습니다.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 정보를 찾을 수 없습니다.';
      case 409:
        return '이미 등록된 정보입니다.';
      case 422:
        return '입력 형식을 다시 확인해주세요.';
      default:
        return '요청 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }
}
