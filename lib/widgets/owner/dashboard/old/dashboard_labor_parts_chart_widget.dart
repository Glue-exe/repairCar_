import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';

// เทียบรายได้แยกค่าแรง / ค่าอะไหล่ ของบิลที่รับเงินแล้วในช่วงที่เลือก
class DashboardLaborPartsChartWidget extends StatelessWidget {
  final double laborTotal;
  final double partsTotal;

  const DashboardLaborPartsChartWidget({
    super.key,
    required this.laborTotal,
    required this.partsTotal,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0');
    final grandTotal = laborTotal + partsTotal;
    final hasData = grandTotal > 0;

    return Card(
      elevation: 2,
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รายได้แยกค่าแรง / ค่าอะไหล่',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 16),
            if (!hasData)
              const SizedBox(
                height: 160,
                child: Center(child: Text('ยังไม่มีรายได้ในช่วงนี้')),
              )
            else ...[
              SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 48,
                        sections: [
                          PieChartSectionData(
                            value: laborTotal,
                            color: AppColors.info,
                            radius: 36,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: partsTotal,
                            color: AppColors.warning,
                            radius: 36,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'รวม',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          '${currencyFormatter.format(grandTotal)} ฿',
                          style: AppTextStyles.bodyBold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ค่าแรง', style: AppTextStyles.bodyMuted),
                            Text(
                              '${currencyFormatter.format(laborTotal)} ฿',
                              style: AppTextStyles.bodyBold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ค่าอะไหล่', style: AppTextStyles.bodyMuted),
                            Text(
                              '${currencyFormatter.format(partsTotal)} ฿',
                              style: AppTextStyles.bodyBold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
