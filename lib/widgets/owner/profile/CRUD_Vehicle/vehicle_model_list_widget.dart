import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/vehicle_model_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Vehicle/vehicle_model_edit_widget.dart';

// widget แสดงรายการรุ่นรถ — รับข้อมูลจากหน้าจอหลัก (ไม่โหลดข้อมูลเอง)
class VehicleModelListWidget extends StatefulWidget {
  final List<VehicleModelModel> models;
  final VoidCallback? onRefresh;

  const VehicleModelListWidget({
    super.key,
    required this.models,
    this.onRefresh,
  });

  @override
  State<VehicleModelListWidget> createState() => _VehicleModelListWidgetState();
}

class _VehicleModelListWidgetState extends State<VehicleModelListWidget> {
  // ลบรุ่นรถ (ยืนยันก่อนลบ)
  Future<void> _deleteModel(VehicleModelModel model) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบรุ่น "${model.vmName}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response = await AppAPI.delete('/vehicle_model', {
        'vm_id': model.vmId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'ลบข้อมูลไม่สำเร็จ', AppColors.danger);
        return;
      }

      _showMessage('ลบข้อมูลรุ่นรถสำเร็จ', AppColors.success);
      widget.onRefresh?.call();
    } catch (_) {
      if (!mounted) return;
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.models.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 72,
              color: AppColors.disabled,
            ),
            SizedBox(height: 14),
            Text(
              'ไม่พบรายการรุ่นรถ',
              style: TextStyle(
                fontSize: AppFontSizes.subtitle,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: widget.models.length,
        itemBuilder: (context, index) {
          final model = widget.models[index];
          return _buildModelCard(model);
        },
      ),
    );
  }

  // การ์ดรุ่นรถ 1 รายการ (ไม่มีรูป)
  Widget _buildModelCard(VehicleModelModel model) {
    return Card(
      key: ValueKey(model.vmId),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ไอคอนรุ่นรถ
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                color: AppColors.primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // ชื่อรุ่น + ยี่ห้อที่สังกัด
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.vmName,
                    style: const TextStyle(
                      fontSize: AppFontSizes.input,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ยี่ห้อ: ${model.vbName}',
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // ปุ่มแก้ไข
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.info),
              tooltip: 'แก้ไขข้อมูลรุ่นรถ',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return VehicleModelEditWidget(
                        model: model,
                        onRefresh: widget.onRefresh,
                      );
                    },
                  ),
                );
              },
            ),

            // ปุ่มลบ
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'ลบรุ่นรถ',
              onPressed: () => _deleteModel(model),
            ),
          ],
        ),
      ),
    );
  }
}
