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
            backgroundColor: Colors.redAccent,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: widget.partModelStore.length,
      itemBuilder: (context, index) {
        PartModel item = widget.partModelStore[index];
        final bool isActive = item.partIsActive;

        return Card(
          key: ValueKey(item.id),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    _buildPartImage(item, isActive),
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
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category_rounded,
                                        size: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.partCategoryName!,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                              // ปุ่มแก้ไขไอคอนสีฟ้าตามแบบ emp_list_widget
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                tooltip: 'แก้ไขข้อมูลอะไหล่',
                                onPressed: () {
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
                              color: isActive ? null : Colors.grey,
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
                                    color: isActive ? Colors.teal.shade50 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isActive ? Colors.teal.shade200 : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 13,
                                        color: isActive ? Colors.teal : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.partCode,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                          color: isActive ? Colors.teal.shade800 : Colors.grey,
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
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.partBrandName!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isActive ? Colors.grey.shade800 : Colors.grey,
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'รุ่นที่รองรับ: ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Expanded(
                        child: _buildCompatibleModels(item),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ================= 3. ส่วนราคา =================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '฿',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.teal : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.partPrice.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.teal : Colors.grey,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${item.unit}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // ================= 4. เส้นคั่นและแถบสถานะเปิด-ปิดตามแบบ emp_list_widget =================
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isActive ? 'สถานะ: เปิดใช้งาน' : 'สถานะ: ปิดใช้งาน',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeThumbColor: Colors.green,
                      onChanged: (bool value) {
                        _toggleStatus(item, value);
                      },
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
  Widget _buildPartImage(PartModel item, bool isActive) {
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.network(
            fullUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackImage(isActive);
            },
          ),
        ),
      );
    } else {
      return _buildFallbackImage(isActive);
    }
  }

  Widget _buildFallbackImage(bool isActive) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isActive ? Colors.teal.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.teal.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.build_circle_outlined,
          color: isActive ? Colors.teal : Colors.grey,
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
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              m.displayText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.all_inclusive_rounded, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            'ใช้ได้ทั่วไป',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }
  }
}
