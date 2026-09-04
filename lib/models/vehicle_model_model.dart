class VehicleModelModel {
  int id;
  String name;
  int brandId;
  String brandName;

  VehicleModelModel({
    required this.id,
    required this.name,
    required this.brandId,
    required this.brandName,
  });

  factory VehicleModelModel.fromJson(Map<String, dynamic> json) {
    return VehicleModelModel(
      id: json['id'] as int,
      name: json['name'] as String,
      brandId: json['brand_id'] as int,
      brandName: json['brand_name'] as String,
    );
  }
}

class VehicleModelResponse {
  bool isError;
  List<VehicleModelModel> data;
  String errorMessage;

  VehicleModelResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory VehicleModelResponse.fromJson(Map<String, dynamic> json) {
    return VehicleModelResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) =>
              VehicleModelModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
