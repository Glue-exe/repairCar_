class AccountantSummaryModel {
  final double totalPendingAmount;
  final int pendingCount;
  final double totalPaidAmount;
  final int paidCount;

  AccountantSummaryModel({
    required this.totalPendingAmount,
    required this.pendingCount,
    required this.totalPaidAmount,
    required this.paidCount,
  });

  factory AccountantSummaryModel.fromJson(Map<String, dynamic> json) {
    return AccountantSummaryModel(
      totalPendingAmount: ((json['totalPendingAmount'] ?? 0) as num).toDouble(),
      pendingCount: (json['pendingCount'] ?? 0) as int,
      totalPaidAmount: ((json['totalPaidAmount'] ?? 0) as num).toDouble(),
      paidCount: (json['paidCount'] ?? 0) as int,
    );
  }
}

class AccountantSummaryResponse {
  final bool isError;
  final AccountantSummaryModel data;
  final String errorMessage;

  AccountantSummaryResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory AccountantSummaryResponse.fromJson(Map<String, dynamic> json) {
    return AccountantSummaryResponse(
      isError: json['isError'] ?? false,
      data: AccountantSummaryModel.fromJson(json['data'] ?? {}),
      errorMessage: json['errorMessage'] ?? '',
    );
  }
}

class AccountantOrderItemModel {
  final int orderId;
  final String symptom;
  final String createdAt;
  final int orderStatusId;
  final String orderStatusName;
  final String priorityName;

  final int vehicleId;
  final String licensePlate;
  final String color;
  final int? year;
  final String brandName;
  final String modelName;

  final int customerId;
  final String customerFirstName;
  final String customerLastName;
  final String customerPhone;

  final int? invoiceId;
  final double laborTotal;
  final double partsTotal;
  final double totalAmount;

  final int paymentStatusId;
  final String paymentStatusName;
  final int? paymentMethodId;
  final String? paymentMethodName;
  final String? paidAt;

  AccountantOrderItemModel({
    required this.orderId,
    required this.symptom,
    required this.createdAt,
    required this.orderStatusId,
    required this.orderStatusName,
    required this.priorityName,
    required this.vehicleId,
    required this.licensePlate,
    required this.color,
    this.year,
    required this.brandName,
    required this.modelName,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerPhone,
    this.invoiceId,
    required this.laborTotal,
    required this.partsTotal,
    required this.totalAmount,
    required this.paymentStatusId,
    required this.paymentStatusName,
    this.paymentMethodId,
    this.paymentMethodName,
    this.paidAt,
  });

  String get customerFullName => '$customerFirstName $customerLastName'.trim();
  String get carTitle => '$brandName $modelName'.trim().isNotEmpty ? '$brandName $modelName'.trim() : 'รถยนต์ลูกค้า';

  factory AccountantOrderItemModel.fromJson(Map<String, dynamic> json) {
    return AccountantOrderItemModel(
      orderId: json['order_id'] ?? 0,
      symptom: json['symptom'] ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      orderStatusId: json['order_status_id'] ?? 1,
      orderStatusName: json['order_status_name'] ?? 'รอดำเนินการ',
      priorityName: json['priority_name'] ?? 'ปกติ',
      vehicleId: json['vehicle_id'] ?? 0,
      licensePlate: json['license_plate'] ?? '-',
      color: json['color'] ?? '-',
      year: json['year'] as int?,
      brandName: json['brand_name'] ?? '',
      modelName: json['model_name'] ?? '',
      customerId: json['customer_id'] ?? 0,
      customerFirstName: json['customer_first_name'] ?? '',
      customerLastName: json['customer_last_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      invoiceId: json['invoice_id'] as int?,
      laborTotal: ((json['labor_total'] ?? 0) as num).toDouble(),
      partsTotal: ((json['parts_total'] ?? 0) as num).toDouble(),
      totalAmount: ((json['total_amount'] ?? 0) as num).toDouble(),
      paymentStatusId: json['payment_status_id'] ?? 1,
      paymentStatusName: json['payment_status_name'] ?? 'รอชำระ',
      paymentMethodId: json['payment_method_id'] as int?,
      paymentMethodName: json['payment_method_name'] as String?,
      paidAt: json['paid_at']?.toString(),
    );
  }
}

class AccountantOrdersResponse {
  final bool isError;
  final List<AccountantOrderItemModel> data;
  final String errorMessage;

  AccountantOrdersResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory AccountantOrdersResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['data'] as List? ?? [];
    List<AccountantOrderItemModel> items = rawList
        .map((item) => AccountantOrderItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return AccountantOrdersResponse(
      isError: json['isError'] ?? false,
      data: items,
      errorMessage: json['errorMessage'] ?? '',
    );
  }
}

class PaymentMethodModel {
  final int id;
  final String name;

  PaymentMethodModel({required this.id, required this.name});

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class PaymentMethodsResponse {
  final bool isError;
  final List<PaymentMethodModel> data;
  final String errorMessage;

  PaymentMethodsResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory PaymentMethodsResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['data'] as List? ?? [];
    return PaymentMethodsResponse(
      isError: json['isError'] ?? false,
      data: rawList.map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>)).toList(),
      errorMessage: json['errorMessage'] ?? '',
    );
  }
}
