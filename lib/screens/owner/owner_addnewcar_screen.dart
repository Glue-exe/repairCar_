import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/app_api.dart';

class OwnerAddnewcarScreen extends StatefulWidget {
  final int customerId;
  const OwnerAddnewcarScreen({super.key, required this.customerId});

  @override
  State<OwnerAddnewcarScreen> createState() => _OwnerAddnewcarScreenState();
}

class _OwnerAddnewcarScreenState extends State<OwnerAddnewcarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  
  int? _selectedBrandId;
  String? _selectedModel;
  String? _selectedYear;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _brands = [
    {"id": 1, "name": "Toyota"},
    {"id": 2, "name": "Honda"},
    {"id": 3, "name": "Isuzu"},
    {"id": 4, "name": "Mazda"},
    {"id": 5, "name": "Nissan"},
  ];

  final Map<int, List<String>> _brandModels = {
    1: ["Corolla Altis", "Yaris Cross", "Camry"],
    2: ["Civic FC", "CR-V", "City Turbo"],
    3: ["D-Max All New", "Mu-X", "D-Max Cab4"],
    4: ["Mazda 2", "Mazda CX-30", "Mazda 3"],
    5: ["Almera", "Kicks", "Navara NP300"],
  };

  final List<String> _years = [
    "2018",
    "2019",
    "2020",
    "2021",
    "2022",
    "2023",
    "2024",
    "2025",
  ];

  List<String> get _filteredModels {
    if (_selectedBrandId == null) return [];
    return _brandModels[_selectedBrandId] ?? [];
  }

  @override
  void dispose() {
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final payload = {
        "customer_id": widget.customerId,
        "veh_licenseplate": _plateController.text.trim(),
        "brand_id": _selectedBrandId,
        "veh_model": _selectedModel,
        "veh_year": _selectedYear,
        "veh_color": _colorController.text.trim(),
      };

      try {
        final response = await AppAPI.post('/addvehicle', payload);
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 201 && responseData['isError'] == false) {
          if (mounted) {
            Navigator.pop(context, _plateController.text.trim());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: const Text(
          'เพิ่มรถใหม่',
          style: TextStyle(
            color: AppColors.textDark, 
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อฟอร์ม
              const Text(
                'กรอกข้อมูลรถ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // 1. ทะเบียนรถ
              _buildLabel('ทะเบียนรถ'),
              _buildTextField(
                controller: _plateController, 
                hintText: '',
                validator: (value) => value!.trim().isEmpty ? 'กรุณากรอกทะเบียนรถ' : null,
              ),

              // 2. ยี่ห้อรถ (Dropdown)
              _buildLabel('ยี่ห้อรถ'),
              _buildDropdownField<int>(
                value: _selectedBrandId,
                items: _brands.map((b) => DropdownMenuItem<int>(
                  value: b['id'] as int,
                  child: Text(b['name'] as String),
                )).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedBrandId = newValue;
                    _selectedModel = null; // รีเซ็ตรุ่นเมื่อเปลี่ยนยี่ห้อ
                  });
                },
                validator: (value) => value == null ? 'กรุณาเลือกยี่ห้อรถ' : null,
              ),

              // 3. รุ่น (Dropdown ตามยี่ห้อ)
              _buildLabel('รุ่น'),
              _buildDropdownField<String>(
                value: _selectedModel,
                items: _filteredModels.map((m) => DropdownMenuItem<String>(
                  value: m,
                  child: Text(m),
                )).toList(),
                onChanged: _selectedBrandId == null ? null : (newValue) {
                  setState(() {
                    _selectedModel = newValue;
                  });
                },
                validator: (value) => value == null ? 'กรุณาเลือกรุ่น' : null,
              ),

              // 4. ปีรถ (Dropdown)
              _buildLabel('ปีรถ'),
              _buildDropdownField<String>(
                value: _selectedYear,
                items: _years.map((y) => DropdownMenuItem<String>(
                  value: y,
                  child: Text(y),
                )).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedYear = newValue;
                  });
                },
                validator: (value) => value == null ? 'กรุณาเลือกปีรถ' : null,
              ),

              // 5. สีรถ
              _buildLabel('สีรถ'),
              _buildTextField(
                controller: _colorController, 
                hintText: '',
                validator: (value) => value!.trim().isEmpty ? 'กรุณากรอกสีรถ' : null,
              ),
              
              const SizedBox(height: 32),
              
              // ปุ่มบันทึกข้อมูล
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF2EE),
                          foregroundColor: const Color(0xFF588B5B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'บันทึกข้อมูล',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างข้อความ Label ข้างบนช่องกรอก
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง Custom TextField (พื้นหลังสีอ่อน มีขอบมนบางๆ)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        fillColor: const Color(0xFFF9FBF7), // สีพื้นหลังขาวนวลตามภาพ
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black26, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black54, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง Dropdown แบบไดนามิก
  Widget _buildDropdownField<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    required String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      decoration: InputDecoration(
        fillColor: const Color(0xFFF9FBF7),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black26, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black54, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
      items: items,
      onChanged: onChanged,
    );
  }
}
