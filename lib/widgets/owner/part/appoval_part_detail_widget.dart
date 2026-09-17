import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/models/appoval_part_model.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/order_pool_model.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/screens/shared/order_detail/order_detail_screen.dart';
import 'package:my_app/utils/app_api.dart';

class AppovalPartDetailWidget extends StatefulWidget {
  final AppovalPartModel item;
  const AppovalPartDetailWidget({super.key, required this.item});

  @override
  State<AppovalPartDetailWidget> createState() => _AppovalPartDetailWidgetState();
}

class _AppovalPartDetailWidgetState extends State<AppovalPartDetailWidget> {
  void _postApproval(int statusId) async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = prefs.getInt('user_id');

    final response = await AppAPI.post('/approval_part', {
      'app_p_id': widget.item.id,
      'account_id': accountId,
      'status_id': statusId,
    });

    final res = jsonDecode(response.body);
    if (res['isError'] == false) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

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

  void _disapprove() async {
    final confirm = await _showConfirm('ยืนยันการทำรายการ', 'คุณต้องการ "ไม่อนุมัติ" การขอเบิกอะไหล่นี้ใช่หรือไม่?');
    if (confirm) {
      _postApproval(3); // 3 = ไม่อนุมัติ
    }
  }

  void _approve() async {
    final confirm = await _showConfirm('ยืนยันการทำรายการ', 'คุณต้องการ "อนุมัติ" การขอเบิกอะไหล่นี้ใช่หรือไม่?');
    if (confirm) {
      _postApproval(2); // 2 = อนุมัติแล้ว
    }
  }
  void _openOrderDetail(int orderId) async {
    final response = await AppAPI.get('/order_by_id?order_id=$orderId');
    final Map<String, dynamic> json = jsonDecode(response.body);
    final match = OrderPoolItemModel.fromJson(json['data']);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          order: OrderModel(
            orderId: match.orderId,
            vehicleId: match.vehicleId,
            symptom: match.symptom,
            orderStatusId: match.orderStatusId,
            orderStatusName: match.orderStatusName,
            createdAt: match.createdAt,
            images: match.images,
            technicians: match.technicians,
          ),
          vehicle: VehicleSearchResultModel(
            vId: match.vehicleId,
            fullName: '${match.customerFirstName} ${match.customerLastName}',
            cusPhone: match.customerPhone,
            licensePlate: match.licensePlate,
            modelName: match.modelName,
            brandName: match.brandName,
            year: match.year,
            color: match.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการขอเบิกอะไหล่'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ทะเบียนรถ: ${item.licensePlate}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('งานซ่อม: ${item.subTaskName}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('ผู้ขอเบิก: ช่าง ${item.empFirstName} ${item.empLastName}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('วันที่ส่งคำขอ: ${item.createdAt}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),

            // ปุ่มกดไปดูรายละเอียดงานซ่อมเต็ม
            OutlinedButton.icon(
              icon: const Icon(Icons.assignment_outlined),
              label: Text('ดูรายละเอียดงานซ่อม (Order #${item.orderId})'),
              onPressed: () => _openOrderDetail(item.orderId),
            ),
            const Divider(height: 32),

            Text('ชื่ออะไหล่: ${item.partName}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('ยี่ห้อ: ${item.partBrand}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('จำนวน: ${item.quantity} ชิ้น', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('ราคาต่อหน่วย: ${item.partPrice} บาท', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('ราคารวม: ${item.partPrice * item.quantity} บาท', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _disapprove,
                    child: const Text('ไม่อนุมัติ', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _approve,
                    child: const Text('อนุมัติ', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
