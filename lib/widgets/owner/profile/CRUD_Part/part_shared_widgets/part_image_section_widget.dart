import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/widgets/image_widget.dart';

class PartImageSectionWidget extends StatelessWidget {
  final XFile? imageFile;
  final String? imageUrl;
  final ValueChanged<XFile?> onImageSelected;
  final VoidCallback onImageRemoved;

  const PartImageSectionWidget({
    super.key,
    required this.imageFile,
    this.imageUrl,
    required this.onImageSelected,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(
                  Icons.photo_camera_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'รูปภาพอะไหล่',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Center(
              child: ImageWidget(
                imageFile: imageFile,
                imageUrl: imageUrl,
                label: imageUrl != null && imageUrl!.trim().isNotEmpty
                    ? 'แก้ไขรูปภาพอะไหล่'
                    : 'เพิ่มรูปภาพอะไหล่',
                width: 130,
                height: 130,
                borderRadius: 14,
                onImageSelected: onImageSelected,
                onImageRemoved: onImageRemoved,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'แตะที่รูปเพื่อถ่ายภาพหรือเลือกจากคลังภาพ (ไม่บังคับ)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
