import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/models/monthly_income_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/dashboard/income_chart_widget.dart';

class AccountantReportScreen extends StatefulWidget {
  const AccountantReportScreen({super.key});

  @override
  State<AccountantReportScreen> createState() => _AccountantReportScreenState();
}

class _AccountantReportScreenState extends State<AccountantReportScreen> {
  bool _isLoading = false;
  AccountantSummaryModel _summary = AccountantSummaryModel(
    totalPendingAmount: 0.0,
    pendingCount: 0,
    totalPaidAmount: 0.0,
    paidCount: 0,
  );
  List<MonthlyIncomeModel> _monthlyIncomes = [];
  List<AccountantOrderItemModel> _recentPaidOrders = [];

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final responses = await Future.wait([
        AppAPI.get('/accountant/summary'),
        AppAPI.get('/income/monthly_history'),
        AppAPI.get('/accountant/orders?type=paid'),
      ]);

      if (responses[0].statusCode == 200) {
        final j = jsonDecode(responses[0].body);
        final res = AccountantSummaryResponse.fromJson(j);
        if (!res.isError) _summary = res.data;
      }

      if (responses[1].statusCode == 200) {
        final j = jsonDecode(responses[1].body);
        final res = MonthlyIncomeResponse.fromJson(j);
        if (!res.isError) _monthlyIncomes = res.data;
      }

      if (responses[2].statusCode == 200) {
        final j = jsonDecode(responses[2].body);
        final res = AccountantOrdersResponse.fromJson(j);
        if (!res.isError) _recentPaidOrders = res.data;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('รายงาน'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade50,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchReportData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // สรุปยอดรวม
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'สรุปภาพรวมรายได้',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('รายได้ที่ชำระแล้วเดือนนี้:'),
                                Text(
                                  '฿${currencyFormatter.format(_summary.totalPaidAmount)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ยอดรอรับชำระคงค้าง:'),
                                Text(
                                  '฿${currencyFormatter.format(_summary.totalPendingAmount)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('จำนวนงานที่ปิดยอดแล้ว:'),
                                Text(
                                  '${_summary.paidCount} งาน',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // กราฟรายได้
                    IncomeChartWidget(incomeList: _monthlyIncomes),
                    const SizedBox(height: 12),

                    // รายการชำระเงินล่าสุด
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ประวัติการรับชำระเงินล่าสุด',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            if (_recentPaidOrders.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Center(child: Text('ยังไม่มีประวัติการรับชำระเงิน')),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentPaidOrders.length > 5 ? 5 : _recentPaidOrders.length,
                                separatorBuilder: (context, index) => const Divider(height: 16),
                                itemBuilder: (context, index) {
                                  final item = _recentPaidOrders[index];
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.licensePlate,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            '${item.customerFullName} • ${item.paymentMethodName ?? 'ชำระแล้ว'}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '฿${currencyFormatter.format(item.totalAmount)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
