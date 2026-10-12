import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_main_model.dart';

class OrderDetailCustomerDataWidget extends StatelessWidget {
  final OrderPoolMainModel order;

  const OrderDetailCustomerDataWidget({
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
                  Icons.person,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'ข้อมูลลูกค้า',
                  style: TextStyle(
                    fontSize: AppFontSizes.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),

            // ชื่อลูกค้า
            Row(
              children: [
                const Text(
                  'ชื่อลูกค้า: ',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  '${order.tName}${order.cusFirstName} ${order.cusLastName}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // เบอร์โทรศัพท์
            Row(
              children: [
                const Text(
                  'เบอร์โทร: ',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  order.cusPhone,
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