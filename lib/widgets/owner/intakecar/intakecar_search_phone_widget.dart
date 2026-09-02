import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_app/utils/app_api.dart';

class IntakecarSearchPhoneWidget extends StatefulWidget {
  const IntakecarSearchPhoneWidget({super.key});

  @override
  State<IntakecarSearchPhoneWidget> createState() => _IntakecarSearchPhoneWidgetState();
}

class _IntakecarSearchPhoneWidgetState extends State<IntakecarSearchPhoneWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('ค้นหาด้วยเบอร์โทรศัพท์'),
          Row(children: [
            Expanded(
              child: TextField(
              
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
