import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:my_app/models/employee_model.dart';
import 'package:my_app/models/title_model.dart';
import 'package:my_app/utils/app_api.dart';

class EmpEditWidget extends StatefulWidget {
  final EmployeeModel employee;
  final VoidCallback onRefresh;

  const EmpEditWidget({
    super.key,
    required this.employee,
    required this.onRefresh,
  });

  @override
  State<EmpEditWidget> createState() => _EmpEditWidgetState();
}

class _EmpEditWidgetState extends State<EmpEditWidget> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _phoneController;

  int? _selectedTitle;

  List<TitleModel> titleModelStore = [];

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController(text: widget.employee.empFirstName);
    _lastnameController = TextEditingController(text: widget.employee.empLastName);
    _phoneController = TextEditingController(text: widget.employee.empPhone);
    _selectedTitle = widget.employee.empTitleId;

    _fetchData();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ดึงข้อมูลคำนำหน้า
  void _fetchData() async {
    var response = await AppAPI.get('/title');
    Map<String, dynamic> titleJson = jsonDecode(response.body);
    TitleResponse titleResponse = TitleResponse.fromJson(titleJson);

    if (mounted) {
      setState(() {
        titleModelStore = titleResponse.data;
      });
    }
  }

  // ตรวจสอบการกรอกข้อมูล
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกข้อมูล';
    }
    return null;
  }

  // Alert ยกเลิก ยืนยัน
  Future<bool> _showConfirmDialog() async {
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
      return true;
    } else {
      return false;
    }
  }

  // บันทึกการแก้ไขข้อมูล
  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      bool confirm = await _showConfirmDialog();

      if (confirm == true) {
        Map<String, dynamic> data = {
          'emp_id': widget.employee.empId,
          'emp_title_id': _selectedTitle,
          'emp_first_name': _firstnameController.text.trim(),
          'emp_last_name': _lastnameController.text.trim(),
          'emp_phone': _phoneController.text.trim(),
        };

        var response = await AppAPI.put('/employee', data);
        var responseBody = jsonDecode(response.body);

        if (responseBody['isError'] == false) {
          widget.onRefresh();
          if (mounted) {
            Navigator.pop(context);
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
        title: const Text('แก้ไขข้อมูลพนักงาน'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ข้อมูลพนักงาน
              const Text(
                'ข้อมูลพนักงาน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // คำนำหน้า
              DropdownButtonFormField<int>(
                initialValue: _selectedTitle,
                validator: (value) => value == null ? 'กรุณาเลือกคำนำหน้า' : null,
                decoration: const InputDecoration(
                  labelText: 'คำนำหน้าชื่อ *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: titleModelStore.map((TitleModel item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTitle = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // ชื่อจริง
              TextFormField(
                controller: _firstnameController,
                validator: _validateRequired,
                decoration: const InputDecoration(
                  labelText: 'ชื่อจริง *',
                  hintText: 'กรอกชื่อจริง',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // นามสกุล
              TextFormField(
                controller: _lastnameController,
                validator: _validateRequired,
                decoration: const InputDecoration(
                  labelText: 'นามสกุล *',
                  hintText: 'กรอกนามสกุล',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // เบอร์โทรศัพท์
              TextFormField(
                controller: _phoneController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  if (value.trim().length != 10) {
                    return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
                  }
                  return null;
                },
                maxLength: 10,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'เบอร์โทรศัพท์ *',
                  hintText: '08xxxxxxxx',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ปุ่มบันทึกการแก้ไข
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text(
                    'บันทึกการแก้ไข',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveData,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
