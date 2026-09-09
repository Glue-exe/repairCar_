class SubTaskStatusModel {
  int id;
  String name;

  SubTaskStatusModel({
    required this.id,
    required this.name,
  });

  factory SubTaskStatusModel.fromJson(Map<String, dynamic> json) {
    return SubTaskStatusModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class SubTaskStatusResponse {
  bool isError;
  List<SubTaskStatusModel> data;
  String errorMessage;

  SubTaskStatusResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory SubTaskStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubTaskStatusResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) =>
              SubTaskStatusModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
