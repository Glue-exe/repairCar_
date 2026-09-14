import 'package:flutter/material.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/order_status_model.dart';

class OrderStatusWidget extends StatelessWidget {
  final OrderModel order;
  final int currentStatusId;
  final List<OrderStatusModel> statuses;
  final Function(int) onStatusChanged;

  const OrderStatusWidget({
    super.key,
    required this.order,
    required this.currentStatusId,
    required this.statuses,
    required this.onStatusChanged,
  });

  String _formatThaiDate(String dateStr) {
    DateTime dt = DateTime.parse(dateStr).toLocal();
    int thaiYear = dt.year + 543;
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$thaiYear $hour:$minute น.';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สถานะการซ่อม',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: currentStatusId,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: statuses.map((status) {
                    return DropdownMenuItem<int>(
                      value: status.id,
                      child: Text(
                        status.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newStatusId) {
                    if (newStatusId != null && newStatusId != currentStatusId) {
                      onStatusChanged(newStatusId);
                    }
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'วันที่เปิดงาน',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatThaiDate(order.createdAt),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
