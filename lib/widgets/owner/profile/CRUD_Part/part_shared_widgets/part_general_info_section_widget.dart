import 'package:flutter/material.dart';
import 'package:my_app/utils/decimal_text_input_formatter.dart';

class PartGeneralInfoSectionWidget extends StatelessWidget {
  final TextEditingController partCodeController;
  final TextEditingController partNameController;
  final TextEditingController partPriceController;
  final List<Map<String, dynamic>> partBrands;
  final int? selectedBrandId;
  final ValueChanged<int?> onBrandChanged;
  final List<Map<String, dynamic>> partCategories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;
  final List<String> unitOptions;
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;

  const PartGeneralInfoSectionWidget({
    super.key,
    required this.partCodeController,
    required this.partNameController,
    required this.partPriceController,
    required this.partBrands,
    required this.selectedBrandId,
    required this.onBrandChanged,
    required this.partCategories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.unitOptions,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  Future<void> _handleCustomUnit(BuildContext context) async {
    final String? customUnit = await CustomUnitDialog.show(context);
    if (customUnit != null && customUnit.trim().isNotEmpty) {
      final trimmed = customUnit.trim();
      if (!unitOptions.contains(trimmed)) {
        unitOptions.add(trimmed);
      }
      onUnitChanged(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'ข้อมูลทั่วไปของอะไหล่',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

          // รหัสอะไหล่ (Part Number) - ไม่บังคับ
          TextFormField(
            controller: partCodeController,
            decoration: InputDecoration(
              labelText: 'รหัสอะไหล่ (Part Number / OEM)',
              hintText: 'เช่น 04465-0D050 (เว้นว่างไว้เพื่อให้ระบบสร้างอัตโนมัติ)',
              helperText: 'หากไม่ระบุ ระบบจะสร้างรหัสอัตโนมัติ (เช่น P-xxxxxx)',
              prefixIcon: const Icon(Icons.qr_code_2),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ชื่ออะไหล่
          TextFormField(
            controller: partNameController,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'กรุณากรอกชื่ออะไหล่';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'ชื่ออะไหล่ *',
              hintText: 'เช่น ผ้าเบรกหน้า, กรองน้ำมันเครื่อง',
              prefixIcon: const Icon(Icons.build_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ยี่ห้ออะไหล่
          DropdownButtonFormField<int>(
            key: ValueKey('brand_${selectedBrandId}_${partBrands.length}'),
            initialValue: partBrands.any((item) => item['pb_id'] == selectedBrandId)
                ? selectedBrandId
                : null,
            decoration: InputDecoration(
              labelText: 'ยี่ห้ออะไหล่ *',
              hintText: 'เลือกยี่ห้ออะไหล่',
              prefixIcon: const Icon(Icons.branding_watermark_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: partBrands.map((item) {
              return DropdownMenuItem<int>(
                value: item['pb_id'] as int,
                child: Text((item['pb_name'] ?? '').toString()),
              );
            }).toList(),
            onChanged: onBrandChanged,
            validator: (val) {
              if (val == null) {
                return 'กรุณาเลือกยี่ห้ออะไหล่';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // หมวดหมู่อะไหล่
          DropdownButtonFormField<int>(
            key: ValueKey('category_${selectedCategoryId}_${partCategories.length}'),
            initialValue: partCategories.any((item) => item['pc_id'] == selectedCategoryId)
                ? selectedCategoryId
                : null,
            decoration: InputDecoration(
              labelText: 'หมวดหมู่อะไหล่ *',
              hintText: 'เลือกหมวดหมู่อะไหล่',
              prefixIcon: const Icon(Icons.category_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: partCategories.map((item) {
              return DropdownMenuItem<int>(
                value: item['pc_id'] as int,
                child: Text((item['pc_name'] ?? '').toString()),
              );
            }).toList(),
            onChanged: onCategoryChanged,
            validator: (val) {
              if (val == null) {
                return 'กรุณาเลือกหมวดหมู่อะไหล่';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // ราคาและหน่วยนับ (วางเคียงข้างกัน)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ราคาจำหน่าย
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: partPriceController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'กรุณากรอกราคาจำหน่าย';
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null) {
                      return 'กรุณากรอกตัวเลข';
                    }
                    if (parsed <= 0) {
                      return 'ราคาต้องมากกว่า 0 บาท';
                    }
                    return null;
                  },
                  maxLength: 10,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [
                    DecimalTextInputFormatter(decimalRange: 2),
                  ],
                  decoration: InputDecoration(
                    labelText: 'ราคาจำหน่าย (บาท) *',
                    hintText: '0.00',
                    counterText: '',
                    prefixIcon: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Text(
                          '฿',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // หน่วยนับ
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('unit_$selectedUnit'),
                  initialValue: selectedUnit,
                  isExpanded: true,
                  menuMaxHeight: 280,
                  decoration: InputDecoration(
                    labelText: 'หน่วยนับ *',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: [
                    ...unitOptions.map((String u) {
                      return DropdownMenuItem<String>(
                        value: u,
                        child: Text(u, overflow: TextOverflow.ellipsis),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: '__custom__',
                      child: Text(
                        '+ ระบุเอง...',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (String? val) {
                    if (val == '__custom__') {
                      _handleCustomUnit(context);
                    } else if (val != null) {
                      onUnitChanged(val);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}

/// Dialog สำหรับให้ผู้ใช้พิมพ์ระบุหน่วยนับเองในกรณีที่ไม่มีในรายการตัวเลือก
class CustomUnitDialog extends StatefulWidget {
  const CustomUnitDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const CustomUnitDialog(),
    );
  }

  @override
  State<CustomUnitDialog> createState() => _CustomUnitDialogState();
}

class _CustomUnitDialogState extends State<CustomUnitDialog> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submit() {
    String text = _customController.text.trim();
    if (text.isNotEmpty == true) {
      Navigator.pop(context, text);
    } else {
      Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('ระบุหน่วยนับเอง'),
      content: TextField(
        controller: _customController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'เช่น ถัง, ม้วน, กิโลกรัม',
          labelText: 'ชื่อหน่วยนับ *',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) {
          _submit();
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('ตกลง'),
        ),
      ],
    );
  }
}
