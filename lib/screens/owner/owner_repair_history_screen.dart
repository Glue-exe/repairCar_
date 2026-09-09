import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/order_pool_model.dart';
import 'package:my_app/models/order_status_model.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_status_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_vehicle_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_symptom_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_images_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_technician_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_sub_task_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_invoice_widget.dart';

class OwnerRepairHistoryScreen extends StatefulWidget {
  final OrderModel order;
  final VehicleSearchResultModel vehicle;

  const OwnerRepairHistoryScreen({
    super.key,
    required this.order,
    required this.vehicle,
  });

  @override
  State<OwnerRepairHistoryScreen> createState() => _OwnerRepairHistoryScreenState();
}

class _OwnerRepairHistoryScreenState extends State<OwnerRepairHistoryScreen> {
  List<OrderTechnicianItemModel> _technicians = [];
  List<OrderStatusModel> _statuses = [];
  int _currentStatusId = 0;

  @override
  void initState() {
    super.initState();
    _currentStatusId = widget.order.orderStatusId;
    _technicians = List<OrderTechnicianItemModel>.from(widget.order.technicians);
    _fetchStatuses();
    _fetchTechnicians();
  }

  Future<void> _fetchStatuses() async {
    final response = await AppAPI.get('/order_status');
    final Map<String, dynamic> json = jsonDecode(response.body);
    final res = OrderStatusResponse.fromJson(json);
    setState(() {
      _statuses = res.data;
    });
  }

  Future<void> _fetchTechnicians() async {
    final response = await AppAPI.get('/order/technicians?order_id=${widget.order.orderId}');
    final Map<String, dynamic> json = jsonDecode(response.body);
    final list = (json['data'] as List)
        .map((item) => OrderTechnicianItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    setState(() {
      _technicians = list;
    });
  }

  // กล่องยืนยันการทำรายการ
  Future<bool> _showConfirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  // อัปเดตสถานะงานซ่อม
  Future<void> _handleStatusChange(int newStatusId) async {
    final newStatus = _statuses.firstWhere((s) => s.id == newStatusId);

    bool confirm = await _showConfirm(
      'ยืนยันการเปลี่ยนสถานะ',
      'ต้องการเปลี่ยนสถานะเป็น "${newStatus.name}" หรือไม่?',
    );
    if (!confirm) return;

    await AppAPI.post('/order/update_status', {
      'order_id': widget.order.orderId,
      'status_id': newStatusId,
    });

    setState(() {
      _currentStatusId = newStatusId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยนสถานะเป็น "${newStatus.name}" เรียบร้อยแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ใบรับซ่อม #${widget.order.orderId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // สถานะและวันที่ใบรับซ่อม
            RepairHistoryStatusWidget(
              order: widget.order,
              currentStatusId: _currentStatusId,
              statuses: _statuses,
              onStatusChanged: _handleStatusChange,
            ),
            const SizedBox(height: 16),

            // ข้อมูลรถยนต์และเจ้าของรถ
            RepairHistoryVehicleWidget(vehicle: widget.vehicle),
            const SizedBox(height: 16),

            // อาการเสีย / รายการที่ต้องซ่อม
            RepairHistorySymptomWidget(symptom: widget.order.symptom),
            const SizedBox(height: 16),

            // รูปถ่ายชิ้นส่วน / สภาพรถ
            RepairHistoryImagesWidget(images: widget.order.images),
            const SizedBox(height: 16),

            // ช่างผู้รับผิดชอบ order นั้น
            RepairHistoryTechnicianWidget(technicians: _technicians),
            const SizedBox(height: 16),

            // รายการงานซ่อมย่อย
            RepairHistorySubTaskWidget(orderId: widget.order.orderId),
            const SizedBox(height: 16),

            // ใบเสร็จรับเงิน / สรุปค่าบริการ
            const RepairHistoryInvoiceWidget(),
          ],
        ),
      ),
    );
  }
}
