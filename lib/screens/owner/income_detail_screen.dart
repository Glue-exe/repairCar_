import 'package:flutter/material.dart';
import 'package:my_app/models/monthly_income_model.dart';

class IncomeDetailScreen extends StatefulWidget {
  final List<MonthlyIncomeModel> incomeList;

  const IncomeDetailScreen({super.key, required this.incomeList});

  @override
  State<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends State<IncomeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดรายรับทั้งหมด'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: widget.incomeList.isEmpty
          ? const Center(
              child: Text('ไม่มีข้อมูลรายได้'),
            )
          : ListView.builder(
                    itemCount: widget.incomeList.length,
                    itemBuilder: (context, index) {
                      final item = widget.incomeList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.calendar_month,
                              color: Colors.blueAccent,
                            ),
                          ),
                          title: Text(
                            'เดือน ${item.month} / พ.ศ. ${item.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('รหัสรอบ: ${item.monthYear}'),
                          trailing: Text(
                            '฿${item.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
    );
  }
}
