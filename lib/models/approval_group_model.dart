import 'package:my_app/models/approval_request_part_model.dart';

// ใบเบิก 1 ใบ (รวมรายการอะไหล่)
class ApprovalGroup {
  int id;
  int statusId;
  String statusName;
  String requesterName;
  String requestedAt;
  int orderId;
  String licensePlate;
  String vehicleName;
  int? vehicleYear;
  String? vehicleColor;
  String customerName;
  String customerPhone;
  String subTaskName;
  List<ApprovalRequestPartModel> items = [];

  ApprovalGroup({
    required this.id,
    required this.statusId,
    required this.statusName,
    required this.requesterName,
    required this.requestedAt,
    required this.orderId,
    required this.licensePlate,
    required this.vehicleName,
    required this.vehicleYear,
    this.vehicleColor,
    required this.customerName,
    required this.customerPhone,
    required this.subTaskName,
  });

  factory ApprovalGroup.fromJson(Map<String, dynamic> json) {
    return ApprovalGroup(
      id: json['id'] as int,
      statusId: json['status_id'] as int,
      statusName: json['status_name'] as String,
      requesterName: json['requester_name'] as String,
      requestedAt: json['requested_at'] as String,
      orderId: json['order_id'] as int,
      licensePlate: json['license_plate'] as String,
      vehicleName: json['vehicle_name'] as String,
      vehicleYear: json['vehicle_year'] as int?,
      vehicleColor: json['vehicle_color'] as String?,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      subTaskName: json['sub_task_name'] as String,
    );
  }

  double get total => items.fold(0, (sum, item) => sum + item.totalPrice);
}
