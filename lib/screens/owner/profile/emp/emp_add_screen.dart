import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/models/title_model.dart';
import 'package:my_app/models/user_role_model.dart';
import 'package:my_app/utils/app_api.dart';

class EmpAddScreen extends StatefulWidget {
  final VoidCallback onRefresh;

  const EmpAddScreen({super.key, required this.onRefresh});

  @override
  State<EmpAddScreen> createState() => _EmpAddScreenState();
}

class _EmpAddScreenState extends State<EmpAddScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // State Variables
  int? _selectedTitle;
  int? _selectedRole;
  int? _selectedSalary = 15000;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List<TitleModel> titleModelStore = [];
  List<RoleModel> roleModelStore = [];

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

  // แปลงตัวเลขเป็นข้อความมีคอมม่า
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // สลับไอคอนเปิด-ปิดตา
  IconData _getEyeIcon(bool isObscured) {
    if (isObscured == true) {
      return Icons.visibility_off;
    } else {
      return Icons.visibility;
    }
  }

  // ดึงข้อมูลคำนำหน้าและตำแหน่งงาน
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await Future.wait([
        AppAPI.get('/title'),
        AppAPI.get('/user_role'),
      ]);

      final Map<String, dynamic> titleJson = jsonDecode(response[0].body);
      final TitleResponse titleResponse = TitleResponse.fromJson(titleJson);

      final Map<String, dynamic> roleJson = jsonDecode(response[1].body);
      final RoleResponse roleResponse = RoleResponse.fromJson(roleJson);

      if (mounted) {
        setState(() {
          titleModelStore = titleResponse.data;
          if (titleModelStore.isNotEmpty) {
            _selectedTitle = titleModelStore.first.id;
          }

          roleModelStore = roleResponse.data;
          if (roleModelStore.isNotEmpty) {
            _selectedRole = roleModelStore.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'ไม่สามารถโหลดข้อมูลคำนำหน้าหรือตำแหน่งได้';
        });
      }
    }
  }

  // Dialog ยืนยันการเพิ่มข้อมูล
  Future<bool> _showConfirmDialog() async {
    String titleName = '';
    for (var t in titleModelStore) {
      if (t.id == _selectedTitle) {
        titleName = t.name;
      }
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการเพิ่มข้อมูล'),
        content: Text('ต้องการเพิ่มพนักงาน "$titleName${_firstnameController.text.trim()} ${_lastnameController.text.trim()}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      return true;
    } else {
      return false;
    }
  }

  // บันทึกข้อมูลพนักงาน
  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      bool confirm = await _showConfirmDialog();

      if (confirm == true) {
        setState(() {
          _isSaving = true;
        });

        try {
          final String rawPassword = _passwordController.text;
          final String hashedPassword = sha256.convert(utf8.encode(rawPassword)).toString();

          final data = {
            'acc_username': _usernameController.text.trim(),
            'acc_password_hash': hashedPassword,
            'emp_title_id': _selectedTitle,
            'emp_first_name': _firstnameController.text.trim(),
            'emp_last_name': _lastnameController.text.trim(),
            'emp_phone': _phoneController.text.trim(),
            'acc_role_id': _selectedRole,
            'emp_current_salary': _selectedSalary,
          };

          final response = await AppAPI.post('/employee', data);
          final responseBody = jsonDecode(response.body);

          if (responseBody['isError'] == false) {
            widget.onRefresh();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('เพิ่มข้อมูลพนักงานเรียบร้อยแล้ว'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          } else {
            if (mounted) {
              String errorMsg;
              if (responseBody['errorMessage'] != null) {
                errorMsg = responseBody['errorMessage'];
              } else {
                errorMsg = 'เกิดข้อผิดพลาดในการบันทึก';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_isLoading == true) {
      bodyContent = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_loadError != null) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loadError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    } else {
      Widget saveIcon;
      Widget saveLabel;
      VoidCallback? onSavePressed;

      if (_isSaving == true) {
        saveIcon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        );
        saveLabel = const Text(
          'กำลังบันทึกข้อมูล...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
        onSavePressed = null;
      } else {
        saveIcon = const Icon(Icons.save_outlined);
        saveLabel = const Text(
          'บันทึกข้อมูลพนักงาน',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
        onSavePressed = _saveData;
      }

      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // การ์ดส่วนที่ 1: ข้อมูลส่วนตัว
              _buildSectionCard(
                title: 'ข้อมูลส่วนตัว',
                icon: Icons.person_outline,
                children: [
                  // คำนำหน้าชื่อ (Dropdown จาก titleModelStore)
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTitle,
                    validator: (value) {
                      if (value == null) {
                        return 'กรุณาเลือกคำนำหน้า';
                      } else {
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'คำนำหน้าชื่อ *',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกชื่อจริง';
                      } else {
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'ชื่อจริง *',
                      hintText: 'กรอกชื่อจริง',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // นามสกุล
                  TextFormField(
                    controller: _lastnameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกนามสกุล';
                      } else {
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'นามสกุล *',
                      hintText: 'กรอกนามสกุล',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // เบอร์โทรศัพท์
                  TextFormField(
                    controller: _phoneController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกเบอร์โทรศัพท์';
                      } else if (value.trim().length != 10) {
                        return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
                      } else {
                        return null;
                      }
                    },
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'เบอร์โทรศัพท์ *',
                      hintText: '08xxxxxxxx',
                      counterText: '',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // การ์ดส่วนที่ 2: ข้อมูลตำแหน่งและเงินเดือน
              _buildSectionCard(
                title: 'ข้อมูลการทำงาน',
                icon: Icons.work_outline,
                children: [
                  // ตำแหน่งงาน
                  DropdownButtonFormField<int>(
                    initialValue: _selectedRole,
                    validator: (value) {
                      if (value == null) {
                        return 'กรุณาเลือกตำแหน่ง';
                      } else {
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'ตำแหน่งพนักงาน *',
                      prefixIcon: Icon(Icons.work_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                    validator: (value) {
                      if (value == null) {
                        return 'กรุณาเลือกเงินเดือน';
                      } else {
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'เงินเดือน *',
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                ],
              ),

              const SizedBox(height: 16),

              // การ์ดส่วนที่ 3: ข้อมูลบัญชีผู้ใช้งาน
              _buildSectionCard(
                title: 'ข้อมูลบัญชีเข้าสู่ระบบ',
                icon: Icons.account_circle_outlined,
                children: [
                  // Username
                  TextFormField(
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกชื่อผู้ใช้งาน';
                      } else {
                        return null;
                      }
                    },
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'))],
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้ใช้งาน (Username) *',
                      hintText: 'ภาษาอังกฤษหรือตัวเลข',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      } else if (value.length < 4) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร';
                      } else {
                        return null;
                      }
                    },
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน (Password) *',
                      hintText: 'อย่างน้อย 4 ตัวอักษร',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณายืนยันรหัสผ่าน';
                      } else if (value != _passwordController.text) {
                        return 'รหัสผ่านไม่ตรงกัน';
                      } else {
                        return null;
                      }
                    },
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'ยืนยันรหัสผ่าน *',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                ],
              ),

              const SizedBox(height: 24),

              // ปุ่มบันทึกข้อมูล
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: saveIcon,
                  label: saveLabel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onSavePressed,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลพนักงาน'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: bodyContent,
    );
  }

  // Helper สร้าง Card ประจำแต่ละส่วน (Section Card)
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
