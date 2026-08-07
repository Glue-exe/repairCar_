import 'package:flutter/material.dart';
import 'package:my_app/models/monthly_income_model.dart';

class IncomeChartWidget extends StatelessWidget {
  final List<MonthlyIncomeModel> incomeList;

  const IncomeChartWidget({super.key, required this.incomeList});

  @override
  Widget build(BuildContext context) {
    // หาค่ายอดขายสูงสุดเพื่อนำมาคำนวณความสูงของแท่งกราฟ (ถ้าไม่มีข้อมูลให้เป็น 1.0 เพื่อกันหารด้วยศูนย์)
    double maxIncome = 1.0;
    for (var item in incomeList) {
      if (item.totalAmount > maxIncome) {
        maxIncome = item.totalAmount;
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แนวโน้มรายได้รายเดือน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // กรณีไม่มีข้อมูล
            if (incomeList.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(child: Text('ไม่มีข้อมูลรายได้')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: incomeList.map((item) {
                      // คำนวณความสูงแท่งกราฟ (ความสูงสูงสุด 100 px)
                      double barHeight = (item.totalAmount / maxIncome) * 100;
                      
                      // กำหนดความสูงขั้นต่ำอย่างน้อย 6 px เพื่อให้มองเห็นแท่งแม้ว่ายอดจะเป็น 0
                      if (barHeight < 6) barHeight = 6;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '฿${item.totalAmount}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 22,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade400,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.monthYear,
                              style: const TextStyle(
                                fontSize: 11,
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

