import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/widgets/accountant/accountant_payment_dialog.dart';
import 'package:my_app/widgets/accountant/accountant_receipt_dialog.dart';

class AccountantOrderCard extends StatelessWidget {
  final AccountantOrderItemModel order;
  final VoidCallback onPaymentSuccess;

  const AccountantOrderCard({
    super.key,
    required this.order,
    required this.onPaymentSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00');
    final bool isPaid = order.paymentStatusId == 2;

    String formattedDate = '-';
    if (order.createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(order.createdAt).toLocal();
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dt);
      } catch (_) {
        formattedDate = order.createdAt;
      }
    }

    String formattedPaidDate = '';
    if (isPaid && order.paidAt != null && order.paidAt!.isNotEmpty) {
      try {
        final dt = DateTime.parse(order.paidAt!).toLocal();
        formattedPaidDate = DateFormat('dd/MM/yy HH:mm').format(dt);
      } catch (_) {
        formattedPaidDate = order.paidAt!;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPaid ? Colors.green.shade100 : Colors.amber.shade200,
          width: 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัว: ป้ายทะเบียน, ยี่ห้อรุ่น, และสถานะ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // ป้ายทะเบียนรถ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black87, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          order.licensePlate,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ชื่อยี่ห้อ รุ่น และสี
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.carTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'สี${order.color} • งาน #${order.orderId}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ป้ายสถานะการเงิน
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPaid ? Colors.green.shade300 : Colors.amber.shade400,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded,
                        size: 14,
                        color: isPaid ? Colors.green.shade700 : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? 'ชำระแล้ว' : 'รอชำระ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ข้อมูลลูกค้าและอาการซ่อม
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        order.customerFullName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      const Spacer(),
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        order.customerPhone,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (order.symptom.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.symptom,
                            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // แถวสรุปค่าใช้จ่าย: ค่าแรง / ค่าอะไหล่ / รวมสุทธิ
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ค่าแรง: ฿${currencyFormatter.format(order.laborTotal)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      Text(
                        'ค่าอะไหล่: ฿${currencyFormatter.format(order.partsTotal)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ยอดสุทธิ',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      '฿${currencyFormatter.format(order.totalAmount)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green.shade800 : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),

            // แถวล่างสุด: ข้อมูลเพิ่มเติม + ปุ่ม Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isPaid) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          order.paymentMethodName ?? 'โอนเงิน',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (formattedPaidDate.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          formattedPaidDate,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.receipt_outlined, size: 16),
                    label: const Text(
                      'ดูใบเสร็จ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AccountantReceiptDialog(order: order),
                      );
                    },
                  ),
                ] else ...[
                  Text(
                    'รับรถ: $formattedDate',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.payment_rounded, size: 17),
                    label: const Text(
                      'รับชำระเงิน',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AccountantPaymentDialog(
                          order: order,
                          onSuccess: onPaymentSuccess,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
