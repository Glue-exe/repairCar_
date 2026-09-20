import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_app/models/monthly_income_model.dart';

class IncomeChartWidget extends StatelessWidget {
  final List<MonthlyIncomeModel> incomeList;

  const IncomeChartWidget({super.key, required this.incomeList});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แนวโน้มรายได้รายเดือน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (incomeList.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(child: Text('ไม่มีข้อมูลรายได้')),
              )
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 25,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < incomeList.length) {
                              return Text(
                                incomeList[index].monthYear,
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const SizedBox();
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
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

