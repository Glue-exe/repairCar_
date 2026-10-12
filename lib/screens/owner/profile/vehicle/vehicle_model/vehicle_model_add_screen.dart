import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/vehicle_brand_model.dart';
import 'package:my_app/utils/app_api.dart';

// หน้าจอเพิ่มรุ่นรถใหม่
class VehicleModelAddScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const VehicleModelAddScreen({super.key, this.onRefresh});

  @override
  State<VehicleModelAddScreen> createState() => _VehicleModelAddScreenState();
}

class _VehicleModelAddScreenState extends State<VehicleModelAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  List<VehicleBrandModel> _brandList = [];
  int? _selectedBrandId;

  bool _isLoadingBrands = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // โหลดยี่ห้อรถสำหรับ dropdown
  Future<void> _fetchBrands() async {
    try {
      final response = await AppAPI.get('/vehicle_brand');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false) {
        final brandResponse = VehicleBrandResponse.fromJson(json);
        setState(() {
          _brandList = brandResponse.data;
        });
      }
    } catch (_) {
      // โหลดยี่ห้อไม่ได้ → dropdown ว่าง (ผู้ใช้ยังเห็นข้อความจาก validator)
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBrands = false;
        });
      }
    }
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
      'คุณต้องการยืนยันการเพิ่มรุ่นรถหรือไม่?',
    );
    if (!confirm) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await AppAPI.post('/vehicle_model', {
        'vm_brand_id': _selectedBrandId,
        'vm_name': _nameController.text.trim(),
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'เพิ่มข้อมูลรุ่นรถไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      widget.onRefresh?.call();
      _showMessage('เพิ่มข้อมูลรุ่นรถสำเร็จ', AppColors.success);
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
        title: const Text('เพิ่มรุ่นรถ', style: AppTextStyles.appBar),
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
              _buildInfoSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // การ์ดกรอกข้อมูลรุ่นรถ (ยี่ห้อ + ชื่อรุ่น)
  Widget _buildInfoSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อมูลรุ่นรถ', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),

            // ยี่ห้อรถ
            DropdownButtonFormField<int>(
              initialValue: _selectedBrandId,
              style: const TextStyle(
                fontSize: AppFontSizes.input,
                color: AppColors.textDark,
                fontFamily: 'Kanit',
              ),
              decoration: InputDecoration(
                labelText: 'ยี่ห้อรถ',
                border: const OutlineInputBorder(),
                hintText: _isLoadingBrands ? 'กำลังโหลดยี่ห้อรถ...' : 'เลือกยี่ห้อรถ',
              ),
              items: _brandList.map((brand) {
                return DropdownMenuItem<int>(
                  value: brand.vbId,
                  child: Text(brand.vbName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBrandId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'กรุณาเลือกยี่ห้อรถ';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ชื่อรุ่นรถ
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: AppFontSizes.input),
              decoration: const InputDecoration(
                labelText: 'ชื่อรุ่นรถ',
                hintText: 'เช่น Yaris, Civic',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อรุ่นรถ';
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
          _isSaving ? 'กำลังบันทึกข้อมูล...' : 'บันทึกข้อมูลรุ่นรถ',
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
