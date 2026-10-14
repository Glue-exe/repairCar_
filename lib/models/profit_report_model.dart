// รายงานกำไรสุทธิ
class ProfitReportItemModel {
  String period;
  double income;
  double expense;
  double profit;

  ProfitReportItemModel({
    required this.period,
    required this.income,
    required this.expense,
    required this.profit,
  });

  factory ProfitReportItemModel.fromJson(Map<String, dynamic> json) {
    return ProfitReportItemModel(
      period: json['period'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
    );
  }
}
