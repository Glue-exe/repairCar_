class OrderModel {
  final int orderId;
  final String symptom;
  final String orderStatusName;
  final String createdAt;

  OrderModel({
    required this.orderId,
    required this.symptom,
    required this.orderStatusName,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['o_id'] as int,
      symptom: json['o_symptom'] as String,
      orderStatusName: json['os_name'] as String,
      createdAt: json['o_created_at'] as String,
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
