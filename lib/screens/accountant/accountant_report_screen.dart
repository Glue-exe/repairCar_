import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/accountant/accountant_receipt_dialog.dart';
import 'package:my_app/widgets/accountant/revenue_trend_chart_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum ReportDateFilterType { today, last7Days, thisMonth, custom }

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

  String _statusFilter = 'paid'; // 'paid' | 'pending'
  bool _isExportingPdf = false;

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

      final daysDiff = _endDate.difference(_startDate).inDays;
      final groupBy = daysDiff > 60 ? 'month' : 'day';

      final response = await AppAPI.get(
        '/accountant/revenue_report?startDate=$startStr&endDate=$endStr&groupBy=$groupBy&status=$_statusFilter',
      );

      if (!mounted) return;

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
            _errorMessage = res.errorMessage.isNotEmpty
                ? res.errorMessage
                : 'ไม่สามารถโหลดข้อมูลรายงานได้';
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
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateRangeTitle() {
    const thaiMonths = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'รายงานรายได้',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'พิมพ์ / ส่งออก PDF',
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.info,
                    ),
                  )
                : const Icon(Icons.print, color: AppColors.info),
            onPressed: (_isLoading || _isExportingPdf)
                ? null
                : _exportReportPdf,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReportData,
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
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
                _buildTransactionListSection(
                  filteredTransactions,
                  currencyFormatter,
                ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ช่วงเวลาแสดงรายงาน',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDateRangeTitle(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
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
                  _buildFilterChip(
                    '7 วันล่าสุด',
                    ReportDateFilterType.last7Days,
                  ),
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
                    backgroundColor:
                        _selectedFilterType == ReportDateFilterType.custom
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
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border, width: 0.8),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryGreen.withValues(
                    alpha: 0.12,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รายได้จริงที่ชำระแล้ว (Net Revenue)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_reportSummary.paidCount} บิล',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.successText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // แถวล่าง: 2 กล่อง (ค่าแรง/อะไหล่ และ เงินสด/โอน)
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 16,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'แยกประเภทรายได้',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ค่าแรง: ฿${currencyFormatter.format(_reportSummary.totalLaborAmount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ค่าอะไหล่: ฿${currencyFormatter.format(_reportSummary.totalPartsAmount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ช่องทางชำระเงิน',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เงินสด: ฿${currencyFormatter.format(_reportSummary.cashTotalAmount)} (${_reportSummary.cashCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'โอนเงิน: ฿${currencyFormatter.format(_reportSummary.transferTotalAmount)} (${_reportSummary.transferCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
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

  // ส่วนที่ 3: ตารางรายการใบเสร็จรับเงิน และแท็บสลับ ชำระแล้ว / รอชำระ
  Widget _buildTransactionListSection(
    List<RevenueTransactionItemModel> transactions,
    NumberFormat currencyFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // แท็บสลับ: รายการชำระแล้ว (Paid) vs รายการรอชำระ (Pending)
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (_statusFilter != 'paid') {
                      setState(() {
                        _statusFilter = 'paid';
                      });
                      _fetchReportData();
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusFilter == 'paid'
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _statusFilter == 'paid'
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: _statusFilter == 'paid'
                                ? AppColors.primaryGreen
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ชำระแล้ว (${_reportSummary.paidCount})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _statusFilter == 'paid'
                                  ? AppColors.primaryGreen
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (_statusFilter != 'pending') {
                      setState(() {
                        _statusFilter = 'pending';
                      });
                      _fetchReportData();
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusFilter == 'pending'
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _statusFilter == 'pending'
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pending_actions_rounded,
                            size: 16,
                            color: _statusFilter == 'pending'
                                ? const Color(0xFFD97706)
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'รอชำระ (${_reportSummary.pendingCount})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _statusFilter == 'pending'
                                  ? const Color(0xFFD97706)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        (_statusFilter == 'pending'
                                ? Colors.amber
                                : AppColors.primaryGreen)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _statusFilter == 'pending'
                        ? Icons.pending_actions_rounded
                        : Icons.receipt_long_rounded,
                    color: _statusFilter == 'pending'
                        ? const Color(0xFFD97706)
                        : AppColors.primaryGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusFilter == 'pending'
                      ? 'รายการงานรอชำระ (${transactions.length} รายการ)'
                      : 'รายการใบเสร็จ (${transactions.length} รายการ)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(
                  color: AppColors.primaryGreen,
                  width: 0.8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (_isLoading || _isExportingPdf)
                  ? null
                  : _exportReportPdf,
              icon: const Icon(Icons.print_outlined, size: 14),
              label: const Text('พิมพ์รายงาน', style: TextStyle(fontSize: 11)),
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
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'ค้นหาทะเบียนรถ, ลูกค้า หรือรหัสงาน...',
            hintStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppColors.primaryGreen,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // รายการใบเสร็จ
        if (transactions.isEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border, width: 0.8),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.receipt_long_outlined,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'ไม่พบบิลที่ตรงกับ "$_searchQuery"'
                          : 'ไม่มีรายการใบเสร็จในช่วงเวลาที่เลือก',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
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
        const thaiMonths = [
          '',
          'ม.ค.',
          'ก.พ.',
          'มี.ค.',
          'เม.ย.',
          'พ.ค.',
          'มิ.ย.',
          'ก.ค.',
          'ส.ค.',
          'ก.ย.',
          'ต.ค.',
          'พ.ย.',
          'ธ.ค.',
        ];
        final minuteStr = dt.minute.toString().padLeft(2, '0');
        final hourStr = dt.hour.toString().padLeft(2, '0');
        formattedPaidTime =
            '${dt.day} ${thaiMonths[dt.month]} ${dt.year + 543}, $hourStr:$minuteStr น.';
      } catch (_) {
        formattedPaidTime = item.paidAt;
      }
    }

    final isPending = item.paymentStatusId == 1;
    final isTransfer = item.paymentMethodId == 2;

    return Card(
      elevation: 1.5,
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ลูกค้า: ${item.customerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'งาน #${item.orderId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const Divider(height: 14, color: AppColors.divider),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.warningBg
                        : (isTransfer ? AppColors.infoBg : AppColors.successBg),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPending
                            ? Icons.pending_actions_rounded
                            : (isTransfer
                                  ? Icons.account_balance_rounded
                                  : Icons.payments_rounded),
                        size: 11,
                        color: isPending
                            ? AppColors.warningText
                            : (isTransfer
                                  ? AppColors.infoText
                                  : AppColors.successText),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isPending ? 'รอชำระ' : item.paymentMethodName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPending
                              ? AppColors.warningText
                              : (isTransfer
                                    ? AppColors.infoText
                                    : AppColors.successText),
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ค่าแรง ฿${currencyFormatter.format(item.laborTotal)} | อะไหล่ ฿${currencyFormatter.format(item.partsTotal)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '฿${currencyFormatter.format(item.totalAmount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPending
                            ? const Color(0xFFB45309)
                            : AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isPending
                        ? const Color(0xFFB45309)
                        : AppColors.primaryGreen,
                    side: BorderSide(
                      color: isPending
                          ? Colors.amber.shade400
                          : AppColors.primaryGreen,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                  icon: Icon(
                    isPending ? Icons.description_outlined : Icons.receipt_long,
                    size: 14,
                  ),
                  label: Text(
                    isPending ? 'ดูบิล' : 'ใบเสร็จ',
                    style: const TextStyle(fontSize: 12),
                  ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 44,
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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

  // ส่งออกรายงานสรุปรายรับและบิลเป็นเอกสาร PDF ผ่าน printing package
  Future<void> _exportReportPdf() async {
    if (_isExportingPdf) return;
    setState(() {
      _isExportingPdf = true;
    });

    try {
      final pdf = pw.Document();
      final thaiRegular = await PdfGoogleFonts.kanitRegular();
      final thaiBold = await PdfGoogleFonts.kanitBold();

      final currency = NumberFormat('#,##0.00');
      final dateTitle = _formatDateRangeTitle();
      final printTime = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(base: thaiRegular, bold: thaiBold),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'อู่ซ่อมรถยนต์เทคนิคยนต์',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                        pw.Text(
                          'รายงานสรุปรายรับและการเงิน (Financial Revenue Report)',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ช่วงเวลา: $dateTitle',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'วันที่พิมพ์: $printTime น.',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'หน้า ${context.pageNumber} จาก ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // 1. ตารางสรุปภาพรวมทางการเงิน
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'สรุปภาพรวมทางการเงิน',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'รายรับรวมสุทธิ (ชำระแล้ว): ฿${currency.format(_reportSummary.totalPaidAmount)} (${_reportSummary.paidCount} บิล)',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'ยอดค้างชำระ / รอเก็บเงิน: ฿${currency.format(_reportSummary.totalPendingAmount)} (${_reportSummary.pendingCount} งาน)',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber900,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'ค่าแรง: ฿${currency.format(_reportSummary.totalLaborAmount)}  |  ค่าอะไหล่: ฿${currency.format(_reportSummary.totalPartsAmount)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'เงินสด: ฿${currency.format(_reportSummary.cashTotalAmount)} (${_reportSummary.cashCount})  |  เงินโอน: ฿${currency.format(_reportSummary.transferTotalAmount)} (${_reportSummary.transferCount})',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 2. หัวข้อตารางรายการ
              pw.Text(
                _statusFilter == 'pending'
                    ? 'รายการงานรอชำระ / ค้างรับ (${_transactions.length} รายการ)'
                    : 'รายละเอียดบิลที่ชำระแล้ว (${_transactions.length} รายการ)',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              // 3. ตารางรายการบิล
              if (_transactions.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'ไม่มีรายการในช่วงเวลาที่เลือก',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'ลำดับ',
                    'วันที่',
                    'งาน#',
                    'ทะเบียนรถ (รุ่น)',
                    'ลูกค้า',
                    'ช่องทาง/สถานะ',
                    'ค่าแรง (฿)',
                    'อะไหล่ (฿)',
                    'รวม (฿)',
                  ],
                  data: [
                    for (int i = 0; i < _transactions.length; i++)
                      [
                        '${i + 1}',
                        _formatDateOnly(_transactions[i].paidAt),
                        '#${_transactions[i].orderId}',
                        '${_transactions[i].licensePlate}\n(${_transactions[i].carTitle})',
                        _transactions[i].customerName,
                        _transactions[i].paymentStatusId == 1
                            ? 'รอชำระ'
                            : _transactions[i].paymentMethodName,
                        currency.format(_transactions[i].laborTotal),
                        currency.format(_transactions[i].partsTotal),
                        currency.format(_transactions[i].totalAmount),
                      ],
                  ],
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    5: pw.Alignment.center,
                    6: pw.Alignment.centerRight,
                    7: pw.Alignment.centerRight,
                    8: pw.Alignment.centerRight,
                  },
                  columnWidths: {
                    0: const pw.FixedColumnWidth(26),
                    1: const pw.FixedColumnWidth(55),
                    2: const pw.FixedColumnWidth(35),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FixedColumnWidth(50),
                    6: const pw.FixedColumnWidth(50),
                    7: const pw.FixedColumnWidth(50),
                    8: const pw.FixedColumnWidth(55),
                  },
                ),
              pw.SizedBox(height: 24),

              // 4. ลายเซ็นผู้จัดทำและผู้อนุมัติ
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 140,
                        child: pw.Divider(color: PdfColors.grey500),
                      ),
                      pw.Text(
                        'ลงชื่อ ....................................................',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'พนักงานบัญชีและการเงิน',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 140,
                        child: pw.Divider(color: PdfColors.grey500),
                      ),
                      pw.Text(
                        'ลงชื่อ ....................................................',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'ผู้จัดการ / เจ้าของอู่',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final fileName =
          'รายงานรายได้_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.pdf';
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  String _formatDateOnly(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year + 543}';
    } catch (_) {
      return dateStr;
    }
  }
}
