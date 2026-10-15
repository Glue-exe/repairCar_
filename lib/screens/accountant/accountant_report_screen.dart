import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/accountant/accountant_receipt_dialog.dart';
import 'package:my_app/widgets/accountant/revenue_trend_chart_widget.dart';

enum ReportDateFilterType {
  today,
  last7Days,
  thisMonth,
  custom,
}

class AccountantReportScreen extends StatefulWidget {
  const AccountantReportScreen({super.key});

  @override
  State<AccountantReportScreen> createState() => _AccountantReportScreenState();
}

class _AccountantReportScreenState extends State<AccountantReportScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  ReportDateFilterType _selectedFilterType = ReportDateFilterType.thisMonth;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  RevenueReportSummaryModel _reportSummary = RevenueReportSummaryModel(
    totalPaidAmount: 0.0,
    paidCount: 0,
    totalLaborAmount: 0.0,
    totalPartsAmount: 0.0,
    cashTotalAmount: 0.0,
    cashCount: 0,
    transferTotalAmount: 0.0,
    transferCount: 0,
  );

  List<RevenueTrendItemModel> _trends = [];
  List<RevenueTransactionItemModel> _transactions = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _setFilter(ReportDateFilterType.thisMonth);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setFilter(ReportDateFilterType type) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (type) {
      case ReportDateFilterType.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day);
        break;
      case ReportDateFilterType.last7Days:
        start = now.subtract(const Duration(days: 6));
        break;
      case ReportDateFilterType.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case ReportDateFilterType.custom:
        // Will be set by date range picker
        return;
    }

    setState(() {
      _selectedFilterType = type;
      _startDate = start;
      _endDate = end;
    });

    _fetchReportData();
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'เลือกช่วงเวลาที่ต้องการดูรายงาน',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryGreen,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilterType = ReportDateFilterType.custom;
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReportData();
    }
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      // ถ้าช่วงเวลามากกว่า 60 วัน ให้ group by month ไม่งั้น group by day
      final daysDiff = _endDate.difference(_startDate).inDays;
      final groupBy = daysDiff > 60 ? 'month' : 'day';

      final response = await AppAPI.get(
        '/accountant/revenue_report?startDate=$startStr&endDate=$endStr&groupBy=$groupBy',
      );

      if (response.statusCode == 200) {
        final j = jsonDecode(response.body);
        final res = RevenueReportResponse.fromJson(j);
        if (!res.isError && res.data != null) {
          setState(() {
            _reportSummary = res.data!.summary;
            _trends = res.data!.trends;
            _transactions = res.data!.transactions;
            _isLoading = false;
          });
          return;
        } else {
          setState(() {
            _errorMessage = res.errorMessage.isNotEmpty ? res.errorMessage : 'ไม่สามารถโหลดข้อมูลรายงานได้';
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _errorMessage = 'เซิร์ฟเวอร์ตอบกลับผิดพลาด (${response.statusCode})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDateRangeTitle() {
    const thaiMonths = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];

    String formatThai(DateTime dt) {
      return '${dt.day} ${thaiMonths[dt.month]} ${dt.year + 543}';
    }

    if (_startDate.year == _endDate.year &&
        _startDate.month == _endDate.month &&
        _startDate.day == _endDate.day) {
      return 'ประจำวันที่ ${formatThai(_startDate)}';
    }

    return '${formatThai(_startDate)} - ${formatThai(_endDate)}';
  }

  List<RevenueTransactionItemModel> _filterTransactions() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _transactions;

    final queryClean = query.replaceAll(' ', '');

    return _transactions.where((item) {
      final plate = item.licensePlate.toLowerCase().replaceAll(' ', '');
      final car = item.carTitle.toLowerCase();
      final customer = item.customerName.toLowerCase();
      final phone = item.customerPhone.replaceAll(' ', '');
      final orderId = item.orderId.toString();
      final invoiceId = item.invoiceId.toString();

      return plate.contains(queryClean) ||
          car.contains(query) ||
          customer.contains(query) ||
          phone.contains(queryClean) ||
          orderId == queryClean.replaceAll('#', '').replaceAll('งาน', '') ||
          invoiceId == queryClean;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00');
    final filteredTransactions = _filterTransactions();

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('รายงานรายได้'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade50,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: _fetchReportData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReportData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. แถบเลือกช่วงเวลา (Date Filter)
              _buildDateFilterSection(),
              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                _buildErrorCard()
              else ...[
                // การ์ดสรุปตัวเลขหลัก (Executive Summary)
                _buildSummaryCards(currencyFormatter),
                const SizedBox(height: 14),

                // 2. กราฟเปรียบเทียบแนวโน้ม (Revenue Trends Chart)
                RevenueTrendChartWidget(
                  trends: _trends,
                  dateRangeSubtitle: _formatDateRangeTitle(),
                ),
                const SizedBox(height: 16),

                // 3. ตารางรายการใบเสร็จรับเงิน (Detailed Transaction List)
                _buildTransactionListSection(filteredTransactions, currencyFormatter),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ส่วนที่ 1: แถบเลือกช่วงเวลา (Date Filter)
  Widget _buildDateFilterSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range_rounded, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'เลือกช่วงเวลาแสดงรายงาน',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200, width: 0.8),
                  ),
                  child: Text(
                    _formatDateRangeTitle(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('วันนี้', ReportDateFilterType.today),
                  const SizedBox(width: 6),
                  _buildFilterChip('7 วันล่าสุด', ReportDateFilterType.last7Days),
                  const SizedBox(width: 6),
                  _buildFilterChip('เดือนนี้', ReportDateFilterType.thisMonth),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: _selectedFilterType == ReportDateFilterType.custom
                          ? Colors.white
                          : AppColors.primaryGreen,
                    ),
                    label: const Text('กำหนดเอง'),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedFilterType == ReportDateFilterType.custom
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                    backgroundColor: _selectedFilterType == ReportDateFilterType.custom
                        ? AppColors.primaryGreen
                        : Colors.grey.shade100,
                    side: BorderSide(
                      color: _selectedFilterType == ReportDateFilterType.custom
                          ? AppColors.primaryGreen
                          : Colors.grey.shade300,
                    ),
                    onPressed: _pickCustomDateRange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ReportDateFilterType type) {
    final isSelected = _selectedFilterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textDark,
      ),
      selectedColor: AppColors.primaryGreen,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
      ),
      onSelected: (selected) {
        if (selected) {
          _setFilter(type);
        }
      },
    );
  }

  // การ์ดสรุปตัวเลขหลัก
  Widget _buildSummaryCards(NumberFormat currencyFormatter) {
    return Column(
      children: [
        // แถวบน: รายได้รวมสุทธิ
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รายได้จริงที่ชำระแล้ว (Net Revenue)',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '฿${currencyFormatter.format(_reportSummary.totalPaidAmount)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_reportSummary.paidCount} บิล',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // แถวล่าง: แบ่งเป็น 2 กล่อง (ค่าแรง/ค่าอะไหล่ และ เงินสด/เงินโอน)
        Row(
          children: [
            // กล่องค่าแรง vs อะไหล่
            Expanded(
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pie_chart_outline_rounded, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'แยกประเภทรายได้',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ค่าแรง: ฿${currencyFormatter.format(_reportSummary.totalLaborAmount)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ค่าอะไหล่: ฿${currencyFormatter.format(_reportSummary.totalPartsAmount)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // กล่องเงินสด vs โอนเงิน
            Expanded(
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'ช่องทางชำระเงิน',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '💵 สด: ฿${currencyFormatter.format(_reportSummary.cashTotalAmount)} (${_reportSummary.cashCount})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📱 โอน: ฿${currencyFormatter.format(_reportSummary.transferTotalAmount)} (${_reportSummary.transferCount})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ส่วนที่ 3: ตารางรายการใบเสร็จรับเงิน (Detailed Transaction List)
  Widget _buildTransactionListSection(
    List<RevenueTransactionItemModel> transactions,
    NumberFormat currencyFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อ + ช่องค้นหา
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'รายการใบเสร็จ (${transactions.length} รายการ)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ช่องค้นหาเฉพาะในรายการใบเสร็จ
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'ค้นหาทะเบียนรถ, ลูกค้า หรือรหัสงาน...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryGreen),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal.shade200, width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal.shade200, width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // รายการใบเสร็จ
        if (transactions.isEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.receipt_long_outlined,
                      size: 44,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'ไม่พบบิลที่ตรงกับ "$_searchQuery"'
                          : 'ไม่มีรายการใบเสร็จในช่วงเวลาที่เลือก',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = transactions[index];
              return _buildTransactionCard(item, currencyFormatter);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionCard(
    RevenueTransactionItemModel item,
    NumberFormat currencyFormatter,
  ) {
    String formattedPaidTime = '-';
    if (item.paidAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(item.paidAt).toLocal();
        formattedPaidTime = DateFormat('dd/MM/yyyy HH:mm น.').format(dt);
      } catch (_) {
        formattedPaidTime = item.paidAt;
      }
    }

    final isTransfer = item.paymentMethodId == 2;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวบน: ทะเบียนรถ + วันที่เวลาชำระ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.licensePlate} (${item.carTitle})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formattedPaidTime,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ลูกค้า และ รหัสงาน
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ลูกค้า: ${item.customerName}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  'งาน #${item.orderId}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const Divider(height: 14),

            // ช่องทางการชำระ + ยอดเงิน + ปุ่มดูใบเสร็จ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge ช่องทางการชำระเงิน
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isTransfer ? Colors.blue.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTransfer ? Colors.blue.shade200 : Colors.amber.shade200,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTransfer ? Icons.qr_code_2_rounded : Icons.payments_rounded,
                        size: 14,
                        color: isTransfer ? Colors.blue.shade800 : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.paymentMethodName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isTransfer ? Colors.blue.shade800 : Colors.amber.shade900,
                        ),
                      ),
                      if (isTransfer && item.invoiceImageUrl != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.attachment_rounded, size: 12, color: Colors.blue),
                      ],
                    ],
                  ),
                ),

                // ยอดเงินสุทธิ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ค่าแรง ฿${currencyFormatter.format(item.laborTotal)} | อะไหล่ ฿${currencyFormatter.format(item.partsTotal)}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    Text(
                      '฿${currencyFormatter.format(item.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),

                // ปุ่มดูใบเสร็จ
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AccountantReceiptDialog(
                        order: item.toOrderItemModel(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 14),
                  label: const Text('ใบเสร็จ', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: _fetchReportData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
