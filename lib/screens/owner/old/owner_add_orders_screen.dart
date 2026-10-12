import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/old/vehiclelicenseplate_search.dart';
import 'package:my_app/utils/app_api.dart';

class OwnerAddOrdersScreen extends StatefulWidget {
  final VehicleLicenseplateSearch vehicle;
  const OwnerAddOrdersScreen({super.key, required this.vehicle});

  @override
  State<OwnerAddOrdersScreen> createState() => _OwnerAddOrdersScreenState();
}

class _OwnerAddOrdersScreenState extends State<OwnerAddOrdersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomController = TextEditingController();
  final _costController = TextEditingController();

  int? _selectedPriorityId;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _priorities = [
    {"id": 1, "name": "งานด่วน"},
    {"id": 2, "name": "งานปานกลาง"},
    {"id": 3, "name": "งานระยะยาว"},
  ];

  @override
  void dispose() {
    _symptomController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final payload = {
        "cus_id": widget.vehicle.customerId,
        "veh_id": widget.vehicle.vehicleId,
        "order_symptom": _symptomController.text.trim(),
        "orders_priority_id": _selectedPriorityId,
        "labor_cost": _costController.text.trim().isEmpty
            ? 0
            : double.parse(_costController.text.trim()),
      };

      try {
        final response = await AppAPI.post('/addorder', payload);
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 201 && responseData['isError'] == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('เปิดงานซ่อมใหม่สำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['errorMessage'] ??
                      'เกิดข้อผิดพลาดในการเปิดงานซ่อม',
                ),
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
    final vehicle = widget.vehicle;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: const Text(
          'เปิดงานซ่อม',
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
              // ส่วนข้อมูลลูกค้าและรถ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลลูกค้าและรถยนต์',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Divider(height: 20),
                    Text(
                      'ชื่อลูกค้า: ${vehicle.customerFullName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เบอร์โทรศัพท์: ${vehicle.customerPhone}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'รถยนต์: ${vehicle.vehicleBrand} ${vehicle.vehicleModel} (${vehicle.vehicleColor})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ทะเบียนรถ: ${vehicle.vehicleLicenseplate}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'รายละเอียดงานซ่อม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // 1. อาการที่แจ้ง
              _buildLabel('อาการที่แจ้ง'),
              _buildTextField(
                controller: _symptomController,
                hintText: 'กรอกอาการขัดข้องของรถยนต์',
                validator: (value) =>
                    value!.trim().isEmpty ? 'กรุณากรอกอาการที่แจ้ง' : null,
              ),

              // 2. ความสำคัญของงาน (Dropdown)
              _buildLabel('ความสำคัญของงาน'),
              _buildDropdownField<int>(
                value: _selectedPriorityId,
                items: _priorities
                    .map(
                      (p) => DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(p['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedPriorityId = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'กรุณาเลือกความสำคัญของงาน' : null,
              ),

              // 3. ค่าใช้จ่ายประมาณ
              _buildLabel('ค่าใช้จ่ายประมาณ (บาท)'),
              _buildTextField(
                controller: _costController,
                hintText: '',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (double.tryParse(value.trim()) == null) {
                    return 'กรุณากรอกตัวเลขค่าใช้จ่ายที่ถูกต้อง';
                  }
                  return null;
                },
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

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
        fillColor: const Color(0xFFF9FBF7),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
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
