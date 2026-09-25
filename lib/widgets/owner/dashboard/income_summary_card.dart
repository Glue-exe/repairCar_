import 'package:flutter/material.dart';
import 'package:my_app/models/dashboard_summary_model.dart';

class IncomeSummaryCard extends StatelessWidget {
  final DashboardSummaryModel summaryData;

  const IncomeSummaryCard({super.key, required this.summaryData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('รายได้รวมเดือนนี้'),
                const SizedBox(height: 8),
                Text(
                  '฿${summaryData.monthlyIncome}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
