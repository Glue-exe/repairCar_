import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/title_model.dart';
import 'package:my_app/models/vehicle_brand_model.dart';
import 'package:my_app/models/vehicle_model_model.dart';

class OwnerAddCusScreen extends StatefulWidget {
  const OwnerAddCusScreen({super.key});

  @override
  State<OwnerAddCusScreen> createState() => _OwnerAddCusScreenState();
}

class _OwnerAddCusScreenState extends State<OwnerAddCusScreen> {
  // ข้อมูลลูกค้า
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<TitleModel> _titleList = [];
  int? _selectedTitleId;

  // ข้อมูลรถยนต์
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  List<VehicleBrandModel> _brandList = [];
  int? _selectedBrandId;

  List<VehicleModelModel> _modelList = [];
  int? _selectedModelId;

  String _errorMessage = '';

  // กรองรุ่นรถตามยี่ห้อที่เลือก
  List<VehicleModelModel> get _filteredModels {
    if (_selectedBrandId == null) {
      return [];
    } else {
      return _modelList.where((m) => m.brandId == _selectedBrandId).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // โหลดคำนำหน้าชื่อ
      final titleRes = await AppAPI.get('/title');
      final titleResponse = TitleResponse.fromJson(jsonDecode(titleRes.body));
      if (titleResponse.isError == false) {
        setState(() {
          _titleList = titleResponse.data;
        });
      }

      // โหลดยี่ห้อรถยนต์ (Toyota, Honda, Isuzu)
      final brandRes = await AppAPI.get('/vehicle_brand');
      final brandResponse = VehicleBrandResponse.fromJson(jsonDecode(brandRes.body));
      if (brandResponse.isError == false) {
        setState(() {
          _brandList = brandResponse.data;
        });
      }

      // โหลดรุ่นรถยนต์ทั้งหมด
      final modelRes = await AppAPI.get('/vehicle_model');
      final modelResponse = VehicleModelResponse.fromJson(jsonDecode(modelRes.body));
      if (modelResponse.isError == false) {
        setState(() {
          _modelList = modelResponse.data;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลเริ่มต้นได้';
      });
    }
  }

  Future<void> _saveCustomerAndVehicle() async {
    if (_selectedTitleId == null ||
        _firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _licensePlateController.text.trim().isEmpty ||
        _selectedBrandId == null ||
        _selectedModelId == null ||
        _yearController.text.trim().isEmpty ||
        _colorController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน';
      });
      return;
    }

    try {
      final response = await AppAPI.post('/add_customer', {
        'cus_title_id': _selectedTitleId,
        'cus_first_name': _firstNameController.text.trim(),
        'cus_last_name': _lastNameController.text.trim(),
        'cus_phone': _phoneController.text.trim(),
        'cus_created_by_account_id': 1,
        'v_license_plate': _licensePlateController.text.trim(),
        'v_vehicle_model_id': _selectedModelId,
        'v_year': int.parse(_yearController.text.trim()),
        'v_color': _colorController.text.trim(),
      });

      final Map<String, dynamic> resJson = jsonDecode(response.body);

      if (resJson['isError'] == false) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = resJson['errorMessage'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเชื่อมต่อระบบได้';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียนลูกค้าและรถยนต์'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อมูลลูกค้า', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              hint: const Text('เลือกคำนำหน้าชื่อ'),
              value: _selectedTitleId,
              isExpanded: true,
              items: _titleList.map((item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTitleId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(hintText: 'กรอกชื่อ'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(hintText: 'กรอกนามสกุล'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(hintText: 'กรอกเบอร์โทรศัพท์'),
            ),
            const SizedBox(height: 24),
            const Text('ข้อมูลรถยนต์', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _licensePlateController,
              decoration: const InputDecoration(hintText: 'กรอกทะเบียนรถ เช่น กข1234สงขลา'),
            ),
            const SizedBox(height: 12),

            // 1. Dropdown เลือกยี่ห้อ (Toyota, Honda, Isuzu)
            DropdownButton<int>(
              hint: const Text('เลือกยี่ห้อรถยนต์ (เช่น Toyota, Honda, Isuzu)'),
              value: _selectedBrandId,
              isExpanded: true,
              items: _brandList.map((item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBrandId = value;
                  _selectedModelId = null; // รีเซ็ตรุ่นเมื่อเปลี่ยนยี่ห้อ
                });
              },
            ),
            const SizedBox(height: 12),

            // 2. Dropdown เลือกรุ่นรถยนต์ (กรองตามยี่ห้อที่เลือก)
            DropdownButton<int>(
              hint: const Text('เลือกรุ่นรถยนต์'),
              value: _selectedModelId,
              isExpanded: true,
              items: _filteredModels.map((item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedModelId = value;
                });
              },
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _yearController,
              decoration: const InputDecoration(hintText: 'กรอกปีรุ่นรถ เช่น 2022'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(hintText: 'กรอกสีรถ'),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveCustomerAndVehicle,
                child: const Text('บันทึกข้อมูล'),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
