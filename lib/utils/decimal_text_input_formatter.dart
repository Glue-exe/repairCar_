import 'package:flutter/services.dart';

/// Formatter สำหรับตรวจสอบตัวเลขทศนิยม ป้องกันการพิมพ์จุดซ้ำซ้อน
/// และจำกัดทศนิยมไม่เกิน [decimalRange] ตำแหน่ง
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  const DecimalTextInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final regex = RegExp('^\\d*\\.?\\d{0,$decimalRange}\$');
    if (regex.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
