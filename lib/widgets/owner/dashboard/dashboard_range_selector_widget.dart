import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';

// ตัวเลือกช่วงเวลา — value ต้องตรงกับ backend: today/week/month/year (ค่าไม่รู้จัก backend จะ fallback เป็น month)
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

  @override
  Widget build(BuildContext context) {
    final entries = _rangeLabels.entries.toList();

    return Row(
      children: [
        const Text(
          'ช่วงเวลา',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
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
                items: entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
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
        ),
      ],
    );
  }
}
