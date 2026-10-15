import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/accountant_model.dart';

class RevenueTrendChartWidget extends StatelessWidget {
  final List<RevenueTrendItemModel> trends;
  final String dateRangeSubtitle;

  const RevenueTrendChartWidget({
    super.key,
    required this.trends,
    this.dateRangeSubtitle = '',
  });

  String _formatYAxis(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toInt()}k';
    }
    return value.toInt().toString();
  }

  String _formatDateLabel(String timeBucket) {
    try {
      if (timeBucket.length == 10) {
        // YYYY-MM-DD
        final dt = DateTime.parse(timeBucket);
        const thaiMonths = [
          '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
          'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
        ];
        return '${dt.day} ${thaiMonths[dt.month]}';
      } else if (timeBucket.length == 7) {
        // YYYY-MM
        final parts = timeBucket.split('-');
        final month = int.parse(parts[1]);
        const thaiMonths = [
          '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
          'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
        ];
        return thaiMonths[month];
      }
    } catch (_) {}
    return timeBucket;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00');

    double totalRevenue = 0;
    double maxAmount = 0;
    for (var item in trends) {
      totalRevenue += item.totalAmount;
      if (item.totalAmount > maxAmount) {
        maxAmount = item.totalAmount;
      }
    }

    double maxY = 10000;
    if (maxAmount > 0) {
      double target = maxAmount * 1.25;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวการ์ด
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'แนวโน้มรายได้',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (dateRangeSubtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dateRangeSubtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '฿${currencyFormatter.format(totalRevenue)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // กราฟ
            if (trends.isEmpty)
              Container(
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_chart_outlined_rounded, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'ไม่มีข้อมูลรายได้ในช่วงเวลานี้',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 220,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: trends.length > 5 ? trends.length * 60.0 : MediaQuery.of(context).size.width - 64,
                    padding: const EdgeInsets.only(top: 16, right: 12),
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        minY: 0,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final item = trends[group.x.toInt()];
                              return BarTooltipItem(
                                '${_formatDateLabel(item.timeBucket)}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'ยอดรวม: ฿${currencyFormatter.format(item.totalAmount)}\n',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'ค่าแรง: ฿${currencyFormatter.format(item.laborAmount)} | อะไหล่: ฿${currencyFormatter.format(item.partsAmount)}\n',
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                  TextSpan(
                                    text: 'จำนวน: ${item.count} คัน',
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: maxY / 4 > 0 ? maxY / 4 : 2500,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox.shrink();
                                return Text(
                                  _formatYAxis(value),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < 0 || index >= trends.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _formatDateLabel(trends[index].timeBucket),
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 2500,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: trends.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;

                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: item.totalAmount,
                                color: AppColors.primaryGreen,
                                width: 22,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
