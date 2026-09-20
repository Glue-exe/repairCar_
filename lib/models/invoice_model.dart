class InvoicePartModel {
  int id;
  String name;
  String brand;
  int quantity;
  double unitPrice;
  double totalPrice;

  InvoicePartModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoicePartModel.fromJson(Map<String, dynamic> json) {
    return InvoicePartModel(
      id: json['id'] as int,
      name: json['name'] as String,
      brand: json['brand'] as String,
      quantity: json['quantity'] as int,
      unitPrice: double.parse(json['unit_price'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
    );
  }
}

class InvoiceSubTaskModel {
  int id;
  String name;
  double laborCost;
  List<InvoicePartModel> parts;

  InvoiceSubTaskModel({
    required this.id,
    required this.name,
    required this.laborCost,
    required this.parts,
  });

  factory InvoiceSubTaskModel.fromJson(Map<String, dynamic> json) {
    return InvoiceSubTaskModel(
      id: json['id'] as int,
      name: json['name'] as String,
      laborCost: double.parse(json['labor_cost'].toString()),
      parts: (json['parts'] as List)
          .map((item) => InvoicePartModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InvoiceModel {
  int invoiceNo;
  String customerName;
  String customerPhone;
  String licensePlate;
  String vehicleName;
  String createdAt;
  double laborTotal;
  double partsTotal;
  double total;
  String paymentMethod;
  String paymentStatus;
  List<InvoiceSubTaskModel> subTasks;

  InvoiceModel({
    required this.invoiceNo,
    required this.customerName,
    required this.customerPhone,
    required this.licensePlate,
    required this.vehicleName,
    required this.createdAt,
    required this.laborTotal,
    required this.partsTotal,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subTasks,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceNo: json['invoice_no'] as int,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      licensePlate: json['license_plate'] as String,
      vehicleName: json['vehicle_name'] as String,
      createdAt: json['created_at'] as String,
      laborTotal: double.parse(json['labor_total'].toString()),
      partsTotal: double.parse(json['parts_total'].toString()),
      total: double.parse(json['total'].toString()),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      subTasks: (json['sub_tasks'] as List)
          .map((item) => InvoiceSubTaskModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InvoiceResponse {
  bool isError;
  InvoiceModel data;
  String errorMessage;

  InvoiceResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceResponse(
      isError: json['isError'] as bool,
      data: InvoiceModel.fromJson(json['data'] as Map<String, dynamic>),
      errorMessage: json['errorMessage'] as String,
    );
  }
}