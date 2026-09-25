import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/title_model.dart';
import 'package:my_app/models/user_role_model.dart';

class EmpAddScreen extends StatefulWidget {
  final VoidCallback onRefresh;

  const EmpAddScreen({super.key, required this.onRefresh});

  @override
  State<EmpAddScreen> createState() => _EmpAddScreenState();
}

class _EmpAddScreenState extends State<EmpAddScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int? _selectedTitle;
  int? _selectedRole;
  int? _selectedSalary;

  final List<int> _salaryList = [
    11500,
    12000,
    13000,
    14000,
    15000,
    15500,
    16000,
    16500,
    17000,
    17500,
    18000,
    18500,
    19000,
    19500,
    20000,
    21000,
    22000,
    25000,
    30000,
    35000,
    40000,
    50000,
    68000,
  ];

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  List<TitleModel> titleModelStore = [];
  List<RoleModel> roleModelStore = [];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    setState(() {
      titleModelStore = titleResponse.data;
      // เลือกได้เฉพาะ พนักงานบัญชี (id: 2) และ ช่าง (id: 3)
      roleModelStore = roleResponse.data
          .where((item) => item.id == 2 || item.id == 3)
          .toList();
    });
  }

  // ตรวจสอบการกรอกข้อมูล
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกข้อมูล';
    }
    return null;
  }

  // ตรวจสอบการยืนยันรหัสผ่าน
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }
    if (value != _passwordController.text) {
      return 'รหัสผ่านไม่ตรงกัน';
    }
    return null;
  }

  // Alert ยกเลิก ยืนยัน
  Future<bool> _showConfirmDialog() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มข้อมูล'),
          content: const Text('คุณต้องการยืนยันการเพิ่มข้อมูลพนักงานหรือไม่?'),
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

  // บันทึกข้อมูลพนักงาน
  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      bool confirm = await _showConfirmDialog();

      if (confirm == true) {
        String rawPassword = _passwordController.text;
        String hashedPassword = sha256
            .convert(utf8.encode(rawPassword))
            .toString();

        var data = {
          'acc_username': _usernameController.text,
          'acc_password_hash': hashedPassword,
          'emp_title_id': _selectedTitle,
          'emp_first_name': _firstnameController.text,
          'emp_last_name': _lastnameController.text,
          'emp_phone': _phoneController.text,
          'acc_role_id': _selectedRole,
          'emp_current_salary': _selectedSalary,
        };

        var response = await AppAPI.post('/employee', data);
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

  // สลับไอคอนเปิด-ปิดตา
  IconData _getEyeIcon(bool isObscured) {
    if (isObscured == true) {
      return Icons.visibility_off;
    } else {
      return Icons.visibility;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลพนักงาน'),
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

              // หัวข้อส่วนที่ 2: ข้อมูลบัญชีผู้ใช้และตำแหน่งงาน
              const Text(
                'ข้อมูลบัญชีผู้ใช้และตำแหน่งงาน',
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
              const SizedBox(height: 16),

              // ชื่อผู้ใช้งาน (Username)
              TextFormField(
                controller: _usernameController,
                validator: _validateRequired,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[\x00-\x7F]'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'ชื่อผู้ใช้งาน (Username) *',
                  hintText: 'ใช้สำหรับเข้าสู่ระบบ',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // รหัสผ่าน (Password)
              TextFormField(
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสผ่าน';
                  }
                  if (value.length < 4) {
                    return 'รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[\x00-\x7F]'),
                  ),
                ],
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน (Password) *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_getEyeIcon(_obscurePassword)),
                    onPressed: () {
                      setState(() {
                        if (_obscurePassword == true) {
                          _obscurePassword = false;
                        } else {
                          _obscurePassword = true;
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ยืนยันรหัสผ่าน (Confirm Password)
              TextFormField(
                controller: _confirmPasswordController,
                validator: _validateConfirmPassword,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[\x00-\x7F]'),
                  ),
                ],
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน *',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_getEyeIcon(_obscureConfirmPassword)),
                    onPressed: () {
                      setState(() {
                        if (_obscureConfirmPassword == true) {
                          _obscureConfirmPassword = false;
                        } else {
                          _obscureConfirmPassword = true;
                        }
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ปุ่มบันทึกข้อมูลพนักงาน
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text(
                    'บันทึกข้อมูลพนักงาน',
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
