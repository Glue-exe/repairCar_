import 'package:flutter/material.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/order_status_model.dart';

class RepairHistoryStatusWidget extends StatelessWidget {
  final OrderModel order;
  final int currentStatusId;
  final List<OrderStatusModel> statuses;
  final Function(int) onStatusChanged;

  const RepairHistoryStatusWidget({
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
                Text(
                  'ใบรับซ่อม #${order.orderId}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'วันที่รับซ่อม: ${_formatThaiDate(order.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            if (statuses.isEmpty)
              Text(
                order.orderStatusName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            else
              DropdownButton<int>(
                value: currentStatusId,
                underline: const SizedBox(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                items: statuses.map((s) {
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.name),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null && newId != currentStatusId) {
                    onStatusChanged(newId);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
