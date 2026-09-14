import 'package:flutter/material.dart';
import 'package:my_app/models/employee_model.dart';
import 'package:my_app/widgets/owner/profile/emp/emp_edit_widget.dart';
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
  // null = ทั้งหมด, 1 = เจ้าของร้าน, 2 = พนักงานบัญชี, 3 = ช่าง
  int? _selectedRoleId;

  // สลับสถานะเปิด-ปิด
  Future<void> _toggleStatus(EmployeeModel item, bool isEnabled) async {
    setState(() {
      item.accStatusId = isEnabled ? 1 : 0;
    });

    await AppAPI.put('/employee/status', {
      'emp_id': item.id,
      'acc_status_id': item.accStatusId,
    });
  }

  // ลบพนักงาน
  Future<void> _deleteEmployee(EmployeeModel item) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบข้อมูล'),
        content: Text('ยืนยันที่จะลบ ${item.firstName} หรือไม่?'),
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
      await AppAPI.delete('/employee', {'emp_id': item.id});
      setState(() {
        widget.employeeModelStore.removeWhere((e) => e.id == item.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedRoleId == null
        ? widget.employeeModelStore
        : widget.employeeModelStore
            .where((emp) => emp.userRoleId == _selectedRoleId)
            .toList();

    return Column(
      children: [
        // แถบตัวกรองตำแหน่งงาน (Role Filter)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('ทั้งหมด'),
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
                    'ไม่พบข้อมูลพนักงานในตำแหน่งนี้',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final bool isEnabled = item.accStatusId == 1;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                '${item.titleName}${item.firstName} ${item.lastName}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('ไอดีผู้ใช้: ${item.username}\nตำแหน่ง: ${item.userRoleName}\nเบอร์โทร: ${item.phone}'),
                              trailing: Row(
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
                                  isEnabled ? 'สถานะ: เปิดใช้งาน' : 'สถานะ: ปิดใช้งาน',
                                  style: TextStyle(
                                    color: isEnabled ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
