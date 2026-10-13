import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/owner_dashboard_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_kpi_card_widget.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_labor_parts_chart_widget.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_range_selector_widget.dart';
import 'package:my_app/widgets/owner/dashboard/dashboard_trend_chart_widget.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
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
    } catch (e) {
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

    final currencyFormatter = NumberFormat('#,##0');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // เปลี่ยนช่วงเวลา = โหลดใหม่ทั้งหน้า
        DashboardRangeSelectorWidget(
          range: _range,
          onRangeChanged: _onRangeChanged,
        ),
        const SizedBox(height: 16),

        // แถว KPI 1: เงิน
        Row(
          children: [
            Expanded(
              child: DashboardKpiCardWidget(
                label: 'รายได้ (รับเงินแล้ว)',
                value: '${currencyFormatter.format(dashboard.income)} ฿',
                valueColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardKpiCardWidget(
                label: 'ยอดค้างชำระ',
                value: '${currencyFormatter.format(dashboard.unpaidTotal)} ฿',
                valueColor: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // แถว KPI 2: งาน
        Row(
          children: [
            Expanded(
              child: DashboardKpiCardWidget(
                label: 'รถเข้าซ่อม',
                value: '${dashboard.vehiclesInRange} คัน',
                valueColor: AppColors.info,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardKpiCardWidget(
                label: 'งานกำลังซ่อม',
                value: '${dashboard.activeRepairs} งาน',
                valueColor: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // กราฟแนวโน้มรายได้ (ปี = รายเดือน ช่วงอื่น = รายวัน)
        DashboardTrendChartWidget(trend: dashboard.trend),
        const SizedBox(height: 8),

        // ค่าแรง vs ค่าอะไหล่
        DashboardLaborPartsChartWidget(
          laborTotal: dashboard.laborTotal,
          partsTotal: dashboard.partsTotal,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
