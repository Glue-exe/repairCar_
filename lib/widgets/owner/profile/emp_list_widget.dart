import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/employee_model.dart';
import 'package:my_app/widgets/owner/profile/emp_edit_widget.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/screens/owner/owner_view_screen.dart';

class EmpListWidget extends StatelessWidget {
  const EmpListWidget({super.key, required this.employeeModelStore});
  final List<EmployeeModel> employeeModelStore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount:
            employeeModelStore.length, // ลูปตามจำนวนสมาชิก employeeModelStore
        itemBuilder: (context, index) {
          // index รันตาม itemCount
          EmployeeModel item =
              employeeModelStore[index]; // index จะไปเอาข้อมูล obj พนักมาใส่ใน item

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              // tileColor: Colors.white,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person),
              ),
              title: Text(
                '${item.titleName}${item.empFirstname} ${item.empLastname}',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                'ตำแหน่ง: ${item.userRoleName} | เบอร์: ${item.empPhone} | สถานะ: ${item.empActive}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    color: Colors.blueAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmpEditWidget(employee: item),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.redAccent,
                    onPressed: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('ลบข้อมูล'),
                          content: const Text('ยืนยันที่จะลบหรือไม่?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text('ตกลง'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        var response = await AppAPI.delete(
                          '/employee',
                          {'emp_id': item.empId},
                        );

                        if (response.statusCode == 200) {
                          var responseBody = jsonDecode(response.body);

                          if (responseBody['isError'] == false) {
                            if (context.mounted) {
                              await showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('สำเร็จ'),
                                  content: Text(
                                    responseBody['data'] ?? 'ลบข้อมูลสำเร็จ',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('ตกลง'),
                                    ),
                                  ],
                                ),
                              );

                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OwnerViewUser(),
                                  ),
                                );
                              }
                            }
                          } else {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('เกิดข้อผิดพลาด'),
                                  content: Text(
                                    responseBody['errorMessage'] ?? 'เกิดข้อผิดพลาดในการลบ',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('ตกลง'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        } else {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('เกิดข้อผิดพลาด'),
                                content: Text('เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (Status: ${response.statusCode})'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('ตกลง'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
