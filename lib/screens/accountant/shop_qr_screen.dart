import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/utils/app_api.dart';

class ShopQrScreen extends StatefulWidget {
  const ShopQrScreen({super.key});

  @override
  State<ShopQrScreen> createState() => _ShopQrScreenState();
}

class _ShopQrScreenState extends State<ShopQrScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _currentQrImage;
  XFile? _selectedImageFile;
  bool _isLoading = true;
  bool _isUploading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchShopQr();
  }

  Future<void> _fetchShopQr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await AppAPI.get('/accountant/shop_qr');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['isError'] == false && json['data'] != null) {
          setState(() {
            _currentQrImage = json['data']['qr_image'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _isLoading = false;
        _currentQrImage = 'shop_qr_default.png';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'โหลด QR Code ไม่สำเร็จ: $e';
      });
    }
  }

  // BottomSheet สำหรับเลือกรูปภาพจากกล้องหรือคลังภาพ ตาม workshop PDF
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: const [
                    Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text(
                      'เลือกรูปภาพ QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                ),
                title: const Text('เลือกจากแกลเลอรี (Gallery)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                ),
                title: const Text('ถ่ายภาพใหม่ (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e')),
        );
      }
    }
  }

  Future<void> _uploadShopQr() async {
    if (_selectedImageFile == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = '';
    });

    try {
      final response = await AppAPI.postMultipart(
        '/accountant/shop_qr',
        file: _selectedImageFile,
      );

      final json = jsonDecode(response.body);
      if (json['isError'] == false) {
        setState(() {
          _currentQrImage = json['data']['qr_image'];
          _selectedImageFile = null;
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('บันทึก QR Code ของร้านเรียบร้อยแล้ว'),
                ],
              ),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = json['errorMessage'] ?? 'บันทึกรูปภาพไม่สำเร็จ';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'การเชื่อมต่อผิดพลาด: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('จัดการ QR Code ร้านค้า'),
        backgroundColor: Colors.teal.shade50,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context, _currentQrImage),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // คำอธิบาย
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'QR Code นี้จะแสดงให้กับพนักงานบัญชีและลูกค้าเพื่อสแกนชำระเงินเมื่อเลือกช่องทาง "โอนเงิน / PromptPay"',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // การ์ดแสดง QR Code
                  Card(
                    color: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.primaryGreen),
                                    SizedBox(width: 6),
                                    Text(
                                      'PromptPay QR Code',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ภาพ QR Code
                          GestureDetector(
                            onTap: _showImageSourcePicker,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedImageFile != null ? AppColors.primaryGreen : Colors.grey.shade300,
                                      width: _selectedImageFile != null ? 2.5 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: _selectedImageFile != null
                                        ? Image.file(
                                            File(_selectedImageFile!.path),
                                            fit: BoxFit.contain,
                                          )
                                        : (_currentQrImage != null && _currentQrImage!.isNotEmpty)
                                            ? Image.network(
                                                AppConfig.getImageUrl(_currentQrImage),
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: const [
                                                      Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                                      SizedBox(height: 8),
                                                      Text('ไม่สามารถโหลดภาพได้', style: TextStyle(color: Colors.grey)),
                                                    ],
                                                  );
                                                },
                                              )
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.qr_code_2, size: 64, color: Colors.grey),
                                                  SizedBox(height: 8),
                                                  Text('ยังไม่มี QR Code ของร้าน', style: TextStyle(color: Colors.grey)),
                                                ],
                                              ),
                                  ),
                                ),
                                // ปุ่มไอคอนกล้องที่มุมภาพ
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_selectedImageFile != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 16, color: Colors.amber.shade800),
                                  const SizedBox(width: 6),
                                  Text(
                                    'เลือกภาพใหม่แล้ว (ยังไม่ได้บันทึก)',
                                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'แตะที่รูปภาพเพื่อเปลี่ยนหรืออัปโหลดใหม่',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ปุ่มเลือกรูปภาพใหม่
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppColors.primaryGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isUploading ? null : _showImageSourcePicker,
                      icon: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primaryGreen),
                      label: Text(
                        _selectedImageFile != null ? 'เลือกภาพอื่น' : 'เปลี่ยนรูป QR Code',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),

                  // ปุ่มบันทึกการเปลี่ยนแปลง (แสดงเมื่อมีการเลือกภาพใหม่)
                  if (_selectedImageFile != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _isUploading ? null : _uploadShopQr,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          _isUploading ? 'กำลังอัปโหลด...' : 'บันทึก QR Code ของร้าน',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
