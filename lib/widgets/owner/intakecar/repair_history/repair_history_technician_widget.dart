import 'package:flutter/material.dart';

class RepairHistoryTechnicianWidget extends StatelessWidget {
  final List<String> technicians;

  const RepairHistoryTechnicianWidget({
    super.key,
    this.technicians = const [],
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
                const Icon(Icons.engineering, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'ช่างผู้รับผิดชอบ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${technicians.length} คน',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 24),
            if (technicians.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'ยังไม่มีช่างรับงานนี้',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: technicians.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.person, size: 20),
                    ),
                    title: Text(technicians[index]),
                    subtitle: const Text('ช่างประจำอู่'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
