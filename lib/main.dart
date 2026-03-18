import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'data/network/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/labor_cost_repository.dart';
import 'data/repositories/manager_home_repository.dart';
import 'data/repositories/owner_home_repository.dart';
import 'data/repositories/staff_management_repository.dart';
import 'data/repositories/store_expense_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage(prefs);
  final apiClient = ApiClient(tokenStorage);
  final authRepository = AuthRepository(apiClient, tokenStorage);
  apiClient.setUnauthorizedHandler(authRepository.handleUnauthorized);

  final ownerHomeRepository = OwnerHomeRepository(apiClient);
  final managerHomeRepository = ManagerHomeRepository(apiClient);
  final laborCostRepository = LaborCostRepository(apiClient);
  final storeExpenseRepository = StoreExpenseRepository(apiClient);
  final staffManagementRepository = StaffManagementRepository(apiClient);

  runApp(ConvenienceStoreApp(
    authRepository: authRepository,
    ownerHomeRepository: ownerHomeRepository,
    managerHomeRepository: managerHomeRepository,
    laborCostRepository: laborCostRepository,
    storeExpenseRepository: storeExpenseRepository,
    staffManagementRepository: staffManagementRepository,
  ));
}

class ConvenienceStoreApp extends StatelessWidget {
  const ConvenienceStoreApp({
    super.key,
    required this.authRepository,
    required this.ownerHomeRepository,
    required this.managerHomeRepository,
    required this.laborCostRepository,
    required this.storeExpenseRepository,
    required this.staffManagementRepository,
  });

  final AuthRepository authRepository;
  final OwnerHomeRepository ownerHomeRepository;
  final ManagerHomeRepository managerHomeRepository;
  final LaborCostRepository laborCostRepository;
  final StoreExpenseRepository storeExpenseRepository;
  final StaffManagementRepository staffManagementRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authRepository),
        RepositoryProvider.value(value: ownerHomeRepository),
        RepositoryProvider.value(value: managerHomeRepository),
        RepositoryProvider.value(value: laborCostRepository),
        RepositoryProvider.value(value: storeExpenseRepository),
        RepositoryProvider.value(value: staffManagementRepository),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository)..add(const AuthCheckRequested()),
        child: MaterialApp.router(
          title: '편의점 ERP',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
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
          routerConfig: createAppRouter(authRepository),
        ),
      ),
    );
  }
}
