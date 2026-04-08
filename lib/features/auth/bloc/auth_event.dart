part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignupStep1Requested extends AuthEvent {
  const AuthSignupStep1Requested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.agreeTermsRequired,
    required this.agreeAgeRequired,
    required this.agreePrivacyRequired,
    this.agreeMarketingOptional = false,
  });

  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final bool agreeTermsRequired;
  final bool agreeAgeRequired;
  final bool agreePrivacyRequired;
  final bool agreeMarketingOptional;

  @override
  List<Object?> get props => [
        email,
        password,
        fullName,
        phoneNumber,
        agreeTermsRequired,
        agreeAgeRequired,
        agreePrivacyRequired,
        agreeMarketingOptional,
      ];
}

class AuthSignupStep2OwnerRequested extends AuthEvent {
  const AuthSignupStep2OwnerRequested({
    required this.branches,
  });

  final List<Map<String, String?>> branches;

  @override
  List<Object?> get props => [branches];
}

class AuthSignupStep2ManagerRequested extends AuthEvent {
  const AuthSignupStep2ManagerRequested({
    required this.registrationIds,
    required this.managerPhoneNumber,
  });

  final List<int> registrationIds;
  final String managerPhoneNumber;

  @override
  List<Object?> get props => [registrationIds, managerPhoneNumber];
}

class AuthSignupStep2ManagerPreRegisteredRequested extends AuthEvent {
  const AuthSignupStep2ManagerPreRegisteredRequested({
    required this.managerRegistrationId,
    required this.managerPhoneNumber,
  });

  final int managerRegistrationId;
  final String managerPhoneNumber;

  @override
  List<Object?> get props => [managerRegistrationId, managerPhoneNumber];
}

class AuthSignupStep2WorkerRequested extends AuthEvent {
  const AuthSignupStep2WorkerRequested();
}

class AuthBranchesSearchRequested extends AuthEvent {
  const AuthBranchesSearchRequested({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

class AuthAppleLoginRequested extends AuthEvent {
  const AuthAppleLoginRequested();
}
