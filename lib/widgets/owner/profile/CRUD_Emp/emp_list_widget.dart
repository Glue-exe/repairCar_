import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_app/models/employee_model.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Emp/emp_edit_widget.dart';
import 'package:my_app/utils/app_api.dart';

class EmpListWidget extends StatefulWidget {
  final List<EmployeeModel> employeeModelStore;
  final VoidCallback onRefresh;

  const EmpListWidget({
    super.key,
    required this.employeeModelStore,
    required this.onRefresh,
  });

  @override
  State<EmpListWidget> createState() => _EmpListWidgetState();
}

class _EmpListWidgetState extends State<EmpListWidget> {
  // null = ทุกตำแหน่ง, 1 = เจ้าของร้าน, 2 = พนักงานบัญชี, 3 = ช่าง
  int? _selectedRoleId;
  // 'all' = ทั้งหมด (พนักงานปัจจุบัน), 'active' = เปิดใช้งาน, 'inactive' = ปิดใช้งาน, 'resigned' = ไม่ได้ทำงานแล้ว
  String _selectedFilter = 'all';

  // สลับสถานะเปิด-ปิด
  Future<void> _toggleStatus(EmployeeModel item, bool isEnabled) async {
    bool previousStatus = item.isActive;

    setState(() {
      item.isActive = isEnabled;
    });

    try {
      var response = await AppAPI.put('/employee/status', {
        'emp_id': item.empId,
        'is_active': isEnabled,
      });

      var res = jsonDecode(response.body);
      if (res['isError'] == true) {
        setState(() {
          item.isActive = previousStatus;
        });
      }
    } catch (e) {
      setState(() {
        item.isActive = previousStatus;
      });
      debugPrint(e.toString());
    }
  }

  // ฟังก์ชันแสดง Dialog ยืนยันการลบ
  Future<bool> _showConfirmDialog(String empFirstName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('จัดเก็บข้อมูล'),
        content: Text('ยืนยันที่จัดเก็บข้อมูลของ $empFirstName หรือไม่?'),
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

  // ลบพนักงาน
  Future<void> _deleteEmployee(EmployeeModel item) async {
    bool confirm = await _showConfirmDialog(item.empFirstName);

    if (confirm == true) {
      var response = await AppAPI.delete('/employee', {'emp_id': item.empId});

      var res = jsonDecode(response.body);
      
      if (res['isError'] == false) {
        widget.onRefresh();
      }
    }
  }

  // Dialog ยืนยันการกู้คืน
  Future<bool> _showRestoreConfirmDialog(String empFirstName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('กู้คืนข้อมูลพนักงาน'),
        content: Text('ยืนยันที่จะกู้คืน $empFirstName กลับมาเป็นพนักงานหรือไม่?'),
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
      ),
    );

    return confirm == true;
  }

  // กู้คืนพนักงาน
  Future<void> _restoreEmployee(EmployeeModel item) async {
    bool confirm = await _showRestoreConfirmDialog(item.empFirstName);

    if (confirm == true) {
      var response = await AppAPI.put('/employee/restore', {'emp_id': item.empId});
      var res = jsonDecode(response.body);

      if (res['isError'] == false) {
        widget.onRefresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.employeeModelStore.where((emp) {
      final matchesRole =
          _selectedRoleId == null || emp.accRoleId == _selectedRoleId;

      bool matchesStatus = true;
      if (_selectedFilter == 'all') {
        matchesStatus = !emp.isDeleted;
      } else if (_selectedFilter == 'active') {
        matchesStatus = !emp.isDeleted && emp.isActive;
      } else if (_selectedFilter == 'inactive') {
        matchesStatus = !emp.isDeleted && !emp.isActive;
      } else if (_selectedFilter == 'resigned') {
        matchesStatus = emp.isDeleted;
      }

      return matchesRole && matchesStatus;
    }).toList();

    return Column(
      children: [
        // แถบตัวกรองสถานะบัญชี (Status Filter)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('ทั้งหมด'),
                selected: _selectedFilter == 'all',
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = 'all';
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('เปิดใช้งาน'),
                selected: _selectedFilter == 'active',
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = 'active';
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('ปิดใช้งาน'),
                selected: _selectedFilter == 'inactive',
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = 'inactive';
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('ไม่ได้ทำงานแล้ว'),
                selected: _selectedFilter == 'resigned',
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = 'resigned';
                  });
                },
              ),
            ],
          ),
        ),

        // แถบตัวกรองตำแหน่งงาน (Role Filter)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('ทุกตำแหน่ง'),
                selected: _selectedRoleId == null,
                onSelected: (_) {
                  setState(() {
                    _selectedRoleId = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('เจ้าของร้าน'),
                selected: _selectedRoleId == 1,
                onSelected: (_) {
                  setState(() {
                    _selectedRoleId = 1;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('พนักงานบัญชี'),
                selected: _selectedRoleId == 2,
                onSelected: (_) {
                  setState(() {
                    _selectedRoleId = 2;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('ช่าง'),
                selected: _selectedRoleId == 3,
                onSelected: (_) {
                  setState(() {
                    _selectedRoleId = 3;
                  });
                },
              ),
            ],
          ),
        ),

        // รายการพนักงาน
        Expanded(
          child: filteredList.isEmpty
              ? const Center(
                  child: Text(
                    'ไม่พบข้อมูลพนักงานที่ตรงกับเงื่อนไข',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {

                    final item = filteredList[index];
                    final bool isEnabled = item.isActive;
                    final bool isResigned = item.isDeleted;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isResigned
                                    ? Colors.grey.shade400
                                    : (isEnabled ? Colors.teal : Colors.grey),
                                child: Icon(
                                  isResigned ? Icons.person_off : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '${item.tName}${item.empFirstName} ${item.empLastName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isResigned ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Text('ไอดีผู้ใช้: ${item.accUsername}\nตำแหน่ง: ${item.arName}\nเบอร์โทร: ${item.empPhone}'),
                              trailing: isResigned
                                  ? OutlinedButton.icon(
                                      icon: const Icon(Icons.restore, size: 18),
                                      label: const Text('กู้คืน'),
                                      onPressed: () => _restoreEmployee(item),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EmpEditWidget(
                                                  employee: item,
                                                  onRefresh: widget.onRefresh,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () => _deleteEmployee(item),
                                        ),
                                      ],
                                    ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isResigned
                                      ? 'สถานะ: ไม่ได้ทำงานแล้ว'
                                      : (isEnabled ? 'สถานะ: เปิดใช้งาน' : 'สถานะ: ปิดใช้งาน'),
                                  style: TextStyle(
                                    color: isResigned
                                        ? Colors.grey
                                        : (isEnabled ? Colors.green : Colors.red),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!isResigned)
                                  Switch(
                                    value: isEnabled,
                                    activeThumbColor: Colors.green,
                                    onChanged: (value) => _toggleStatus(item, value),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
