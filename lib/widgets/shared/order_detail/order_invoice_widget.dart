import 'package:flutter/material.dart';

class InvoiceData {
  final String invoiceNo;
  final String customerName;
  final String licensePlate;
  final String createdAt;
  final double laborTotal;
  final double partsTotal;
  final double total;
  final String paymentMethod;
  final String paymentStatus;

  const InvoiceData({
    required this.invoiceNo,
    required this.customerName,
    required this.licensePlate,
    required this.createdAt,
    required this.laborTotal,
    required this.partsTotal,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
  });
}

class OrderInvoiceWidget extends StatelessWidget {
  final InvoiceData? invoice;

  const OrderInvoiceWidget({
    super.key,
    this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ใบเสร็จรับเงิน / คิดเงิน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (invoice != null)
                  Text(
                    invoice!.paymentStatus,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            if (invoice == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'ยังไม่ออกใบเสร็จ / ยังไม่มีการคิดเงิน',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เลขที่บิล: #${invoice!.invoiceNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'วันที่: ${invoice!.createdAt}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('ลูกค้า: ${invoice!.customerName}'),
              const SizedBox(height: 4),
              Text('ทะเบียนรถ: ${invoice!.licensePlate}'),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ค่าแรงรวม:'),
                  Text('${invoice!.laborTotal.toStringAsFixed(2)} บาท'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ค่าอะไหล่รวม:'),
                  Text('${invoice!.partsTotal.toStringAsFixed(2)} บาท'),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดรวมทั้งสิ้น:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${invoice!.total.toStringAsFixed(2)} บาท',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('วิธีชำระเงิน: ${invoice!.paymentMethod}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
