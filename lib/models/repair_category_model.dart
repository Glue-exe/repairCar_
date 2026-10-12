class RepairCategoryModel {
  int id;
  String name;
  String detail;

  RepairCategoryModel({
    required this.id,
    required this.name,
    required this.detail,
  });

  factory RepairCategoryModel.fromJson(Map<String, dynamic> json) {
    return RepairCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      detail: json['detail'] as String? ?? '',
    );
  }
}

class RepairCategoryResponse {
  bool isError;
  List<RepairCategoryModel> data;
  String errorMessage;

  RepairCategoryResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory RepairCategoryResponse.fromJson(Map<String, dynamic> json) {
    return RepairCategoryResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map(
            (item) =>
                RepairCategoryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
