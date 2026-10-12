import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/decimal_text_input_formatter.dart';

// ส่วนข้อมูลทั่วไปของบริการ — ใช้ร่วมกันทั้งหน้าฟอร์มเพิ่มและแก้ไข
class ServiceGeneralInfoSectionWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController detailController;
  final TextEditingController laborCostController;

  const ServiceGeneralInfoSectionWidget({
    super.key,
    required this.nameController,
    required this.detailController,
    required this.laborCostController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ข้อมูลทั่วไปของบริการ',
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // ชื่อบริการ
            TextFormField(
              controller: nameController,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'กรุณากรอกชื่อบริการ';
                }
                return null;
              },
              decoration: _inputDecoration(
                labelText: 'ชื่อบริการ *',
                hintText: 'เช่น เปลี่ยนถ่ายน้ำมันเครื่อง',
                prefixIcon: const Icon(Icons.handyman_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // รายละเอียดบริการ (ไม่บังคับ)
            TextFormField(
              controller: detailController,
              maxLines: 3,
              decoration: _inputDecoration(
                labelText: 'รายละเอียด',
                hintText: 'เช่น บริการเปลี่ยนน้ำมันเครื่องและไส้กรอง',
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // ค่าแรง
            TextFormField(
              controller: laborCostController,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'กรุณากรอกค่าแรง';
                }
                final parsed = double.tryParse(val.trim());
                if (parsed == null) {
                  return 'กรุณากรอกตัวเลข';
                }
                if (parsed < 0) {
                  return 'ค่าแรงต้องไม่ติดลบ';
                }
                return null;
              },
              maxLength: 10,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [
                DecimalTextInputFormatter(decimalRange: 2),
              ],
              decoration: _inputDecoration(
                labelText: 'ค่าแรง (บาท) *',
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
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // รูปแบบช่องกรอกมาตรฐานของฟอร์ม
  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    Widget? prefixIcon,
    String? counterText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      counterText: counterText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
