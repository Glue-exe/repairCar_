import 'package:flutter/material.dart';

class OwnerApprovalpartScreen extends StatefulWidget {
  const OwnerApprovalpartScreen({super.key});

  @override
  State<OwnerApprovalpartScreen> createState() => _OwnerApprovalpartScreenState();
}

class _OwnerApprovalpartScreenState extends State<OwnerApprovalpartScreen> {
  // ตัวอย่างข้อมูลอะไหล่ที่ต้องยืนยัน
  

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันอะไหล่'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        key: const Key('approval_body'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รายการอะไหล่เสนอเปลี่ยน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
          ],
        ),
      ),
    );
  }
}
