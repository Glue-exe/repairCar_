import 'package:flutter/material.dart';
import 'package:my_app/models/order_pool_model.dart';

class RepairHistoryTechnicianWidget extends StatelessWidget {
  final List<OrderTechnicianItemModel> technicians;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ช่างผู้รับผิดชอบ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                  final tech = technicians[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${tech.firstname} ${tech.lastname}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      tech.roleName,
                      style: const TextStyle(color: Colors.grey),
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
