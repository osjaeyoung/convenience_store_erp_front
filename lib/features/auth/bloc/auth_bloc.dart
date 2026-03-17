import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/user.dart';
import '../../../data/models/branch.dart';
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
      await _repository.signupCompleteOwner(
        branches: event.branches,
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

  Future<void> _onSignupStep2ManagerRequested(
    AuthSignupStep2ManagerRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _repository.signupCompleteManager(
        requestedBranchId: event.requestedBranchId,
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

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['detail'] ?? data['error'])?.toString() ??
          '요청에 실패했습니다.';
    }
    return e.message ?? '요청에 실패했습니다.';
  }
}
