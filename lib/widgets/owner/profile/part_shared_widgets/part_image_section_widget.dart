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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'รูปภาพอะไหล่',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
    );
  }
}
