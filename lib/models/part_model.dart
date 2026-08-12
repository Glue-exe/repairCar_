class PartModel {
  int partId = 0;
  String partName = "";
  double partPrice = 0.0;
  String partBrand = "";

  PartModel({
    required this.partId,
    required this.partName,
    required this.partPrice,
    required this.partBrand,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      partId: json['part_id'] as int,
      partName: json['part_name'],
      partPrice: double.parse(json['part_price'].toString()),
      partBrand: json['part_brand'] as String,
    );
  }
}

class PartResponse {
  bool isError = false;
  List<PartModel> data = [];
  String errorMessage = "";

  PartResponse ({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory PartResponse.fromJson(Map<String, dynamic> json) {
    return PartResponse(
      isError: json['isError'] as bool,
     data: (json['data'] as List)
     .map((item) => PartModel.fromJson(item as Map<String, dynamic>))
     .toList(),
     errorMessage: json['errorMessage'] as String);
  }
}
