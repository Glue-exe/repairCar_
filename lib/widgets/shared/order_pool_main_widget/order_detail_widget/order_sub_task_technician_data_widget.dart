import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_model.dart';

// การ์ดแสดงช่างที่รับงานซ่อมย่อยนี้
class OrderSubTaskTechnicianDataWidget extends StatelessWidget {
  final List<OrderTechnicianItemModel> technicians;

  const OrderSubTaskTechnicianDataWidget({
    super.key,
    required this.technicians,
  });

  Widget _buildRow(OrderTechnicianItemModel tech) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.inputBackground,
            child: Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tech.fullName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tech.roleName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.engineering,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ช่างผู้รับผิดชอบ',
                  style: TextStyle(
                    fontSize: AppFontSizes.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${technicians.length} คน',
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),

            if (technicians.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'ยังไม่มีช่างรับงาน',
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < technicians.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _buildRow(technicians[i]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
