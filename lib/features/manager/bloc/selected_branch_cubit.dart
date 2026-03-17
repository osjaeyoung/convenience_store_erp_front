import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 선택된 지점 ID 관리
/// 홈에서 사용자가 선택한 지점 ID를 사용자별로 로컬 저장/복원
class SelectedBranchCubit extends Cubit<int?> {
  SelectedBranchCubit({required String userId})
      : _userId = userId,
        super(null) {
    _restore();
  }

  final String _userId;

  String get _storageKey => 'selected_branch_id_$_userId';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBranchId = prefs.getInt(_storageKey);
    if (savedBranchId != null) {
      emit(savedBranchId);
    }
  }

  Future<void> select(int branchId) async {
    emit(branchId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, branchId);
  }

  Future<void> clear() async {
    emit(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
