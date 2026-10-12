import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/approval_group_model.dart';
import 'package:my_app/models/approval_request_part_model.dart';
import 'package:my_app/models/req_part_status_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/shared/part_image_thumbnail_widget.dart';

// รายการใบเบิกให้เจ้าของร้านอนุมัติ
class PartApprovalListWidget extends StatefulWidget {
  final List<ApprovalGroup> groups;
  final VoidCallback onUpdated;

  const PartApprovalListWidget({
    super.key,
    required this.groups,
    required this.onUpdated,
  });

  @override
  State<PartApprovalListWidget> createState() => _PartApprovalListWidgetState();
}

class _PartApprovalListWidgetState extends State<PartApprovalListWidget> {
  static final NumberFormat _currency = NumberFormat('#,##0.00');

  bool _saving = false;

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

  Future<void> _updateStatus(int requestPartId, int statusId) async {
    final String action = statusId == ReqPartStatusId.approved ? 'อนุมัติ' : 'ปฏิเสธ';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('ยืนยันการ$action'),
          content: Text('ต้องการ$actionใบเบิก #$requestPartId หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('ยืนยัน$action'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _saving = true;
    });

    try {
      final response = await AppAPI.post('/request_part/update_status', {
        'request_part_id': requestPartId,
        'status_id': statusId,
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

      _showMessage('$actionเรียบร้อยแล้ว', AppColors.success);
      widget.onUpdated();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
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

  // ป้ายสถานะ 
  Widget _statusBadge(int statusId, String statusName) {
    Color bg = AppColors.disabledBg;
    Color fg = AppColors.textDark;

    if (statusId == ReqPartStatusId.pending) {
      bg = AppColors.warningBg;
      fg = AppColors.warningText;
    } else if (statusId == ReqPartStatusId.approved) {
      bg = AppColors.successBg;
      fg = AppColors.successText;
    } else if (statusId == ReqPartStatusId.rejected) {
      bg = AppColors.dangerBg;
      fg = AppColors.dangerText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusName,
        style: TextStyle(
          fontSize: AppFontSizes.badge,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // ข้อมูลรถ
  String _vehicleText(ApprovalGroup group) {
    final color = group.vehicleColor;
    final parts = <String>[
      group.licensePlate,
      group.vehicleName,
      if (group.vehicleYear != null) '${group.vehicleYear}',
      if (color != null && color.trim().isNotEmpty) color,
    ];
    return parts.where((part) => part.isNotEmpty).join(' · ');
  }

  // ข้อมูลลูกค้า
  String _customerText(ApprovalGroup group) {
    final parts = <String>[group.customerName, group.customerPhone];
    return parts.where((part) => part.isNotEmpty).join(' · ');
  }

  // แถว label/value: label ขนาด caption กว้างคงที่ไม่ขึ้นบรรทัดใหม่ ส่วน value กินที่เหลือและตัดคำเมื่อเกิน 2 บรรทัด
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSizes.caption,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ชื่ออะไหล่ + ยี่ห้อ (แสดงยี่ห้อเฉพาะเมื่อมีค่า)
  String _partLabel(ApprovalRequestPartModel item) {
    final brand = item.partBrand;
    if (brand != null && brand.trim().isNotEmpty) {
      return '${item.partName} ($brand)';
    }
    return item.partName;
  }

  Widget _itemRow(ApprovalRequestPartModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartImageThumbnail(imageUrl: item.imageUrl, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _partLabel(item),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.textDark,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'x${item.quantity}',
            style: const TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              '฿${_currency.format(item.totalPrice)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(ApprovalGroup group) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวการ์ด: เลขที่ใบเบิก + สถานะ
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ใบเบิก #${group.id}',
                    style: const TextStyle(
                      fontSize: AppFontSizes.title,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(group.statusId, group.statusName),
              ],
            ),
            const SizedBox(height: 4),

            // ออเดอร์ + วันที่ อยู่ใต้หัวการ์ด ให้กล่องข้อมูลเหลือแค่สิ่งที่ต้องกวาดตาและไม่ต้องตัดคำ
            Text(
              'ออเดอร์ #${group.orderId} · ${_formatThaiDate(group.requestedAt)}',
              style: const TextStyle(
                fontSize: AppFontSizes.caption,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // กล่องข้อมูลอ้างอิง (label/value เป็นระเบียบ)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _infoRow('รถยนต์', _vehicleText(group)),
                  _infoRow('ลูกค้า', _customerText(group)),
                  _infoRow('งานซ่อมย่อย', group.subTaskName),
                  _infoRow('ผู้ขอเบิก', group.requesterName),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // รายการอะไหล่
            Row(
              children: [
                const Text(
                  'รายการอะไหล่',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${group.items.length} รายการ',
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            for (final item in group.items) _itemRow(item),

            const Divider(height: 18),

            // ยอดอะไหล่ที่กำลังขออนุมัติ
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ยอดค่าอะไหล่ (ขออนุมัติ)',
                    style: TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  '฿${_currency.format(group.total)}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),

            // ปุ่มอนุมัติ/ปฏิเสธ (เฉพาะสถานะรออนุมัติ)
            if (group.statusId == ReqPartStatusId.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => _updateStatus(group.id, 3),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ปฏิเสธ',
                        style: TextStyle(
                          fontSize: AppFontSizes.button,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () => _updateStatus(group.id, 2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'อนุมัติ',
                        style: TextStyle(
                          fontSize: AppFontSizes.button,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีรายการ',
          style: TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [for (final group in widget.groups) _buildGroup(group)],
    );
  }
}
