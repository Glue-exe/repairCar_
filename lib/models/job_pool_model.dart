// 1. Model สำหรับเก็บข้อมูลงานแต่ละรายการ (Item ใน List)
class JobPoolModel {
  // --- ข้อมูลของ Job Pool ---
  final int jopPoolId;
  final String poolStatus;
  final DateTime? claimedAt;

  // --- ข้อมูลใบสั่งซ่อม (Order) ---
  final int ordersId;
  final String orderSymptom;
  final DateTime? orderCreatedAt;

  // --- ข้อมูลสถานะและความสำคัญ ---
  final String? priorityName;
  final String? repairStatusName;

  // --- ข้อมูลลูกค้า ---
  final int? cusId;
  final String? customerName;
  final String? cusPhone;

  // --- ข้อมูลรถยนต์ ---
  final String? vehLicenseplate;
  final String? vehBrand;
  final String? vehModel;
  final String? vehColor;

  // --- ข้อมูลช่างผู้รับงาน ---
  final int? claimedByEmpId;
  final String? claimedByEmpName;

  // Constructor
  JobPoolModel({
    required this.jopPoolId,
    required this.poolStatus,
    this.claimedAt,
    required this.ordersId,
    required this.orderSymptom,
    this.orderCreatedAt,
    this.priorityName,
    this.repairStatusName,
    this.cusId,
    this.customerName,
    this.cusPhone,
    this.vehLicenseplate,
    this.vehBrand,
    this.vehModel,
    this.vehColor,
    this.claimedByEmpId,
    this.claimedByEmpName,
  });
  
  // Factory จาก JSON Map มาเป็น Object
  factory JobPoolModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedClaimedAt;
    if (json['claimed_at'] != null) {
      parsedClaimedAt = DateTime.tryParse(json['claimed_at'].toString());
    }

    DateTime? parsedOrderCreatedAt;
    if (json['order_created_at'] != null) {
      parsedOrderCreatedAt = DateTime.tryParse(json['order_created_at'].toString());
    }

    return JobPoolModel(
      // ข้อมูล Job Pool
      jopPoolId: json['jop_pool_id'] as int,
      poolStatus: json['pool_status']?.toString() ?? '',
      claimedAt: parsedClaimedAt,

      // ข้อมูล Order
      ordersId: json['orders_id'] as int,
      orderSymptom: json['order_symptom']?.toString() ?? '',
      orderCreatedAt: parsedOrderCreatedAt,

      // ข้อมูลสถานะ
      priorityName: json['priority_name']?.toString(),
      repairStatusName: json['repair_status_name']?.toString(),

      // ข้อมูลลูกค้า
      cusId: json['cus_id'] as int?,
      customerName: json['customer_name']?.toString(),
      cusPhone: json['cus_phone']?.toString(),

      // ข้อมูลรถยนต์
      vehLicenseplate: json['veh_licenseplate']?.toString(),
      vehBrand: json['veh_brand']?.toString(),
      vehModel: json['veh_model']?.toString(),
      vehColor: json['veh_color']?.toString(),

      // ข้อมูลช่าง
      claimedByEmpId: json['claimed_by_emp_id'] as int?,
      claimedByEmpName: json['claimed_by_emp_name']?.toString(),
    );
  }
}



// 2. Model สำหรับห่อหุ้มโครงสร้างการตอบกลับจาก API
class JobPoolResponse {
  final bool isError;
  final String errorMessage;
  final List<JobPoolModel> data;

  JobPoolResponse({
    required this.isError,
    required this.errorMessage,
    required this.data,
  });

  factory JobPoolResponse.fromJson(Map<String, dynamic> json) {
    return JobPoolResponse(
      isError: json['isError'] as bool? ?? false,
      errorMessage: json['errorMessage']?.toString() ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => JobPoolModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}