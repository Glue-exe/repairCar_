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
      type: json['type'] as String,
      subTaskId: json['sub_task_id'] as int?,
      partId: json['part_id'] as int?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      unit: json['unit'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: double.parse(json['unit_price'].toString()),
      total: double.parse(json['total'].toString()),
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
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      partsTotal: double.parse(json['parts_total'].toString()),
      laborTotal: double.parse(json['labor_total'].toString()),
      total: double.parse(json['total'].toString()),
      paymentMethodId: json['payment_method_id'] as int?,
      paymentMethod: json['payment_method'] as String?,
      paymentStatusId: json['payment_status_id'] as int,
      paymentStatus: json['payment_status'] as String,
      createdAt: json['created_at'] as String,
      imageUrl: json['image_url'] as String?,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      licensePlate: json['license_plate'] as String,
      vehicleName: json['vehicle_name'] as String,
      lines: (json['lines'] as List)
          .map((e) => Invoice2LineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
