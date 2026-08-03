import 'package:flutter/material.dart';

class AccountantHomeScreen extends StatefulWidget {
  const AccountantHomeScreen({super.key});

  @override
  State<AccountantHomeScreen> createState() => _AccountantHomeScreenState();
}

class _AccountantHomeScreenState extends State<AccountantHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountant Dashboard (พนักงานบัญชี)'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'ยินดีต้อนรับ พนักงานบัญชี (Accountant)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
