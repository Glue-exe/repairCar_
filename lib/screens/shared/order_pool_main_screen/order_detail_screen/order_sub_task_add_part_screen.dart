import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/shared/part_image_thumbnail_widget.dart';

// หน้าเบิกอะไหล่ของงานซ่อมย่อย (เพิ่มได้หลายรายการ แก้จำนวน/ราคาได้)
class OrderSubTaskAddPartScreen extends StatefulWidget {
  final int subTaskId;
  final String subTaskName;

  const OrderSubTaskAddPartScreen({
    super.key,
    required this.subTaskId,
    required this.subTaskName,
  });

  @override
  State<OrderSubTaskAddPartScreen> createState() =>
      _OrderSubTaskAddPartScreenState();
}

class _OrderSubTaskAddPartScreenState extends State<OrderSubTaskAddPartScreen> {
  final NumberFormat _currency = NumberFormat('#,##0.00');

  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _priceController = TextEditingController();

  // อะไหล่ที่เข้ากับรถของงานย่อยนี้
  List<PartModel> _parts = [];
  int? _selectedPartId;

  // รายการที่เพิ่มเข้าใบเบิกแล้ว
  final List<_DraftItem> _items = [];

  bool _loading = true;
  bool _saving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadParts() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await AppAPI.get(
        '/compatible_parts?sub_task_id=${widget.subTaskId}',
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        setState(() {
          _parts = (json['data'] as List)
              .map((e) => PartModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {
      _showMessage('โหลดรายการอะไหล่ไม่สำเร็จ', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  PartModel? _partById(int? id) {
    for (final part in _parts) {
      if (part.id == id) return part;
    }
    return null;
  }

  PartModel? get _selectedPart => _partById(_selectedPartId);

  double get _total => _items.fold(0, (sum, item) => sum + item.lineTotal);

  void _selectPart(int? value) {
    setState(() {
      _selectedPartId = value;
      final part = _partById(value);
      if (part != null) {
        // เติมราคามาตรฐานมาให้ก่อน แก้ได้
        _priceController.text = part.partPrice.toString();
      }
    });
  }

  void _addItem() {
    final part = _selectedPart;
    if (part == null) {
      setState(() => _errorMessage = 'กรุณาเลือกอะไหล่');
      return;
    }

    // ห้ามซ้ำ: ให้ไปแก้จำนวนที่บรรทัดเดิม
    if (_items.any((item) => item.partId == part.id)) {
      _showMessage(
        'อะไหล่ชนิดนี้อยู่ในรายการแล้ว ปรับจำนวนที่บรรทัดเดิมได้เลย',
        AppColors.warning,
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      setState(() => _errorMessage = 'กรุณากรอกจำนวนให้ถูกต้อง');
      return;
    }
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price < 0) {
      setState(() => _errorMessage = 'กรุณากรอกราคาให้ถูกต้อง');
      return;
    }

    setState(() {
      _errorMessage = '';
      _items.add(
        _DraftItem(
          partId: part.id,
          name: part.name,
          unit: part.unit,
          imageUrl: part.url,
          quantity: TextEditingController(text: quantity.toString()),
          price: TextEditingController(text: price.toStringAsFixed(2)),
        ),
      );
      _selectedPartId = null;
      _quantityController.text = '1';
      _priceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      setState(() => _errorMessage = 'กรุณาเพิ่มรายการอะไหล่ก่อน');
      return;
    }
    for (final item in _items) {
      if (item.quantityValue <= 0) {
        setState(() => _errorMessage = 'จำนวนต้องมากกว่า 0');
        return;
      }
      if (item.priceValue < 0) {
        setState(() => _errorMessage = 'ราคาต้องไม่ติดลบ');
        return;
      }
    }
    setState(() => _errorMessage = '');

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการเบิกอะไหล่'),
          content: Text(
            'ต้องการส่งคำขอเบิก ${_items.length} รายการ รวม ${_currency.format(_total)} บาท หรือไม่?',
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
      final response = await AppAPI.post('/request_part', {
        'sub_task_id': widget.subTaskId,
        'items': _items
            .map(
              (item) => {
                'part_id': item.partId,
                'quantity': item.quantityValue,
                'price': item.priceValue,
              },
            )
            .toList(),
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        setState(() {
          _errorMessage = json['errorMessage'] ?? 'บันทึกไม่สำเร็จ';
        });
        return;
      }

      _showMessage('ส่งคำขอเบิกเรียบร้อยแล้ว', AppColors.success);
      Navigator.pop(context, true);
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildPartDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('เลือกอะไหล่'),
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
              value: _selectedPartId,
              isExpanded: true,
              hint: const Text('เลือกอะไหล่'),
              icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
              items: _parts.map((part) {
                return DropdownMenuItem<int>(
                  value: part.id,
                  child: Text(
                    part.name,
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
              onChanged: _saving ? null : _selectPart,
            ),
          ),
        ),
      ],
    );
  }

  // การ์ดตัวอย่างอะไหล่ที่กำลังเลือกอยู่ (โชว์รูป + เบอร์ + ยี่ห้อ + ราคา)
  Widget _buildSelectedPartPreview() {
    final part = _selectedPart;
    if (part == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartImageThumbnail(imageUrl: part.url, size: 84),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'เบอร์: ${part.partCode}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: AppColors.textMuted,
                  ),
                ),
                if (part.partBrandName != null &&
                    part.partBrandName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ยี่ห้อ: ${part.partBrandName}',
                    style: const TextStyle(
                      fontSize: AppFontSizes.caption,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '฿${_currency.format(part.partPrice)} / ${part.unit}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เพิ่มรายการอะไหล่',
              style: TextStyle(
                fontSize: AppFontSizes.headline,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const Divider(height: 20, thickness: 0.8),

            if (_parts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'ไม่พบอะไหล่ที่เข้ากับรถคันนี้',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else ...[
              _buildPartDropdown(),
              _buildSelectedPartPreview(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('จำนวน'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _quantityController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _inputDecoration('จำนวน'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('ราคา/ชิ้น'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _priceController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          decoration: _inputDecoration('ราคา'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'เพิ่มรายการ',
                    style: TextStyle(
                      fontSize: AppFontSizes.button,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PartImageThumbnail(imageUrl: item.imageUrl, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: _saving ? null : () => _removeItem(index),
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.danger,
                tooltip: 'ลบรายการ',
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('จำนวน'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: item.quantity,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration('จำนวน'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('ราคา/ชิ้น'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: item.price,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration('ราคา'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'รวม ฿${_currency.format(item.lineTotal)}',
              style: const TextStyle(
                fontSize: AppFontSizes.subtitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'รายการที่เบิก',
                  style: TextStyle(
                    fontSize: AppFontSizes.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_items.length} รายการ',
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),

            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'ยังไม่มีรายการอะไหล่',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < _items.length; i++) _buildItemCard(i),
                ],
              ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวม',
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '฿${_currency.format(_total)}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving || _items.isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ส่งคำขอเบิก',
                  style: TextStyle(
                    fontSize: AppFontSizes.button,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ขอเบิกอะไหล่',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // งานย่อยที่กำลังเบิก
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'งานย่อย: ${widget.subTaskName}',
                      style: const TextStyle(
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildAddForm(),
                  const SizedBox(height: 12),

                  _buildSummary(),
                ],
              ),
            ),
    );
  }
}

// รายการอะไหล่ที่กำลังจะเบิก (ยังไม่บันทึก)
class _DraftItem {
  final int partId;
  final String name;
  final String unit;
  final String? imageUrl;
  final TextEditingController quantity;
  final TextEditingController price;

  _DraftItem({
    required this.partId,
    required this.name,
    required this.unit,
    this.imageUrl,
    required this.quantity,
    required this.price,
  });

  int get quantityValue => int.tryParse(quantity.text.trim()) ?? 0;

  double get priceValue => double.tryParse(price.text.trim()) ?? 0;

  double get lineTotal => quantityValue * priceValue;

  void dispose() {
    quantity.dispose();
    price.dispose();
  }
}
