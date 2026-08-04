import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_app/models/monthly_income_model.dart';

class IncomeChartWidget extends StatelessWidget {
  final List<MonthlyIncomeModel> incomeList;

  const IncomeChartWidget({super.key, required this.incomeList});

  @override
  Widget build(BuildContext context) {
    double maxIncome = 1.0;
    for (MonthlyIncomeModel item in incomeList) {
      if (item.totalAmount > maxIncome) {
        maxIncome = item.totalAmount;
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แนวโน้มรายได้รายเดือน (ย้อนหลัง 6-12 เดือน)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (incomeList.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(
                  child: Text('ไม่มีข้อมูลรายได้ย้อนหลัง'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  height: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: incomeList.map((item) {
                      final double ratio = max(0.05, item.totalAmount / maxIncome);
                      final double barHeight = ratio * 110;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '฿${item.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 24,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.monthYear,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
