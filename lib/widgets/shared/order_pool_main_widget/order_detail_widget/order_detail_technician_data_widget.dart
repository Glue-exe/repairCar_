import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_detail_technicians_model.dart';
import 'package:my_app/utils/app_api.dart';

// การ์ดแสดงรายชื่อช่างที่รับงาน Order นี้
class OrderDetailTechnicianDataWidget extends StatefulWidget {
  final int orderId;

  const OrderDetailTechnicianDataWidget({super.key, required this.orderId});

  @override
  State<OrderDetailTechnicianDataWidget> createState() =>
      _OrderDetailTechnicianDataWidgetState();
}

class _OrderDetailTechnicianDataWidgetState
    extends State<OrderDetailTechnicianDataWidget> {
  // รายชื่อช่างที่ได้จากเซิร์ฟเวอร์
  List<OrderDetailTechniciansModel> _technicians = [];

  // กำลังโหลดอยู่หรือไม่
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await AppAPI.get(
        '/order3/order_technicians/${widget.orderId}',
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        final list = json['data'] as List;
        setState(() {
          _technicians = list
              .map((e) => OrderDetailTechniciansModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {
      _showMessage('โหลดรายชื่อช่างไม่สำเร็จ', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
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

  // แปลงวันเวลา (ISO) เป็นรูปแบบไทย พ.ศ.
  String _formatThaiDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final thaiYear = dt.year + 543;
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$thaiYear $hour:$minute น.';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.engineering, color: AppColors.primaryGreen, size: 22),
        const SizedBox(width: 8),
        const Text(
          'ช่างผู้รับผิดชอบ',
          style: TextStyle(
            fontSize: AppFontSizes.headline,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const Spacer(),
        Text(
          '${_technicians.length} คน',
          style: const TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianRow(OrderDetailTechniciansModel tech) {
    final fullName = '${tech.tName}${tech.empFirstName} ${tech.empLastName}';
    final assignedAt = _formatThaiDate(tech.otAssignedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.inputBackground,
            child: Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อ-นามสกุลช่าง
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),

                // บทบาท · เบอร์โทร
                Text(
                  '${tech.arName} · ${tech.empPhone}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),

                // วันที่รับงาน
                if (assignedAt.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'รับงาน $assignedAt',
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_technicians.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(
            'ยังไม่มีช่างรับงาน',
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _technicians.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _buildTechnicianRow(_technicians[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 20, thickness: 0.8),
            _buildBody(),
          ],
        ),
      ),
    );
  }
}
