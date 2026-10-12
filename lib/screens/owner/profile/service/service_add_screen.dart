import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Service/service_shared_widgets/service_general_info_section_widget.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Service/service_shared_widgets/service_image_section_widget.dart';

// หน้าจอเพิ่มบริการใหม่
class ServiceAddScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const ServiceAddScreen({super.key, this.onRefresh});

  @override
  State<ServiceAddScreen> createState() => _ServiceAddScreenState();
}

class _ServiceAddScreenState extends State<ServiceAddScreen> {
  final _formKey = GlobalKey<FormState>();

  XFile? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _laborCostController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _laborCostController.dispose();
    super.dispose();
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
        );
      },
    );

    return confirm == true;
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate() != true) {
      return;
    }

    final bool confirm = await _showConfirmDialog(
      'ยืนยันการเพิ่มข้อมูล',
      'คุณต้องการยืนยันการเพิ่มข้อมูลบริการหรือไม่?',
    );
    if (!confirm) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await AppAPI.postMultipart(
        '/service',
        fields: {
          's_name': _nameController.text.trim(),
          's_detail': _detailController.text.trim(),
          's_labor_cost': _laborCostController.text.trim(),
        },
        file: _imageFile,
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'เพิ่มข้อมูลบริการไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      widget.onRefresh?.call();
      _showMessage('เพิ่มข้อมูลบริการสำเร็จ', AppColors.success);
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'เพิ่มบริการ',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SECTION 1: รูปภาพบริการ
              ServiceImageSectionWidget(
                imageFile: _imageFile,
                onImageSelected: (file) {
                  setState(() {
                    _imageFile = file;
                  });
                },
                onImageRemoved: () {
                  setState(() {
                    _imageFile = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // SECTION 2: ข้อมูลทั่วไปของบริการ
              ServiceGeneralInfoSectionWidget(
                nameController: _nameController,
                detailController: _detailController,
                laborCostController: _laborCostController,
              ),
              const SizedBox(height: 24),

              // SUBMIT BUTTON
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(
          _isSaving ? 'กำลังบันทึกข้อมูล...' : 'บันทึกข้อมูลบริการ',
          style: const TextStyle(
            fontSize: AppFontSizes.button,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSaving ? null : _saveData,
      ),
    );
  }
}
