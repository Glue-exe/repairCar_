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
  final String? invoiceImageUrl;
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
    this.invoiceImageUrl,
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
      invoiceImageUrl: json['invoice_image_url']?.toString(),
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

class RevenueReportSummaryModel {
  final double totalPaidAmount;
  final int paidCount;
  final double totalLaborAmount;
  final double totalPartsAmount;
  final double cashTotalAmount;
  final int cashCount;
  final double transferTotalAmount;
  final int transferCount;

  RevenueReportSummaryModel({
    required this.totalPaidAmount,
    required this.paidCount,
    required this.totalLaborAmount,
    required this.totalPartsAmount,
    required this.cashTotalAmount,
    required this.cashCount,
    required this.transferTotalAmount,
    required this.transferCount,
  });

  factory RevenueReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return RevenueReportSummaryModel(
      totalPaidAmount: ((json['total_paid_amount'] ?? 0) as num).toDouble(),
      paidCount: (json['paid_count'] ?? 0) as int,
      totalLaborAmount: ((json['total_labor_amount'] ?? 0) as num).toDouble(),
      totalPartsAmount: ((json['total_parts_amount'] ?? 0) as num).toDouble(),
      cashTotalAmount: ((json['cash_total_amount'] ?? 0) as num).toDouble(),
      cashCount: (json['cash_count'] ?? 0) as int,
      transferTotalAmount: ((json['transfer_total_amount'] ?? 0) as num).toDouble(),
      transferCount: (json['transfer_count'] ?? 0) as int,
    );
  }
}

class RevenueTrendItemModel {
  final String timeBucket;
  final double totalAmount;
  final double laborAmount;
  final double partsAmount;
  final int count;

  RevenueTrendItemModel({
    required this.timeBucket,
    required this.totalAmount,
    required this.laborAmount,
    required this.partsAmount,
    required this.count,
  });

  factory RevenueTrendItemModel.fromJson(Map<String, dynamic> json) {
    return RevenueTrendItemModel(
      timeBucket: json['time_bucket']?.toString() ?? '',
      totalAmount: ((json['total_amount'] ?? 0) as num).toDouble(),
      laborAmount: ((json['labor_amount'] ?? 0) as num).toDouble(),
      partsAmount: ((json['parts_amount'] ?? 0) as num).toDouble(),
      count: (json['count'] ?? 0) as int,
    );
  }
}

class RevenueTransactionItemModel {
  final int invoiceId;
  final int orderId;
  final String paidAt;
  final double totalAmount;
  final double laborTotal;
  final double partsTotal;
  final int? paymentMethodId;
  final String paymentMethodName;
  final String? invoiceImageUrl;
  final String licensePlate;
  final String brandName;
  final String modelName;
  final String customerName;
  final String customerPhone;

  RevenueTransactionItemModel({
    required this.invoiceId,
    required this.orderId,
    required this.paidAt,
    required this.totalAmount,
    required this.laborTotal,
    required this.partsTotal,
    this.paymentMethodId,
    required this.paymentMethodName,
    this.invoiceImageUrl,
    required this.licensePlate,
    required this.brandName,
    required this.modelName,
    required this.customerName,
    required this.customerPhone,
  });

  String get carTitle => '$brandName $modelName'.trim().isNotEmpty ? '$brandName $modelName'.trim() : 'รถยนต์ลูกค้า';

  factory RevenueTransactionItemModel.fromJson(Map<String, dynamic> json) {
    return RevenueTransactionItemModel(
      invoiceId: json['invoice_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      paidAt: json['paid_at']?.toString() ?? '',
      totalAmount: ((json['total_amount'] ?? 0) as num).toDouble(),
      laborTotal: ((json['labor_total'] ?? 0) as num).toDouble(),
      partsTotal: ((json['parts_total'] ?? 0) as num).toDouble(),
      paymentMethodId: json['payment_method_id'] as int?,
      paymentMethodName: json['payment_method_name'] ?? 'ไม่ระบุ',
      invoiceImageUrl: json['invoice_image_url'] as String?,
      licensePlate: json['license_plate'] ?? '-',
      brandName: json['brand_name'] ?? '',
      modelName: json['model_name'] ?? '',
      customerName: json['customer_name'] ?? '-',
      customerPhone: json['customer_phone'] ?? '-',
    );
  }

  AccountantOrderItemModel toOrderItemModel() {
    return AccountantOrderItemModel(
      orderId: orderId,
      symptom: '',
      createdAt: paidAt,
      orderStatusId: 4,
      orderStatusName: 'ส่งมอบรถคืนเรียบร้อย',
      priorityName: 'ปกติ',
      vehicleId: 0,
      licensePlate: licensePlate,
      color: '-',
      brandName: brandName,
      modelName: modelName,
      customerId: 0,
      customerFirstName: customerName,
      customerLastName: '',
      customerPhone: customerPhone,
      invoiceId: invoiceId,
      invoiceImageUrl: invoiceImageUrl,
      laborTotal: laborTotal,
      partsTotal: partsTotal,
      totalAmount: totalAmount,
      paymentStatusId: 2,
      paymentStatusName: 'ชำระแล้ว',
      paymentMethodId: paymentMethodId,
      paymentMethodName: paymentMethodName,
      paidAt: paidAt,
    );
  }
}

class RevenueReportDataModel {
  final RevenueReportSummaryModel summary;
  final List<RevenueTrendItemModel> trends;
  final List<RevenueTransactionItemModel> transactions;

  RevenueReportDataModel({
    required this.summary,
    required this.trends,
    required this.transactions,
  });

  factory RevenueReportDataModel.fromJson(Map<String, dynamic> json) {
    var rawTrends = json['trends'] as List? ?? [];
    var rawTrans = json['transactions'] as List? ?? [];
    return RevenueReportDataModel(
      summary: RevenueReportSummaryModel.fromJson(json['summary'] ?? {}),
      trends: rawTrends.map((e) => RevenueTrendItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      transactions: rawTrans.map((e) => RevenueTransactionItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class RevenueReportResponse {
  final bool isError;
  final RevenueReportDataModel? data;
  final String errorMessage;

  RevenueReportResponse({
    required this.isError,
    this.data,
    required this.errorMessage,
  });

  factory RevenueReportResponse.fromJson(Map<String, dynamic> json) {
    return RevenueReportResponse(
      isError: json['isError'] ?? false,
      data: json['data'] != null ? RevenueReportDataModel.fromJson(json['data']) : null,
      errorMessage: json['errorMessage'] ?? '',
    );
  }
}

