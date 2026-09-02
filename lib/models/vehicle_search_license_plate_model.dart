class VehicleSearchResultModel {
  final String fullName;
  final String licensePlate;
  final String modelName;
  final String brandName;
  final int year;
  final String color;

  VehicleSearchResultModel({
    required this.fullName,
    required this.licensePlate,
    required this.modelName,
    required this.brandName,
    required this.year,
    required this.color,
  });

  factory VehicleSearchResultModel.fromJson(Map<String, dynamic> json) {
    return VehicleSearchResultModel(
      fullName: json['fullname'] as String,
      licensePlate: json['v_license_plate'] as String,
      modelName: json['vm_name'] as String,
      brandName: json['vb_name'] as String,
      year: json['v_year'] as int,
      color: json['v_color'] as String,
    );
  }
}

class VehicleSearchResultResponse {
  bool isError;
  List<VehicleSearchResultModel> data;
  String errorMessage;

  VehicleSearchResultResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory VehicleSearchResultResponse.fromJson(Map<String, dynamic> json) {
    return VehicleSearchResultResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) =>
              VehicleSearchResultModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
