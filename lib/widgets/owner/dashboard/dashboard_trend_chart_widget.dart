import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/owner_dashboard_model.dart';

// กราฟแท่งรายได้ — วาดเฉพาะจุดที่มีเงินเข้า (ยอด 0 ตัดออก: ช่องว่างทิ้งไว้กราฟจะโล่ง แท่งบาง)
// ≤ 10 แท่ง: เต็มความกว้าง ป้ายครบ · > 10 แท่ง: กว้างคงที่ เลื่อนแนวนอนได้
// (หน้ารายงานบัญชีใช้ income_chart_widget ต่างหาก)
class DashboardTrendChartWidget extends StatelessWidget {
  final List<DashboardTrendItemModel> trend;

  const DashboardTrendChartWidget({super.key, required this.trend});

  // แท่งที่จะวาดจริง = จุดที่มีรายได้
  List<DashboardTrendItemModel> get _visible =>
      trend.where((item) => item.total > 0).toList();

  // แกน Y ย่อ: 150000 -> 150k
  String _formatYAxis(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toInt()}k';
    }
    return value.toInt().toString();
  }

  // วันที่เต็มสำหรับ tooltip: '13/10/2026' หรือ '10/2026'
  String _fullLabel(String period) {
    if (period.length == 7) {
      // '2026-10' → '10/2026'
      return '${period.substring(5, 7)}/${period.substring(0, 4)}';
    }
    // '2026-10-13' → '13/10/2026'
    return '${period.substring(8, 10)}/${period.substring(5, 7)}/${period.substring(0, 4)}';
  }

  // ป้ายใต้แท่ง: ≤ 10 แท่งโชว์ทุกแท่ง / มากกว่านั้นโชว์ทุก 5 (ปี = 2) + แท่งสุดท้าย
  Widget? _bottomTitle(double value, TitleMeta meta, int itemCount) {
    final index = value.toInt();
    if (value != index.toDouble() || index < 0 || index >= itemCount) {
      return null;
    }
    final isYearly = _visible[index].period.length == 7;
    final showEvery = isYearly ? 2 : 5;
    if (itemCount > 10 && index % showEvery != 0 && index != itemCount - 1) {
      return null;
    }
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(
        _fullLabel(_visible[index].period),
        style: AppTextStyles.caption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0');
    final visible = _visible;

    double totalIncome = 0;
    double maxAmount = 0;
    for (final item in trend) {
      totalIncome += item.total;
      if (item.total > maxAmount) {
        maxAmount = item.total;
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
                  'แนวโน้มรายได้',
                  style: AppTextStyles.cardTitle,
                ),
                if (totalIncome > 0)
                  Text(
                    'รวม ${currencyFormatter.format(totalIncome)} ฿',
                    style: AppTextStyles.bodyMuted,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (trend.isEmpty)
              const SizedBox(
                height: 200,
                child: Center(child: Text('ไม่มีข้อมูลรายได้')),
              )
            else if (visible.isEmpty)
              const SizedBox(
                height: 200,
                child: Center(child: Text('ยังไม่มีรายได้ในช่วงนี้')),
              )
            else
              _buildChart(visible, currencyFormatter, maxY),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    List<DashboardTrendItemModel> visible,
    NumberFormat currencyFormatter,
    double maxY,
  ) {
    // ≤ 10 แท่ง = เต็มจอไม่เลื่อน · > 10 = ล็อก 48px ต่อแท่ง เลื่อนดู (ใช้จอในกรณีงานแน่น)
    final isScrollable = visible.length > 10;
    final barWidth = visible.length <= 3 ? 32.0 : (visible.length <= 10 ? 24.0 : 16.0);
    if (visible.length == 1) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${currencyFormatter.format(visible.first.total)} ฿',
                style: AppTextStyles.statNumber.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'รายได้ ${_fullLabel(visible.first.period)}',
                style: AppTextStyles.bodyMuted,
              ),
            ],
          ),
        ),
      );
    }

    final chart = SizedBox(
      height: 200,
      child: _buildBarChart(visible, currencyFormatter, maxY, barWidth),
    );

    if (isScrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: visible.length * 48.0,
          child: chart,
        ),
      );
    }
    return chart;
  }

  Widget _buildBarChart(
    List<DashboardTrendItemModel> visible,
    NumberFormat currencyFormatter,
    double maxY,
    double barWidth,
  ) {
    return BarChart(
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
        // ลากนิ้ว แล้ว tooltip ตามแท่งที่นิ้วชี้
        barTouchData: BarTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.toInt();
              if (index < 0 || index >= visible.length) {
                return null;
              }
              final item = visible[index];
              return BarTooltipItem(
                '${_fullLabel(item.period)}\n',
                AppTextStyles.caption.copyWith(
                  color: Colors.white70,
                ),
                children: [
                  TextSpan(
                    text: '${currencyFormatter.format(item.total)} ฿',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
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
                final widget = _bottomTitle(value, meta, visible.length);
                if (widget == null) {
                  return const SizedBox.shrink();
                }
                return widget;
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < visible.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: visible[i].total,
                  width: barWidth,
                  color: AppColors.info,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
