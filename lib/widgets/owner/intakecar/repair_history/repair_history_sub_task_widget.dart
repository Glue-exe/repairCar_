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
              children: [
                const Icon(Icons.assignment, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'รายการงานซ่อม (Sub-tasks)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
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
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          color: Colors.purple.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
