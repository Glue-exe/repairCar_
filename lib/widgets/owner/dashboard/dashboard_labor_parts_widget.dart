import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';

// รายได้แยกค่าแรง / ค่าอะไหล่ ของช่วงที่เลือก
class DashboardLaborPartsWidget extends StatelessWidget {
  final double laborTotal;
  final double partsTotal;

  const DashboardLaborPartsWidget({
    super.key,
    required this.laborTotal,
    required this.partsTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _item('ค่าแรง', laborTotal, AppColors.info, Icons.handyman_outlined),
            const SizedBox(height: 10),
            _item('ค่าอะไหล่', partsTotal, AppColors.warning,
                Icons.settings_outlined),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, double value, Color color, IconData icon) {
    final currency = NumberFormat('#,##0');

    return Column(
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
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${currency.format(value)} ฿',
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: AppFontSizes.headline,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
