import 'package:flutter/material.dart';
import 'package:my_app/widgets/owner/intakecar/intakecar_search_licensePlate_widget.dart';
import 'package:my_app/widgets/owner/intakecar/intakecar_search_phone_widget.dart';

class OwnerIntakecarScreen2 extends StatefulWidget {
  const OwnerIntakecarScreen2({super.key});

  @override
  State<OwnerIntakecarScreen2> createState() => _OwnerIntakecarScreen2State();
}

class _OwnerIntakecarScreen2State extends State<OwnerIntakecarScreen2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รับรถ'),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              IntakecarSearchWidget(),
              IntakecarSearchPhoneWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
