import 'package:flutter/material.dart';

class OrderSymptomWidget extends StatelessWidget {
  final String symptom;

  const OrderSymptomWidget({
    super.key,
    required this.symptom,
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
            const Text(
              'อาการเสีย / รายการที่ต้องซ่อม',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Text(
              symptom,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
