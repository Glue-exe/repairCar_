import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_app/utils/app_api.dart';

class VehicleEditBrand extends StatefulWidget {
  final Map<String, dynamic> brand;

  const VehicleEditBrand({super.key, required this.brand});

  @override
  State<VehicleEditBrand> createState() => _VehicleEditBrandState();
}

class _VehicleEditBrandState extends State<VehicleEditBrand> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _brandNameController;

  @override
  void initState() {
    super.initState();
    _brandNameController = TextEditingController(
      text: widget.brand['brand_name'] ?? widget.brand['name'] ?? '',
    );
  }

  @override
  void dispose() {
    _brandNameController.dispose();
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
        builder: (context) {
          return AlertDialog(
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
          );
        },
      );

      if (confirm == true) {
        Map<String, dynamic> data = {
          'brand_id': widget.brand['brand_id'] ?? widget.brand['id'],
          'brand_name': _brandNameController.text.trim(),
        };

        var response = await AppAPI.put('/vehicle_brand', data);
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
                content: Text(responseBody['errorMessage'] ?? 'ไม่สามารถบันทึกข้อมูลได้'),
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
        title: const Text('แก้ไขยี่ห้อรถยนต์'),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('ยี่ห้อรถยนต์ (Brand Name)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _brandNameController,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'เช่น Toyota, Honda',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
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
