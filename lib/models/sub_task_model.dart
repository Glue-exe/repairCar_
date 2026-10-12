import 'package:my_app/models/order_pool_model.dart';

class SubTaskModel {
  int id;
  int orderId;
  int? serviceId;
  int? repairCategoryId;
  String? repairCategoryName;
  String name;
  double laborCost;
  int statusId;
  String statusName;
  bool acceptByMe;
  List<OrderTechnicianItemModel> technicians;

  SubTaskModel({
    required this.id,
    required this.orderId,
    required this.serviceId,
    this.repairCategoryId,
    this.repairCategoryName,
    required this.name,
    required this.laborCost,
    required this.statusId,
    required this.statusName,
    required this.acceptByMe,
    required this.technicians,
  });

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      serviceId: json['service_id'] as int?,
      repairCategoryId: json['repair_category_id'] as int?,
      repairCategoryName: json['repair_category_name'] as String?,
      name: json['name'] as String,
      laborCost: double.parse(json['labor_cost'].toString()),
      statusId: json['status_id'] as int,
      statusName: json['status_name'] as String,
      acceptByMe: json['accept_by_me'] as bool? ?? false,
      technicians: (json['technicians'] as List)
          .map(
            (item) =>
                OrderTechnicianItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
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
