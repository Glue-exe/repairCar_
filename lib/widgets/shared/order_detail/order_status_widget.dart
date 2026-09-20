import 'package:flutter/material.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/order_status_model.dart';
import 'package:my_app/utils/app_api.dart';

class OrderStatusWidget extends StatefulWidget {
  final OrderModel order;
  final int currentStatusId;
  final List<OrderStatusModel> statuses;
  final Function(int)? onStatusChanged;
  final bool isOrderAccepted;

  const OrderStatusWidget({
    super.key,
    required this.order,
    required this.currentStatusId,
    required this.statuses,
    this.onStatusChanged,
    this.isOrderAccepted = false,
  });

  @override
  State<OrderStatusWidget> createState() => _OrderStatusWidgetState();
}

class _OrderStatusWidgetState extends State<OrderStatusWidget> {
  late int _currentStatusId;

  @override
  void initState() {
    super.initState();
    _currentStatusId = widget.currentStatusId;
  }

  @override
  void didUpdateWidget(covariant OrderStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatusId != widget.currentStatusId) {
      _currentStatusId = widget.currentStatusId;
    }
  }

  // กล่องยืนยันการทำรายการ
  Future<bool> _showConfirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  // ยิง API อัปเดตสถานะ
  Future<void> _postUpdateStatus(int newStatusId) async {
    await AppAPI.post('/order/update_status', {
      'order_id': widget.order.orderId,
      'status_id': newStatusId,
    });
  }

  void onPassStatus(int newStatusId, String statusName) async {
    bool confirm = await _showConfirm(
      'ยืนยันการเปลี่ยนสถานะ',
      'ต้องการเปลี่ยนสถานะเป็น "$statusName" หรือไม่?',
    );
    if (!confirm) return;

    await _postUpdateStatus(newStatusId);

    setState(() {
      _currentStatusId = newStatusId;
    });

    if (widget.onStatusChanged != null) {
      widget.onStatusChanged!(newStatusId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยนสถานะเป็น "$statusName" เรียบร้อยแล้ว')),
      );
    }
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'สถานะการซ่อม',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.order.createdAt.isNotEmpty ? _formatThaiDate(widget.order.createdAt) : '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var status in widget.statuses)
                  ChoiceChip(
                    label: Text(status.name),
                    selected: status.id == _currentStatusId,
                    onSelected: widget.isOrderAccepted && status.id != _currentStatusId
                        ? (_) => onPassStatus(status.id, status.name)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
