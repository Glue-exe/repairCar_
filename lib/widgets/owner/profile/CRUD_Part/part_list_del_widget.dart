import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Part/part_edit_widget.dart';

class PartListWidget extends StatefulWidget {
  final List<PartModel> partModelStore;
  final VoidCallback? onRefresh;

  const PartListWidget({
    super.key,
    required this.partModelStore,
    this.onRefresh,
  });

  @override
  State<PartListWidget> createState() => _PartListWidgetState();
}

class _PartListWidgetState extends State<PartListWidget> {
  // สลับสถานะเปิด-ปิดอะไหล่
  Future<void> _toggleStatus(PartModel item, bool nextActive) async {
    bool previousStatus = item.partIsActive;

    setState(() {
      item.partIsActive = nextActive;
    });

    void revertState(String message) {
      setState(() {
        item.partIsActive = previousStatus;
      });
      if (mounted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontSize: 14)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    try {
      final response = await AppAPI.put('/part/status', {
        'part_id': item.id,
        'part_is_active': nextActive,
      });

      if (response.statusCode != 200) {
        revertState('เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (HTTP ${response.statusCode})');
        return;
      }

      final res = jsonDecode(response.body);
      if (res['isError'] == true) {
        String errorMsg = (res['errorMessage'] != null && res['errorMessage'].toString().isNotEmpty == true)
            ? res['errorMessage'].toString()
            : 'เกิดข้อผิดพลาดในการเปลี่ยนสถานะ';
        revertState(errorMsg);
        return;
      }

      // ซิงก์ข้อมูลสถานะกับหน้าหลักเมื่ออัปเดตสำเร็จ
      widget.onRefresh?.call();
    } catch (e) {
      debugPrint(e.toString());
      revertState('เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: widget.partModelStore.length,
      itemBuilder: (context, index) {
        PartModel item = widget.partModelStore[index];
        final bool isActive = item.partIsActive;

        // สถานะ isActive (Active vs Inactive)
        final statusLabel = isActive ? 'เปิดใช้งาน' : 'ปิดใช้งาน';
        final statusBgColor = isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
        final statusTextColor = isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
        final statusDotColor = isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final cardBorderColor = isActive ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1);
        final titleColor = isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B);
        final priceColor = isActive ? const Color(0xFF0F766E) : const Color(0xFF94A3B8);

        return Container(
          key: ValueKey(item.id),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardBorderColor,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= 1. ส่วนบน: รูปภาพ + ข้อมูลหลัก + ปุ่มแก้ไข =================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // รูปภาพอะไหล่ (ขนาด 72x72)
                    _buildPartImage(item),
                    const SizedBox(width: 12),

                    // ข้อมูลหลัก: หมวดหมู่, ชื่อ, รหัสอะไหล่, ยี่ห้อ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // แถวบนสุด: ป้ายหมวดหมู่ + ปุ่มแก้ไข
                          Row(
                            children: [
                              if (item.partCategoryName != null && item.partCategoryName!.isNotEmpty == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9), // slate-100
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.category_rounded,
                                        size: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.partCategoryName!,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                              // ปุ่มแก้ไขดีไซน์ปุ่มกลม 
                              Material(
                                color: const Color(0xFFEFF6FF), // blue-50
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return PartEditWidget(
                                            part: item,
                                            onRefresh: widget.onRefresh,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: Color(0xFF2563EB), // blue-600
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // ชื่ออะไหล่
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // ป้ายรหัสอะไหล่ และ ยี่ห้อ
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // ป้ายรหัสอะไหล่
                              if (item.partCode.isNotEmpty == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDFA), // teal-50
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCCFBF1)), // teal-100
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 13,
                                        color: Color(0xFF0F766E),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.partCode,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // ยี่ห้ออะไหล่
                              if (item.partBrandName != null && item.partBrandName!.isNotEmpty == true)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: Color(0xFF4F46E5), // indigo-600
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.partBrandName!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ================= 2. ส่วนกลาง: รุ่นรถที่รองรับ =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC), // slate-50
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'รุ่นที่รองรับ: ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Expanded(
                        child: _buildCompatibleModels(item),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // ================= 3. ส่วนล่าง: ราคา และ ปุ่มสลับสถานะเปิด-ปิด =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ราคาอะไหล่
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '฿',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: priceColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.partPrice.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: priceColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ ${item.unit}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    // ป้ายสถานะ
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusDotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: isActive,
                            activeThumbColor: const Color(0xFF16A34A),
                            activeTrackColor: const Color(0xFFBBF7D0),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (bool value) {
                              _toggleStatus(item, value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // รูปภาพอะไหล่ขนาด 72x72
  Widget _buildPartImage(PartModel item) {
    if (item.url != null && item.url!.trim().isNotEmpty == true) {
      String imagePath = item.url!.trim();
      String fullUrl = '';
      if (imagePath.startsWith('http://') == true || imagePath.startsWith('https://') == true) {
        fullUrl = imagePath;
      } else {
        String cleanPath = imagePath;
        if (cleanPath.startsWith('/') == true) {
          cleanPath = cleanPath.substring(1);
        }
        fullUrl = '${AppConfig.imageBaseUri}/$cleanPath';
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.network(
            fullUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackImage();
            },
          ),
        ),
      );
    } else {
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA), // teal-50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCCFBF1)), // teal-100
      ),
      child: const Center(
        child: Icon(
          Icons.build_circle_rounded,
          color: Color(0xFF0F766E), // teal-700
          size: 32,
        ),
      ),
    );
  }

  // แสดงรายการรุ่นรถที่รองรับ
  Widget _buildCompatibleModels(PartModel item) {
    if (item.compatibleModels.isNotEmpty == true) {
      return Wrap(
        spacing: 6,
        runSpacing: 5,
        children: item.compatibleModels.map((m) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              m.displayText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.all_inclusive_rounded, size: 14, color: Color(0xFF64748B)),
          SizedBox(width: 4),
          Text(
            'ใช้ได้ทั่วไป',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      );
    }
  }
}
