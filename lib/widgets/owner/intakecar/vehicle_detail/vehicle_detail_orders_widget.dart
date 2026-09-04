import 'package:flutter/material.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/screens/owner/owner_repair_history_screen.dart';

class VehicleDetailOrdersWidget extends StatelessWidget {
  final List<OrderModel> orderList;
  final bool isLoading;
  final VehicleSearchResultModel vehicle;

  const VehicleDetailOrdersWidget({
    super.key,
    required this.orderList,
    required this.isLoading,
    required this.vehicle,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.history),
                ),
                SizedBox(width: 12),
                Text(
                  'ประวัติการซ่อม',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OwnerRepairHistoryScreen(
                            order: order,
                            vehicle: vehicle,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.build, color: Colors.blueGrey),
                            title: Text('อาการ: ${order.symptom}'),
                            subtitle: Text('วันที่: ${_formatThaiDate(order.createdAt)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    order.orderStatusName,
                                    style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                          if (order.images.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 65,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: order.images.length,
                                itemBuilder: (context, imgIdx) {
                                  final imgUrl =
                                      "${AppConfig.apiBaseUri.replaceAll('/api', '')}${order.images[imgIdx]}";
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 65,
                                    height: 65,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
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
