import 'package:flutter/material.dart';
import 'package:my_app/models/monthly_income_model.dart';

class IncomeSummaryCard extends StatelessWidget {
  final List<MonthlyIncomeModel> incomeList;
  final VoidCallback? onTap;

  const IncomeSummaryCard({
    super.key,
    required this.incomeList,
    this.onTap,
  });

  // คำนวณรายรับเฉพาะเดือนปัจจุบัน
  double get _currentMonthIncome {
    final now = DateTime.now();
    final String currentMonthStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";

    for (var item in incomeList) {
      if (item.monthYear == currentMonthStr) {
        return item.totalAmount;
      }
    }
    // หากไม่พบข้อมูลเดือนปัจจุบัน ให้แสดงข้อมูลเดือนล่าสุด หรือ 0.0
    return incomeList.isNotEmpty ? incomeList.first.totalAmount : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.teal.shade700,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "รายรับเดือนนี้",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "฿${_currentMonthIncome.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


