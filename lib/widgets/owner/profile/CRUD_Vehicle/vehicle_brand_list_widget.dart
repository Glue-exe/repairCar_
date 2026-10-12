import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/vehicle_brand_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Vehicle/vehicle_brand_edit_widget.dart';

// widget แสดงรายการยี่ห้อรถ — รับข้อมูลจากหน้าจอหลัก (ไม่โหลดข้อมูลเอง)
class VehicleBrandListWidget extends StatefulWidget {
  final List<VehicleBrandModel> brands;
  final VoidCallback? onRefresh;

  const VehicleBrandListWidget({
    super.key,
    required this.brands,
    this.onRefresh,
  });

  @override
  State<VehicleBrandListWidget> createState() => _VehicleBrandListWidgetState();
}

class _VehicleBrandListWidgetState extends State<VehicleBrandListWidget> {
  // ลบยี่ห้อรถ (ยืนยันก่อนลบ)
  Future<void> _deleteBrand(VehicleBrandModel brand) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบยี่ห้อ "${brand.vbName}" ?'),
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
      final response = await AppAPI.delete('/vehicle_brand', {
        'vb_id': brand.vbId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'ลบข้อมูลไม่สำเร็จ', AppColors.danger);
        return;
      }

      _showMessage('ลบข้อมูลยี่ห้อรถสำเร็จ', AppColors.success);
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
    if (widget.brands.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sell_outlined, size: 72, color: AppColors.disabled),
            SizedBox(height: 14),
            Text(
              'ไม่พบรายการยี่ห้อรถ',
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
        itemCount: widget.brands.length,
        itemBuilder: (context, index) {
          final brand = widget.brands[index];
          return _buildBrandCard(brand);
        },
      ),
    );
  }

  // การ์ดยี่ห้อรถ 1 รายการ (ไม่มีรูป)
  Widget _buildBrandCard(VehicleBrandModel brand) {
    return Card(
      key: ValueKey(brand.vbId),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ไอคอนยี่ห้อรถ
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sell_outlined,
                color: AppColors.primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // ชื่อยี่ห้อรถ
            Expanded(
              child: Text(
                brand.vbName,
                style: const TextStyle(
                  fontSize: AppFontSizes.input,
                  color: AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ปุ่มแก้ไข
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.info),
              tooltip: 'แก้ไขข้อมูลยี่ห้อรถ',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return VehicleBrandEditWidget(
                        brand: brand,
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
              tooltip: 'ลบยี่ห้อรถ',
              onPressed: () => _deleteBrand(brand),
            ),
          ],
        ),
      ),
    );
  }
}
