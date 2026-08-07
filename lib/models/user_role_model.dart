class RoleModel {
  int userRoleId = 0;
  String uesrRoleName = "";

  RoleModel ({
    required this.userRoleId,
    required this.uesrRoleName,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      userRoleId: json["user_role_id"] as int,
      uesrRoleName: json["user_role_name"] as String
    );
  }
}

class RoleResponse {
  bool isError = false;
  List<RoleModel> data = [];
  String errorMessage = "";

  RoleResponse ({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory RoleResponse.fromJson(Map<String, dynamic> json) {
    return RoleResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
            .map((item) => RoleModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      errorMessage: json['errorMessage'] as String);
  }
}