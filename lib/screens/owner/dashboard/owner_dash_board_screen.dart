import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/dashboard_summary_model.dart';
import 'package:my_app/models/monthly_income_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/dashboard/income_chart_widget.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  DashboardSummaryModel _summary = DashboardSummaryModel(
    monthlyIncome: 0.0,
    unpaidTotal: 0.0,
    vehiclesThisMonth: 0,
    activeJobsCount: 0,
    pendingApprovalsCount: 0,
  );

  List<MonthlyIncomeModel> _monthlyIncomes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final resSummary = await AppAPI.get("/dashboard/summary");
    final summaryJson = jsonDecode(resSummary.body);

    final resHistory = await AppAPI.get("/income/monthly_history");
    final historyJson = jsonDecode(resHistory.body);

    setState(() {
      _summary = DashboardSummaryModel.fromJson(summaryJson['data']);
      _monthlyIncomes = (historyJson['data'] as List)
          .map((item) => MonthlyIncomeModel.fromJson(item as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // แถวที่ 1
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('รายได้เดือนนี้ (ชำระแล้ว)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('${_summary.monthlyIncome} ฿', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ยอดค้างชำระ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('${_summary.unpaidTotal} ฿', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // แถวที่ 2
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('งานที่กำลังซ่อม', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('${_summary.activeJobsCount} งาน', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('รถเข้าซ่อมเดือนนี้', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('${_summary.vehiclesThisMonth} คัน', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // แถวที่ 3 (การ์ดยาว)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('อะไหล่รออนุมัติสั่งซื้อ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          Text('${_summary.pendingApprovalsCount} รายการ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // กราฟรายได้
                  IncomeChartWidget(incomeList: _monthlyIncomes),
                ],
              ),
            ),
    );
  }
}
