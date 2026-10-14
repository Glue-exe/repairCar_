import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';

// หัวข้อโซนของ Dashboard — มีช่อง trailing สำหรับวางตัวควบคุมของโซนนั้น
// (เช่น dropdown ช่วงเวลา ของโซน "ภาพรวม")
class DashboardSectionHeaderWidget extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const DashboardSectionHeaderWidget({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
