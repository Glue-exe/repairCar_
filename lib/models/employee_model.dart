class EmployeeModel {
  int empId;
  int empTitleId;
  String tName;
  String empFirstName;
  String empLastName;
  String empPhone;
  String empCurrentSalary;
  String? deletedAt;
  int accId;
  int accEmployeeId;
  String accUsername;
  int accRoleId;
  bool accIsActive;
  String arName;

  bool get isDeleted => deletedAt != null;

  EmployeeModel({
    required this.empId,
    required this.empTitleId,
    required this.tName,
    required this.empFirstName,
    required this.empLastName,
    required this.empPhone,
    required this.empCurrentSalary,
    this.deletedAt,
    required this.accId,
    required this.accEmployeeId,
    required this.accUsername,
    required this.accRoleId,
    required this.accIsActive,
    required this.arName,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      empId: json['emp_id'] as int,
      empTitleId: json['emp_title_id'] as int,
      tName: json['t_name'] as String,
      empFirstName: json['emp_first_name'] as String,
      empLastName: json['emp_last_name'] as String,
      empPhone: json['emp_phone'] as String,
      empCurrentSalary: json['emp_current_salary'] as String,
      deletedAt: json['deleted_at']?.toString(),
      accId: json['acc_id'] as int,
      accEmployeeId: json['acc_employee_id'] as int,
      accUsername: json['acc_username'] as String,
      accRoleId: json['acc_role_id'] as int,
      accIsActive: json['acc_is_active'] as bool,
      arName: json['ar_name'] as String,
    );
  }
}

class EmployeeResponse {
  bool isError;
  List<EmployeeModel> data;
  String errorMessage;

  EmployeeResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => EmployeeModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}





