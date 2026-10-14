import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/owner_dashboard_model.dart';
import 'package:my_app/screens/owner/part/part_approval_screen.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_action_row_widget.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_labor_parts_widget.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_profit_report_widget.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_range_selector_widget.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_section_header_widget.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_stat_card_widget.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  // ค่าเริ่มต้น = เดือนนี้
  String _range = 'month';

  OwnerDashboardModel? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AppAPI.get('/dashboard/summary?range=$_range');
      final resJson = jsonDecode(response.body);

      if (!mounted) return;

      if (resJson['isError'] == true) {
        setState(() {
          _isLoading = false;
          _errorMessage = resJson['errorMessage'] as String? ?? 'เกิดข้อผิดพลาด';
        });
        return;
      }

      setState(() {
        _dashboard = OwnerDashboardModel.fromJson(resJson['data']);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่สามารถโหลดข้อมูล Dashboard ได้';
      });
    }
  }

  void _onRangeChanged(String range) {
    if (range == _range) return;
    setState(() {
      _range = range;
    });
    _fetchDashboard();
  }

  void _openPartApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PartApprovalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchDashboard,
                  child: _buildBody(),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'เกิดข้อผิดพลาด',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDashboard,
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final dashboard = _dashboard;
    if (dashboard == null) {
      return const Center(child: Text('ไม่พบข้อมูล'));
    }

    final currency = NumberFormat('#,##0');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // งานในอู่ — สถานะปัจจุบัน
        const DashboardSectionHeaderWidget(title: 'งานในอู่'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardStatCardWidget(
                label: 'รอรับงาน',
                value: '${dashboard.pendingRepairs}',
                icon: Icons.inbox_outlined,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardStatCardWidget(
                label: 'กำลังซ่อม',
                value: '${dashboard.activeRepairs}',
                icon: Icons.build_outlined,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardStatCardWidget(
                label: 'รอส่งมอบ',
                value: '${dashboard.awaitingPickup}',
                icon: Icons.local_shipping_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // รอจัดการ
        const DashboardSectionHeaderWidget(title: 'รอจัดการ'),
        const SizedBox(height: 12),
        DashboardActionRowWidget(
          icon: Icons.build_circle_outlined,
          label: 'รออนุมัติเบิกอะไหล่',
          count: dashboard.pendingPartApprovals,
          unit: 'ใบ',
          color: AppColors.warning,
          onTap: _openPartApproval,
        ),
        const SizedBox(height: 20),

        // ช่วงนี้
        DashboardSectionHeaderWidget(
          title: 'ช่วงนี้',
          trailing: DashboardRangeSelectorWidget(
            range: _range,
            onRangeChanged: _onRangeChanged,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardStatCardWidget(
                label: 'รายได้',
                value: '${currency.format(dashboard.income)} ฿',
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardStatCardWidget(
                label: 'กำไรสุทธิ',
                value: '${currency.format(dashboard.profit)} ฿',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DashboardStatCardWidget(
                  label: 'รถเข้าซ่อม',
                  value: '${dashboard.vehiclesInRange} คัน',
                  icon: Icons.directions_car_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DashboardLaborPartsWidget(
                  laborTotal: dashboard.laborTotal,
                  partsTotal: dashboard.partsTotal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // รายงานกำไรสุทธิ
        const DashboardProfitReportWidget(),
      ],
    );
  }
}
