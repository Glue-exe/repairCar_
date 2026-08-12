import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/utils/app_api.dart';

class PartEditWidget extends StatefulWidget {
  final PartModel part;

  const PartEditWidget({super.key, required this.part});

  @override
  State<PartEditWidget> createState() => _PartEditWidgetState();
}

class _PartEditWidgetState extends State<PartEditWidget> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _partNameController;
  late TextEditingController _partPriceController;
  late TextEditingController _partBrandController;

  @override
  void initState() {
    super.initState();
    _partNameController = TextEditingController(text: widget.part.partName);
    _partPriceController = TextEditingController(
      text: widget.part.partPrice.toString(),
    );
    _partBrandController = TextEditingController(text: widget.part.partBrand);
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _partPriceController.dispose();
    _partBrandController.dispose();
    super.dispose();
  }

  String? _validateRequired(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'กรุณากรอกข้อมูล';
    }
    return null;
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการแก้ไขข้อมูล'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการบันทึกการแก้ไขนี้?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        Map<String, dynamic> data = {
          'part_id': widget.part.partId,
          'part_name': _partNameController.text,
          'part_price': _partPriceController.text,
          'part_brand': _partBrandController.text,
        };

        var response = await AppAPI.put('/part', data);
        var responseBody = jsonDecode(response.body);

        if (responseBody['isError'] == false) {
          if (mounted) {
            // mounted จะมีค่าเป็น true ถ้าหน้าจอยังเปิดอยู่ปกติ
            // mounted จะมีค่าเป็น false ถ้าหน้าจอโดนปิดไปแล้ว
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('เกิดข้อผิดพลาด'),
                content: Text(responseBody['errorMessage']),
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
        title: const Text('แก้ไขข้อมูลอะไหล่'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('ชื่ออะไหล่'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _partNameController,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('ราคา'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _partPriceController,
                            validator: _validateRequired,
                            maxLength: 10,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('ยี่ห้อ'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _partBrandController,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveData,
                  child: const Text('บันทึกการแก้ไข'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
