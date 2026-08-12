import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/screens/owner/owner_part_screen.dart';
import 'package:my_app/widgets/owner/profile/part_edit_widget.dart';

class PartListWidget extends StatelessWidget {
  final List<PartModel> partModelStore;
  const PartListWidget({super.key, required this.partModelStore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: partModelStore.length,
        itemBuilder: (context, index) {
          PartModel item = partModelStore[index];

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
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.build),
              ),
              title: Text('${item.partName}'),
              subtitle: Text('${item.partBrand}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    color: Colors.blueAccent,
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PartEditWidget(part: item),
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
                        var response = await AppAPI.delete('/part', {
                          'part_id': item.partId,
                        });

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
                                        const OwnerPartScreen(),
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
