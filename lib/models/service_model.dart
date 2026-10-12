class ServiceModel {
  int id;
  String name;
  String? detail;
  double laborCost;
  String? serviceUrl;
  bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    this.detail,
    required this.laborCost,
    this.serviceUrl,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      detail: json['detail'] as String?,
      laborCost: double.parse(json['labor_cost'].toString()),
      serviceUrl: json['service_url'] as String?,
      isActive: json['is_active'] as bool,
    );
  }
}

class ServiceResponse {
  bool isError;
  List<ServiceModel> data;
  String errorMessage;

  ServiceResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    return ServiceResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
