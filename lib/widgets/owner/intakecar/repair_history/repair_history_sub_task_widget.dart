import 'package:flutter/material.dart';

class SubTaskItem {
  final String name;
  final double laborCost;
  final String status;

  const SubTaskItem({
    required this.name,
    required this.laborCost,
    required this.status,
  });
}

class RepairHistorySubTaskWidget extends StatelessWidget {
  final List<SubTaskItem> subTasks;

  const RepairHistorySubTaskWidget({
    super.key,
    this.subTasks = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายการงานซ่อม (Sub-tasks)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${subTasks.length} รายการ',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 24),
            if (subTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'ยังไม่มีรายการงานซ่อม',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subTasks.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = subTasks[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('ค่าแรง: ${item.laborCost.toStringAsFixed(2)} บาท'),
                    trailing: Text(
                      item.status,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
