import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Part/part_edit_widget.dart';

class PartListWidget extends StatelessWidget {
  final List<PartModel> partModelStore;
  final VoidCallback? onRefresh;

  const PartListWidget({
    super.key,
    required this.partModelStore,
    this.onRefresh,
  });

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
    return result == true;
  }

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
              leading: item.url != null && item.url!.trim().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.url!.trim().startsWith('http')
                            ? item.url!.trim()
                            : '${AppConfig.imageBaseUri}/${item.url!.trim().startsWith('/') ? item.url!.trim().substring(1) : item.url!.trim()}',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.build),
                        ),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.build),
                    ),
              title: Text(item.name),
              subtitle: Text(
                'ยี่ห้อ: ${item.brand}${item.modelName != null ? ' \nรุ่นที่เข้ากันได้: ${item.vehicleBrandName ?? ''} ${item.modelName}' : ''}\nราคา: ${item.price} บาท',
              ),
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
                          builder: (context) =>
                              PartEditWidget(part: item, onRefresh: onRefresh),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.redAccent,
                    onPressed: () async {
                      bool confirm = await _showConfirmDialog(
                        context,
                        'ลบข้อมูล',
                        'ยืนยันที่จะลบหรือไม่?',
                      );

                      if (!confirm) return;

                      final response = await AppAPI.delete(
                        '/deletePart',
                        {'part_id': item.id},
                      );
                      final resJson = jsonDecode(response.body);

                      if (context.mounted) {
                        if (resJson['isError'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('ลบไม่สำเร็จ: ${resJson['errorMessage']}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ลบข้อมูลอะไหล่สำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }

                      if (onRefresh != null) {
                        onRefresh!();
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
