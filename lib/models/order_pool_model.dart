class OrderTechnicianItemModel {
  final int accountId;
  final String firstname;
  final String lastname;
  final String roleName;

  OrderTechnicianItemModel({
    required this.accountId,
    required this.firstname,
    required this.lastname,
    required this.roleName,
  });

  String get fullName {
    return '$firstname $lastname'.trim();
  }

  factory OrderTechnicianItemModel.fromJson(Map<String, dynamic> json) {
    return OrderTechnicianItemModel(
      accountId: json['account_id'] as int,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      roleName: json['role_name'] as String,
    );
  }
}

class OrderPoolItemModel {
  final int orderId;
  final int vehicleId;
  final String symptom;
  final int orderStatusId;
  final String orderStatusName;
  final int priorityId;
  final String priorityName;
  final String createdAt;
  final String licensePlate;
  final String color;
  final int year;
  final String brandName;
  final String modelName;
  final int customerId;
  final String customerFirstName;
  final String customerLastName;
  final String customerPhone;
  final int technicianCount;
  final List<OrderTechnicianItemModel> technicians;
  final List<String> images;

  OrderPoolItemModel({
    required this.orderId,
    required this.vehicleId,
    required this.symptom,
    required this.orderStatusId,
    required this.orderStatusName,
    required this.priorityId,
    required this.priorityName,
    required this.createdAt,
    required this.licensePlate,
    required this.color,
    required this.year,
    required this.brandName,
    required this.modelName,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerPhone,
    required this.technicianCount,
    required this.technicians,
    required this.images,
  });

  factory OrderPoolItemModel.fromJson(Map<String, dynamic> json) {
    return OrderPoolItemModel(
      orderId: json['o_id'] as int,
      vehicleId: json['o_vehicle_id'] as int,
      symptom: json['o_symptom'] as String,
      orderStatusId: json['o_order_status_id'] as int,
      orderStatusName: json['os_name'] as String,
      priorityId: json['o_priority_id'] as int,
      priorityName: json['priority_name'] as String,
      createdAt: json['o_created_at'] as String,
      licensePlate: json['v_license_plate'] as String,
      color: json['v_color'] as String,
      year: json['v_year'] as int,
      brandName: json['brand_name'] as String,
      modelName: json['model_name'] as String,
      customerId: json['cus_id'] as int,
      customerFirstName: json['cus_first_name'] as String,
      customerLastName: json['cus_last_name'] as String,
      customerPhone: json['cus_phone'] as String,
      technicianCount: json['technician_count'] as int,
      technicians: (json['technicians'] as List)
          .map((e) => OrderTechnicianItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List)
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class OrderPoolResponse {
  bool isError;
  List<OrderPoolItemModel> data;
  String errorMessage;

  OrderPoolResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory OrderPoolResponse.fromJson(Map<String, dynamic> json) {
    return OrderPoolResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => OrderPoolItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
