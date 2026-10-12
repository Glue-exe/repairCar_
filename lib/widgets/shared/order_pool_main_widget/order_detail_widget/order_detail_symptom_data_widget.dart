import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_main_model.dart';
import 'package:my_app/models/order_status_model.dart';
import 'package:my_app/models/priority_model.dart';
import 'package:my_app/utils/app_api.dart';

// การ์ดแสดง/แก้ไข อาการเสีย สถานะงาน และระดับความสำคัญของ Order
class OrderDetailSymptomDataWidget extends StatefulWidget {
  final OrderPoolMainModel order;

  const OrderDetailSymptomDataWidget({super.key, required this.order});

  @override
  State<OrderDetailSymptomDataWidget> createState() =>
      _OrderDetailSymptomDataWidgetState();
}

class _OrderDetailSymptomDataWidgetState
    extends State<OrderDetailSymptomDataWidget> {
  // ค่าที่หน้านี้แก้ไขได้
  late int _priorityId;
  late String _symptom;

  // รายการให้เลือก (โหลดจาก API)
  List<OrderStatusModel> _statuses = [];
  List<PriorityModel> _priorities = [];

  // กำลังบันทึกอยู่หรือไม่
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _priorityId = widget.order.oPriorityId;
    _symptom = widget.order.oSymptom ?? '';

    // ใส่ค่าปัจจุบันในรายการไปก่อน (ระหว่างรอ API)
    _statuses = [
      OrderStatusModel(
        id: widget.order.oOrderStatusId,
        name: widget.order.osName,
      ),
    ];
    _priorities = [PriorityModel(id: _priorityId, name: widget.order.pName)];

    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    // โหลดสถานะงาน
    try {
      final response = await AppAPI.get('/order_status');
      final json = jsonDecode(response.body);
      if (json['isError'] == false && json['data'] != null) {
        final list = json['data'] as List;
        if (mounted) {
          setState(() {
            _statuses = list.map((e) => OrderStatusModel.fromJson(e)).toList();
          });
        }
      }
    } catch (_) {}

    // โหลดระดับความสำคัญ
    try {
      final response = await AppAPI.get('/priority');
      final json = jsonDecode(response.body);
      if (json['isError'] == false && json['data'] != null) {
        final list = json['data'] as List;
        if (mounted) {
          setState(() {
            _priorities = list.map((e) => PriorityModel.fromJson(e)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _changeStatus(int newStatusId) async {
    // ต้องกดรับงานก่อน
    if (!widget.order.acceptByMe) {
      _showMessage(
        'กรุณากดรับงานนี้ก่อน จึงจะสามารถเปลี่ยนสถานะได้',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final response = await AppAPI.post('/order3/update_status', {
        'order_id': widget.order.oId,
        'status_id': newStatusId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'เปลี่ยนสถานะไม่สำเร็จ',
          Colors.red,
        );
        return;
      }

      // สำเร็จ: อัปเดตค่าที่แสดง (เขียนที่ object ที่แชร์)
      setState(() {
        widget.order.oOrderStatusId = newStatusId;
      });
      _showMessage('เปลี่ยนสถานะเรียบร้อยแล้ว', Colors.green);
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _changePriority(int newPriorityId) async {
    if (!widget.order.acceptByMe) {
      _showMessage(
        'กรุณากดรับงานนี้ก่อน จึงจะสามารถเปลี่ยนระดับความสำคัญได้',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final response = await AppAPI.post('/order3/update_priority', {
        'order_id': widget.order.oId,
        'priority_id': newPriorityId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'เปลี่ยนระดับความสำคัญไม่สำเร็จ',
          Colors.red,
        );
        return;
      }

      setState(() {
        _priorityId = newPriorityId;
        widget.order.oPriorityId = newPriorityId;
      });
      _showMessage('เปลี่ยนระดับความสำคัญเรียบร้อยแล้ว', Colors.green);
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _changeSymptom(String newSymptom) async {
    // ต้องกดรับงานก่อน
    if (!widget.order.acceptByMe) {
      _showMessage(
        'กรุณากดรับงานนี้ก่อน จึงจะสามารถแก้ไขอาการเสียได้',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final response = await AppAPI.post('/order3/update_symptom', {
        'order_id': widget.order.oId,
        'symptom': newSymptom,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'แก้ไขอาการเสียไม่สำเร็จ',
          Colors.red,
        );
        return;
      }

      setState(() {
        _symptom = newSymptom;
        widget.order.oSymptom = newSymptom;
      });
      _showMessage('แก้ไขอาการเสียเรียบร้อยแล้ว', Colors.green);
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // แสดงข้อความสั้นๆ ด้านล่างจอ
  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // เปิดกล่องแก้ไขอาการเสีย
  void _openEditSymptomDialog() {
    if (!widget.order.acceptByMe) {
      _showMessage(
        'กรุณากดรับงานนี้ก่อน จึงจะสามารถแก้ไขอาการเสียได้',
        Colors.orange,
      );
      return;
    }

    final controller = TextEditingController(text: _symptom);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('แก้ไขอาการเสีย'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'ระบุอาการเสีย...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _changeSymptom(controller.text.trim());
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.build, color: AppColors.primaryGreen, size: 22),
        SizedBox(width: 8),
        Text(
          'ข้อมูลอาการเสียและสถานะงาน',
          style: TextStyle(
            fontSize: AppFontSizes.headline,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ช่องเลือกสถานะงาน
  Widget _buildStatusField() {
    final bool enabled = widget.order.acceptByMe && !_saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สถานะงาน',
          style: TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: widget.order.oOrderStatusId,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
              disabledHint: Text(widget.order.osName),
              items: _statuses.map((status) {
                return DropdownMenuItem<int>(
                  value: status.id,
                  child: Text(
                    status.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled
                  ? (value) {
                      if (value != null &&
                          value != widget.order.oOrderStatusId) {
                        _changeStatus(value);
                      }
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ช่องเลือกระดับความสำคัญ
  Widget _buildPriorityField() {
    final bool enabled = widget.order.acceptByMe && !_saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ระดับความสำคัญ',
          style: TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _priorityId,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
              disabledHint: Text(widget.order.pName),
              items: _priorities.map((priority) {
                return DropdownMenuItem<int>(
                  value: priority.id,
                  child: Text(
                    priority.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled
                  ? (value) {
                      if (value != null && value != _priorityId) {
                        _changePriority(value);
                      }
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // กล่องแสดงอาการเสีย
  Widget _buildSymptomBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'อาการเสียที่แจ้ง',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.textMuted,
              ),
            ),
            if (widget.order.acceptByMe && !_saving)
              TextButton.icon(
                onPressed: _openEditSymptomDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text(
                  'แก้ไข',
                  style: TextStyle(
                    fontSize: AppFontSizes.button,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _symptom.isNotEmpty ? _symptom : 'ไม่ได้ระบุอาการ',
            style: TextStyle(
              fontSize: AppFontSizes.subtitle,
              height: 1.4,
              color: _symptom.isNotEmpty
                  ? AppColors.textDark
                  : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  // แบนเนอร์เตือนตอนยังไม่กดรับงาน
  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ต้องกดรับงานก่อน จึงจะแก้ไขสถานะได้',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.warningText,
              ),
            ),
          ),
        ],
      ),
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

            // แถบโหลด ตอนกำลังบันทึก
            if (_saving) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
            ],

            _buildStatusField(),
            const SizedBox(height: 16),

            _buildPriorityField(),
            const SizedBox(height: 16),

            _buildSymptomBox(),

            // ถ้ายังไม่รับงาน ให้แสดงคำเตือน
            if (!widget.order.acceptByMe) ...[
              const SizedBox(height: 16),
              _buildWarningBanner(),
            ],
          ],
        ),
      ),
    );
  }
}
