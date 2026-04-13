import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../../../data/models/labor_cost/expected_labor_cost.dart';
import '../../../data/models/manager_home/manager_alert.dart';
import '../../../data/models/manager_home/manager_branch.dart';
import '../../../data/models/owner_home/owner_branch.dart';
import '../../../data/repositories/labor_cost_repository.dart';
import '../../../data/repositories/manager_home_repository.dart';
import '../../../data/repositories/owner_home_repository.dart';
import '../../../data/models/manager_home/today_worker.dart';
import '../../../data/repositories/staff_management_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

/// 홈 화면 BLoC
/// 경영주: owner home branches
/// 점장: manager home branches
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._ownerHomeRepository,
    this._managerHomeRepository,
    this._laborCostRepository,
    StaffManagementRepository staffManagementRepository, {
    required bool isOwner,
  }) : _isOwner = isOwner,
       super(const HomeState.initial()) {
    on<HomeBranchesRequested>(_onBranchesRequested);
    on<HomeBranchDetailRequested>(_onBranchDetailRequested);
    on<HomeWorkerStatusSaveRequested>(_onWorkerStatusSaveRequested);
    on<HomeWorkerMemoDeleteRequested>(_onWorkerMemoDeleteRequested);
  }

  final OwnerHomeRepository _ownerHomeRepository;
  final ManagerHomeRepository _managerHomeRepository;
  final LaborCostRepository _laborCostRepository;
  final bool _isOwner;

  Future<void> _onBranchesRequested(
    HomeBranchesRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeState.loading());
    try {
      if (_isOwner) {
        final branches = await _ownerHomeRepository.getBranches();
        emit(HomeState.ownerBranchesLoaded(branches));
      } else {
        try {
          final branches = await _managerHomeRepository.getBranches(
            date: event.date,
          );
          emit(HomeState.managerBranchesLoaded(branches));
        } on DioException catch (e) {
          final detail = (e.response?.data is Map)
              ? (e.response?.data['detail']?.toString() ?? '')
              : '';
          // owner 계정이 잘못 점장 엔드포인트를 타는 경우를 안전하게 처리
          if (e.response?.statusCode == 403 &&
              detail.toLowerCase().contains('manager access only')) {
            final ownerBranches = await _ownerHomeRepository.getBranches();
            emit(HomeState.ownerBranchesLoaded(ownerBranches));
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      emit(HomeState.failure(e.toString()));
    }
  }

  Future<void> _onBranchDetailRequested(
    HomeBranchDetailRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(detailLoading: true, detailErrorMessage: null));
    try {
      final date = _normalizeWorkDate(event.date ?? _todayDate());
      if (_isOwner) {
        final branch = await _ownerHomeRepository.getBranchDetail(
          event.branchId,
        );
        final recruitment = await _ownerHomeRepository.getRecruitmentStatus(
          event.branchId,
        );
        final alerts = await _ownerHomeRepository.getAlerts(event.branchId);
        final todayWorkers = await _ownerHomeRepository.getTodayWorkers(
          branchId: event.branchId,
          date: date,
        );
        final expected = await _getExpectedLaborOrNull(event.branchId);

        final rows = _todayWorkersToRows(todayWorkers);
        final workDate = _normalizeWorkDate(
          todayWorkers['date']?.toString() ?? date,
        );

        final openAlerts = alerts.where((a) => a['is_open'] == true).toList();
        final todayAlertTitles = _ownerTodayAlertTitles(alerts);
        final alertTitle = openAlerts.isNotEmpty
            ? (openAlerts.first['title']?.toString() ?? '오늘의 알림')
            : (alerts.isNotEmpty
                  ? (alerts.first['title']?.toString() ?? '오늘의 알림')
                  : '오늘의 알림');

        final detail = HomeBranchDetail(
          branchId: event.branchId,
          managerName: branch.manager?.fullName ?? '',
          alertTitle: alertTitle,
          todayAlertTitles: todayAlertTitles,
          waitingInterview: _recruitmentCount(
            recruitment,
            primaryKey: 'application_count',
            fallbackKey: 'waiting_interviews',
          ),
          newApplicants: _recruitmentCount(
            recruitment,
            primaryKey: 'today_applicants_count',
            fallbackKey: 'new_applicants',
          ),
          newContacts: _recruitmentCount(
            recruitment,
            primaryKey: 'active_postings_count',
            fallbackKey: 'new_contacts',
          ),
          rows: rows,
          workDate: _normalizeWorkDate(workDate),
          dateLabel: _formatDateLabel(_normalizeWorkDate(workDate)),
          expectedTotalAmountText: expected == null
              ? null
              : '총 ${_formatWon(expected.currentTotalCost)} 원',
          expectedChangeText: expected == null
              ? null
              : '전월 대비 총 ${expected.changeRatePercent.toStringAsFixed(1)}% 올랐어요',
          savingPointTexts:
              expected?.savingPoints
                  .map((e) => '${e.title} ${e.description}')
                  .toList() ??
              const [],
        );
        emit(
          state.copyWith(
            selectedBranchDetail: detail,
            detailLoading: false,
            detailErrorMessage: null,
          ),
        );
      } else {
        final recruitment = await _managerHomeRepository.getRecruitmentStatus(
          event.branchId,
        );
        final alerts = await _managerHomeRepository.getAlerts(event.branchId);
        final workers = await _managerHomeRepository.getTodayWorkers(
          branchId: event.branchId,
          date: date,
        );
        final expected = await _getExpectedLaborOrNull(event.branchId);

        final rows = _managerTodayWorkersToRows(workers);
        final workDate = _normalizeWorkDate(
          workers.isNotEmpty ? workers.first.workDate : date,
        );
        final todayAlertTitles = _managerTodayAlertTitles(alerts);

        final detail = HomeBranchDetail(
          branchId: event.branchId,
          managerName: '등록된 점장',
          alertTitle: alerts.isNotEmpty ? alerts.first.title : '오늘의 알림',
          todayAlertTitles: todayAlertTitles,
          waitingInterview: _recruitmentCount(
            recruitment,
            primaryKey: 'application_count',
            fallbackKey: 'waiting_interviews',
          ),
          newApplicants: _recruitmentCount(
            recruitment,
            primaryKey: 'today_applicants_count',
            fallbackKey: 'new_applicants',
          ),
          newContacts: _recruitmentCount(
            recruitment,
            primaryKey: 'active_postings_count',
            fallbackKey: 'new_contacts',
          ),
          rows: rows,
          workDate: _normalizeWorkDate(workDate),
          dateLabel: _formatDateLabel(_normalizeWorkDate(workDate)),
          expectedTotalAmountText: expected == null
              ? null
              : '총 ${_formatWon(expected.currentTotalCost)} 원',
          expectedChangeText: expected == null
              ? null
              : '전월 대비 총 ${expected.changeRatePercent.toStringAsFixed(1)}% 올랐어요',
          savingPointTexts:
              expected?.savingPoints
                  .map((e) => '${e.title} ${e.description}')
                  .toList() ??
              const [],
        );
        emit(
          state.copyWith(
            selectedBranchDetail: detail,
            detailLoading: false,
            detailErrorMessage: null,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(detailLoading: false, detailErrorMessage: e.toString()),
      );
    }
  }

  Future<void> _onWorkerStatusSaveRequested(
    HomeWorkerStatusSaveRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final normalizedWorkDate = _normalizeWorkDate(event.workDate);
      final apiStatus = _toApiWorkerStatus(event.status);

      if (_isOwner) {
        await _ownerHomeRepository.putTodayWorkerStatus(
          branchId: event.branchId,
          workDate: normalizedWorkDate,
          timeLabel: event.timeLabel,
          workerName: event.workerName,
          status: apiStatus,
          memo: event.memo,
        );
      } else {
        await _managerHomeRepository.putTodayWorkerStatus(
          branchId: event.branchId,
          workDate: normalizedWorkDate,
          timeLabel: event.timeLabel,
          workerName: event.workerName,
          status: apiStatus,
          memo: event.memo,
        );
      }

      final detail = state.selectedBranchDetail;
      if (detail == null || detail.branchId != event.branchId) return;

      final displayStatus = _mapWorkerStatus(apiStatus);
      final updatedRows = detail.rows
          .map(
            (r) =>
                (r.time == event.timeLabel && r.workerName == event.workerName)
                ? HomeWorkerRow(
                    time: r.time,
                    workerName: r.workerName,
                    status: displayStatus,
                    memo: event.memo ?? r.memo,
                    statusId: r.statusId,
                  )
                : r,
          )
          .toList();

      emit(
        state.copyWith(
          selectedBranchDetail: HomeBranchDetail(
            branchId: detail.branchId,
            managerName: detail.managerName,
            alertTitle: detail.alertTitle,
            todayAlertTitles: detail.todayAlertTitles,
            waitingInterview: detail.waitingInterview,
            newApplicants: detail.newApplicants,
            newContacts: detail.newContacts,
            rows: updatedRows,
            workDate: detail.workDate,
            dateLabel: detail.dateLabel,
            expectedTotalAmountText: detail.expectedTotalAmountText,
            expectedChangeText: detail.expectedChangeText,
            savingPointTexts: detail.savingPointTexts,
          ),
          detailErrorMessage: null,
        ),
      );

      // 서버 기준 최신 데이터로 재조회해 로컬/서버 불일치와 키 불일치를 방지
      add(
        HomeBranchDetailRequested(
          branchId: event.branchId,
          date: normalizedWorkDate,
        ),
      );
    } catch (e) {
      emit(state.copyWith(detailErrorMessage: e.toString()));
    }
  }

  Future<void> _onWorkerMemoDeleteRequested(
    HomeWorkerMemoDeleteRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final normalizedWorkDate = _normalizeWorkDate(event.workDate);

      if (_isOwner) {
        if (event.statusId != null) {
          await _ownerHomeRepository.deleteTodayWorkerMemo(
            branchId: event.branchId,
            statusId: event.statusId!,
          );
        } else {
          await _ownerHomeRepository.putTodayWorkerStatus(
            branchId: event.branchId,
            workDate: normalizedWorkDate,
            timeLabel: event.timeLabel,
            workerName: event.workerName,
            status: _toApiWorkerStatus(event.status),
            memo: null,
          );
        }
      } else {
        if (event.statusId != null) {
          await _managerHomeRepository.deleteTodayWorkerMemo(
            branchId: event.branchId,
            statusId: event.statusId!,
          );
        } else {
          await _managerHomeRepository.putTodayWorkerStatus(
            branchId: event.branchId,
            workDate: normalizedWorkDate,
            timeLabel: event.timeLabel,
            workerName: event.workerName,
            status: _toApiWorkerStatus(event.status),
            memo: null,
          );
        }
      }

      add(
        HomeBranchDetailRequested(
          branchId: event.branchId,
          date: normalizedWorkDate,
        ),
      );
    } catch (e) {
      emit(state.copyWith(detailErrorMessage: e.toString()));
    }
  }

  Future<ExpectedLaborCost?> _getExpectedLaborOrNull(int branchId) async {
    try {
      return await _laborCostRepository.getExpected(
        branchId: branchId,
        rangeType: 'this_month',
      );
    } catch (_) {
      return null;
    }
  }

  List<HomeWorkerRow> _todayWorkersToRows(Map<String, dynamic> data) {
    final rowsRaw =
        (data['rows'] as List?) ??
        (data['items'] as List?) ??
        (data['today_workers'] as List?) ??
        (data['today_shift_rows'] as List?) ??
        const [];
    return rowsRaw
        .whereType<Map>()
        .map(
          (row) => HomeWorkerRow(
            time: row['time_label']?.toString() ?? '-',
            workerName: row['worker_name']?.toString() ?? '-',
            status: _mapWorkerStatus(row['status']?.toString() ?? ''),
            memo: row['memo']?.toString(),
            statusId: _toNullableInt(row['status_id'] ?? row['shift_id']),
          ),
        )
        .toList();
  }

  List<HomeWorkerRow> _managerTodayWorkersToRows(List<dynamic> workers) {
    return workers
        .whereType<TodayWorker>()
        .map(
          (w) => HomeWorkerRow(
            time: w.timeLabel,
            workerName: w.workerName,
            status: _mapWorkerStatus(w.status),
            memo: w.memo,
            statusId: w.statusId,
          ),
        )
        .toList();
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _ownerTodayAlertTitles(List<Map<String, dynamic>> alerts) {
    return alerts
        .map(
          (alert) => (
            title: alert['title']?.toString().trim() ?? '',
            createdAt: _parseAlertDateTime(alert['created_at']),
          ),
        )
        .where(
          (alert) =>
              alert.title.isNotEmpty &&
              alert.createdAt != null &&
              _isToday(alert.createdAt!),
        )
        .map((alert) => alert.title)
        .toList();
  }

  List<String> _managerTodayAlertTitles(List<ManagerAlert> alerts) {
    return alerts
        .map(
          (alert) => (
            title: alert.title.trim(),
            createdAt: _parseAlertDateTime(alert.createdAt),
          ),
        )
        .where(
          (alert) =>
              alert.title.isNotEmpty &&
              alert.createdAt != null &&
              _isToday(alert.createdAt!),
        )
        .map((alert) => alert.title)
        .toList();
  }

  int _recruitmentCount(
    Map<String, dynamic> recruitment, {
    required String primaryKey,
    required String fallbackKey,
  }) {
    if (recruitment.containsKey(primaryKey)) {
      return _toInt(recruitment[primaryKey]);
    }
    return _toInt(recruitment[fallbackKey]);
  }

  int? _toNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _todayDate() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  String _formatDateLabel(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final day = int.tryParse(parts[2]) ?? DateTime.now().day;
    final d = DateTime(year, month, day);
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '$year.${parts[1]}.${parts[2]}(${weekdays[d.weekday - 1]})';
  }

  String _mapWorkerStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'done' ||
        normalized == 'completed' ||
        status == '완료' ||
        status == '근무완료') {
      return '완료';
    }
    if (normalized == 'planned' ||
        normalized == 'scheduled' ||
        status == '예정' ||
        status == '근무예정') {
      return '예정';
    }
    if (normalized == 'absent' || status == '결근') return '결근';
    if (normalized == 'pending' || normalized == 'unset' || status == '미정') {
      return '미정';
    }
    return status;
  }

  /// Manager/Owner home today-workers API용 (done|planned|absent|pending)
  String _toApiWorkerStatus(String status) {
    switch (status) {
      case '완료':
      case '근무완료':
        return 'done';
      case '예정':
      case '근무예정':
        return 'planned';
      case '결근':
        return 'absent';
      case '미정':
        return 'pending';
      default:
        return status.toLowerCase();
    }
  }

  String _normalizeWorkDate(String value) {
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    if (iso.hasMatch(value)) return value;

    final dotted = RegExp(r'^(\d{4})\.(\d{2})\.(\d{2})');
    final dottedMatch = dotted.firstMatch(value);
    if (dottedMatch != null) {
      return '${dottedMatch.group(1)}-${dottedMatch.group(2)}-${dottedMatch.group(3)}';
    }

    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  DateTime? _parseAlertDateTime(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
  }

  String _formatWon(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      final idxFromEnd = str.length - i;
      buffer.write(str[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}
