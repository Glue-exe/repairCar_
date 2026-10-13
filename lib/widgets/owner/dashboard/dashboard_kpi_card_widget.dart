import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';

// การ์ด KPI ของ Dashboard
class DashboardKpiCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const DashboardKpiCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.statLabel,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.statNumber.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}
