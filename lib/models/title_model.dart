class TitleModel {
  int titleId = 0;
  String titleName = "";

  TitleModel ({
    required this.titleId,
    required this.titleName
  });

  factory TitleModel.fromJson(Map<String, dynamic> json) {
    return TitleModel(
      titleId: json["title_id"] as int,
      titleName: json["title_name"] as String,
    );
  }
}

class TitleResponse {
  bool isError = false;
  List<TitleModel> data = [];
  String errorMessage = "";

  TitleResponse ({
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
      errorMessage: json['errorMessage'] as String);
  }
}