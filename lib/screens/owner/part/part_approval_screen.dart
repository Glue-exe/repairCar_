import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/approval_group_model.dart';
import 'package:my_app/models/approval_request_part_model.dart';
import 'package:my_app/models/req_part_status_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/part_approval/part_approval_list_widget.dart';

class PartApprovalScreen extends StatefulWidget {
  const PartApprovalScreen({super.key});

  @override
  State<PartApprovalScreen> createState() => _PartApprovalScreenState();
}

class _PartApprovalScreenState extends State<PartApprovalScreen> {
  int _status = ReqPartStatusId.pending;

  // แท็บสถานะการอนุมัติ แสดงเฉพาะ 4 สถานะหลัก (1: รออนุมัติ, 2: อนุมัติแล้ว, 3: ปฏิเสธ, 4: ยกเลิก)
  List<ReqPartStatusModel> _statuses = [
    ReqPartStatusModel(id: ReqPartStatusId.pending, name: 'รออนุมัติ'),
    ReqPartStatusModel(id: ReqPartStatusId.approved, name: 'อนุมัติแล้ว'),
    ReqPartStatusModel(id: ReqPartStatusId.rejected, name: 'ปฏิเสธ'),
    ReqPartStatusModel(id: ReqPartStatusId.cancelled, name: 'ยกเลิก'),
  ];
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _loadingStatuses = false;
  bool _statusError = false;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
    _loadRequests();
  }

  Future<void> _loadStatuses() async {
    setState(() {
      _loadingStatuses = true;
      _statusError = false;
    });

    try {
      final response = await AppAPI.get('/req_part_status');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        //แสดง 4 สถานะการอนุมัติ (1: รออนุมัติ, 2: อนุมัติแล้ว, 3: ปฏิเสธ, 4: ยกเลิก)
        final all = (json['data'] as List)
            .map((e) => ReqPartStatusModel.fromJson(e))
            .where((s) => s.id <= 4)
            .toList();

        setState(() {
          _statuses = all;
        });
      } else {
        setState(() {
          _statusError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStatuses = false;
        });
      }
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await AppAPI.get(
        '/approval_request_parts?status_id=$_status',
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        setState(() {
          _rows = List<Map<String, dynamic>>.from(json['data'] as List);
        });
      }
    } catch (_) {
      _showMessage('โหลดรายการไม่สำเร็จ', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // รวมแถวที่เป็นใบเบิกเดียวกัน (group by rp_id)
  List<ApprovalGroup> get _groups {
    final map = <int, ApprovalGroup>{};
    for (final row in _rows) {
      final id = row['id'] as int;
      final group = map.putIfAbsent(id, () => ApprovalGroup.fromJson(row));
      group.items.add(ApprovalRequestPartModel.fromJson(row));
    }
    return map.values.toList();
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Widget _statusButton(int status, String label) {
    final selected = _status == status;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? AppColors.primaryGreen
              : AppColors.inputBackground,
          foregroundColor: selected ? Colors.white : AppColors.textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
        onPressed: _loading
            ? null
            : () {
                if (_status == status) return;
                setState(() {
                  _status = status;
                });
                _loadRequests();
              },
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppFontSizes.badge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // แถวแท็บสถานะ — ดึงจากตาราง req_part_status ทั้งหมด
  Widget _buildStatusTabs() {
    if (_loadingStatuses) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_statusError) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'โหลดสถานะไม่สำเร็จ',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.danger,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadStatuses,
            child: const Text('ลองใหม่'),
          ),
        ],
      );
    }
    // กรองแสดงเฉพาะ 4 สถานะการอนุมัติ (1: รออนุมัติ, 2: อนุมัติแล้ว, 3: ปฏิเสธ, 4: ยกเลิก) เสมอ
    final displayStatuses = _statuses.where((s) => s.id <= 4).toList();

    return Row(
      children: [
        for (int i = 0; i < displayStatuses.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _statusButton(displayStatuses[i].id, displayStatuses[i].name),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'อนุมัติอะไหล่',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildStatusTabs(),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : PartApprovalListWidget(
                      groups: _groups,
                      onUpdated: () {
                        _loadRequests();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
