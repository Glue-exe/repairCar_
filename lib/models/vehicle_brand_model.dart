class VehicleBrandModel {
  int id;
  String name;

  VehicleBrandModel({
    required this.id,
    required this.name,
  });

  factory VehicleBrandModel.fromJson(Map<String, dynamic> json) {
    return VehicleBrandModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class VehicleBrandResponse {
  bool isError;
  List<VehicleBrandModel> data;
  String errorMessage;

  VehicleBrandResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory VehicleBrandResponse.fromJson(Map<String, dynamic> json) {
    return VehicleBrandResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) =>
              VehicleBrandModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
