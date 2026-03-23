part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  signupStep1Completed,
  authenticated,
  branchesLoaded,
  failure,
}

class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user,
    this.signupResponse,
    this.branches = const [],
    this.errorMessage,
  });

  const AuthState.initial()
      : this._(status: AuthStatus.initial);

  const AuthState.loading()
      : this._(status: AuthStatus.loading);

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  const AuthState.failure(String message)
      : this._(status: AuthStatus.failure, errorMessage: message);

  AuthState.signupStep1Completed(SignupResponse response)
      : this._(
          status: AuthStatus.signupStep1Completed,
          signupResponse: response,
        );

  AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  AuthState.branchesLoaded(List<Branch> branches)
      : this._(status: AuthStatus.branchesLoaded, branches: branches);

  final AuthStatus status;
  final User? user;
  final SignupResponse? signupResponse;
  final List<Branch> branches;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isSignupStep1Completed =>
      status == AuthStatus.signupStep1Completed && signupResponse != null;

  @override
  List<Object?> get props => [status, user, signupResponse, branches, errorMessage];
}
