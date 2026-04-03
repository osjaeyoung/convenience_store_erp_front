// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in a Flutter application and use the
// WidgetTester utility. For example, you can send tap and scroll gestures.
// You can also use WidgetTester to find child widgets in the widget tree,
// read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:convenience_store_erp_front/core/storage/token_storage.dart';
import 'package:convenience_store_erp_front/data/network/api_client.dart';
import 'package:convenience_store_erp_front/data/repositories/auth_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/labor_cost_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/manager_home_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/owner_home_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/staff_management_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/store_expense_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/worker_recruitment_repository.dart';
import 'package:convenience_store_erp_front/main.dart';

void main() {
  setUpAll(() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env may not exist in test; ApiConfig uses default baseUrl
    }
  });

  testWidgets('App builds without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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

    await tester.pumpWidget(
      ConvenienceStoreApp(
        authRepository: authRepository,
        ownerHomeRepository: ownerHomeRepository,
        managerHomeRepository: managerHomeRepository,
        laborCostRepository: laborCostRepository,
        storeExpenseRepository: storeExpenseRepository,
        staffManagementRepository: staffManagementRepository,
        workerRecruitmentRepository: workerRecruitmentRepository,
      ),
    );

    await tester.pumpAndSettle();
  });
}
