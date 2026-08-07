class EmployeeModel {
  int empId = 0;
  int titleId = 0;
  String titleName = "";
  String empFirstname = "";
  String empLastname = "";
  String empPhone = "";
  int userRoleId = 0;
  String userRoleName = "";
  String empActive = "";

  EmployeeModel({
    required this.empId,
    required this.titleId,
    required this.titleName,
    required this.empFirstname,
    required this.empLastname,
    required this.empPhone,
    required this.userRoleId,
    required this.userRoleName,
    required this.empActive,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      empId: json['emp_id'] as int,
      titleId: json['title_id'] as int,
      titleName: json['title_name'] as String,
      empFirstname: json['emp_firstname'] as String,
      empLastname: json['emp_lastname'] as String,
      empPhone: json['emp_phone'] as String,
      userRoleId: json['user_role_id'] as int,
      userRoleName: json['user_role_name'] as String,
      empActive: json['emp_active'] as String,
    );
  }
}

class EmployeeResponse {
  bool isError = false;
  List<EmployeeModel> data = [];
  String errorMessage = "";

  EmployeeResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeResponse(
      isError: json['isError'],
      data: (json['data'] as List)
          .map((item) => EmployeeModel.fromJson(item))
          .toList(),
      errorMessage: json['errorMessage'],
    );
  }
}
