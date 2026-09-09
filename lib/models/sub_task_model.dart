class SubTaskModel {
  int id;
  int orderId;
  int serviceId;
  String name;
  double laborCost;
  int statusId;
  String statusName;
  int technicianAccountId;
  String technicianFirstName;
  String technicianLastName;

  SubTaskModel({
    required this.id,
    required this.orderId,
    required this.serviceId,
    required this.name,
    required this.laborCost,
    required this.statusId,
    required this.statusName,
    required this.technicianAccountId,
    required this.technicianFirstName,
    required this.technicianLastName,
  });

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      serviceId: json['service_id'] as int,
      name: json['name'] as String,
      laborCost: double.parse(json['labor_cost'].toString()),
      statusId: json['status_id'] as int,
      statusName: json['status_name'] as String,
      technicianAccountId: json['technician_account_id'] as int,
      technicianFirstName: json['technician_first_name'] as String,
      technicianLastName: json['technician_last_name'] as String,
    );
  }
}

class SubTaskResponse {
  bool isError;
  List<SubTaskModel> data;
  String errorMessage;

  SubTaskResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory SubTaskResponse.fromJson(Map<String, dynamic> json) {
    return SubTaskResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => SubTaskModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
