import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../enums/user_role.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/screens/login_screen.dart';
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
  static const String signupComplete = '/signup/complete';
  static const String managerMain = '/manager';
  static const String jobSeekerMain = '/job-seeker';
}

GoRouter createAppRouter(
  AuthRepository authRepository, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: _initialLocationFor(authRepository),
    refreshListenable: authRepository,
    redirect: (context, state) {
      final userRole = authRepository.role;
      final isLoggingIn = state.matchedLocation == AppRouter.login;
      final isSigningUp = state.matchedLocation == AppRouter.signup;
      final isSignupComplete =
          state.matchedLocation == AppRouter.signupComplete;
      final isManagerMain = state.matchedLocation == AppRouter.managerMain;
      final isJobSeekerMain = state.matchedLocation == AppRouter.jobSeekerMain;
      final signupFlowRoute = isSigningUp || isSignupComplete;

      if (!authRepository.isLoggedIn &&
          !isLoggingIn &&
          !isSigningUp &&
          !isSignupComplete) {
        return AppRouter.login;
      }

      // 회원가입 1차 토큰 발급 후에는 마지막 단계 완료 전까지
      // 메인으로 이동하지 않고 signup flow 안에서만 이동하도록 제한
      if (authRepository.isLoggedIn && authRepository.isSignupInProgress) {
        if (!signupFlowRoute) return AppRouter.signup;
        return null;
      }

      if (authRepository.isLoggedIn && userRole != null) {
        if (userRole.isJobSeeker && isManagerMain) {
          return AppRouter.jobSeekerMain;
        }
        if (!userRole.isJobSeeker && isJobSeekerMain) {
          return AppRouter.managerMain;
        }
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
        path: AppRouter.signupComplete,
        builder: (context, state) {
          final role = state.extra as UserRole? ?? UserRole.jobSeeker;
          return SignupStep2Screen(role: role);
        },
      ),
      GoRoute(
        path: AppRouter.managerMain,
        builder: (_, state) => ManagerMainScreen(
          initialTabIndex: _queryInt(state, 'tab') ?? 0,
          initialLaborCostTabIndex: _queryInt(state, 'laborCostTab') ?? 0,
          initialRecruitmentTabIndex: _queryInt(state, 'recruitmentTab') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRouter.jobSeekerMain,
        builder: (_, state) =>
            JobSeekerMainScreen(initialTabIndex: _queryInt(state, 'tab') ?? 0),
      ),
    ],
  );
}

int? _queryInt(GoRouterState state, String key) {
  final raw = state.uri.queryParameters[key];
  if (raw == null) return null;
  return int.tryParse(raw);
}

String _initialLocationFor(AuthRepository authRepository) {
  if (authRepository.isLoggedIn && authRepository.isSignupInProgress) {
    return AppRouter.signup;
  }
  if (authRepository.isLoggedIn) {
    return authRepository.isJobSeeker
        ? AppRouter.jobSeekerMain
        : AppRouter.managerMain;
  }
  return AppRouter.login;
}
