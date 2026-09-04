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
  final bool isCreated;

  const InvoiceData({
    this.invoiceNo = '',
    this.customerName = '',
    this.licensePlate = '',
    this.createdAt = '',
    this.laborTotal = 0.0,
    this.partsTotal = 0.0,
    this.total = 0.0,
    this.paymentMethod = 'ยังไม่ระบุ',
    this.paymentStatus = 'รอชำระเงิน',
    this.isCreated = false,
  });
}

class RepairHistoryInvoiceWidget extends StatelessWidget {
  final InvoiceData? invoice;

  const RepairHistoryInvoiceWidget({
    super.key,
    this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasInvoice = invoice != null && invoice!.isCreated;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'ใบเสร็จรับเงิน / คิดเงิน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (hasInvoice)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      invoice!.paymentStatus,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            if (!hasInvoice)
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
                      color: Colors.green,
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
                child: Row(
                  children: [
                    const Icon(Icons.payment, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('วิธีชำระเงิน: ${invoice!.paymentMethod}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
