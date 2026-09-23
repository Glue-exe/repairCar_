class EmployeeModel {
  int empId;
  int empTitleId;
  String tName;
  String empFirstName;
  String empLastName;
  String empPhone;
  String empCurrentSalary;
  int accId;
  String accUsername;
  int accRoleId;
  String arName;
  int accStatusId;

  EmployeeModel({
    required this.empId,
    required this.empTitleId,
    required this.tName,
    required this.empFirstName,
    required this.empLastName,
    required this.empPhone,
    required this.empCurrentSalary,
    required this.accId,
    required this.accUsername,
    required this.accRoleId,
    required this.arName,
    required this.accStatusId,
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
      accId: json['acc_id'] as int,
      accUsername: json['acc_username'] as String,
      accRoleId: json['acc_role_id'] as int,
      arName: json['ar_name'] as String,
      accStatusId: json['acc_status_id'] as int,
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
