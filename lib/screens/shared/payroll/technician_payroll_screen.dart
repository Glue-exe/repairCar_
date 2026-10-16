import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/payroll_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/payroll/salary_payment_dialog.dart';
import 'package:my_app/widgets/payroll/salary_slip_dialog.dart';

class TechnicianPayrollScreen extends StatefulWidget {
  final String title;

  const TechnicianPayrollScreen({
    super.key,
    this.title = 'เงินเดือนช่าง',
  });

  @override
  State<TechnicianPayrollScreen> createState() => _TechnicianPayrollScreenState();
}

class _TechnicianPayrollScreenState extends State<TechnicianPayrollScreen> {
  DateTime _currentDate = DateTime.now();
  bool _isLoading = false;
  String _errorMessage = '';

  MonthlyPayrollData? _payrollData;
  String _statusFilter = 'all'; // 'all' | 'pending' | 'paid'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPayrollData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _monthParam => DateFormat('yyyy-MM').format(_currentDate);

  String _formatThaiMonthTitle(DateTime dt) {
    const thaiMonths = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${thaiMonths[dt.month]} ${dt.year + 543}';
  }

  Future<void> _fetchPayrollData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await AppAPI.get('/payroll/monthly?month=$_monthParam');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final res = MonthlyPayrollResponse.fromJson(json);

        if (!res.isError && res.data != null) {
          setState(() {
            _payrollData = res.data;
            _isLoading = false;
          });
          return;
        } else {
          setState(() {
            _errorMessage = res.errorMessage.isNotEmpty ? res.errorMessage : 'ไม่สามารถโหลดข้อมูลเงินเดือนได้';
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

  void _changeMonth(int delta) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + delta, 1);
    });
    _fetchPayrollData();
  }

  Future<void> _pickMonthYear() async {
    int selectedYear = _currentDate.year;
    int selectedMonth = _currentDate.month;

    const thaiMonths = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('เลือกรอบเดือนและปี', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // เลือกปี
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ปี พ.ศ.:', style: TextStyle(fontSize: 14)),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(10, (i) {
                          final yr = DateTime.now().year - 4 + i;
                          return DropdownMenuItem(
                            value: yr,
                            child: Text('${yr + 543}'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedYear = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // เลือกเดือน
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('เดือน:', style: TextStyle(fontSize: 14)),
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (i) {
                          final m = i + 1;
                          return DropdownMenuItem(
                            value: m,
                            child: Text(thaiMonths[m]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedMonth = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentDate = DateTime(selectedYear, selectedMonth, 1);
                    });
                    _fetchPayrollData();
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<TechnicianPayrollItem> _filterTechnicians() {
    if (_payrollData == null) return [];
    var list = _payrollData!.technicians;

    // กรองตามสถานะ
    if (_statusFilter == 'pending') {
      list = list.where((item) => !item.isPaid).toList();
    } else if (_statusFilter == 'paid') {
      list = list.where((item) => item.isPaid).toList();
    }

    // กรองตามคำค้นหา
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return list;

    final queryClean = query.replaceAll(' ', '');
    return list.where((item) {
      final name = item.fullName.toLowerCase();
      final phone = item.phone.replaceAll(' ', '');
      return name.contains(query) || phone.contains(queryClean);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00');
    final filteredTechnicians = _filterTechnicians();
    final summary = _payrollData?.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPayrollData,
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. แถบเลือกรอบเดือน
              _buildMonthNavigator(),
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
                // 2. การ์ดสรุปยอดประจำเดือน (Summary Card)
                if (summary != null) _buildSummaryCard(summary, currencyFormatter),
                const SizedBox(height: 14),

                // 3. แท็บสลับสถานะ (ทั้งหมด / รอจ่าย / จ่ายแล้ว)
                _buildStatusTabBar(summary),
                const SizedBox(height: 10),

                // 4. ช่องค้นหา
                _buildSearchBox(),
                const SizedBox(height: 10),

                // 5. รายการการ์ดช่างแต่ละคน
                _buildTechnicianList(filteredTechnicians, currencyFormatter),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 1. แถบเลือกรอบเดือน (Month Navigator)
  Widget _buildMonthNavigator() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryGreen, size: 28),
              tooltip: 'เดือนก่อนหน้า',
              onPressed: () => _changeMonth(-1),
            ),
            InkWell(
              onTap: _pickMonthYear,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _formatThaiMonthTitle(_currentDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryGreen, size: 28),
              tooltip: 'เดือนถัดไป',
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
      ),
    );
  }

  // 2. การ์ดสรุปยอดประจำเดือน
  Widget _buildSummaryCard(MonthlyPayrollSummary summary, NumberFormat currencyFormatter) {
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
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  child: const Icon(Icons.payments_rounded, color: AppColors.primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ยอดรวมเงินเดือนช่างเดือนนี้',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '฿${currencyFormatter.format(summary.totalPayout)}',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ช่าง ${summary.totalTechnicians} คน',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
            const Divider(height: 18, color: AppColors.divider),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'จ่ายแล้ว (${summary.paidCount})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '฿${currencyFormatter.format(summary.paidTotalAmount)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.successText),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pending_actions_rounded, size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'รอจ่าย (${summary.pendingCount})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warningText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '฿${currencyFormatter.format(summary.pendingTotalAmount)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warningText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. แท็บสลับสถานะ
  Widget _buildStatusTabBar(MonthlyPayrollSummary? summary) {
    final allCount = summary?.totalTechnicians ?? 0;
    final pendingCount = summary?.pendingCount ?? 0;
    final paidCount = summary?.paidCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildTabItem('all', 'ทั้งหมด ($allCount)', Icons.people_outline),
          _buildTabItem('pending', 'รอจ่าย ($pendingCount)', Icons.pending_actions_rounded),
          _buildTabItem('paid', 'จ่ายแล้ว ($paidCount)', Icons.check_circle_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(String key, String label, IconData icon) {
    final isSelected = _statusFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _statusFilter = key;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primaryGreen : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primaryGreen : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. ช่องค้นหา
  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อช่าง หรือเบอร์โทร...',
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.primaryGreen),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  // 5. รายการการ์ดช่าง
  Widget _buildTechnicianList(List<TechnicianPayrollItem> list, NumberFormat currencyFormatter) {
    if (list.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Center(
            child: Column(
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty ? 'ไม่พบช่างที่ตรงกับ "$_searchQuery"' : 'ไม่มีข้อมูลช่างในสถานะนี้',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildTechnicianCard(item, currencyFormatter);
      },
    );
  }

  Widget _buildTechnicianCard(TechnicianPayrollItem item, NumberFormat currencyFormatter) {
    String formattedPaidDate = '-';
    if (item.paidDate != null && item.paidDate!.isNotEmpty) {
      try {
        final dt = DateTime.parse(item.paidDate!).toLocal();
        const thaiMonths = [
          '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
          'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
        ];
        formattedPaidDate = '${dt.day} ${thaiMonths[dt.month]} ${dt.year + 543}';
      } catch (_) {
        formattedPaidDate = item.paidDate!;
      }
    }

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
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            item.roleName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                          Text(
                            item.phone,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ป้ายสถานะ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isPaid ? AppColors.successBg : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                        size: 11,
                        color: item.isPaid ? AppColors.successText : AppColors.warningText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.isPaid ? 'จ่ายแล้ว' : 'รอจ่าย',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.isPaid ? AppColors.successText : AppColors.warningText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.isPaid ? 'ยอดที่จ่ายจริง' : 'ฐานเงินเดือนปัจจุบัน',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      '฿${currencyFormatter.format(item.isPaid ? item.paidAmount : item.baseSalary)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.isPaid ? AppColors.primaryGreen : const Color(0xFFB45309),
                      ),
                    ),
                    if (item.isPaid)
                      Text(
                        'วันที่จ่าย: $formattedPaidDate (${item.paymentMethodName ?? 'โอนเงิน'})',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),
                // ปุ่ม Action
                if (!item.isPaid)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => SalaryPaymentDialog(
                          technician: item,
                          targetMonth: _monthParam,
                          onSuccess: _fetchPayrollData,
                        ),
                      );
                    },
                    icon: const Icon(Icons.payments_rounded, size: 16),
                    label: const Text('จ่ายเงินเดือน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => SalarySlipDialog(
                          technician: item,
                          targetMonth: _monthParam,
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: const Text('ดูสลิป', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 36),
              const SizedBox(height: 8),
              Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _fetchPayrollData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
