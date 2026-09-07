class OrderModel {
  final int orderId;
  final int vehicleId;
  final String symptom;
  final int orderStatusId;
  final String orderStatusName;
  final String createdAt;
  final List<String> images;

  OrderModel({
    required this.orderId,
    required this.vehicleId,
    required this.symptom,
    required this.orderStatusId,
    required this.orderStatusName,
    required this.createdAt,
    this.images = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['o_id'] as int,
      vehicleId: json['o_vehicle_id'] as int,
      symptom: json['o_symptom'] as String,
      orderStatusId: json['o_order_status_id'] as int,
      orderStatusName: json['os_name'] as String,
      createdAt: json['o_created_at'] as String,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class OrderResponse {
  bool isError;
  List<OrderModel> data;
  String errorMessage;

  OrderResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
