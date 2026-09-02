class RoleModel {
  int id;
  String name;

  // Getters for legacy compatibility
  int get userRoleId => id;
  String get userRoleName => name;
  String get uesrRoleName => name;

  RoleModel({
    required this.id,
    required this.name,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class RoleResponse {
  bool isError;
  List<RoleModel> data;
  String errorMessage;

  RoleResponse({
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
      errorMessage: json['errorMessage'] as String,
    );
  }
}