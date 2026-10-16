import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/utils/app_api.dart';

class AccountantReceiptDialog extends StatefulWidget {
  final AccountantOrderItemModel order;

  const AccountantReceiptDialog({super.key, required this.order});

  @override
  State<AccountantReceiptDialog> createState() => _AccountantReceiptDialogState();
}

class _AccountantReceiptDialogState extends State<AccountantReceiptDialog> {
  bool _isLoadingLines = false;
  List<Map<String, dynamic>> _invoiceLines = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoiceLines();
  }

  Future<void> _fetchInvoiceLines() async {
    setState(() {
      _isLoadingLines = true;
    });

    try {
      final res = await AppAPI.get('/invoice2/${widget.order.orderId}');
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['isError'] == false && j['data'] != null) {
          final rawLines = j['data']['lines'] as List? ?? [];
          if (mounted) {
            setState(() {
              _invoiceLines = rawLines.map((e) => Map<String, dynamic>.from(e as Map)).toList();
              _isLoadingLines = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingLines = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00');
    final order = widget.order;

    String formattedPaidDate = '-';
    if (order.paidAt != null && order.paidAt!.isNotEmpty) {
      try {
        final dt = DateTime.parse(order.paidAt!).toLocal();
        formattedPaidDate = DateFormat('dd/MM/yyyy HH:mm น.').format(dt);
      } catch (_) {
        formattedPaidDate = order.paidAt!;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวกระดาษใบเสร็จ
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.green.shade700,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ใบเสร็จรับเงิน / Receipt',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'อู่ซ่อมรถยนต์เทคนิคยนต์',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1),

              // เลขที่ใบเสร็จและวันที่
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'เลขที่ใบเสร็จ: INV-${(order.invoiceId ?? order.orderId).toString().padLeft(6, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'งานซ่อม #${order.orderId}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('วันเวลาที่ชำระ:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formattedPaidDate,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ข้อมูลลูกค้าและยานพาหนะ
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ลูกค้า:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.customerFullName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('เบอร์โทรศัพท์:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.customerPhone,
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ทะเบียนรถ:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${order.licensePlate} (${order.carTitle})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ตารางค่าบริการและรายการย่อย
              const Text(
                'รายการค่าบริการและอะไหล่',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              _buildLineItemsSection(currencyFormatter),
              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดรวมทั้งสิ้น (Total):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '฿${currencyFormatter.format(order.totalAmount)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // วิธีชำระเงิน
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ช่องทางชำระเงิน:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          order.paymentMethodName ?? 'ชำระแล้ว',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // หลักฐานการชำระเงิน (ถ้ามีสลิป)
              if (order.invoiceImageUrl != null && order.invoiceImageUrl!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.image_outlined, size: 16, color: AppColors.primaryGreen),
                              SizedBox(width: 6),
                              Text(
                                'หลักฐานการโอนเงิน (สลิป)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ],
                          ),
                          Text(
                            'แตะเพื่อดูรูปใหญ่',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  AppConfig.getImageUrl(order.invoiceImageUrl),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            AppConfig.getImageUrl(order.invoiceImageUrl),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 60,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Text('ไม่สามารถโหลดภาพสลิปได้', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ปุ่มปิด
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'ปิดหน้าต่าง',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineItemsSection(NumberFormat currencyFormatter) {
    if (_isLoadingLines) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
          ),
        ),
      );
    }

    if (_invoiceLines.isEmpty) {
      // แสดงสรุป 2 บรรทัด (ค่าแรงรวม และ ค่าอะไหล่รวม)
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. ค่าแรงงานบริการ/ช่าง', style: TextStyle(fontSize: 13)),
              Text('฿${currencyFormatter.format(widget.order.laborTotal)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. ค่าอะไหล่และอุปกรณ์', style: TextStyle(fontSize: 13)),
              Text('฿${currencyFormatter.format(widget.order.partsTotal)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      );
    }

    // แสดงตารางรายการละเอียด (Itemized Lines)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Expanded(flex: 5, child: Text('รายการ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('จำนวน', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('รวม (฿)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ..._invoiceLines.map((line) {
          final isLabor = line['type'] == 'labor';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Icon(
                        isLabor ? Icons.build_outlined : Icons.settings_outlined,
                        size: 13,
                        color: isLabor ? Colors.blue : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          line['name'] ?? '-',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${line['quantity'] ?? 1} ${line['unit'] ?? (isLabor ? 'งาน' : 'ชิ้น')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    currencyFormatter.format((line['total'] ?? 0) as num),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        const Divider(height: 12, color: AppColors.divider),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('รวมค่าแรงบริการ:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text('฿${currencyFormatter.format(widget.order.laborTotal)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('รวมค่าอะไหล่และอุปกรณ์:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text('฿${currencyFormatter.format(widget.order.partsTotal)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
