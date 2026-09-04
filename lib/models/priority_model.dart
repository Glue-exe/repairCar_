class PriorityModel {
  int id;
  String name;

  PriorityModel({
    required this.id,
    required this.name,
  });

  factory PriorityModel.fromJson(Map<String, dynamic> json) {
    return PriorityModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class PriorityResponse {
  bool isError;
  List<PriorityModel> data;
  String errorMessage;

  PriorityResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory PriorityResponse.fromJson(Map<String, dynamic> json) {
    return PriorityResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => PriorityModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
