class MonthlyIncomeModel {
  String monthYear;
  double totalAmount;

  MonthlyIncomeModel({
    required this.monthYear,
    required this.totalAmount,
  });

  factory MonthlyIncomeModel.fromJson(Map<String, dynamic> json) {
    return MonthlyIncomeModel(
      monthYear: json['month_year'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }
}

class MonthlyIncomeResponse {
  bool isError;
  List<MonthlyIncomeModel> data;
  String errorMessage;

  MonthlyIncomeResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory MonthlyIncomeResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyIncomeResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => MonthlyIncomeModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
