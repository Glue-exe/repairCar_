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
  String? _errorMessage;

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
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        AppAPI.get("/accountant/summary"),
        AppAPI.get("/accountant/orders?type=pending"),
      ]);

      if (!mounted) return;

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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.primaryGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // สรุปสถิติภาพรวม 4 มิติ (ยอดรอชำระ vs ยอดที่เก็บได้แล้วเดือนนี้)
                        _buildSummaryStatsGrid(),
                        const SizedBox(height: 18),

                        // หัวข้อรายการงานที่รอชำระ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'รายการงานที่รอชำระ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_pendingOrders.length} รายการ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warningText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // รายการงานที่รอชำระ
                        if (_pendingOrders.isEmpty)
                          _buildEmptyPendingOrdersCard()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pendingOrders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderItemCard(_pendingOrders[index]);
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  // วิดเจ็ตแสดงสถิติสรุป 4 กล่อง (2 แถว)
  Widget _buildSummaryStatsGrid() {
    final currencyFormatter = NumberFormat('#,##0.00');

    return Column(
      children: [
        // แถวที่ 1: สถานะค้างชำระ (Pending)
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'ยอดรอชำระ',
                value: '฿${currencyFormatter.format(_summary.totalPendingAmount)}',
                icon: Icons.pending_actions_rounded,
                accentColor: AppColors.warning,
                bgColor: AppColors.warningBg.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                title: 'งานรอชำระ',
                value: '${_summary.pendingCount} คัน',
                icon: Icons.receipt_long_rounded,
                accentColor: AppColors.info,
                bgColor: AppColors.infoBg.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // แถวที่ 2: งานที่ชำระแล้วเดือนนี้ (Month-to-Date Performance)
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'ยอดชำระแล้วเดือนนี้',
                value: '฿${currencyFormatter.format(_summary.totalPaidAmount)}',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: AppColors.success,
                bgColor: AppColors.successBg.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                title: 'ชำระแล้วเดือนนี้',
                value: '${_summary.paidCount} บิล',
                icon: Icons.task_alt_rounded,
                accentColor: AppColors.primaryGreen,
                bgColor: AppColors.primaryGreen.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // การ์ดแสดงรายการงานซ่อม
  Widget _buildOrderItemCard(AccountantOrderItemModel order) {
    final currencyFormatter = NumberFormat('#,##0.00');

    // สถานะงานซ่อม (เช่น ซ่อมเสร็จสิ้น / กำลังซ่อม)
    final bool isRepairFinished = order.orderStatusId == 3;
    final Color statusBg = isRepairFinished ? AppColors.successBg : AppColors.infoBg;
    final Color statusTextColor = isRepairFinished ? AppColors.successText : AppColors.infoText;
    final String statusLabel = order.orderStatusName.isNotEmpty ? order.orderStatusName : 'กำลังดำเนินการ';

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวบน: ทะเบียนรถ + ยี่ห้อ/รุ่น + ป้ายงาน
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            order.licensePlate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.carTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'งาน #${order.orderId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ลูกค้าและเบอร์โทร
            Row(
              children: [
                const Icon(Icons.person_outline, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.customerFullName,
                    style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  order.customerPhone,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
              ],
            ),

            if (order.symptom.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.build_circle_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'อาการ: ${order.symptom}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 18, color: AppColors.divider),

            // ยอดเงิน + ปุ่มรับชำระเงิน
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ค่าแรง ฿${currencyFormatter.format(order.laborTotal)} · ค่าอะไหล่ ฿${currencyFormatter.format(order.partsTotal)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text(
                          'ยอดสุทธิ: ',
                          style: TextStyle(fontSize: 13, color: AppColors.textDark),
                        ),
                        Text(
                          '฿${currencyFormatter.format(order.totalAmount)}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  icon: const Icon(Icons.payments_rounded, size: 17),
                  label: const Text(
                    'รับชำระเงิน',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPendingOrdersCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ไม่มีรายการงานที่ค้างชำระในขณะนี้',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'รถทุกคันได้รับการชำระเงินเรียบร้อยแล้ว',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('ลองใหม่อีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}
