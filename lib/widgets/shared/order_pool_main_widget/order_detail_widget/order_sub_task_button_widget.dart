import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/app_api.dart';

class OrderSubTaskButtonWidget extends StatefulWidget {
  final int subTaskId;

  final bool isOrderAccepted;
  final bool isMySubTask;
  final VoidCallback? onChanged;

  const OrderSubTaskButtonWidget({
    super.key,
    required this.subTaskId,
    required this.isOrderAccepted,
    required this.isMySubTask,
    this.onChanged,
  });

  @override
  State<OrderSubTaskButtonWidget> createState() =>
      _OrderSubTaskButtonWidgetState();
}

class _OrderSubTaskButtonWidgetState extends State<OrderSubTaskButtonWidget> {
  // รับงานซ่อมย่อยนี้แล้วหรือยัง
  late bool _isAccepted;

  // กำลังส่งคำขออยู่หรือไม่
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isAccepted = widget.isMySubTask;
  }

  @override
  void didUpdateWidget(covariant OrderSubTaskButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMySubTask != oldWidget.isMySubTask) {
      _isAccepted = widget.isMySubTask;
    }
  }

  // กดรับงาน
  Future<void> _handleAccept() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการรับงาน'),
          content: Text(
            'คุณต้องการรับงานซ่อมย่อย #${widget.subTaskId} เข้าสู่รายการงานของคุณหรือไม่?',
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
      await _submit('/sub_task/accept');
    }
  }

  // กดยกเลิก
  Future<void> _handleCancel() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการยกเลิกรับงาน'),
          content: Text(
            'คุณต้องการยกเลิกรับงานซ่อมย่อย #${widget.subTaskId} ใช่หรือไม่?',
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
      await _submit('/sub_task/cancel');
    }
  }

  Future<void> _submit(String path) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AppAPI.post(path, {
        'sub_task_id': widget.subTaskId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'ดำเนินการไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      setState(() {
        _isAccepted = path == '/sub_task/accept';
      });
      _showMessage(
        path == '/sub_task/accept'
            ? 'รับงานเรียบร้อยแล้ว'
            : 'ยกเลิกรับงานเรียบร้อยแล้ว',
        AppColors.success,
      );
      widget.onChanged?.call();
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
    // รับงานแล้ว: แสดงแถบสถานะ + ปุ่มยกเลิก
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
                  'คุณได้รับงานซ่อมย่อยนี้แล้ว',
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

    // ยังไม่กดรับ Order หลักจะรับงานย่อยไม่ได้
    if (!widget.isOrderAccepted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
            SizedBox(width: 8),
            Text(
              'โปรดกดรับงานซ่อมนี้ก่อน',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // ยังไม่รับงาน: แสดงปุ่มกดรับ
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleAccept,
        icon: const Icon(Icons.assignment_turned_in_rounded),
        label: const Text(
          'กดรับงานซ่อมย่อยนี้',
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
