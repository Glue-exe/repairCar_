class VehicleBrandModel {
  int vbId;
  String vbName;

  VehicleBrandModel({
    required this.vbId,
    required this.vbName,
  });

  factory VehicleBrandModel.fromJson(Map<String, dynamic> json) {
    return VehicleBrandModel(
      vbId: json['vb_id'] as int,
      vbName: json['vb_name'] as String,
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
