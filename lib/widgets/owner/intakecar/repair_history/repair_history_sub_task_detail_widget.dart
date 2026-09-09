import 'package:flutter/material.dart';
import 'package:my_app/models/sub_task_model.dart';

class RepairHistorySubTaskDetailWidget extends StatelessWidget {
  final SubTaskModel subTask;

  const RepairHistorySubTaskDetailWidget({
    super.key,
    required this.subTask,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subTask.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subTask.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subTask.statusName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Order: #${subTask.orderId}'),
                    const SizedBox(height: 8),
                    Text('ค่าแรง: ${subTask.laborCost.toStringAsFixed(2)} บาท'),
                    const SizedBox(height: 8),
                    Text(
                      'ช่างผู้รับผิดชอบ: ${subTask.technicianFirstName} ${subTask.technicianLastName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
