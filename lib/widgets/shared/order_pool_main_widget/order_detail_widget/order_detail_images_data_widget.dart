import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/order_image_model.dart';
import 'package:my_app/models/order_pool_main_model.dart';
import 'package:my_app/utils/app_api.dart';

// การ์ดแสดงรูปถ่ายสภาพรถของ Order (เพิ่ม/ลบรูปได้จากกล้อง / คลังภาพ)
// เพิ่ม-ลบรูปได้เฉพาะเมื่อกดรับงานนี้แล้วเท่านั้น (เหมือนการ์ดอาการเสีย)
class OrderDetailImagesDataWidget extends StatefulWidget {
  final OrderPoolMainModel order;

  const OrderDetailImagesDataWidget({super.key, required this.order});

  @override
  State<OrderDetailImagesDataWidget> createState() =>
      _OrderDetailImagesDataWidgetState();
}

class _OrderDetailImagesDataWidgetState
    extends State<OrderDetailImagesDataWidget> {
  // รายการรูปที่ได้จากเซิร์ฟเวอร์
  List<OrderImageModel> _images = [];

  // สถานะกำลังโหลด / กำลังทำงาน (อัปโหลดหรือลบ)
  bool _loading = true;
  bool _busy = false;

  // ผู้ใช้กดรับงานนี้แล้วหรือยัง (ใช้คุมสิทธิ์เพิ่ม/ลบรูป)
  bool get _accepted => widget.order.acceptByMe;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await AppAPI.get('/order3/images/${widget.order.oId}');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        final list = json['data'] as List;
        setState(() {
          _images = list.map((e) => OrderImageModel.fromJson(e)).toList();
        });
      }
    } catch (_) {
      _showMessage('โหลดรูปภาพไม่สำเร็จ', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // เพิ่มรูป: เลือกจากกล้อง / คลังภาพ แล้วอัปโหลด
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;
      await _uploadImage(pickedFile);
    } catch (_) {
      _showMessage('ไม่สามารถเลือกรูปภาพได้', Colors.red);
    }
  }

  Future<void> _uploadImage(XFile file) async {
    setState(() {
      _busy = true;
    });

    try {
      final response = await AppAPI.postMultipart(
        '/order3/upload_image',
        fields: {'order_id': widget.order.oId.toString()},
        file: file,
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'อัปโหลดรูปไม่สำเร็จ', Colors.red);
        return;
      }

      _showMessage('อัปโหลดรูปเรียบร้อยแล้ว', Colors.green);
      await _loadImages();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // เปิดแผงเลือกแหล่งรูป (กล้อง / คลังภาพ)
  void _showImageSourcePicker() {
    // ต้องกดรับงานก่อน
    if (!_accepted) {
      _showMessage(
        'กรุณากดรับงานนี้ก่อน จึงจะสามารถเพิ่มรูปได้',
        Colors.orange,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primaryGreen,
                ),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primaryGreen,
                ),
                title: const Text('เลือกจากคลังภาพ'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ลบรูป
  Future<void> _confirmDelete(OrderImageModel image) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบรูปภาพ'),
          content: const Text('ต้องการลบรูปภาพนี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteImage(image.id);
    }
  }

  Future<void> _deleteImage(int imageId) async {
    // ต้องกดรับงานก่อน
    if (!_accepted) {
      _showMessage('กรุณากดรับงานนี้ก่อน จึงจะสามารถลบรูปได้', Colors.orange);
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final response = await AppAPI.delete('/order3/image/$imageId', {});
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'ลบรูปไม่สำเร็จ', Colors.red);
        return;
      }

      _showMessage('ลบรูปเรียบร้อยแล้ว', Colors.green);
      await _loadImages();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // แสดงรูปขนาดเต็มเมื่อกดที่รูป
  void _showFullImage(String fileName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                AppConfig.getImageUrl(fileName),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(40.0),
                    color: AppColors.inputBackground,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('ไม่สามารถโหลดรูปภาพได้'),
                      ],
                    ),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('ปิด'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.photo_camera, color: AppColors.primaryGreen, size: 22),
        const SizedBox(width: 8),
        const Text(
          'รูปถ่ายสภาพรถ',
          style: TextStyle(
            fontSize: AppFontSizes.headline,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const Spacer(),
        Text(
          '${_images.length} รูป',
          style: const TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textMuted,
          ),
        ),
        // แสดงปุ่มเพิ่มรูปเฉพาะเมื่อกดรับงานแล้ว
        if (_accepted && !_busy)
          IconButton(
            onPressed: _showImageSourcePicker,
            icon: const Icon(Icons.add_a_photo_outlined),
            color: AppColors.primaryGreen,
            tooltip: 'เพิ่มรูปภาพ',
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_images.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(
            'ไม่มีรูปภาพประกอบ',
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final image = _images[index];
          return Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullImage(image.url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    AppConfig.getImageUrl(image.url),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        color: AppColors.inputBackground,
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
                        width: 100,
                        height: 100,
                        color: AppColors.inputBackground,
                        child: const Icon(
                          Icons.broken_image,
                          color: AppColors.textMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ปุ่มลบมุมขวาบน แสดงเฉพาะเมื่อกดรับงานแล้ว
              if (_accepted && !_busy)
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => _confirmDelete(image),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // แบนเนอร์เตือนตอนยังไม่กดรับงาน
  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ต้องกดรับงานก่อน จึงจะเพิ่ม/ลบรูปได้',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.warningText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 20, thickness: 0.8),

            // แถบโหลด ตอนกำลังอัปโหลด/ลบ
            if (_busy) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
            ],

            _buildBody(),

            // ถ้ายังไม่รับงาน ให้แสดงคำเตือน
            if (!_accepted) ...[
              const SizedBox(height: 16),
              _buildWarningBanner(),
            ],
          ],
        ),
      ),
    );
  }
}
