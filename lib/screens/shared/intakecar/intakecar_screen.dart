import 'package:flutter/material.dart';
import 'package:my_app/widgets/shared/intakecar/intakecar_search_license_plate_widget.dart';
import 'package:my_app/widgets/shared/intakecar/intakecar_search_phone_widget.dart';
import 'package:my_app/widgets/shared/intakecar/intakecar_add_cus_widget.dart';

class IntakecarScreen extends StatefulWidget {
  const IntakecarScreen({super.key});

  @override
  State<IntakecarScreen> createState() => _IntakecarScreenState();
}

class _IntakecarScreenState extends State<IntakecarScreen> {
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
              IntakecarAddCusWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
