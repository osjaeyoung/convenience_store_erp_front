/// 오늘 근무자 현황
class TodayWorker {
  const TodayWorker({
    required this.statusId,
    required this.workDate,
    required this.timeLabel,
    required this.workerName,
    required this.status,
    this.memo,
    this.updatedAt,
  });

  final int statusId;
  final String workDate;
  final String timeLabel;
  final String workerName;
  final String status;
  final String? memo;
  final String? updatedAt;

  factory TodayWorker.fromJson(Map<String, dynamic> json) {
    return TodayWorker(
      statusId: json['status_id'] as int,
      workDate: json['work_date'] as String,
      timeLabel: json['time_label'] as String,
      workerName: json['worker_name'] as String,
      status: json['status'] as String,
      memo: json['memo'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
