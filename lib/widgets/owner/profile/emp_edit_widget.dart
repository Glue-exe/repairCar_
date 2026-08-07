import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:my_app/models/employee_model.dart';
import 'package:my_app/models/title_model.dart';
import 'package:my_app/models/user_role_model.dart';
import 'package:my_app/utils/app_api.dart';

class EmpEditWidget extends StatefulWidget {
  final EmployeeModel employee;

  const EmpEditWidget({super.key, required this.employee});

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

  List<TitleModel> titleModelStore = [];
  List<RoleModel> roleModelStore = [];

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController(
      text: widget.employee.empFirstname,
    );
    _lastnameController = TextEditingController(
      text: widget.employee.empLastname,
    );
    _phoneController = TextEditingController(text: widget.employee.empPhone);
    _selectedTitle = widget.employee.titleId;
    _selectedRole = widget.employee.userRoleId;
    _fetchData();
  }

  @override
  void dispose() {
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
      roleModelStore = roleResponse.data;
    });
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
          'emp_id': widget.employee.empId,
          'title_id': _selectedTitle,
          'firstname': _firstnameController.text,
          'lastname': _lastnameController.text,
          'phone': _phoneController.text,
          'user_role_id': _selectedRole,
        };

        var response = await AppAPI.put('/employee', data);
        var responseBody = jsonDecode(response.body);

        if (responseBody['isError'] == false) {
          if (mounted) {
            // mounted จะมีค่าเป็น true ถ้าหน้าจอยังเปิดอยู่ปกติ
            // mounted จะมีค่าเป็น false ถ้าหน้าจอโดนปิดไปแล้ว
            Navigator.pop(context, true);
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('title'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedTitle,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: titleModelStore.map((TitleModel item) {
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('firstname'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _firstnameController,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('lastname'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _lastnameController,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('phone'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            validator: _validateRequired,
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('role'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedRole,
                            validator: _validateRequired,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: roleModelStore.map((RoleModel item) {
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
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _saveData,
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
