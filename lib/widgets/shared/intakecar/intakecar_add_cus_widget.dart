import 'package:flutter/material.dart';
import 'package:my_app/screens/shared/intakecar/intakecar_add_cus_screen.dart';

class IntakecarAddCusWidget extends StatefulWidget {
  const IntakecarAddCusWidget({super.key});

  @override
  State<IntakecarAddCusWidget> createState() => _IntakecarAddCusWidgetState();
}

class _IntakecarAddCusWidgetState extends State<IntakecarAddCusWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ลูกค้าใหม่',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IntakecarAddCusScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('ลงทะเบียนลูกค้าและรถใหม่'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
