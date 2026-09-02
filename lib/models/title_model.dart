class TitleModel {
  int id;
  String name;

  // Getters for legacy compatibility
  int get titleId => id;
  String get titleName => name;

  TitleModel({
    required this.id,
    required this.name,
  });

  factory TitleModel.fromJson(Map<String, dynamic> json) {
    return TitleModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class TitleResponse {
  bool isError;
  List<TitleModel> data;
  String errorMessage;

  TitleResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory TitleResponse.fromJson(Map<String, dynamic> json) {
    return TitleResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => TitleModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}