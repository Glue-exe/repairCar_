class PaymentMethodModel {
  int id;
  String name;

  PaymentMethodModel({
    required this.id,
    required this.name,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class PaymentMethodResponse {
  bool isError;
  List<PaymentMethodModel> data;
  String errorMessage;

  PaymentMethodResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory PaymentMethodResponse.fromJson(Map<String, dynamic> json) {
    return PaymentMethodResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) =>
              PaymentMethodModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
