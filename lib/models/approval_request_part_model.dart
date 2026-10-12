class ApprovalRequestPartModel {
  final int id;
  final int statusId;
  final String statusName;
  final int requestedByAccountId;
  final String requesterName;
  final String requestedAt;
  final int orderId;
  final String licensePlate;
  final String vehicleName;
  final String customerName;
  final String subTaskName;
  final int partId;
  final String partName;
  final String? partBrand;
  final String? imageUrl;
  final int quantity;
  final double price;

  ApprovalRequestPartModel({
    required this.id,
    required this.statusId,
    required this.statusName,
    required this.requestedByAccountId,
    required this.requesterName,
    required this.requestedAt,
    required this.orderId,
    required this.licensePlate,
    required this.vehicleName,
    required this.customerName,
    required this.subTaskName,
    required this.partId,
    required this.partName,
    this.partBrand,
    this.imageUrl,
    required this.quantity,
    required this.price,
  });

  double get totalPrice => price * quantity;

  factory ApprovalRequestPartModel.fromJson(Map<String, dynamic> json) {
    return ApprovalRequestPartModel(
      id: json['id'] as int,
      statusId: json['status_id'] as int,
      statusName: json['status_name'] as String,
      requestedByAccountId: json['requested_by_account_id'] as int,
      requesterName: json['requester_name'] as String,
      requestedAt: json['requested_at'] as String,
      orderId: json['order_id'] as int,
      licensePlate: json['license_plate'] as String,
      vehicleName: json['vehicle_name'] as String,
      customerName: json['customer_name'] as String,
      subTaskName: json['sub_task_name'] as String,
      partId: json['part_id'] as int,
      partName: json['part_name'] as String,
      partBrand: json['part_brand'] as String?,
      imageUrl: json['part_url'] as String?,
      quantity: json['quantity'] as int,
      price: double.parse(json['price'].toString()),
    );
  }
}
