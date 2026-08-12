import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_app/utils/app_api.dart';

class VehicleEditModel extends StatefulWidget {
  final Map<String, dynamic> vehicleModel;

  const VehicleEditModel({super.key, required this.vehicleModel});

  @override
  State<VehicleEditModel> createState() => _VehicleEditModelState();
}

class _VehicleEditModelState extends State<VehicleEditModel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _modelNameController;

  int? _selectedBrandId;
  int? _selectedYearId;
  List<Map<String, dynamic>> _brandsStore = [];
  List<Map<String, dynamic>> _yearsStore = [];

  @override
  void initState() {
    super.initState();
    _modelNameController = TextEditingController(
      text: widget.vehicleModel['model_name'] ?? widget.vehicleModel['name'] ?? '',
    );
    _selectedBrandId = widget.vehicleModel['brand_id'];
    _selectedYearId = widget.vehicleModel['veh_year_id'];
    _fetchData();
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    super.dispose();
  }

  String? _validateRequired(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'กรุณากรอกข้อมูล';
    }
    return null;
  }

  void _fetchData() async {
    try {
      var responses = await Future.wait([
        AppAPI.get('/vehicle_brand'),
        AppAPI.get('/vehicle_year'),
      ]);

      Map<String, dynamic> brandJson = jsonDecode(responses[0].body);
      Map<String, dynamic> yearJson = jsonDecode(responses[1].body);

      setState(() {
        if (brandJson['isError'] == false && brandJson['data'] != null) {
          _brandsStore = List<Map<String, dynamic>>.from(brandJson['data']);
        }
        if (yearJson['isError'] == false && yearJson['data'] != null) {
          _yearsStore = List<Map<String, dynamic>>.from(yearJson['data']);
        }
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
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
          'veh_model_id': widget.vehicleModel['veh_model_id'] ?? widget.vehicleModel['id'],
          'model_name': _modelNameController.text.trim(),
          'brand_id': _selectedBrandId,
          'veh_year_id': _selectedYearId,
        };

        var response = await AppAPI.put('/vehicle_model', data);
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
        title: const Text('แก้ไขรุ่นรถยนต์'),
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
                          const Text('ยี่ห้อรถยนต์ (Brand)'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedBrandId,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _brandsStore.map((brand) {
                              return DropdownMenuItem<int>(
                                value: brand['brand_id'] ?? brand['id'],
                                child: Text(brand['brand_name'] ?? brand['name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBrandId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('รุ่นรถยนต์ (Model Name)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _modelNameController,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'เช่น Civic, Camry',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('ปีรุ่นรถยนต์ (Year)'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedYearId,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _yearsStore.map((yearItem) {
                              return DropdownMenuItem<int>(
                                value: yearItem['veh_year_id'] ?? yearItem['id'],
                                child: Text((yearItem['year'] ?? '').toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedYearId = value;
                              });
                            },
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
