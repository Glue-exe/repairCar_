import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/repair_category_model.dart';
import 'package:my_app/utils/app_api.dart';

// หน้าเพิ่มรายการซ่อมย่อย (เลือกจากหมวดซ่อมตามส่วนของรถ)
class OrderAddRepairSubTaskScreen extends StatefulWidget {
  final int orderId;

  const OrderAddRepairSubTaskScreen({super.key, required this.orderId});

  @override
  State<OrderAddRepairSubTaskScreen> createState() =>
      _OrderAddRepairSubTaskScreenState();
}

class _OrderAddRepairSubTaskScreenState
    extends State<OrderAddRepairSubTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _laborCostController = TextEditingController();

  // รายการหมวดซ่อมที่ได้จากเซิร์ฟเวอร์
  List<RepairCategoryModel> _repairCategories = [];
  int? _selectedRepairCategoryId;

  // สถานะกำลังโหลด / กำลังบันทึก
  bool _loading = true;
  bool _saving = false;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRepairCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _laborCostController.dispose();
    super.dispose();
  }

  Future<void> _loadRepairCategories() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await AppAPI.get('/repair_categories');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        final list = json['data'] as List;
        setState(() {
          _repairCategories = list
              .map((e) => RepairCategoryModel.fromJson(e))
              .toList();
        });

        // เลือกหมวดแรกให้อัตโนมัติ
        if (_repairCategories.isNotEmpty) {
          _selectRepairCategory(_repairCategories.first.id);
        }
      }
    } catch (_) {
      _showMessage('โหลดรายการหมวดซ่อมไม่สำเร็จ', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // เลือกหมวดซ่อม แล้วเติมชื่อหมวดให้ (ค่าแรงให้ช่างกรอกเอง)
  void _selectRepairCategory(int? categoryId) {
    if (categoryId == null) return;
    final selected = _repairCategories.firstWhere((c) => c.id == categoryId);

    setState(() {
      _selectedRepairCategoryId = categoryId;
      _nameController.text = selected.name;
      _laborCostController.text = '';
    });
  }

  Future<void> _saveSubTask() async {
    // ตรวจสอบข้อมูล
    if (_selectedRepairCategoryId == null) {
      setState(() => _errorMessage = 'กรุณาเลือกหมวดซ่อม');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'กรุณากรอกชื่องานซ่อม');
      return;
    }
    final double? laborCost = double.tryParse(_laborCostController.text.trim());
    if (laborCost == null) {
      setState(() => _errorMessage = 'กรุณากรอกค่าแรงเป็นตัวเลข');
      return;
    }

    setState(() {
      _errorMessage = '';
    });

    // ยืนยันก่อนบันทึก
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มรายการซ่อม'),
          content: Text(
            'ต้องการบันทึกรายการ ${_nameController.text.trim()} หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _saving = true;
    });

    try {
      final response = await AppAPI.post('/sub_task', {
        'st_order_id': widget.orderId,
        'st_repair_category_id': _selectedRepairCategoryId,
        'st_name': _nameController.text.trim(),
        'st_labor_cost': laborCost,
        'st_sub_task_status_id': 1, // 1 = รอดำเนินการ
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        setState(() {
          _errorMessage = json['errorMessage'] ?? 'บันทึกไม่สำเร็จ';
        });
        return;
      }

      _showMessage('เพิ่มรายการซ่อมเรียบร้อยแล้ว', Colors.green);
      Navigator.pop(context, true);
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppFontSizes.body,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildRepairCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('เลือกหมวดซ่อม'),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedRepairCategoryId,
              isExpanded: true,
              hint: const Text('เลือกหมวดซ่อม'),
              icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
              items: _repairCategories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _saving ? null : _selectRepairCategory,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool numberOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !_saving,
          keyboardType: numberOnly
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    if (_repairCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'ไม่พบรายการหมวดซ่อม',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRepairCategoryDropdown(),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'ชื่องานซ่อม',
          controller: _nameController,
          hint: 'ชื่องานซ่อม',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'ค่าแรง',
          controller: _laborCostController,
          hint: 'ค่าแรง',
          numberOnly: true,
        ),

        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(_errorMessage, style: const TextStyle(color: AppColors.danger)),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveSubTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'บันทึกข้อมูล',
              style: TextStyle(
                fontSize: AppFontSizes.button,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'เพิ่มงานซ่อมส่วน #${widget.orderId}',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : _buildForm(),
      ),
    );
  }
}
