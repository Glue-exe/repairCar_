import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_main_model.dart';
import 'package:my_app/models/sub_task_model.dart';
import 'package:my_app/screens/shared/order_pool_main_screen/order_detail_screen/order_add_sub_task_repair_screen.dart';
import 'package:my_app/screens/shared/order_pool_main_screen/order_detail_screen/order_add_sub_task_service_screen.dart';
import 'package:my_app/screens/shared/order_pool_main_screen/order_detail_screen/order_sub_task_detail_screen.dart';
import 'package:my_app/utils/app_api.dart';

// การ์ดแสดงรายการงานซ่อมย่อยของ Order
class OrderDetailSubTaskDataWidget extends StatefulWidget {
  final OrderPoolMainModel order;
  final VoidCallback? onOrderChanged;

  const OrderDetailSubTaskDataWidget({
    super.key,
    required this.order,
    this.onOrderChanged,
  });

  @override
  State<OrderDetailSubTaskDataWidget> createState() =>
      _OrderDetailSubTaskDataWidgetState();
}

class _OrderDetailSubTaskDataWidgetState
    extends State<OrderDetailSubTaskDataWidget> {
  // รายการงานย่อยที่ได้จากเซิร์ฟเวอร์
  List<SubTaskModel> _subTasks = [];

  // กำลังโหลดอยู่หรือไม่
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubTasks();
  }

  Future<void> _loadSubTasks() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await AppAPI.get(
        '/sub_tasks?order_id=${widget.order.oId}',
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        final list = json['data'] as List;
        setState(() {
          _subTasks = list.map((e) => SubTaskModel.fromJson(e)).toList();
        });
      }
    } catch (_) {
      _showMessage('โหลดรายการงานซ่อมไม่สำเร็จ', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // เปิดหน้าเพิ่มรายการซ่อม (เลือกจากบริการ) แล้วโหลดใหม่เมื่อเพิ่มสำเร็จ
  Future<void> _openAddServiceSubTask() async {
    final bool? addResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrderAddServiceSubTaskScreen(orderId: widget.order.oId),
      ),
    );

    if (addResult == true) {
      await _loadSubTasks();
    }
  }

  // เปิดหน้าเพิ่มรายการซ่อม (เลือกจากหมวดซ่อมตามส่วนของรถ) แล้วโหลดใหม่เมื่อเพิ่มสำเร็จ
  Future<void> _openAddRepairSubTask() async {
    final bool? addResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrderAddRepairSubTaskScreen(orderId: widget.order.oId),
      ),
    );

    if (addResult == true) {
      await _loadSubTasks();
    }
  }

  // เปิดหน้ารายละเอียดงานย่อย แล้วโหลดใหม่เมื่อกลับ
  Future<void> _openSubTaskDetail(SubTaskModel item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSubTaskDetailScreen(
          subTask: item,
          onOrderStatusChanged: (statusId) {
            // งานย่อยเปลี่ยนเป็น "กำลังทำ" → Order หลักขยับตาม แจ้งหน้าจอแม่ให้ rebuild
            widget.order.oOrderStatusId = statusId;
            widget.onOrderChanged?.call();
          },
        ),
      ),
    );
    await _loadSubTasks();
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Widget _buildHeader() {
    return Column(
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
            const Text(
              'งานซ่อมย่อย',
              style: TextStyle(
                fontSize: AppFontSizes.headline,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Text(
              '${_subTasks.length} รายการ',
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        // แสดงปุ่มเพิ่มงานย่อย เฉพาะเมื่อกดรับงานแล้ว
        if (widget.order.acceptByMe) ...[
          const SizedBox(height: 10),
          _buildAddButtons(),
        ],
      ],
    );
  }

  // ปุ่มเพิ่มงานย่อย 2 ทาง — เลือกบริการมาตรฐาน หรือ ซ่อมเฉพาะส่วนของรถ
  Widget _buildAddButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _openAddServiceSubTask,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'เพิ่มบริการ',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _openAddRepairSubTask,
            icon: const Icon(Icons.build_circle_outlined, size: 18),
            label: const Text(
              'ซ่อมส่วนรถ',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String statusName) {
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

  Widget _buildSubTaskRow(SubTaskModel item) {
    final laborCost = NumberFormat('#,##0.00').format(item.laborCost);

    return InkWell(
      onTap: () => _openSubTaskDetail(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่องาน + สถานะ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(item.statusName),
              ],
            ),
            const SizedBox(height: 4),

            // ค่าแรง
            Text(
              'ค่าแรง: ฿$laborCost',
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
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

    if (_subTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(
            'ยังไม่มีรายการงานซ่อม',
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
        for (int i = 0; i < _subTasks.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _buildSubTaskRow(_subTasks[i]),
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
