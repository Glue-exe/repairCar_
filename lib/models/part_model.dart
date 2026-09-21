class PartModel {
  int id;
  String name;
  double price;
  String brand;
  String? url;
  int? vehModelId;
  String? modelName;
  String? vehicleBrandName;

  PartModel({
    required this.id,
    required this.name,
    required this.price,
    required this.brand,
    this.url,
    this.vehModelId,
    this.modelName,
    this.vehicleBrandName,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['part_id'] as int,
      name: json['part_name'] as String,
      price: double.parse(json['part_price'].toString()),
      brand: json['part_brand'] as String,
      url: json['part_url'] as String?,
      vehModelId: json['veh_model_id'] != null
          ? int.tryParse(json['veh_model_id'].toString())
          : null,
      modelName: json['model_name'] as String?,
      vehicleBrandName: json['vehicle_brand_name'] as String?,
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
