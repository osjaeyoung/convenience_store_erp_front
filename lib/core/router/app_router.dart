import 'package:go_router/go_router.dart';

import '../enums/user_role.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_phone_verification_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/signup_step2_screen.dart';
import '../../features/manager/screens/manager_main_screen.dart';
import '../../features/job_seeker/screens/job_seeker_main_screen.dart';

/// 앱 라우팅 설정
/// - 비로그인: 로그인 → 회원가입
/// - 경영자/점장: 바텀바 메인 (홈, 직원관리, 인건비, 매장·비용, 구인·채용)
/// - 구직자: 전혀 다른 메인 화면
class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String signup = '/signup';
  static const String signupPhoneVerification = '/signup/phone-verification';
  static const String signupComplete = '/signup/complete';
  static const String managerMain = '/manager';
  static const String jobSeekerMain = '/job-seeker';
}

GoRouter createAppRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: AppRouter.login,
    refreshListenable: authRepository,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == AppRouter.login;
      final isSigningUp = state.matchedLocation == AppRouter.signup;
      final isPhoneVerification =
          state.matchedLocation == AppRouter.signupPhoneVerification;
      final isSignupComplete =
          state.matchedLocation == AppRouter.signupComplete;
      final signupFlowRoute =
          isSigningUp || isPhoneVerification || isSignupComplete;

      if (authRepository.hasPendingPhoneVerification && !isPhoneVerification) {
        return AppRouter.signupPhoneVerification;
      }

      if (!authRepository.isLoggedIn &&
          !isLoggingIn &&
          !isSigningUp &&
          !isPhoneVerification &&
          !isSignupComplete) {
        return AppRouter.login;
      }

      // 회원가입 1차 토큰 발급 후에는 마지막 단계 완료 전까지
      // 메인으로 이동하지 않고 signup flow 안에서만 이동하도록 제한
      if (authRepository.isLoggedIn && authRepository.isSignupInProgress) {
        if (!signupFlowRoute) return AppRouter.signup;
        return null;
      }

      if (authRepository.isLoggedIn && (isLoggingIn || signupFlowRoute)) {
        return authRepository.isJobSeeker
            ? AppRouter.jobSeekerMain
            : AppRouter.managerMain;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRouter.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRouter.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: AppRouter.signupPhoneVerification,
        builder: (_, __) => const SignupPhoneVerificationScreen(),
      ),
      GoRoute(
        path: AppRouter.signupComplete,
        builder: (context, state) {
          final role = state.extra as UserRole? ?? UserRole.jobSeeker;
          return SignupStep2Screen(role: role);
        },
      ),
      GoRoute(
        path: AppRouter.managerMain,
        builder: (_, __) => const ManagerMainScreen(),
      ),
      GoRoute(
        path: AppRouter.jobSeekerMain,
        builder: (_, __) => const JobSeekerMainScreen(),
      ),
    ],
  );
}
