import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:my_app/models/employee_model.dart';
import 'package:my_app/models/title_model.dart';
import 'package:my_app/models/user_role_model.dart';
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
  int? _selectedRole;
  int? _selectedSalary;

  final List<int> _salaryList = [
    11500,
    12000,
    13000,
    14000,
    15000,
    16000,
    17000,
    18000,
    19000,
    20000,
    22000,
    25000,
  ];

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  List<TitleModel> titleModelStore = [];
  List<RoleModel> roleModelStore = [];

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController(text: widget.employee.empFirstName);
    _lastnameController = TextEditingController(text: widget.employee.empLastName);
    _phoneController = TextEditingController(text: widget.employee.empPhone);
    _selectedTitle = widget.employee.empTitleId;
    _selectedRole = widget.employee.accRoleId;
    _selectedSalary = double.tryParse(widget.employee.empCurrentSalary)?.toInt();

    _fetchData();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ดึงข้อมูลคำนำหน้าและตำแหน่ง
  void _fetchData() async {
    var response = await Future.wait([
      AppAPI.get('/title'),
      AppAPI.get('/user_role'),
    ]);

    Map<String, dynamic> titleJson = jsonDecode(response[0].body);
    TitleResponse titleResponse = TitleResponse.fromJson(titleJson);

    Map<String, dynamic> roleJson = jsonDecode(response[1].body);
    RoleResponse roleResponse = RoleResponse.fromJson(roleJson);

    if (mounted) {
      setState(() {
        titleModelStore = titleResponse.data;
        // เลือกได้เฉพาะ พนักงานบัญชี (id: 2) และ ช่าง (id: 3) หรือตำแหน่งเดิมของผู้ใช้
        roleModelStore = roleResponse.data
            .where((item) =>
                item.id == 2 ||
                item.id == 3 ||
                item.id == widget.employee.accRoleId)
            .toList();
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
          'emp_first_name': _firstnameController.text,
          'emp_last_name': _lastnameController.text,
          'emp_phone': _phoneController.text,
          'acc_role_id': _selectedRole,
          'emp_current_salary': _selectedSalary,
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
              // หัวข้อส่วนที่ 1: ข้อมูลส่วนตัว
              const Text(
                'ข้อมูลส่วนตัว',
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

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // หัวข้อส่วนที่ 2: ข้อมูลตำแหน่งงาน
              const Text(
                'ตำแหน่งงาน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // ตำแหน่งงาน
              DropdownButtonFormField<int>(
                initialValue: _selectedRole,
                validator: (value) => value == null ? 'กรุณาเลือกตำแหน่ง' : null,
                decoration: const InputDecoration(
                  labelText: 'ตำแหน่งพนักงาน *',
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: roleModelStore.map((RoleModel item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // เงินเดือน
              DropdownButtonFormField<int>(
                initialValue: _selectedSalary,
                validator: (value) =>
                    value == null ? 'กรุณาเลือกเงินเดือน' : null,
                decoration: const InputDecoration(
                  labelText: 'เงินเดือน *',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: _salaryList.map((int salary) {
                  return DropdownMenuItem<int>(
                    value: salary,
                    child: Text('${_formatNumber(salary)} บาท'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSalary = value;
                  });
                },
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
