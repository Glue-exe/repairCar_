import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_model.dart';
import 'package:my_app/models/sub_task_model.dart';
import 'package:my_app/models/sub_task_status_model.dart';
import 'package:my_app/screens/shared/order_pool_main_screen/order_detail_screen/order_sub_task_add_part_screen.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_sub_task_button_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_sub_task_part_data_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_sub_task_technician_data_widget.dart';

// หน้ารายละเอียดงานซ่อมย่อย (กดเข้ามาจากการ์ดงานซ่อมย่อย)
class OrderSubTaskDetailScreen extends StatefulWidget {
  final SubTaskModel subTask;
  final ValueChanged<int>? onOrderStatusChanged;

  const OrderSubTaskDetailScreen({
    super.key,
    required this.subTask,
    this.onOrderStatusChanged,
  });

  @override
  State<OrderSubTaskDetailScreen> createState() =>
      _OrderSubTaskDetailScreenState();
}

class _OrderSubTaskDetailScreenState extends State<OrderSubTaskDetailScreen> {
  // รับงานซ่อมย่อยนี้แล้วหรือยัง (อัปเดตเมื่อกดรับ/ยกเลิก)
  late bool _accepted;
  late List<OrderTechnicianItemModel> _technicians;

  // สถานะงานย่อย (เปลี่ยนได้เมื่อกดรับงานย่อยนี้แล้ว)
  late int _statusId;
  late String _statusName;
  List<SubTaskStatusModel> _statuses = [];
  bool _saving = false;
  int _partReloadToken = 0;

  @override
  void initState() {
    super.initState();
    _accepted = widget.subTask.acceptByMe;
    _technicians = widget.subTask.technicians;

    _statusId = widget.subTask.statusId;
    _statusName = widget.subTask.statusName;
    _statuses = [SubTaskStatusModel(id: _statusId, name: _statusName)];
    _loadStatuses();
  }

  // รับ/ยกเลิกแล้ว → ดึงงานย่อยนี้ใหม่ ให้รายชื่อช่างอัปเดตทันที
  Future<void> _reloadSubTask() async {
    try {
      final response = await AppAPI.get(
        '/sub_tasks?order_id=${widget.subTask.orderId}',
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        final list = (json['data'] as List)
            .map((e) => SubTaskModel.fromJson(e))
            .toList();
        final updated = list.firstWhere(
          (s) => s.id == widget.subTask.id,
          orElse: () => widget.subTask,
        );

        setState(() {
          _technicians = updated.technicians;
          _accepted = updated.acceptByMe;
          _statusId = updated.statusId;
          _statusName = updated.statusName;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStatuses() async {
    try {
      final response = await AppAPI.get('/sub_task_status');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        final list = (json['data'] as List)
            .map((e) => SubTaskStatusModel.fromJson(e))
            .toList();
        setState(() {
          _statuses = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _changeStatus(int newStatusId) async {
    setState(() {
      _saving = true;
    });

    try {
      final response = await AppAPI.post('/sub_task/update_status', {
        'sub_task_id': widget.subTask.id,
        'status_id': newStatusId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'เปลี่ยนสถานะไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      final newName = _statuses
          .firstWhere(
            (s) => s.id == newStatusId,
            orElse: () =>
                SubTaskStatusModel(id: newStatusId, name: _statusName),
          )
          .name;

      setState(() {
        _statusId = newStatusId;
        _statusName = newName;
      });
      _showMessage('เปลี่ยนสถานะเรียบร้อยแล้ว', AppColors.success);

      // เปลี่ยนเป็น "กำลังทำ" → Order หลักขยับเป็น "กำลังซ่อม" ด้วย
      if (newStatusId == 2) {
        widget.onOrderStatusChanged?.call(newStatusId);
      }
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

  Widget _buildStatusField() {
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
              value: _statusId,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
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
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null && value != _statusId) {
                        _changeStatus(value);
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String statusName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusName,
        style: const TextStyle(
          fontSize: AppFontSizes.body,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _infoRow(String label, Widget value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textMuted,
          ),
        ),
        value,
      ],
    );
  }

  Widget _buildInfoCard() {
    final laborCost = NumberFormat('#,##0.00').format(widget.subTask.laborCost);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.handyman,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.subTask.name,
                    style: const TextStyle(
                      fontSize: AppFontSizes.headline,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),

            if (_saving) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
            ],

            // กดรับงานย่อยนี้แล้ว → เปลี่ยนสถานะได้
            if (_accepted)
              _buildStatusField()
            else
              _infoRow('สถานะงาน', _statusBadge(_statusName)),
            const SizedBox(height: 12),
            _infoRow(
              'ค่าแรง',
              Text(
                '฿$laborCost',
                style: const TextStyle(
                  fontSize: AppFontSizes.subtitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _infoRow(
              'Order',
              Text(
                '#${widget.subTask.orderId}',
                style: const TextStyle(
                  fontSize: AppFontSizes.subtitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddPart() async {
    final bool? added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSubTaskAddPartScreen(
          subTaskId: widget.subTask.id,
          subTaskName: widget.subTask.name,
        ),
      ),
    );

    // เพิ่มสำเร็จ → ให้การ์ดรายการเบิกโหลดใหม่
    if (added == true) {
      setState(() {
        _partReloadToken++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.subTask.name,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OrderSubTaskButtonWidget(
            subTaskId: widget.subTask.id,
            orderId: widget.subTask.orderId,
            isMySubTask: _accepted,
            onChanged: () {
              // อัปเดตสถานะทันที แล้วค่อยดึงข้อมูลจริงมาทับ
              setState(() {
                _accepted = !_accepted;
              });
              _reloadSubTask();
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 12),

            // ช่างผู้รับผิดชอบงานซ่อมย่อยนี้
            OrderSubTaskTechnicianDataWidget(technicians: _technicians),
            const SizedBox(height: 12),

            // รายการเบิกอะไหล่ (ปุ่มขอเบิกอยู่ในหัวการ์ด)
            OrderSubTaskPartDataWidget(
              key: ValueKey(_partReloadToken),
              subTaskId: widget.subTask.id,
              subTaskName: widget.subTask.name,
              canRequest: _accepted,
              onRequestPart: _openAddPart,
            ),
          ],
        ),
      ),
    );
  }
}
