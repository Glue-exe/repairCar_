import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/profit_report_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// รายงานกำไรสุทธิ — รายเดือน / รายปี + ปุ่มส่งออก PDF
class DashboardProfitReportWidget extends StatefulWidget {
  const DashboardProfitReportWidget({super.key});

  @override
  State<DashboardProfitReportWidget> createState() =>
      _DashboardProfitReportWidgetState();
}

class _DashboardProfitReportWidgetState
    extends State<DashboardProfitReportWidget> {
  final NumberFormat _currency = NumberFormat('#,##0');

  String _mode = 'month';
  List<ProfitReportItemModel> _items = [];
  bool _loading = true;
  bool _exporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await AppAPI.get('/dashboard/profit_report?mode=$_mode');
      final resJson = jsonDecode(response.body);

      if (!mounted) return;

      if (resJson['isError'] == true) {
        setState(() {
          _loading = false;
          _errorMessage = resJson['errorMessage'] as String? ?? 'เกิดข้อผิดพลาด';
        });
        return;
      }

      setState(() {
        _items = (resJson['data'] as List)
            .map((item) =>
                ProfitReportItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'ไม่สามารถโหลดรายงานกำไรสุทธิได้';
      });
    }
  }

  void _onModeChanged(String mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
    });
    _fetchReport();
  }

  double get _totalIncome => _items.fold(0.0, (sum, item) => sum + item.income);
  double get _totalExpense =>
      _items.fold(0.0, (sum, item) => sum + item.expense);
  double get _totalProfit => _items.fold(0.0, (sum, item) => sum + item.profit);

  // เฉพาะงวดที่มีข้อมูล (ยอด 0 ตัดออก — กราฟจะได้ไม่โล่ง)
  List<ProfitReportItemModel> get _visibleItems =>
      _items.where((item) => item.income > 0).toList();

  // 'YYYY-MM' → 'MM/YYYY' · 'YYYY' → 'YYYY'
  String _periodLabel(String period) {
    if (period.length == 7) {
      return '${period.substring(5, 7)}/${period.substring(0, 4)}';
    }
    return period;
  }

  // แกน Y ย่อ: 150000 -> 150k
  String _formatYAxis(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toInt()}k';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายงานกำไรสุทธิ',
                  style: AppTextStyles.cardTitle,
                ),
                Row(
                  children: [
                    _modeButton('month', 'รายเดือน'),
                    const SizedBox(width: 6),
                    _modeButton('year', 'รายปี'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _fetchReport,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildSummary(),
              const SizedBox(height: 16),
              _buildChart(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(
                    _exporting ? 'กำลังสร้างไฟล์...' : 'ส่งออกรายงาน (PDF)',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String mode, String label) {
    final selected = _mode == mode;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selected ? AppColors.primaryGreen : AppColors.inputBackground,
        foregroundColor: selected ? Colors.white : AppColors.textDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _onModeChanged(mode),
      child: Text(label, style: const TextStyle(fontSize: AppFontSizes.tag)),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryItem('รายได้รวม', _totalIncome, AppColors.textDark),
        ),
        Expanded(
          child:
              _summaryItem('ค่าใช้จ่ายรวม', _totalExpense, AppColors.warning),
        ),
        Expanded(
          child: _summaryItem(
            'กำไรสุทธิ',
            _totalProfit,
            _totalProfit < 0 ? AppColors.danger : AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: AppFontSizes.tag),
        ),
        const SizedBox(height: 2),
        Text(
          '${_currency.format(value)} ฿',
          style: AppTextStyles.bodyBold.copyWith(
            color: color,
            fontSize: AppFontSizes.subtitle,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildChart() {
    final visible = _visibleItems;

    if (visible.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('ยังไม่มีข้อมูลในช่วงนี้')),
      );
    }

    double maxAmount = 0;
    for (final item in visible) {
      if (item.profit > maxAmount) {
        maxAmount = item.profit;
      }
    }

    // เพดานแกน Y ปัดขึ้นเป็นเลขสวย + กันแท่งสูงสุดชนขอบบน
    double maxY = 10000;
    if (maxAmount > 0) {
      final target = maxAmount * 1.2;
      if (target >= 100000) {
        maxY = (target / 50000).ceil() * 50000;
      } else if (target >= 10000) {
        maxY = (target / 10000).ceil() * 10000;
      } else {
        maxY = (target / 1000).ceil() * 1000;
      }
    }

    final barWidth =
        visible.length <= 3 ? 36.0 : (visible.length <= 10 ? 26.0 : 18.0);

    // แท่งยิ่งเยอะยิ่งชิด → ย่อตัวเลขบนแท่ง (12k) เพื่อไม่ให้ซ้อนกัน
    final useCompact = visible.length > 8;

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          // โชว์ค่ากำไรบนแท่งทุกแท่งเลย (ไม่ต้องแตะ) — ปิด touch แล้วให้
          // showingTooltipIndicators ของแต่ละกลุ่มค้าง tooltip ไว้
          barTouchData: BarTouchData(
            handleBuiltInTouches: false,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 2,
              getTooltipColor: (group) => Colors.transparent,
              fitInsideHorizontally: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final index = group.x.toInt();
                if (index < 0 || index >= visible.length) {
                  return null;
                }
                final value = visible[index].profit;
                return BarTooltipItem(
                  useCompact ? _formatYAxis(value) : _currency.format(value),
                  AppTextStyles.caption.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatYAxis(value),
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 25,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (value != index.toDouble() ||
                      index < 0 ||
                      index >= visible.length) {
                    return const SizedBox.shrink();
                  }
                  // > 10 แท่งโชว์ทุก 3 · > 6 แท่งโชว์ทุก 2 · นอกนั้นโชว์ครบ + แท่งสุดท้ายเสมอ
                  final showEvery =
                      visible.length > 10 ? 3 : (visible.length > 6 ? 2 : 1);
                  if (index % showEvery != 0 && index != visible.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      _periodLabel(visible[index].period),
                      style: AppTextStyles.caption,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < visible.length; i++)
              BarChartGroupData(
                x: i,
                showingTooltipIndicators: const [0],
                barRods: [
                  BarChartRodData(
                    toY: visible[i].profit,
                    width: barWidth,
                    color: AppColors.success,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // พิมพ์รายงานเป็น PDF (ฟอนต์ไทย Kanit — แพทเทิร์นเดียวกับใบเบิก/บิล)
  Future<void> _exportPdf() async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
    });

    try {
      final pdf = pw.Document();
      final thaiFont = await PdfGoogleFonts.kanitRegular();
      final thaiBold = await PdfGoogleFonts.kanitBold();
      final isYear = _mode == 'year';
      final title =
          isYear ? 'รายงานกำไรสุทธิ (รายปี)' : 'รายงานกำไรสุทธิ (รายเดือน)';
      final fileName =
          isYear ? 'รายงานกำไรสุทธิ_รายปี.pdf' : 'รายงานกำไรสุทธิ_รายเดือน.pdf';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: thaiFont, bold: thaiBold),
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Divider(),
                  pw.Text('วันที่พิมพ์: ${_formatThaiDate(DateTime.now())}'),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'รายได้รวม: ${_currency.format(_totalIncome)} บาท',
                      ),
                      pw.Text(
                        'ค่าใช้จ่ายรวม: ${_currency.format(_totalExpense)} บาท',
                      ),
                      pw.Text(
                        'กำไรสุทธิ: ${_currency.format(_totalProfit)} บาท',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.TableHelper.fromTextArray(
                    headers: [
                      'งวด',
                      'รายได้ (บาท)',
                      'ค่าใช้จ่าย (บาท)',
                      'กำไรสุทธิ (บาท)',
                    ],
                    data: [
                      for (final item in _items)
                        [
                          _periodLabel(item.period),
                          _currency.format(item.income),
                          _currency.format(item.expense),
                          _currency.format(item.profit),
                        ],
                    ],
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งออกรายงานไม่สำเร็จ')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  String _formatThaiDate(DateTime dt) {
    final thaiYear = dt.year + 543;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$thaiYear $hour:$minute';
  }
}
