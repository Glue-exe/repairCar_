import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/utils/app_api.dart';

class OwnerAddCustomerScreen extends StatefulWidget {
  const OwnerAddCustomerScreen({super.key});

  @override
  State<OwnerAddCustomerScreen> createState() => _OwnerAddCustomerScreenState();
}

class _OwnerAddCustomerScreenState extends State<OwnerAddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _licensePlateController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();

  int? _selectedBrandId;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _brands = [
    {"id": 1, "name": "Toyota"},
    {"id": 2, "name": "Honda"},
    {"id": 3, "name": "Isuzu"},
    {"id": 4, "name": "Nissan"},
    {"id": 5, "name": "Mazda"},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _licensePlateController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final payload = {
        "cus_firstname": _firstNameController.text.trim(),
        "cus_lastname": _lastNameController.text.trim(),
        "cus_phone": _phoneController.text.trim(),
        "veh_licenseplate": _licensePlateController.text.trim(),
        "brand_id": _selectedBrandId,
        "veh_model": _modelController.text.trim(),
        "veh_year": _yearController.text.trim(),
        "veh_color": _colorController.text.trim(),
      };

      try {
        final response = await AppAPI.post('/addnewcustomer', payload);
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 201 && responseData['isError'] == false) {
          if (mounted) {
            Navigator.pop(context, _licensePlateController.text.trim());
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ฟังก์ชันช่วยสร้างช่องกรอกข้อมูลข้อความธรรมดา
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (value) => value!.trim().isEmpty ? 'กรุณากรอก$label' : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มข้อมูลลูกค้าและรถ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildSectionTitle('กรอกข้อมูลลูกค้า'),
            _buildInputField(controller: _firstNameController, label: 'ชื่อ'),
            _buildInputField(controller: _lastNameController, label: 'นามสกุล'),
            _buildInputField(
              controller: _phoneController, 
              label: 'เบอร์', 
              keyboardType: TextInputType.phone,
            ),

            _buildSectionTitle('กรอกข้อมูลรถ'),
            _buildInputField(controller: _licensePlateController, label: 'ทะเบียนรถ'),
            
            // เปลี่ยนส่วนยี่ห้อรถเป็น Dropdown เพื่อดึง brand_id
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ยี่ห้อรถ', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _selectedBrandId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _brands.map((brand) {
                      return DropdownMenuItem<int>(
                        value: brand['id'] as int,
                        child: Text(brand['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBrandId = value;
                      });
                    },
                    validator: (value) => value == null ? 'กรุณาเลือกยี่ห้อรถ' : null,
                  ),
                ],
              ),
            ),

            _buildInputField(controller: _modelController, label: 'รุ่น'),
            _buildInputField(
              controller: _yearController, 
              label: 'ปีรถ', 
              keyboardType: TextInputType.number,
            ),
            _buildInputField(controller: _colorController, label: 'สีรถ'),

            const SizedBox(height: 20),

            // ปุ่มบันทึกข้อมูล
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitData,
                    child: const Text('บันทึกข้อมูล'),
                  ),
          ],
        ),
      ),
    );
  }
}
