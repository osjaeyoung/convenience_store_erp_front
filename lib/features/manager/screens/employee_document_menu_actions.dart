import 'package:flutter/material.dart';

import 'employee_etc_records_screen.dart';
import 'employee_work_history_screen.dart';
import 'employment_contracts_list_screen.dart';
import 'payroll_statement_list_screen.dart';

/// 직원 카드 하단 문서 메뉴(근무이력·급여명세·근로계약…) 공통 탭 동작
Future<void> openEmployeeDocumentMenuItem(
  BuildContext context, {
  required String title,
  required int branchId,
  required int employeeId,
  required String employeeName,
  required String branchName,
  required String hireDate,
  required String contact,
  String? resignationDate,
  int? starCount,
  required List<Map<String, dynamic>> workHistories,
  Object? payrollStatementsRaw,
  VoidCallback? onPayrollFlowFinished,
}) async {
  switch (title) {
    case '근무이력':
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EmployeeWorkHistoryScreen(
            branchName: branchName,
            employeeName: employeeName,
            hireDate: hireDate,
            contact: contact,
            resignationDate: resignationDate,
            starCount: starCount,
            workHistories: workHistories,
          ),
        ),
      );
      return;
    case '급여명세':
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => PayrollStatementListScreen(
            branchId: branchId,
            employeeId: employeeId,
            employeeName: employeeName,
            initialItemsPayload: payrollStatementsRaw is List
                ? {'payroll_statements': payrollStatementsRaw}
                : null,
          ),
        ),
      );
      if (changed == true) {
        onPayrollFlowFinished?.call();
      }
      return;
    case '근로계약서':
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EmploymentContractsListScreen(
            branchId: branchId,
            employeeId: employeeId,
            employeeName: employeeName,
            screenTitle: '근로계약서',
            templateVersion: 'standard_v1',
          ),
        ),
      );
      return;
    case '연소근로자(18세 미만) 표준근로계약':
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EmploymentContractsListScreen(
            branchId: branchId,
            employeeId: employeeId,
            employeeName: employeeName,
            screenTitle: '연소근로자(18세 미만) 표준근로계약',
            templateVersion: 'minor_standard_v1',
          ),
        ),
      );
      return;
    case '친권동의서':
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EmploymentContractsListScreen(
            branchId: branchId,
            employeeId: employeeId,
            employeeName: employeeName,
            screenTitle: '친권동의서',
            templateVersion: 'guardian_consent_v1',
          ),
        ),
      );
      return;
    case '기타':
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EmployeeEtcRecordsScreen(
            branchId: branchId,
            employeeId: employeeId,
          ),
        ),
      );
      return;
    default:
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title 기능은 곧 연결됩니다.')),
        );
      }
  }
}
