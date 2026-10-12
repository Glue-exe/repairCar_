import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/order_pool_main_model.dart';
import 'package:my_app/screens/shared/order_pool_main_screen/order_detail_screen/order_detail_screen2.dart';
import 'package:my_app/utils/app_api.dart';

class VehicleDetailOrdersWidget extends StatelessWidget {
  final List<OrderModel> orderList;
  final bool isLoading;

  const VehicleDetailOrdersWidget({
    super.key,
    required this.orderList,
    required this.isLoading,
  });

  String _formatThaiDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      int thaiYear = dt.year + 543;
      String day = dt.day.toString().padLeft(2, '0');
      String month = dt.month.toString().padLeft(2, '0');
      String hour = dt.hour.toString().padLeft(2, '0');
      String minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$thaiYear $hour:$minute น.';
    } catch (e) {
      return dateStr;
    }
  }

  // เปิดหน้ารายละเอียดใบสั่งซ่อมด้วยหน้าจอใหม่ (ศูนย์รวมงานซ่อม)
  // ดึงข้อมูลใบสั่งซ่อมนั้นใหม่จากเซิร์ฟเวอร์ เพื่อให้ได้สิทธิ์ accept_by_me ล่าสุด
  Future<void> _openOrderDetail(BuildContext context, OrderModel order) async {
    try {
      final response = await AppAPI.get('/order3/${order.orderId}');
      final json = jsonDecode(response.body);
      final res = OrderPoolMainResponse.fromJson(json);

      if (!context.mounted) return;

      if (res.isError || res.data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.errorMessage.isNotEmpty
                  ? res.errorMessage
                  : 'ไม่พบข้อมูลใบสั่งซ่อม',
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(order: res.data.first),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 8),
                Text(
                  'ประวัติการซ่อม',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (orderList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    'ยังไม่มีประวัติการซ่อมสำหรับรถคันนี้',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orderList.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final order = orderList[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openOrderDetail(context, order),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.build, color: Colors.blueGrey),
                        title: Text('อาการ: ${order.symptom}'),
                        subtitle: Text('วันที่: ${_formatThaiDate(order.createdAt)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                order.orderStatusName,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
