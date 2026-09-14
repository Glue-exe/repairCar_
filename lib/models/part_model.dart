class PartModel {
  int id;
  String name;
  double price;
  String brand;

  PartModel({
    required this.id,
    required this.name,
    required this.price,
    required this.brand,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['part_id'] as int,
      name: json['part_name'] as String,
      price: double.parse(json['part_price'].toString()),
      brand: json['part_brand'] as String,
    );
  }
}

class PartResponse {
  bool isError;
  List<PartModel> data;
  String errorMessage;

  PartResponse({
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
      errorMessage: json['errorMessage'] as String,
    );
  }
}
