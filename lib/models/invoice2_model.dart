// บิล (invoice2): หัวบิล + บรรทัดที่คำนวณสดจากต้นทาง
// (ยอดเงิน/รายการไม่ถูกเก็บในตาราง invoice — มาจาก sub_task ที่เสร็จสิ้น + อะไหล่ที่อนุมัติ)
class Invoice2LineModel {
  final String type; // 'labor' = ค่าแรง, 'part' = อะไหล่
  final int? subTaskId;
  final int? partId;
  final String name;
  final String? brand;
  final String? unit;
  final int quantity;
  final double unitPrice;
  final double total;

  Invoice2LineModel({
    required this.type,
    this.subTaskId,
    this.partId,
    required this.name,
    this.brand,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  bool get isLabor => type == 'labor';

  factory Invoice2LineModel.fromJson(Map<String, dynamic> json) {
    return Invoice2LineModel(
      type: json['type']?.toString() ?? 'labor',
      subTaskId: json['sub_task_id'] != null ? int.tryParse(json['sub_task_id'].toString()) : null,
      partId: json['part_id'] != null ? int.tryParse(json['part_id'].toString()) : null,
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString(),
      unit: json['unit']?.toString(),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : (int.tryParse(json['quantity']?.toString() ?? '1') ?? 1),
      unitPrice: (json['unit_price'] is num)
          ? (json['unit_price'] as num).toDouble()
          : (double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0),
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : (double.tryParse(json['total']?.toString() ?? '0') ?? 0.0),
    );
  }
}

class Invoice2Model {
  final int id;
  final int orderId;
  final double partsTotal;
  final double laborTotal;
  final double total;
  final int? paymentMethodId;
  final String? paymentMethod;
  final int paymentStatusId;
  final String paymentStatus;
  final String createdAt;
  final String? imageUrl;
  final String customerName;
  final String customerPhone;
  final String licensePlate;
  final String vehicleName;
  final List<Invoice2LineModel> lines;

  Invoice2Model({
    required this.id,
    required this.orderId,
    required this.partsTotal,
    required this.laborTotal,
    required this.total,
    this.paymentMethodId,
    this.paymentMethod,
    required this.paymentStatusId,
    required this.paymentStatus,
    required this.createdAt,
    this.imageUrl,
    required this.customerName,
    required this.customerPhone,
    required this.licensePlate,
    required this.vehicleName,
    required this.lines,
  });

  factory Invoice2Model.fromJson(Map<String, dynamic> json) {
    return Invoice2Model(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      partsTotal: (json['parts_total'] is num)
          ? (json['parts_total'] as num).toDouble()
          : (double.tryParse(json['parts_total']?.toString() ?? '0') ?? 0.0),
      laborTotal: (json['labor_total'] is num)
          ? (json['labor_total'] as num).toDouble()
          : (double.tryParse(json['labor_total']?.toString() ?? '0') ?? 0.0),
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : (double.tryParse(json['total']?.toString() ?? '0') ?? 0.0),
      paymentMethodId: json['payment_method_id'] != null
          ? int.tryParse(json['payment_method_id'].toString())
          : null,
      paymentMethod: json['payment_method']?.toString(),
      paymentStatusId: int.tryParse(json['payment_status_id']?.toString() ?? '1') ?? 1,
      paymentStatus: json['payment_status']?.toString() ?? 'รอชำระเงิน',
      createdAt: json['created_at']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      licensePlate: json['license_plate']?.toString() ?? '',
      vehicleName: json['vehicle_name']?.toString() ?? '',
      lines: json['lines'] is List
          ? (json['lines'] as List)
              .map((e) => Invoice2LineModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
