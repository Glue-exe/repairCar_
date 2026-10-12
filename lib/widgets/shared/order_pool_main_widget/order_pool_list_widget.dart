import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_main_model.dart';
import 'package:my_app/screens/shared/order_pool_main_screen/order_detail_screen/order_detail_screen2.dart';

class OrderPoolListWidget extends StatelessWidget {
  final List<OrderPoolMainModel> orders;
  final Future<void> Function()? onRefresh;
  final void Function(OrderPoolMainModel order)? onOrderTap;

  const OrderPoolListWidget({
    super.key,
    required this.orders,
    this.onRefresh,
    this.onOrderTap,
  });

  /// ป้ายกำกับระดับความสำคัญ
  Widget _buildPriorityBadge(OrderPoolMainModel order) {
    Color bg;
    Color textColor;

    switch (order.oPriorityId) {
      case 1: // ด่วน
        bg = AppColors.dangerBg;
        textColor = AppColors.dangerText;
        break;
      case 2: // ปานกลาง
        bg = AppColors.warningBg;
        textColor = AppColors.warningText;
        break;
      case 3: // ระยะยาว
      default:
        bg = AppColors.disabledBg;
        textColor = AppColors.textDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        order.pName,
        style: TextStyle(
          fontSize: AppFontSizes.tag,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// ป้ายกำกับสถานะงานซ่อม
  Widget _buildStatusBadge(OrderPoolMainModel order) {
    Color bg;
    Color textColor;

    switch (order.oOrderStatusId) {
      case 1: // รอดำเนินการ
        bg = AppColors.warningBg;
        textColor = AppColors.warningText;
        break;
      case 2: // กำลังซ่อม
        bg = AppColors.infoBg;
        textColor = AppColors.infoText;
        break;
      case 3: // ซ่อมเสร็จสิ้น
      case 4: // ส่งมอบรถคืนเรียบร้อย
        bg = AppColors.successBg;
        textColor = AppColors.successText;
        break;
      case 5: // ยกเลิก
        bg = AppColors.disabledBg;
        textColor = AppColors.disabled;
        break;
      default:
        bg = AppColors.inputBackground;
        textColor = AppColors.textDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        order.osName,
        style: TextStyle(
          fontSize: AppFontSizes.tag,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีรายการงานซ่อม',
          style: TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    final listView = ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (onOrderTap != null) {
                onOrderTap!(order);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                ).then((_) {
                  if (onRefresh != null) {
                    onRefresh!();
                  }
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ส่วนที่ 1: ข้อมูลงานและรถยนต์ (Header & Vehicle)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${order.oId}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.body,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order.vLicensePlate,
                                style: const TextStyle(
                                  fontSize: AppFontSizes.title,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityBadge(order),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ข้อมูลรถยนต์: ยี่ห้อ รุ่น และ สถานะงานซ่อม
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions_car,
                              size: 20,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${order.vbName} ${order.vmName}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.subtitle,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(order),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // สีและปีรถ
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      'สี: ${order.vColor}  •  ปี: ${order.vYear}',
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  const SizedBox(height: 12),

                  // ส่วนที่ 2: อาการที่แจ้งซ่อม (Symptom Section)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.build_circle_outlined,
                              size: 18,
                              color: AppColors.primaryGreen,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'อาการที่แจ้งซ่อม:',
                              style: TextStyle(
                                fontSize: AppFontSizes.body,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            order.oSymptom ?? 'ไม่ระบุอาการ',
                            style: const TextStyle(
                              fontSize: AppFontSizes.body,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  const SizedBox(height: 10),

                  // ส่วนที่ 3: ข้อมูลลูกค้า (Customer Section)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${order.tName}${order.cusFirstName} ${order.cusLastName}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.body,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.cusPhone,
                            style: const TextStyle(
                              fontSize: AppFontSizes.body,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}