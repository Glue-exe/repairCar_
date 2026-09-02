class DashboardSummaryModel {
  double monthlyIncome;
  int vehiclesThisMonth;
  int activeJobsCount;
  int pendingApprovalsCount;

  DashboardSummaryModel({
    required this.monthlyIncome,
    required this.vehiclesThisMonth,
    required this.activeJobsCount,
    required this.pendingApprovalsCount,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
      vehiclesThisMonth: json['vehiclesThisMonth'] as int,
      activeJobsCount: json['activeJobsCount'] as int,
      pendingApprovalsCount: json['pendingApprovalsCount'] as int,
    );
  }
}

class DashboardSummaryResponse {
  bool isError;
  DashboardSummaryModel data;
  String errorMessage;

  DashboardSummaryResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory DashboardSummaryResponse.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryResponse(
      isError: json['isError'] as bool,
      data: DashboardSummaryModel.fromJson(json['data'] as Map<String, dynamic>),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
