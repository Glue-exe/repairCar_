import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:crypto/crypto.dart';

class PartAddScreen extends StatefulWidget {
  const PartAddScreen({super.key});

  @override
  State<PartAddScreen> createState() => _PartAddScreenState();
}

class _PartAddScreenState extends State<PartAddScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _partNameController = TextEditingController();
  final TextEditingController _partPriceController = TextEditingController();
  final TextEditingController _partBrandController = TextEditingController();

  @override
  void dispose() {
    _partNameController.dispose();
    _partPriceController.dispose();
    _partBrandController.dispose();
    super.dispose();
  }

  String? _validateRequired(dynamic value) {
    if(value == null || value.toString().trim().isEmpty) {
      return 'กรุณากรอกข้อมูล';
    }
    return null;
  }

  void _saveData() async {
    if(_formKey.currentState!.validate()) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการเพิ่มข้อมูล'),
          content: const Text('คุณต้องการยืนยันการเพิ่มข้อมูลอะไหล่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              }, 
                child: const Text('ยืนยัน'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        var data = {
          'part_name': _partNameController.text,
          'part_price': _partPriceController.text,
          'part_brand': _partBrandController.text,
        };

        var response = await AppAPI.post('/part', data);

        if (response.statusCode == 200) {
          var responseBody = jsonDecode(response.body);

          if (responseBody['isError'] == false) {
            if (mounted) {
              Navigator.pop(context, true);
            }
          } else {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('เกิดข้อผิดพลาด'),
                  content: Text(responseBody['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ตกลง'),
                    ),
                  ],
                ),
              );
            }
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('เกิดข้อผิดพลาด'),
                content: Text('เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (Status: ${response.statusCode})'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ตกลง'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลอะไหล่'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('ชื่ออะไหล่'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _partNameController,
                            validator: _validateRequired,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ราคา'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _partPriceController,
                            keyboardType: TextInputType.number,
                            validator: _validateRequired,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ยี่ห้อ'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _partBrandController,
                            validator: _validateRequired,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveData,
                  child: const Text('ยืนยัน'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
