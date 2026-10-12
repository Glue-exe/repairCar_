import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/service_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Service/service_edit_widget.dart';

// widget แสดงรายการบริการ — รับข้อมูลจากหน้าจอหลัก (ไม่โหลดข้อมูลเอง)
// รูปแบบการ์ดเหมือน part_list_del_widget
class ServiceListWidget extends StatefulWidget {
  final List<ServiceModel> services;
  final VoidCallback? onRefresh;

  const ServiceListWidget({
    super.key,
    required this.services,
    this.onRefresh,
  });

  @override
  State<ServiceListWidget> createState() => _ServiceListWidgetState();
}

class _ServiceListWidgetState extends State<ServiceListWidget> {
  // เปลี่ยนสถานะเปิด/ปิดการใช้งาน (อัปเดต UI ก่อน แล้วย้อนกลับถ้าล้มเหลว)
  Future<void> _toggleStatus(ServiceModel service, bool isActive) async {
    final bool previousStatus = service.isActive;

    setState(() {
      service.isActive = isActive;
    });

    try {
      final response = await AppAPI.put('/service/status', {
        'service_id': service.id,
        's_service_active': isActive,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        setState(() {
          service.isActive = previousStatus;
        });
        _showMessage(json['errorMessage'] ?? 'เปลี่ยนสถานะไม่สำเร็จ');
        return;
      }

      // ซิงก์ข้อมูลกับหน้าหลักเมื่ออัปเดตสำเร็จ
      widget.onRefresh?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        service.isActive = previousStatus;
      });
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.services.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman_outlined, size: 72, color: AppColors.disabled),
            SizedBox(height: 14),
            Text(
              'ไม่พบรายการบริการ',
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
        itemCount: widget.services.length,
        itemBuilder: (context, index) {
          final service = widget.services[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  // การ์ดบริการ 1 รายการ (รูปแบบเหมือนการ์ดอะไหล่)
  Widget _buildServiceCard(ServiceModel service) {
    final bool isActive = service.isActive;

    return Card(
      key: ValueKey(service.id),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 1. ส่วนบน: รูปภาพ + ชื่อ + รายละเอียด =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceImage(service.serviceUrl, isActive),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // แถวบนสุด: ชื่อบริการ (ซ้าย) + ปุ่มแก้ไข (ขวา) อยู่บรรทัดเดียวกัน
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ชื่อบริการ
                          Expanded(
                            child: Text(
                              service.name,
                              style: TextStyle(
                                fontSize: AppFontSizes.title,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? AppColors.textDark
                                    : AppColors.disabled,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.info),
                            tooltip: 'แก้ไขข้อมูลบริการ',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return ServiceEditWidget(
                                      service: service,
                                      onRefresh: widget.onRefresh,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // รายละเอียดบริการ
                      Text(
                        service.detail ?? '-',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSizes.badge,
                          color: isActive
                              ? AppColors.textMuted
                              : AppColors.disabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ===== 2. ส่วนราคา (ค่าแรง) =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '฿',
                  style: TextStyle(
                    fontSize: AppFontSizes.tag,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? AppColors.primaryGreen
                        : AppColors.disabled,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  service.laborCost.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: AppFontSizes.headline,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? AppColors.primaryGreen
                        : AppColors.disabled,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '/ ครั้ง',
                  style: TextStyle(
                    fontSize: AppFontSizes.badge,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            // ===== 3. เส้นคั่น + แถบสถานะเปิด-ปิด =====
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isActive ? 'สถานะ: เปิดใช้งาน' : 'สถานะ: ปิดใช้งาน',
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: isActive,
                  activeThumbColor: AppColors.success,
                  onChanged: (value) {
                    _toggleStatus(service, value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // รูปภาพ
  Widget _buildServiceImage(String? serviceUrl, bool isActive) {
    final String imageUrl = AppConfig.getImageUrl(serviceUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.inputBackground
              : AppColors.disabledBg,
          border: Border.all(color: AppColors.border),
        ),
        child: imageUrl.isEmpty
            ? Icon(
                Icons.handyman_outlined,
                color: isActive ? AppColors.primaryGreen : AppColors.disabled,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.disabled,
                  );
                },
              ),
      ),
    );
  }
}
