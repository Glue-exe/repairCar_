import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';

// ตัวเลือกช่วงเวลาของโซน 
class DashboardRangeSelectorWidget extends StatelessWidget {
  final String range;
  final ValueChanged<String> onRangeChanged;

  const DashboardRangeSelectorWidget({
    super.key,
    required this.range,
    required this.onRangeChanged,
  });

  static const Map<String, String> _rangeLabels = {
    'today': 'วันนี้',
    'week': 'สัปดาห์นี้',
    'month': 'เดือนนี้',
    'year': 'ปีนี้',
  };

  static const TextStyle _textStyle = TextStyle(
    fontSize: AppFontSizes.body,
    fontFamily: 'Kanit',
    color: AppColors.textDark,
  );

  @override
  Widget build(BuildContext context) {
    final entries = _rangeLabels.entries.toList();

    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: range,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            style: _textStyle,
            dropdownColor: AppColors.card,
            items: entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value, style: _textStyle),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onRangeChanged(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
