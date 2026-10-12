import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/app_api.dart';

// หน้าจอเพิ่มยี่ห้อรถใหม่
class VehicleBrandAddScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const VehicleBrandAddScreen({super.key, this.onRefresh});

  @override
  State<VehicleBrandAddScreen> createState() => _VehicleBrandAddScreenState();
}

class _VehicleBrandAddScreenState extends State<VehicleBrandAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
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
      'คุณต้องการยืนยันการเพิ่มยี่ห้อรถหรือไม่?',
    );
    if (!confirm) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await AppAPI.post('/vehicle_brand', {
        'vb_name': _nameController.text.trim(),
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'เพิ่มข้อมูลยี่ห้อรถไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      widget.onRefresh?.call();
      _showMessage('เพิ่มข้อมูลยี่ห้อรถสำเร็จ', AppColors.success);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('เพิ่มยี่ห้อรถ', style: AppTextStyles.appBar),
        centerTitle: true,
        backgroundColor: AppColors.card,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ช่องกรอกชื่อยี่ห้อรถ
  Widget _buildNameField() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อมูลยี่ห้อรถ', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: AppFontSizes.input),
              decoration: const InputDecoration(
                labelText: 'ชื่อยี่ห้อรถ',
                hintText: 'เช่น Toyota, Honda',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อยี่ห้อรถ';
                }
                return null;
              },
            ),
          ],
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
          _isSaving ? 'กำลังบันทึกข้อมูล...' : 'บันทึกข้อมูลยี่ห้อรถ',
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
