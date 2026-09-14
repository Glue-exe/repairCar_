import 'package:flutter/material.dart';
import 'package:my_app/models/order_pool_model.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/screens/shared/order_detail/order_detail_screen.dart';
import 'package:my_app/utils/app_api.dart';

class OrderPoolCardWidget extends StatefulWidget {
  final OrderPoolItemModel order;
  final int? currentUserId;
  final VoidCallback onActionSuccess;

  const OrderPoolCardWidget({
    super.key,
    required this.order,
    this.currentUserId,
    required this.onActionSuccess,
  });

  @override
  State<OrderPoolCardWidget> createState() => _OrderPoolCardWidgetState();
}

class _OrderPoolCardWidgetState extends State<OrderPoolCardWidget> {
  bool _isProcessing = false;

  // ตรวจสอบว่าฉันเคยกดรับงานนี้หรือยัง
  bool _checkIsAcceptedByMe() {
    if (widget.currentUserId == null) return false;
    return widget.order.technicians.any((tech) => tech.accountId == widget.currentUserId);
  }

  // กล่องแจ้งเตือนถามยืนยัน
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

  // แสดงข้อความแจ้งเตือน SnackBar
  void _showMessage(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
    }
  }

  // ฟังก์ชันกดรับงาน
  Future<void> _handleAccept() async {
    bool confirm = await _showConfirm(
      'ยืนยันการรับงาน',
      'ต้องการรับงานทะเบียน ${widget.order.licensePlate} หรือไม่?',
    );
    if (!confirm) return;

    setState(() {
      _isProcessing = true;
    });

    await AppAPI.post('/order/accept', {
      'order_id': widget.order.orderId,
    });

    _showMessage('รับงานเรียบร้อยแล้ว');
    widget.onActionSuccess();

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // ฟังก์ชันกดยกเลิกการรับงาน
  Future<void> _handleCancel() async {
    bool confirm = await _showConfirm(
      'ยืนยันยกเลิกการรับงาน',
      'ต้องการยกเลิกการรับงานทะเบียน ${widget.order.licensePlate} หรือไม่?',
    );
    if (!confirm) return;

    setState(() {
      _isProcessing = true;
    });

    await AppAPI.post('/order/cancel_technician', {
      'order_id': widget.order.orderId,
    });

    _showMessage('ยกเลิกการรับงานเรียบร้อยแล้ว');
    widget.onActionSuccess();

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // ส่วนแสดงปุ่มรับงานและยกเลิก
  Widget _buildActionRow(bool isAcceptedByMe) {
    if (_isProcessing) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // กรณีรับงานแล้ว รับงานแล้ว และปุ่ม ยกเลิก
    if (isAcceptedByMe) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'รับงานแล้ว',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton(
              onPressed: _handleCancel,
              child: const Text('ยกเลิก'),
            ),
          ],
        ),
      );
    } else {
      // กรณียังไม่ได้รับงาน แสดงปุ่ม กดรับงาน
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _handleAccept,
              child: const Text('กดรับงาน'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String techStatusText = widget.order.technicianCount > 0
        ? 'มีช่างรับแล้ว (${widget.order.technicianCount} คน)'
        : 'ยังไม่มีคนรับ';

    bool isAcceptedByMe = _checkIsAcceptedByMe();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          final orderObj = OrderModel(
            orderId: widget.order.orderId,
            vehicleId: widget.order.vehicleId,
            symptom: widget.order.symptom,
            orderStatusId: widget.order.orderStatusId,
            orderStatusName: widget.order.orderStatusName,
            createdAt: widget.order.createdAt,
            images: widget.order.images,
            technicians: widget.order.technicians,
          );

          final vehicleObj = VehicleSearchResultModel(
            vId: widget.order.vehicleId,
            fullName: '${widget.order.customerFirstName} ${widget.order.customerLastName}',
            cusPhone: widget.order.customerPhone,
            licensePlate: widget.order.licensePlate,
            modelName: widget.order.modelName,
            brandName: widget.order.brandName,
            year: 0,
            color: widget.order.color,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(
                order: orderObj,
                vehicle: vehicleObj,
              ),
            ),
          ).then((_) {
            widget.onActionSuccess();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ยี่ห้อ รุ่น และ สถานะงาน
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${widget.order.brandName} ${widget.order.modelName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    widget.order.orderStatusName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ทะเบียน: ${widget.order.licensePlate}  |  สี: ${widget.order.color}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'อาการ: ${widget.order.symptom}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'เจ้าของรถ: ${widget.order.customerFirstName} ${widget.order.customerLastName}  |  โทร: ${widget.order.customerPhone}',
                style: const TextStyle(fontSize: 14),
              ),
              const Divider(height: 20),

              // ความสำคัญ และ สถานะช่าง
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ความสำคัญ: ${widget.order.priorityName}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    techStatusText,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),

              // ส่วนปุ่มกดรับงาน / ยกเลิก
              _buildActionRow(isAcceptedByMe),
            ],
          ),
        ),
      ),
    );
  }
}
