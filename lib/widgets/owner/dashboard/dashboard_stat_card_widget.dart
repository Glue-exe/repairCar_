import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';

// การ์ดตัวเลขสรุปของ Dashboard
class DashboardStatCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardStatCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: AppFontSizes.tag,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTextStyles.statNumber.copyWith(color: color),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
