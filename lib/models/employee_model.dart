class EmployeeModel {
  int id;
  String username;
  int titleId;
  String titleName;
  String firstName;
  String lastName;
  String phone;
  int userRoleId;
  String userRoleName;
  double salary;
  int accStatusId;

  EmployeeModel({
    required this.id,
    required this.username,
    required this.titleId,
    required this.titleName,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.userRoleId,
    required this.userRoleName,
    required this.salary,
    required this.accStatusId,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as int,
      username: json['username']as String,
      titleId: json['title_id'] as int,
      titleName: json['title_name'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String,
      userRoleId: json['user_role_id'] as int,
      userRoleName: json['user_role_name'] as String,
      salary: double.parse(json['current_salary'].toString()),
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
