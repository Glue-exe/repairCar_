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
      vehicleId: json['veh_id'] as int,
      vehicleLicenseplate: json['veh_licenseplate'] as String,
      vehicleBrand: (json['brand_name'] as String?) ?? '',
      vehicleModel: json['veh_model'] as String,
      vehicleColor: json['veh_color'] as String,
      vehicleYear: json['veh_year'] as int,
      customerId: json['cus_id'] as int,
      customerFirstname: json['cus_firstname'] as String,
      customerLastname: json['cus_lastname'] as String,
      customerPhone: json['cus_phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'veh_id': vehicleId,
      'veh_licenseplate': vehicleLicenseplate,
      'brand_name': vehicleBrand,
      'veh_model': vehicleModel,
      'veh_color': vehicleColor,
      'veh_year': vehicleYear,
      'cus_id': customerId,
      'cus_firstname': customerFirstname,
      'cus_lastname': customerLastname,
      'cus_phone': customerPhone,
    };
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
    final dataMap = json['data'] as Map<String, dynamic>?;
    final vehiclesList = dataMap != null ? (dataMap['customersAndVehicles'] as List?) : null;
    final ordersList = dataMap != null ? (dataMap['orders'] as List?) : null;
    return VehicleLicenseplateSearchResponse(
      isError: json['isError'] as bool,
      data: vehiclesList != null
          ? vehiclesList.map((item) => VehicleLicenseplateSearch.fromJson(item as Map<String, dynamic>)).toList()
          : [],
      orders: ordersList != null
          ? ordersList.map((item) => OrderSearchModel.fromJson(item as Map<String, dynamic>)).toList()
          : [],
      errorMessage: json['errorMessage'] as String? ?? '',
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
      orderId: json['orders_id'] as int,
      customerId: json['cus_id'] as int,
      vehicleId: json['veh_id'] as int,
      employeeId: json['emp_id'] as int?,
      orderSymptom: json['order_symptom'] as String? ?? '',
      statusId: json['status_id'] as int,
      ordersPriorityId: json['orders_priority_id'] as int,
      laborCost: json['labor_cost'] != null ? double.parse(json['labor_cost'].toString()) : null,
      repairTime: json['repair_time']?.toString(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}