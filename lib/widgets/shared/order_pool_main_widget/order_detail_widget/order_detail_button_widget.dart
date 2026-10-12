import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/app_api.dart';

// ปุ่มกดรับงานซ่อม (แสดงแถบ "รับงานแล้ว" เมื่อเป็นงานของเรา)
class OrderDetailButtonWidget extends StatefulWidget {
  final int orderId;
  final bool isMyOrder;
  final VoidCallback? onAccepted;
  final VoidCallback? onCancelled;

  const OrderDetailButtonWidget({
    super.key,
    required this.orderId,
    required this.isMyOrder,
    this.onAccepted,
    this.onCancelled,
  });

  @override
  State<OrderDetailButtonWidget> createState() =>
      _OrderDetailButtonWidgetState();
}

class _OrderDetailButtonWidgetState extends State<OrderDetailButtonWidget> {
  // รับงานแล้วหรือยัง
  late bool _isAccepted;

  // กำลังส่งคำขอรับงานอยู่หรือไม่
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isAccepted = widget.isMyOrder;
  }

  @override
  void didUpdateWidget(covariant OrderDetailButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMyOrder != oldWidget.isMyOrder) {
      _isAccepted = widget.isMyOrder;
    }
  }

  // กดปุ่ม -> ถามยืนยัน -> ส่งคำขอรับงาน
  Future<void> _handleAccept() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการรับงาน'),
          content: Text(
            'คุณต้องการรับงานซ่อม #${widget.orderId} เข้าสู่รายการงานของคุณหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ยืนยันรับงาน'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _acceptOrder();
    }
  }

  Future<void> _acceptOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AppAPI.post('/order3/accept_order', {
        'order_id': widget.orderId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'รับงานไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      setState(() {
        _isAccepted = true;
      });
      _showMessage('รับงานเรียบร้อยแล้ว', AppColors.success);
      widget.onAccepted?.call();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // กดปุ่มยกเลิก -> ถามยืนยัน -> ส่งคำขอยกเลิกรับงาน
  Future<void> _handleCancel() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการยกเลิกรับงาน'),
          content: Text(
            'คุณต้องการยกเลิกรับงานซ่อม #${widget.orderId} ใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ไม่'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ยืนยันยกเลิก'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _cancelOrder();
    }
  }

  Future<void> _cancelOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AppAPI.post('/order3/cancel_order', {
        'order_id': widget.orderId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'ยกเลิกรับงานไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      setState(() {
        _isAccepted = false;
      });
      _showMessage('ยกเลิกรับงานเรียบร้อยแล้ว', AppColors.success);
      widget.onCancelled?.call();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    // รับงานแล้ว: แสดงแถบสถานะ + ปุ่มยกเลิกรับงาน
    if (_isAccepted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'คุณได้รับงานซ่อมนี้แล้ว',
                  style: TextStyle(
                    fontSize: AppFontSizes.button,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text(
                'ยกเลิกรับงาน',
                style: TextStyle(
                  fontSize: AppFontSizes.button,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ยังไม่รับงาน: แสดงปุ่มกดรับงาน
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleAccept,
        icon: const Icon(Icons.assignment_turned_in_rounded),
        label: const Text(
          'กดรับงานซ่อมนี้',
          style: TextStyle(
            fontSize: AppFontSizes.button,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
