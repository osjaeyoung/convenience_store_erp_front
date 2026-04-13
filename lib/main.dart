import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/constants/app_assets.dart';
import 'core/push/push_notification_service.dart';
import 'core/screen/app_design.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'data/network/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/labor_cost_repository.dart';
import 'data/repositories/manager_home_repository.dart';
import 'data/repositories/owner_home_repository.dart';
import 'data/repositories/push_repository.dart';
import 'data/repositories/staff_management_repository.dart';
import 'data/repositories/store_expense_repository.dart';
import 'data/repositories/worker_recruitment_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/splash/screens/app_splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: '.env');
  final splashImageBytes = (await rootBundle.load(
    AppAssets.splashScreen,
  )).buffer.asUint8List();

  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage(prefs);
  final apiClient = ApiClient(tokenStorage);
  final authRepository = AuthRepository(apiClient, tokenStorage);

  final ownerHomeRepository = OwnerHomeRepository(apiClient);
  final managerHomeRepository = ManagerHomeRepository(apiClient);
  final laborCostRepository = LaborCostRepository(apiClient);
  final storeExpenseRepository = StoreExpenseRepository(apiClient);
  final staffManagementRepository = StaffManagementRepository(apiClient);
  final workerRecruitmentRepository = WorkerRecruitmentRepository(apiClient);
  final pushRepository = PushRepository(apiClient);

  runApp(
    ConvenienceStoreApp(
      apiClient: apiClient,
      authRepository: authRepository,
      ownerHomeRepository: ownerHomeRepository,
      managerHomeRepository: managerHomeRepository,
      laborCostRepository: laborCostRepository,
      storeExpenseRepository: storeExpenseRepository,
      staffManagementRepository: staffManagementRepository,
      workerRecruitmentRepository: workerRecruitmentRepository,
      pushRepository: pushRepository,
      splashImageBytes: splashImageBytes,
    ),
  );
}

class ConvenienceStoreApp extends StatefulWidget {
  const ConvenienceStoreApp({
    super.key,
    required this.apiClient,
    required this.authRepository,
    required this.ownerHomeRepository,
    required this.managerHomeRepository,
    required this.laborCostRepository,
    required this.storeExpenseRepository,
    required this.staffManagementRepository,
    required this.workerRecruitmentRepository,
    required this.pushRepository,
    required this.splashImageBytes,
  });

  final ApiClient apiClient;
  final AuthRepository authRepository;
  final OwnerHomeRepository ownerHomeRepository;
  final ManagerHomeRepository managerHomeRepository;
  final LaborCostRepository laborCostRepository;
  final StoreExpenseRepository storeExpenseRepository;
  final StaffManagementRepository staffManagementRepository;
  final WorkerRecruitmentRepository workerRecruitmentRepository;
  final PushRepository pushRepository;
  final Uint8List splashImageBytes;

  @override
  State<ConvenienceStoreApp> createState() => _ConvenienceStoreAppState();
}

class _ConvenienceStoreAppState extends State<ConvenienceStoreApp> {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  GoRouter? _router;
  AuthBloc? _authBloc;
  bool _isBootstrapped = false;

  @override
  void initState() {
    super.initState();
    widget.apiClient.setUnauthorizedHandler(_handleUnauthorized);
    _bootstrap();
  }

  Future<void> _handleUnauthorized() async {
    await widget.authRepository.handleUnauthorized();
    if (!mounted) return;

    _router?.go(AppRouter.login);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = _scaffoldMessengerKey.currentState;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다. 다시 로그인해주세요.')),
        );
    });
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();

    if (widget.authRepository.isLoggedIn) {
      try {
        await widget.authRepository.getMe();
      } catch (_) {
        await widget.authRepository.logout();
      }
    }

    final elapsed = DateTime.now().difference(startedAt);
    const minimumSplash = Duration(seconds: 1);
    if (elapsed < minimumSplash) {
      await Future<void>.delayed(minimumSplash - elapsed);
    }

    _router = createAppRouter(
      widget.authRepository,
      navigatorKey: _rootNavigatorKey,
    );
    _authBloc = AuthBloc(widget.authRepository)
      ..add(const AuthCheckRequested());
    await PushNotificationService.instance.initialize(
      navigatorKey: _rootNavigatorKey,
      onTokenReceived: (token) async {
        if (!widget.authRepository.isLoggedIn) return;
        await widget.pushRepository.upsertDeviceToken(
          token: token,
          platform: PushNotificationService.platformName,
        );
      },
    );

    if (widget.authRepository.isLoggedIn) {
      await PushNotificationService.instance.onUserAuthenticated();
      if (!widget.authRepository.hasLoadedNotificationUnreadCount) {
        try {
          await widget.authRepository.refreshNotificationUnreadCount();
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _isBootstrapped = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.flushPendingNavigation();
    });
  }

  @override
  void dispose() {
    _router?.dispose();
    _authBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppDesign.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        if (!_isBootstrapped || _router == null || _authBloc == null) {
          return MaterialApp(
            title: '편의점 ERP',
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
            locale: const Locale('ko', 'KR'),
            home: AppSplashScreen(splashImageBytes: widget.splashImageBytes),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: widget.authRepository),
            RepositoryProvider.value(value: widget.ownerHomeRepository),
            RepositoryProvider.value(value: widget.managerHomeRepository),
            RepositoryProvider.value(value: widget.laborCostRepository),
            RepositoryProvider.value(value: widget.storeExpenseRepository),
            RepositoryProvider.value(value: widget.staffManagementRepository),
            RepositoryProvider.value(value: widget.workerRecruitmentRepository),
          ],
          child: BlocProvider.value(
            value: _authBloc!,
            child: BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status,
              listener: (_, state) async {
                if (state.status == AuthStatus.authenticated) {
                  await PushNotificationService.instance.onUserAuthenticated();
                  if (!widget.authRepository.hasLoadedNotificationUnreadCount) {
                    try {
                      await widget.authRepository
                          .refreshNotificationUnreadCount();
                    } catch (_) {}
                  }
                  PushNotificationService.instance.flushPendingNavigation();
                }
              },
              child: MaterialApp.router(
                title: '편의점 ERP',
                theme: AppTheme.light,
                debugShowCheckedModeBanner: false,
                scaffoldMessengerKey: _scaffoldMessengerKey,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('ko', 'KR'),
                  Locale('en', 'US'),
                ],
                locale: const Locale('ko', 'KR'),
                routerConfig: _router!,
              ),
            ),
          ),
        );
      },
    );
  }
}
