import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/title_model.dart';
import 'package:my_app/models/user_role_model.dart';

class EmpAddScreen extends StatefulWidget {
  const EmpAddScreen({super.key});

  @override
  State<EmpAddScreen> createState() => _EmpAddScreenState();
}

class _EmpAddScreenState extends State<EmpAddScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int? _selectedTitle;
  int? _selectedRole;

  List<TitleModel> titleModelStore = [];
  List<RoleModel> RoleModelStore = [];

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

  String? _validateRequired(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'กรุณากรอกข้อมูล';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }
    if (value != _passwordController.text) {
      return 'รหัสผ่านไม่ตรงกัน';
    }
    return null;
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('ยืนยันการเพิ่มข้อมูล'),
            content: const Text(
              'คุณต้องการยืนยันการเพิ่มข้อมูลพนักงานหรือไม่?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('ยืนยัน'),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        String rawPassword = _passwordController.text;
        String hashedPassword = sha256
            .convert(utf8.encode(rawPassword))
            .toString();

        var data = {
          'username': _usernameController.text,
          'password': hashedPassword,
          'title_id': _selectedTitle,
          'firstname': _firstnameController.text,
          'lastname': _lastnameController.text,
          'phone': _phoneController.text,
          'user_role_id': _selectedRole,
        };

        var response = await AppAPI.post('/employee', data);
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
                content: Text(
                  responseBody['errorMessage'] ?? 'ไม่สามารถเพิ่มข้อมูลได้',
                ),
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
      RoleModelStore = roleResponse.data;
    });
  }

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
        title: Text('เพิ่มข้อมูลพนักงาน'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
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
                        children: [
                          Text('username'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _usernameController,
                            validator: _validateRequired,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\x00-\x7F]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('password'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            validator: _validateRequired,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\x00-\x7F]'),
                              ),
                            ],
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
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
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('confirm password'),
                          SizedBox(height: 8),
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
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _getEyeIcon(_obscureConfirmPassword),
                                ),
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
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('title'),
                          SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedTitle,
                            validator: _validateRequired,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: titleModelStore.map((TitleModel item) {
                              // .map() จะไปดึงข้อมูลใน titleModelStore ออกมาทีละ 1 ตัว ข้อมูล 1 ตัวที่ดึงออกมา จะถูกตั้งชื่อชั่วคราวว่า item (ซึ่งมีชนิดเป็น TitleModel)
                              return DropdownMenuItem<int>(
                                value: item.titleId,
                                child: Text(item.titleName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTitle = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('firstname'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _firstnameController,
                            validator: _validateRequired,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('lastname'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _lastnameController,
                            validator: _validateRequired,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('phone'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            validator: _validateRequired,
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('role'),
                          SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedRole,
                            validator: _validateRequired,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: RoleModelStore.map((RoleModel item) {
                              return DropdownMenuItem<int>(
                                value: item.userRoleId,
                                child: Text(item.uesrRoleName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _saveData,
                  child: const Text('ยืนยัน'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
