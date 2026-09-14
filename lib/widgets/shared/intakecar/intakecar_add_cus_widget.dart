import 'package:flutter/material.dart';
import 'package:my_app/screens/owner/owner_add_cus_screen.dart';

class IntakecarAddCusWidget extends StatefulWidget {
  const IntakecarAddCusWidget({super.key});

  @override
  State<IntakecarAddCusWidget> createState() => _IntakecarAddCusWidgetState();
}

class _IntakecarAddCusWidgetState extends State<IntakecarAddCusWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OwnerAddCusScreen(),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('ลงทะเบียนลูกค้าใหม่'),
      ),
    );
  }
}
