// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in a Flutter application and use the
// WidgetTester utility. For example, you can send tap and scroll gestures.
// You can also use WidgetTester to find child widgets in the widget tree,
// read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:convenience_store_erp_front/core/storage/token_storage.dart';
import 'package:convenience_store_erp_front/data/network/api_client.dart';
import 'package:convenience_store_erp_front/data/repositories/auth_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/labor_cost_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/manager_home_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/owner_home_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/push_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/staff_management_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/store_expense_repository.dart';
import 'package:convenience_store_erp_front/data/repositories/worker_recruitment_repository.dart';
import 'package:convenience_store_erp_front/main.dart';

/// Minimal 1×1 PNG for [ConvenienceStoreApp.splashImageBytes] in tests.
final Uint8List _testSplashPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

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
    final pushRepository = PushRepository(apiClient);

    await tester.pumpWidget(
      ConvenienceStoreApp(
        authRepository: authRepository,
        ownerHomeRepository: ownerHomeRepository,
        managerHomeRepository: managerHomeRepository,
        laborCostRepository: laborCostRepository,
        storeExpenseRepository: storeExpenseRepository,
        staffManagementRepository: staffManagementRepository,
        workerRecruitmentRepository: workerRecruitmentRepository,
        pushRepository: pushRepository,
        splashImageBytes: _testSplashPngBytes,
      ),
    );

    await tester.pump();
    // [ConvenienceStoreApp] keeps splash until a 1s minimum elapses in _bootstrap.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
