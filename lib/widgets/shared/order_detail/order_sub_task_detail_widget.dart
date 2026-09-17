import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/request_part_model.dart';
import 'package:my_app/models/sub_task_model.dart';
import 'package:my_app/models/sub_task_status_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/shared/order_detail/order_sub_task_add_part_widget.dart';

// pdf
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrderSubTaskDetailWidget extends StatefulWidget {
  final SubTaskModel subTask;

  const OrderSubTaskDetailWidget({super.key, required this.subTask});

  @override
  State<OrderSubTaskDetailWidget> createState() =>
      _OrderSubTaskDetailWidgetState();
}

class _OrderSubTaskDetailWidgetState extends State<OrderSubTaskDetailWidget> {
  List<RequestPartModel> _partRequests = [];
  int? _currentStatusId;
  List<SubTaskStatusModel> _statuses = [];

  @override
  void initState() {
    super.initState();
    _currentStatusId = widget.subTask.statusId;
    _fetchSubTaskStatuses();
    _fetchPartRequests();
  }

  Future<void> _fetchSubTaskStatuses() async {
    final response = await AppAPI.get('/sub_task_status');
    final res = SubTaskStatusResponse.fromJson(jsonDecode(response.body));
    setState(() {
      _statuses = res.data;
    });
  }

  Future<void> _updateSubTaskStatus(int newStatusId) async {
    final response = await AppAPI.post('/sub_task/update_status', {
      'sub_task_id': widget.subTask.id,
      'status_id': newStatusId,
    });
    final Map<String, dynamic> resJson = jsonDecode(response.body);
    if (resJson['isError'] == false) {
      setState(() {
        _currentStatusId = newStatusId;
      });
    }
  }

  Future<void> _fetchPartRequests() async {
    final response = await AppAPI.get(
      '/request_parts?sub_task_id=${widget.subTask.id}',
    );
    final res = RequestPartResponse.fromJson(jsonDecode(response.body));
    setState(() {
      _partRequests = res.data;
    });
  }

    Future<void> _printPdf(RequestPartModel req) async {
    // 1. สร้างเอกสาร PDF
    final pdf = pw.Document();

    // 2. โหลดฟอนต์ภาษาไทย (มีอยู่ในโฟลเดอร์ fonts ของโปรเจกต์แล้ว)
    final fontData = await rootBundle.load('fonts/Kanit-Regular.ttf');
    final thaiFont = pw.Font.ttf(fontData);

    // 3. ออกแบบหน้ากระดาษ
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: thaiFont), // กำหนดฟอนต์ไทยให้ทั้งหน้า
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // หัวกระดาษ
                pw.Center(
                  child: pw.Text(
                    'ใบขอเบิกอะไหล่ (Parts Requisition Slip)',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),

                // ข้อมูลใบเบิก
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('เลขที่ใบเบิก: #${req.id}'),
                    pw.Text('วันที่: ${req.requestedAt}'),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('ชื่องานซ่อม: ${widget.subTask.name} (Order #${widget.subTask.orderId})'),
                pw.SizedBox(height: 8),
                pw.Text('ผู้ขอเบิก: ${req.requesterName}'),
                pw.SizedBox(height: 8),
                pw.Text('สถานะ: ${req.statusName}'),
                pw.SizedBox(height: 16),
                pw.Divider(),

                // ตารางรายการอะไหล่
                pw.Text('รายการอะไหล่ที่ขอเบิก:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['ลำดับ', 'ชื่ออะไหล่', 'ยี่ห้อ', 'จำนวน', 'ราคาต่อหน่วย', 'ราคารวม'],
                  data: [
                    [
                      '1',
                      req.partName,
                      req.partBrand,
                      '${req.quantity}',
                      '${req.partPrice.toStringAsFixed(2)}',
                      '${req.totalPrice.toStringAsFixed(2)}',
                    ]
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.SizedBox(height: 16),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'ยอดรวมสุทธิ: ${req.totalPrice.toStringAsFixed(2)} บาท',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),

                pw.Spacer(),

                // ช่องลงลายมือชื่อด้านล่าง
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ ................................................'),
                        pw.SizedBox(height: 4),
                        pw.Text('( ${req.requesterName} )'),
                        pw.Text('ผู้ขอเบิก'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ ................................................'),
                        pw.SizedBox(height: 4),
                        pw.Text('( ................................................ )'),
                        pw.Text('ผู้อนุมัติ / เจ้าของอู่'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );

    // 4. สั่งแสดงหน้าต่างพรีวิว / พิมพ์ / เซฟเป็น PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ใบเบิกอะไหล่_${req.id}.pdf',
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subTask.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รายละเอียดงานย่อย
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.subTask.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownButton<int>(
                          value: _currentStatusId,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: _statuses.map((status) {
                            return DropdownMenuItem<int>(
                              value: status.id,
                              child: Text(
                                status.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newStatusId) {
                            if (newStatusId != null &&
                                newStatusId != _currentStatusId) {
                              _updateSubTaskStatus(newStatusId);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Order ID: #${widget.subTask.orderId}'),
                    const SizedBox(height: 8),
                    Text(
                      'ค่าแรง: ${widget.subTask.laborCost.toStringAsFixed(2)} บาท',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ช่างผู้รับผิดชอบ: ${widget.subTask.technicians.isEmpty ? "ยังไม่มีช่างรับงาน" : widget.subTask.technicians.map((t) => t.fullName).join(", ")}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // แถบหัวข้อรายการเบิกอะไหล่ + ปุ่มขอเบิก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายการเบิกอะไหล่',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderSubTaskAddPartWidget(
                          subTaskId: widget.subTask.id,
                          subTaskName: widget.subTask.name,
                        ),
                      ),
                    );

                    if (result == true) {
                      _fetchPartRequests();
                    }
                  },
                  child: const Text('ขอเบิกอะไหล่'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // รายการใบเบิกอะไหล่
            _buildPartRequestsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPartRequestsContent() {
    if (_partRequests.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Text(
              'ยังไม่มีรายการขอเบิกอะไหล่สำหรับงานนี้',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _partRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final req = _partRequests[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ใบขอเบิก #${req.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '[${req.statusName}]',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ผู้ขอเบิก: ${req.requesterName.isNotEmpty ? req.requesterName : '-'}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${req.partName} (${req.partBrand}) x ${req.quantity}',
                      ),
                    ),
                    Text(
                      '${req.totalPrice.toStringAsFixed(2)} บาท',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (req.statusId == 2) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _printPdf(req),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('ปริ้น PDF'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
