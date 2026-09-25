import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/monthly_income_model.dart';

class IncomeChartWidget extends StatelessWidget {
  final List<MonthlyIncomeModel> incomeList;

  const IncomeChartWidget({super.key, required this.incomeList});

  // แปลงตัวเลขแกน Y ให้สั้นลง เช่น 150000 -> 150k
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
    // 1. คำนวณยอดรวม และหายอดสูงสุดเพื่อตั้งเพดานกราฟ (maxY)
    double totalIncome = 0;
    double maxAmount = 0;
    for (var item in incomeList) {
      totalIncome += item.totalAmount;
      if (item.totalAmount > maxAmount) {
        maxAmount = item.totalAmount;
      }
    }

    double maxY = 10000;
    if (maxAmount > 0) {
      double target = maxAmount * 1.2;
      if (target >= 100000) {
        maxY = (target / 50000).ceil() * 50000;
      } else if (target >= 10000) {
        maxY = (target / 10000).ceil() * 10000;
      } else {
        maxY = (target / 1000).ceil() * 1000;
      }
    }

    final currencyFormatter = NumberFormat('#,##0');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัว: หัวข้อ + สรุปยอดรวม + บอกผู้ใช้ว่าเลื่อนดูได้
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'แนวโน้มรายได้รายเดือน',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (incomeList.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'รวม ${incomeList.length} เดือน: ${currencyFormatter.format(totalIncome)} ฿',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
                if (incomeList.length > 5)
                  const Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'เลื่อนดูได้',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (incomeList.isEmpty)
              const SizedBox(
                height: 200,
                child: Center(child: Text('ไม่มีข้อมูลรายได้')),
              )
            else
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    // 1. แกน Y ทางซ้าย (คงที่อยู่กับที่ เวลาเลื่อนจะไม่หายไป)
                    SizedBox(
                      width: 42,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxY,
                          lineTouchData: const LineTouchData(enabled: false),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 25,
                                getTitlesWidget: _emptyTitle,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _formatYAxis(value),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                const FlSpot(0, 0),
                                FlSpot(0, maxY),
                              ],
                              color: Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 2. ตัวกราฟที่สามารถเลื่อนซ้าย-ขวาดูข้อมูลได้
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          // ขยายความกว้างเดือนละ 60px เพื่อให้เลื่อนดูได้สบาย ไม่เบียดกัน
                          width: incomeList.length * 60.0,
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: maxY,
                              minX: -0.3,
                              maxX: (incomeList.length - 1) + 0.3,
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
                              lineTouchData: LineTouchData(
                                handleBuiltInTouches: true,
                                getTouchedSpotIndicator: (barData, spotIndexes) {
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(
                                        color: Colors.blue.withValues(alpha: 0.6),
                                        strokeWidth: 1.5,
                                        dashArray: [4, 4],
                                      ),
                                      FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 5,
                                            color: Colors.blue,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                    );
                                  }).toList();
                                },
                                touchTooltipData: LineTouchTooltipData(
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final index = spot.x.toInt();
                                      if (index < 0 || index >= incomeList.length) {
                                        return null;
                                      }
                                      final item = incomeList[index];
                                      return LineTooltipItem(
                                        '${item.monthYear}\n',
                                        const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${currencyFormatter.format(item.totalAmount)} ฿',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList();
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
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1, // เมื่อเลื่อนดูได้ สามารถแสดงครบทุกเดือนได้เลย
                                    reservedSize: 25,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (value != index.toDouble()) {
                                        return const SizedBox.shrink();
                                      }
                                      if (index < 0 || index >= incomeList.length) {
                                        return const SizedBox.shrink();
                                      }

                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 6,
                                        child: Text(
                                          incomeList[index].monthYear,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (int i = 0; i < incomeList.length; i++)
                                      FlSpot(i.toDouble(), incomeList[i].totalAmount),
                                  ],
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blue.withValues(alpha: 0.15),
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
          ],
        ),
      ),
    );
  }

  static Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();
}
