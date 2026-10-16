import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/accountant/accountant_payment_dialog.dart';
import 'package:my_app/widgets/accountant/accountant_receipt_dialog.dart';

class AccountantPaymentScreen extends StatefulWidget {
  const AccountantPaymentScreen({super.key});

  @override
  State<AccountantPaymentScreen> createState() => _AccountantPaymentScreenState();
}

class _AccountantPaymentScreenState extends State<AccountantPaymentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  String _errorMessage = '';

  List<AccountantOrderItemModel> _pendingOrders = [];
  List<AccountantOrderItemModel> _paidOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final responses = await Future.wait([
        AppAPI.get('/accountant/orders?type=pending'),
        AppAPI.get('/accountant/orders?type=paid'),
      ]);

      if (!mounted) return;

      if (responses[0].statusCode == 200) {
        final pendingJson = jsonDecode(responses[0].body);
        final pendingRes = AccountantOrdersResponse.fromJson(pendingJson);
        if (!pendingRes.isError) {
          _pendingOrders = pendingRes.data;
        }
      }

      if (responses[1].statusCode == 200) {
        final paidJson = jsonDecode(responses[1].body);
        final paidRes = AccountantOrdersResponse.fromJson(paidJson);
        if (!paidRes.isError) {
          _paidOrders = paidRes.data;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล กรุณาลองใหม่อีกครั้ง';
          _isLoading = false;
        });
      }
    }
  }

  // ฟังก์ชันกรองรายการงานตามคำค้นหา
  List<AccountantOrderItemModel> _filterOrders(List<AccountantOrderItemModel> orders) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return orders;

    final queryClean = query.replaceAll(' ', '');

    return orders.where((order) {
      final plate = order.licensePlate.toLowerCase();
      final plateClean = plate.replaceAll(' ', '');
      final carTitle = order.carTitle.toLowerCase();
      final customerName = order.customerFullName.toLowerCase();
      final customerPhone = order.customerPhone.replaceAll(' ', '');
      final orderId = order.orderId.toString();
      final symptom = order.symptom.toLowerCase();

      return plate.contains(query) ||
          plateClean.contains(queryClean) ||
          carTitle.contains(query) ||
          customerName.contains(query) ||
          customerPhone.contains(queryClean) ||
          orderId == query ||
          orderId == queryClean.replaceAll('#', '').replaceAll('งาน', '') ||
          symptom.contains(query);
    }).toList();
  }

  String _formatPaidDate(String? paidAtStr) {
    if (paidAtStr == null || paidAtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(paidAtStr).toLocal();
      const thaiMonths = [
        '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      final hourStr = dt.hour.toString().padLeft(2, '0');
      return '${dt.day} ${thaiMonths[dt.month]} ${dt.year + 543}, $hourStr:$minuteStr น.';
    } catch (_) {
      return paidAtStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPending = _filterOrders(_pendingOrders);
    final filteredPaid = _filterOrders(_paidOrders);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ชำระเงิน',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: [
            Tab(text: 'รอชำระ (${_pendingOrders.length})'),
            Tab(text: 'ชำระส่งมอบแล้ว (${_paidOrders.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : Column(
                  children: [
                    _buildSearchBox(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrderListView(
                            orders: filteredPending,
                            isPaidTab: false,
                          ),
                          _buildOrderListView(
                            orders: filteredPaid,
                            isPaidTab: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ส่วนกล่องค้นหา (Search Box)
  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'ค้นหาทะเบียนรถ, ยี่ห้อ, รุ่น, ลูกค้า หรือรหัสงาน...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primaryGreen),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  tooltip: 'ล้างคำค้นหา',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.inputBackground,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderListView({
    required List<AccountantOrderItemModel> orders,
    required bool isPaidTab,
  }) {
    final currencyFormatter = NumberFormat('#,##0.00');

    if (orders.isEmpty) {
      final hasSearch = _searchQuery.trim().isNotEmpty;
      return RefreshIndicator(
        onRefresh: _fetchOrders,
        color: AppColors.primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hasSearch ? Colors.orange.shade50 : (isPaidTab ? AppColors.successBg : AppColors.infoBg),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasSearch
                              ? Icons.search_off_rounded
                              : (isPaidTab ? Icons.receipt_long_rounded : Icons.task_alt_rounded),
                          size: 42,
                          color: hasSearch
                              ? Colors.orange.shade700
                              : (isPaidTab ? AppColors.success : AppColors.info),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        hasSearch
                            ? 'ไม่พบข้อมูลรถที่ตรงกับ "$_searchQuery"'
                            : (isPaidTab ? 'ไม่มีรายการงานที่ชำระส่งมอบแล้ว' : 'ไม่มีรายการงานที่รอชำระ'),
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSearch
                            ? 'ลองตรวจสอบคำสะกด หรือค้นหาด้วยเลขทะเบียนรถ'
                            : (isPaidTab ? 'เมื่อรับชำระเงิน ประวัติจะปรากฏที่นี่' : 'รถทุกคันชำระเงินเรียบร้อยแล้ว'),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (hasSearch) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(color: AppColors.primaryGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('ล้างคำค้นหา'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          // ป้ายสถานะสำหรับแท็บรอชำระ (สถานะงานซ่อม)
          final bool isRepairFinished = order.orderStatusId == 3;
          final Color repairStatusBg = isRepairFinished ? AppColors.successBg : AppColors.infoBg;
          final Color repairStatusTextColor = isRepairFinished ? AppColors.successText : AppColors.infoText;
          final String repairStatusLabel = order.orderStatusName.isNotEmpty ? order.orderStatusName : 'กำลังดำเนินการ';

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
                  // ทะเบียนรถ + ป้ายสถานะ + รหัสงาน
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                const SizedBox(width: 8),

                                // ถ้าเป็นแท็บรอชำระ แสดงสถานะซ่อม / ถ้าชำระแล้ว แสดงช่องทางจ่ายเงิน
                                if (!isPaidTab)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: repairStatusBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      repairStatusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: repairStatusTextColor,
                                      ),
                                    ),
                                  )
                                else
                                  _buildPaymentMethodBadge(order),
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

                  // ลูกค้า และ เบอร์โทร (แตะคัดลอกเบอร์ได้สะดวก)
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
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.customerPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('คัดลอกเบอร์โทร ${order.customerPhone} แล้ว'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: AppColors.primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                order.customerPhone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // อาการเสีย
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

                  // ถ้าชำระแล้ว แสดงวันเวลาที่ชำระ
                  if (isPaidTab && order.paidAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'ชำระเมื่อ: ${_formatPaidDate(order.paidAt)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],

                  const Divider(height: 18, color: AppColors.divider),

                  // ยอดเงินและปุ่ม Action
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
                                  color: isPaidTab ? AppColors.success : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isPaidTab)
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
                                onSuccess: _fetchOrders,
                              ),
                            );
                          },
                          icon: const Icon(Icons.payments_rounded, size: 17),
                          label: const Text(
                            'รับชำระเงิน',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AccountantReceiptDialog(order: order),
                            );
                          },
                          icon: const Icon(Icons.receipt_long_rounded, size: 17),
                          label: const Text(
                            'ดูใบเสร็จ',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ป้ายแสดงวิธีชำระเงิน (เงินสด vs โอนเงิน)
  Widget _buildPaymentMethodBadge(AccountantOrderItemModel order) {
    final isTransfer = order.paymentMethodId == 2 ||
        (order.paymentMethodName != null && order.paymentMethodName!.contains('โอน'));
    final label = isTransfer ? 'โอนเงิน' : 'เงินสด';
    final icon = isTransfer ? Icons.account_balance_rounded : Icons.payments_rounded;
    final bgColor = isTransfer ? AppColors.infoBg : AppColors.successBg;
    final textColor = isTransfer ? AppColors.infoText : AppColors.successText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
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
              _errorMessage,
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
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('ลองใหม่อีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}
