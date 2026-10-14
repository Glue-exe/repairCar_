import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';

// แถว รอจัดการ
class DashboardActionRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final String unit;
  final Color color;
  final VoidCallback? onTap;

  const DashboardActionRowWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.unit,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: AppFontSizes.subtitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count $unit',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: AppFontSizes.tag,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
