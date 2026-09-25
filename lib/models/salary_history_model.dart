class SalaryHistoryModel {
  int shId;
  int shEmpId;
  String shsalaryAmount;
  String shEffectiveDate;
  String shCreatedAt;
  String empFirstName;
  String empLastName;
  String empCurrentSalary;
  String tName;
  int accRoleId;
  String arName;

  SalaryHistoryModel({
    required this.shId,
    required this.shEmpId,
    required this.shsalaryAmount,
    required this.shEffectiveDate,
    required this.shCreatedAt,
    required this.empFirstName,
    required this.empLastName,
    required this.empCurrentSalary,
    required this.tName,
    required this.accRoleId,
    required this.arName,
  });

  factory SalaryHistoryModel.fromJson(Map<String, dynamic> json) {
    return SalaryHistoryModel(
      shId: json['sh_id'] as int,
      shEmpId: json['sh_emp_id'] as int,
      shsalaryAmount: json['sh_salary_amount'] as String,
      shEffectiveDate: json['sh_effective_date'] as String,
      shCreatedAt: json['sh_created_at'] as String,
      empFirstName: json['emp_first_name'] as String,
      empLastName: json['emp_last_name'] as String,
      empCurrentSalary: json['emp_current_salary'] as String,
      tName: json['t_name'] as String,
      accRoleId: json['acc_role_id'] as int,
      arName: json['ar_name'] as String,
    );
  }
}

class SalaryHistoryResponse {
  bool isError;
  List<SalaryHistoryModel> data;
  String errorMessage;

  SalaryHistoryResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory SalaryHistoryResponse.fromJson(Map<String, dynamic> json) {
    return SalaryHistoryResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => SalaryHistoryModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}