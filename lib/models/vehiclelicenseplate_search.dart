class VehicleLicenseplateSearch {
  int vehicleId;
  String vehicleLicenseplate;
  String vehicleBrand;
  String vehicleModel;
  String vehicleColor;
  int vehicleYear;
  int customerId;
  String customerFirstname;
  String customerLastname;
  String customerPhone;

  int get id => vehicleId;
  String get licensePlate => vehicleLicenseplate;
  String get brandName => vehicleBrand;
  String get modelName => vehicleModel;
  String get color => vehicleColor;
  int get year => vehicleYear;
  String get firstName => customerFirstname;
  String get lastName => customerLastname;
  String get phone => customerPhone;

  VehicleLicenseplateSearch({
    required this.vehicleId,
    required this.vehicleLicenseplate,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehicleYear,
    required this.customerId,
    required this.customerFirstname,
    required this.customerLastname,
    required this.customerPhone,
  });

  factory VehicleLicenseplateSearch.fromJson(Map<String, dynamic> json) {
    return VehicleLicenseplateSearch(
      vehicleId: json['id'] as int,
      vehicleLicenseplate: json['license_plate'] as String,
      vehicleBrand: json['brand_name'] as String,
      vehicleModel: json['model_name'] as String,
      vehicleColor: json['color'] as String,
      vehicleYear: json['year'] as int,
      customerId: json['cus_id'] as int,
      customerFirstname: json['first_name'] as String,
      customerLastname: json['last_name'] as String,
      customerPhone: json['phone'] as String,
    );
  }

  String get customerFullName => '$customerFirstname $customerLastname';
  String get vehicleSummary => vehicleBrand.isEmpty 
      ? '$vehicleLicenseplate - $vehicleModel ($vehicleColor)' 
      : '$vehicleLicenseplate - $vehicleBrand $vehicleModel ($vehicleColor)';
}

class VehicleLicenseplateSearchResponse {
  bool isError;
  List<VehicleLicenseplateSearch> data;
  List<OrderSearchModel> orders;
  String errorMessage;

  VehicleLicenseplateSearchResponse({
    required this.isError,
    required this.data,
    required this.orders,
    required this.errorMessage,
  });

  factory VehicleLicenseplateSearchResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>;
    final vehiclesList = dataMap['customersAndVehicles'] as List;
    final ordersList = dataMap['orders'] as List;
    return VehicleLicenseplateSearchResponse(
      isError: json['isError'] as bool,
      data: vehiclesList.map((item) => VehicleLicenseplateSearch.fromJson(item as Map<String, dynamic>)).toList(),
      orders: ordersList.map((item) => OrderSearchModel.fromJson(item as Map<String, dynamic>)).toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}

class OrderSearchModel {
  int orderId;
  int customerId;
  int vehicleId;
  int? employeeId;
  String orderSymptom;
  int statusId;
  int ordersPriorityId;
  double? laborCost;
  String? repairTime;
  String createdAt;

  int get id => orderId;
  String get symptom => orderSymptom;
  int get orderStatusId => statusId;
  int get priorityId => ordersPriorityId;

  OrderSearchModel({
    required this.orderId,
    required this.customerId,
    required this.vehicleId,
    this.employeeId,
    required this.orderSymptom,
    required this.statusId,
    required this.ordersPriorityId,
    this.laborCost,
    this.repairTime,
    required this.createdAt,
  });

  factory OrderSearchModel.fromJson(Map<String, dynamic> json) {
    return OrderSearchModel(
      orderId: json['id'] as int,
      customerId: json['cus_id'] as int,
      vehicleId: json['vehicle_id'] as int,
      employeeId: json['emp_id'] as int?,
      orderSymptom: json['symptom'] as String,
      statusId: json['status_id'] as int,
      ordersPriorityId: json['orders_priority_id'] as int,
      laborCost: json['labor_cost'] != null ? double.parse(json['labor_cost'].toString()) : null,
      repairTime: json['repair_time']?.toString(),
      createdAt: json['created_at'] as String,
    );
  }
}