class VehicleModelModel {
  int vmId;
  String vmName;
  int vmBrandId;
  String vbName;

  VehicleModelModel({
    required this.vmId,
    required this.vmName,
    required this.vmBrandId,
    required this.vbName,
  });

  factory VehicleModelModel.fromJson(Map<String, dynamic> json) {
    return VehicleModelModel(
      vmId: json['vm_id'] as int,
      vmName: json['vm_name'] as String,
      vmBrandId: json['vm_brand_id'] as int,
      vbName: json['vb_name'] as String,
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
