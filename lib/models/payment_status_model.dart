class PaymentStatusModel {
  int id;
  String name;

  PaymentStatusModel({
    required this.id,
    required this.name,
  });

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) {
    return PaymentStatusModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class PaymentStatusResponse {
  bool isError;
  List<PaymentStatusModel> data;
  String errorMessage;

  PaymentStatusResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) =>
              PaymentStatusModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
