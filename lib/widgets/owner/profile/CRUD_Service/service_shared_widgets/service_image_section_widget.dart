import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/widgets/image_widget.dart';

// ส่วนรูปภาพบริการ — ใช้ร่วมกันทั้งหน้าฟอร์มเพิ่มและแก้ไข
class ServiceImageSectionWidget extends StatelessWidget {
  final XFile? imageFile;
  final String? imageUrl;
  final ValueChanged<XFile?> onImageSelected;
  final VoidCallback onImageRemoved;

  const ServiceImageSectionWidget({
    super.key,
    required this.imageFile,
    this.imageUrl,
    required this.onImageSelected,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                const Text(
                  'รูปภาพบริการ',
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Center(
              child: ImageWidget(
                imageFile: imageFile,
                imageUrl: imageUrl,
                label: hasImage ? 'แก้ไขรูปภาพบริการ' : 'เพิ่มรูปภาพบริการ',
                width: 130,
                height: 130,
                borderRadius: 14,
                onImageSelected: onImageSelected,
                onImageRemoved: onImageRemoved,
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'แตะที่รูปเพื่อถ่ายภาพหรือเลือกจากคลังภาพ (ไม่บังคับ)',
                style: TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
