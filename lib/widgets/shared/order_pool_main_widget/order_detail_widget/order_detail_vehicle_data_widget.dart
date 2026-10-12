import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_main_model.dart';

class OrderDetailVehicleDataWidget extends StatelessWidget {
  final OrderPoolMainModel order;

  const OrderDetailVehicleDataWidget({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัว: ไอคอนและชื่อหัวข้อ
            const Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'ข้อมูลรถยนต์',
                  style: TextStyle(
                    fontSize: AppFontSizes.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),

            // ป้ายทะเบียนรถ
            Row(
              children: [
                const Text(
                  'ทะเบียนรถ: ',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  order.vLicensePlate,
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ยี่ห้อรถยนต์
            Row(
              children: [
                const Text(
                  'ยี่ห้อ: ',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  order.vbName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // รุ่นรถยนต์
            Row(
              children: [
                const Text(
                  'รุ่นรถ: ',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  order.vmName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // สีตัวรถ
            Row(
              children: [
                const Text(
                  'สีตัวรถ: ',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  '${order.vColor}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ปีรถยนต์
            Row(
              children: [
                const Text(
                  'ปี: ',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  '${order.vYear}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: AppColors.textDark,
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