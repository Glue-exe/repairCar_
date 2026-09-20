class DashboardSummaryModel {
  double monthlyIncome;
  double unpaidTotal;
  int vehiclesThisMonth;
  int activeJobsCount;
  int pendingApprovalsCount;

  DashboardSummaryModel({
    required this.monthlyIncome,
    required this.unpaidTotal,
    required this.vehiclesThisMonth,
    required this.activeJobsCount,
    required this.pendingApprovalsCount,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      monthlyIncome: double.parse(json['monthlyIncome'].toString()),
      unpaidTotal: double.parse(json['unpaidTotal'].toString()),
      vehiclesThisMonth: int.parse(json['vehiclesThisMonth'].toString()),
      activeJobsCount: int.parse(json['activeJobsCount'].toString()),
      pendingApprovalsCount: int.parse(json['pendingApprovalsCount'].toString()),
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
