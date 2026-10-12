import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/service_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Service/service_shared_widgets/service_general_info_section_widget.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Service/service_shared_widgets/service_image_section_widget.dart';

// หน้าจอแก้ไขบริการ — ใช้ shared section ชุดเดียวกับหน้าฟอร์มเพิ่ม
class ServiceEditWidget extends StatefulWidget {
  final ServiceModel service;
  final VoidCallback? onRefresh;

  const ServiceEditWidget({
    super.key,
    required this.service,
    this.onRefresh,
  });

  @override
  State<ServiceEditWidget> createState() => _ServiceEditWidgetState();
}

class _ServiceEditWidgetState extends State<ServiceEditWidget> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _detailController;
  late TextEditingController _laborCostController;

  XFile? _imageFile;
  String? _imageUrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _detailController = TextEditingController(
      text: widget.service.detail ?? '',
    );
    _laborCostController = TextEditingController(
      text: widget.service.laborCost.toStringAsFixed(2),
    );
    _imageUrl = widget.service.serviceUrl;
  }

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
      'ยืนยันการแก้ไขข้อมูล',
      'คุณแน่ใจหรือไม่ว่าต้องการบันทึกการแก้ไขนี้?',
    );
    if (!confirm) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await AppAPI.putMultipart(
        '/service',
        fields: {
          's_id': widget.service.id.toString(),
          's_name': _nameController.text.trim(),
          's_detail': _detailController.text.trim(),
          's_labor_cost': _laborCostController.text.trim(),
          // ส่งรูปเดิมกลับไป ("" = ลบรูปเดิม) — ถ้าเลือกไฟล์ใหม่ ไฟล์จะชนะ
          's_service_url': _imageUrl ?? '',
        },
        file: _imageFile,
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'แก้ไขข้อมูลบริการไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      widget.onRefresh?.call();
      _showMessage('แก้ไขข้อมูลบริการสำเร็จ', AppColors.success);
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
          'แก้ไขบริการ',
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
              // SECTION 1: รูปภาพบริการ (ส่งรูปเดิมไปด้วย)
              ServiceImageSectionWidget(
                imageFile: _imageFile,
                imageUrl: _imageUrl,
                onImageSelected: (file) {
                  setState(() {
                    _imageFile = file;
                  });
                },
                onImageRemoved: () {
                  setState(() {
                    _imageFile = null;
                    _imageUrl = null;
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
          _isSaving ? 'กำลังบันทึกข้อมูล...' : 'บันทึกการแก้ไข',
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
