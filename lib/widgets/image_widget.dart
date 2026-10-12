import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_config.dart';

class ImageWidget extends StatefulWidget {
  final XFile? imageFile;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final ValueChanged<XFile>? onImageSelected;
  final ValueChanged<Uint8List>? onBytesSelected;
  final VoidCallback? onImageRemoved;
  final double width;
  final double height;
  final double borderRadius;
  final String label;
  final bool isEditable;
  final BoxFit fit;

  const ImageWidget({
    super.key,
    this.imageFile,
    this.imageBytes,
    this.imageUrl,
    this.onImageSelected,
    this.onBytesSelected,
    this.onImageRemoved,
    this.width = 140,
    this.height = 140,
    this.borderRadius = 12,
    this.label = 'เพิ่มรูปภาพ',
    this.isEditable = true,
    this.fit = BoxFit.cover,
  });

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _syncBytes();
  }

  @override
  void didUpdateWidget(covariant ImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageFile != oldWidget.imageFile || widget.imageBytes != oldWidget.imageBytes) {
      _syncBytes();
    }
  }

  void _syncBytes() async {
    if (widget.imageBytes != null) {
      setState(() {
        _previewBytes = widget.imageBytes;
      });
    } else if (widget.imageFile != null) {
      final bytes = await widget.imageFile!.readAsBytes();
      if (mounted) {
        setState(() {
          _previewBytes = bytes;
        });
      }
    } else {
      setState(() {
        _previewBytes = null;
      });
    }
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) {
          setState(() {
            _previewBytes = bytes;
          });
        }
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(pickedFile);
        }
        if (widget.onBytesSelected != null) {
          widget.onBytesSelected!(bytes);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปภาพได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    final hasImage = _previewBytes != null || (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.green),
                title: const Text('เลือกจากคลังภาพ'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              if (hasImage && widget.onImageRemoved != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('ลบรูปภาพ', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _previewBytes = null;
                    });
                    widget.onImageRemoved!();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = AppConfig.getImageUrl(widget.imageUrl);
    final hasImage = _previewBytes != null || fullUrl.isNotEmpty;

    Widget imageContent;

    if (_previewBytes != null) {
      // 1. แสดงรูปพรีวิวจาก memory (รองรับทั้ง Web, Android, iOS, Windows, Mac)
      imageContent = Image.memory(
        _previewBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    } else if (fullUrl.isNotEmpty) {
      // 2. แสดงรูปเดิมจากเซิร์ฟเวอร์
      imageContent = Image.network(
        fullUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
                SizedBox(height: 4),
                Text(
                  'โหลดรูปไม่สำเร็จ',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // 3. สถานะยังไม่มีรูป
      imageContent = Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: Colors.grey[350]!, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // กรอบรวม พร้อมตกแต่งขอบมนและไอคอนเปลี่ยนรูป
    return Center(
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: widget.isEditable ? () => _showImageSourceDialog(context) : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: imageContent,
                ),
              ),
            ),
          ),
          // ปุ่มไอคอนกล้อง/ดินสอ ที่มุมขวาล่างเมื่อมีรูปแล้ว
          if (widget.isEditable && hasImage)
            Positioned(
              right: 6,
              bottom: 6,
              child: InkWell(
                onTap: () => _showImageSourceDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
