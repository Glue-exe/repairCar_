import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/invoice_model.dart';
import 'package:my_app/models/payment_method_model.dart';
import 'package:my_app/models/payment_status_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderInvoiceWidget extends StatefulWidget {
  final int orderId;
  final int orderStatusId;

  const OrderInvoiceWidget({
    super.key,
    required this.orderId,
    required this.orderStatusId,
  });

  @override
  State<OrderInvoiceWidget> createState() => _OrderInvoiceWidgetState();
}

class _OrderInvoiceWidgetState extends State<OrderInvoiceWidget> {
  InvoiceModel? _invoice;
  List<PaymentMethodModel> _paymentMethods = [];
  List<PaymentStatusModel> _paymentStatuses = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
    _fetchPaymentConfigs();
  }

  void _fetchPaymentConfigs() async {

    final resMethod = await AppAPI.get('/payment_methods');
    final jsonMethod = jsonDecode(resMethod.body);

    final resStatus = await AppAPI.get('/payment_statuses');
    final jsonStatus = jsonDecode(resStatus.body);

    setState(() {
      _paymentMethods = PaymentMethodResponse.fromJson(jsonMethod).data;
      _paymentStatuses = PaymentStatusResponse.fromJson(jsonStatus).data;
    });
  }

  void _fetchInvoice() async {
    var body = {'order_id': widget.orderId};
    final fetchRes = await AppAPI.post('/getInvoice', body);

    final json = jsonDecode(fetchRes.body);
    if (json['data'] != null) {
      setState(() {
        _invoice = InvoiceModel.fromJson(json['data']);
      });
    }
  }

  void _postCreateInvoice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int accId = prefs.getInt('user_id')!;
    var body = {'order_id': widget.orderId, 'created_by_account_id': accId};

    final createRes = await AppAPI.post('/createInvoice', body);
    final json = jsonDecode(createRes.body);

    if (json['isError'] == false) {
      _fetchInvoice();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(json['errorMessage'])),
      );
    }
  }

  Future<bool> _showConfirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void onPassMethod(int methodId, String methodName) async {
    bool confirm = await _showConfirm(
      'เปลี่ยนวิธีชำระเงิน',
      'ต้องการเปลี่ยนวิธีชำระเงินเป็น "$methodName" หรือไม่?',
    );
    if (!confirm) return;

    var body = {
      'order_id': widget.orderId,
      'payment_method_id': methodId,
    };
    await AppAPI.post('/updateInvoiceMethod', body);
    _fetchInvoice();
  }

  void onPassStatus(int statusId, String statusName) async {
    bool confirm = await _showConfirm(
      'เปลี่ยนสถานะการชำระเงิน',
      'ต้องการเปลี่ยนสถานะเป็น "$statusName" หรือไม่?',
    );
    if (!confirm) return;

    var body = {
      'order_id': widget.orderId,
      'payment_status_id': statusId,
    };
    await AppAPI.post('/updateInvoiceStatus', body);
    _fetchInvoice();
  }

  Future<void> _printPdf() async {
    if (_invoice == null) return;

    final pdf = pw.Document();
    final thaiFont = await PdfGoogleFonts.kanitRegular();
    final thaiBoldFont = await PdfGoogleFonts.kanitBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: thaiFont,
          bold: thaiBoldFont,
        ),
        build: (pw.Context context) {
          // รวมรายการสำหรับแสดงในตาราง
          List<List<String>> tableData = [];
          int index = 1;

          for (var task in _invoice!.subTasks) {
            // แถวงานซ่อม
            tableData.add([
              '$index',
              'งานซ่อม: ${task.name}',
              '-',
              '-',
              task.laborCost.toStringAsFixed(2),
            ]);
            index++;

            // แถวอะไหล่ของงานซ่อมนั้น
            for (var part in task.parts) {
              tableData.add([
                '',
                '  - ${part.name} (${part.brand})',
                '${part.quantity}',
                part.unitPrice.toStringAsFixed(2),
                part.totalPrice.toStringAsFixed(2),
              ]);
            }
          }

          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'ใบเสร็จรับเงิน',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('เลขที่ใบเสร็จ: #${_invoice!.invoiceNo}'),
                    pw.Text('วันที่: ${_invoice!.createdAt}'),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text('ลูกค้า: ${_invoice!.customerName} (${_invoice!.customerPhone})'),
                pw.SizedBox(height: 6),
                pw.Text('รถยนต์: ${_invoice!.licensePlate} ${_invoice!.vehicleName}'),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('วิธีชำระเงิน: ${_invoice!.paymentMethod}'),
                    pw.Text('สถานะการชำระ: ${_invoice!.paymentStatus}'),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),

                pw.Text(
                  'รายการซ่อมและค่าใช้จ่าย:',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),

                pw.TableHelper.fromTextArray(
                  headers: ['ลำดับ', 'รายการ', 'จำนวน', 'ราคา/หน่วย', 'ยอดรวม (บาท)'],
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(40),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FixedColumnWidth(55),
                    3: const pw.FixedColumnWidth(85),
                    4: const pw.FixedColumnWidth(95),
                  },
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),

                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ค่าแรงรวม: ${_invoice!.laborTotal.toStringAsFixed(2)} บาท'),
                      pw.SizedBox(height: 4),
                      pw.Text('ค่าอะไหล่รวม: ${_invoice!.partsTotal.toStringAsFixed(2)} บาท'),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ยอดรวมทั้งสิ้น: ${_invoice!.total.toStringAsFixed(2)} บาท',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ใบเสร็จ_#${_invoice!.invoiceNo}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัว
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ใบเสร็จรับเงิน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (_invoice != null)
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.blue),
                        tooltip: 'พิมพ์ PDF',
                        onPressed: _printPdf,
                      ),
                    TextButton(
                      onPressed: widget.orderStatusId == 3 ? _postCreateInvoice : null,
                      child: const Text('สร้างบิล'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            if (_invoice == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'ยังไม่ออกใบเสร็จ',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              Text('เลขที่บิล: #${_invoice!.invoiceNo}'),
              const SizedBox(height: 4),
              Text('ลูกค้า: ${_invoice!.customerName} (${_invoice!.customerPhone})'),
              const SizedBox(height: 4),
              Text('ทะเบียนรถ: ${_invoice!.licensePlate} ${_invoice!.vehicleName}'),
              const SizedBox(height: 4),
              Text('วันที่: ${_invoice!.createdAt}'),
              const Divider(height: 16),

              // รายการงานซ่อมและอะไหล่
              const Text(
                'รายการงานซ่อมและอะไหล่:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._invoice!.subTasks.map((task) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${task.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${task.laborCost} บาท'),
                        ],
                      ),
                      if (task.parts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                          child: Column(
                            children: task.parts.map((part) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '- ${part.name} (${part.brand}) x${part.quantity}',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                  Text(
                                    '${part.totalPrice} บาท',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              const Divider(height: 16),
              Text('ค่าแรงรวม: ${_invoice!.laborTotal} บาท'),
              const SizedBox(height: 4),
              Text('ค่าอะไหล่รวม: ${_invoice!.partsTotal} บาท'),
              const Divider(height: 16),
              Text(
                'ยอดรวมทั้งสิ้น: ${_invoice!.total} บาท',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('วิธีชำระเงิน: ${_invoice!.paymentMethod}'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _paymentMethods.map((m) {
                  final isSelected = m.name == _invoice!.paymentMethod;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                    ),
                    onPressed: () => onPassMethod(m.id, m.name),
                    child: Text(m.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              Text('สถานะ: ${_invoice!.paymentStatus}'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _paymentStatuses.map((s) {
                  final isSelected = s.name == _invoice!.paymentStatus;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.green : Colors.grey[200],
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                    ),
                    onPressed: () => onPassStatus(s.id, s.name),
                    child: Text(s.name),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

