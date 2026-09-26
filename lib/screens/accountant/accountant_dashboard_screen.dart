import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/accountant/accountant_payment_dialog.dart';

class AccountantDashboardScreen extends StatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  State<AccountantDashboardScreen> createState() => _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState extends State<AccountantDashboardScreen> {
  bool _isLoading = false;

  AccountantSummaryModel _summary = AccountantSummaryModel(
    totalPendingAmount: 0.0,
    pendingCount: 0,
    totalPaidAmount: 0.0,
    paidCount: 0,
  );

  List<AccountantOrderItemModel> _pendingOrders = [];

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final responses = await Future.wait([
        AppAPI.get("/accountant/summary"),
        AppAPI.get("/accountant/orders?type=pending"),
      ]);

      if (responses[0].statusCode == 200) {
        final summaryJson = jsonDecode(responses[0].body);
        final summaryRes = AccountantSummaryResponse.fromJson(summaryJson);
        if (!summaryRes.isError) {
          _summary = summaryRes.data;
        }
      }

      if (responses[1].statusCode == 200) {
        final pendingJson = jsonDecode(responses[1].body);
        final pendingRes = AccountantOrdersResponse.fromJson(pendingJson);
        if (!pendingRes.isError) {
          _pendingOrders = pendingRes.data;
        }
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
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.teal.shade50,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // แสดงแค่ 2 การ์ด: ยอดที่ยังไม่ชำระ และ งานที่รอชำระ (ตามรูปแบบ Owner ในภาพ)
                    Row(
                      children: [
                        // การ์ดที่ 1: ยอดที่ยังไม่ชำระ
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'ยอดที่ยังไม่ชำระ',
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '฿${currencyFormatter.format(_summary.totalPendingAmount)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // การ์ดที่ 2: งานที่รอชำระ
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'งานที่รอชำระ',
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_summary.pendingCount} งาน',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // รายการงานที่รอชำระ
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'รายการงานที่รอชำระ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_pendingOrders.isEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: Colors.white,
                        child: const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'ไม่มีรายการงานที่ค้างชำระในขณะนี้',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pendingOrders.length,
                        itemBuilder: (context, index) {
                          final order = _pendingOrders[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${order.licensePlate} (${order.carTitle})',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        'งาน #${order.orderId}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ลูกค้า: ${order.customerFullName}  เบอร์โทร: ${order.customerPhone}',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  if (order.symptom.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'อาการ: ${order.symptom}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ค่าแรง: ฿${currencyFormatter.format(order.laborTotal)}  ค่าอะไหล่: ฿${currencyFormatter.format(order.partsTotal)}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ยอดสุทธิ: ฿${currencyFormatter.format(order.totalAmount)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AccountantPaymentDialog(
                                              order: order,
                                              onSuccess: _fetchData,
                                            ),
                                          );
                                        },
                                        child: const Text('รับชำระเงิน'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
