class OrderStatusModel {
  final int id;
  final String name;

  OrderStatusModel({
    required this.id,
    required this.name,
  });

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class OrderStatusResponse {
  bool isError;
  List<OrderStatusModel> data;
  String errorMessage;

  OrderStatusResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory OrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return OrderStatusResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => OrderStatusModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
