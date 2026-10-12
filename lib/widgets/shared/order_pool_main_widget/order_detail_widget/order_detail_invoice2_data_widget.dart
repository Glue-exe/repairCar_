import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/invoice2_model.dart';
import 'package:my_app/models/order_pool_main_model.dart';
import 'package:my_app/models/payment_method_model.dart';
import 'package:my_app/models/payment_status_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// การ์ดบิลของ Order — แสดงเส้นเงินทั้งหมด (ค่าแรง + อะไหล่ที่อนุมัติ) ที่คำนวณสดจากงานที่เสร็จสิ้น
// ช่างและเจ้าของใช้เหมือนกัน · ออกบิลได้เมื่อ Order สถานะ "ซ่อมเสร็จสิ้น" (id 3)
class OrderDetailInvoice2DataWidget extends StatefulWidget {
  final OrderPoolMainModel order;

  const OrderDetailInvoice2DataWidget({super.key, required this.order});

  @override
  State<OrderDetailInvoice2DataWidget> createState() =>
      _OrderDetailInvoice2DataWidgetState();
}

class _OrderDetailInvoice2DataWidgetState
    extends State<OrderDetailInvoice2DataWidget> {
  static final NumberFormat _currency = NumberFormat('#,##0.00');

  // ชื่อร้านที่แสดงบนใบเสร็จ (ยังไม่มีตารางร้านใน DB)
  static const String _shopName = 'อู่ซ่อมรถยนต์เทคนิคยนต์';

  // สถานะ Order ที่ออกบิลได้ (ซ่อมเสร็จสิ้น)
  static const int _orderStatusFinished = 3;

  Invoice2Model? _invoice;
  List<PaymentMethodModel> _paymentMethods = [];
  List<PaymentStatusModel> _paymentStatuses = [];

  bool _loading = true;
  bool _busy = false;

  // ผู้ใช้กดรับงานนี้แล้วหรือยัง (ใช้คุมสิทธิ์ออกบิล/แก้ไขบิล)
  bool get _accepted => widget.order.acceptByMe;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
    _loadPaymentConfigs();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await AppAPI.get('/invoice2/${widget.order.oId}');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false) {
        final data = json['data'];
        setState(() {
          _invoice = data == null
              ? null
              : Invoice2Model.fromJson(data as Map<String, dynamic>);
        });
      }
    } catch (_) {
      _showMessage('โหลดข้อมูลบิลไม่สำเร็จ', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPaymentConfigs() async {
    try {
      final methodRes = await AppAPI.get('/payment_methods');
      final statusRes = await AppAPI.get('/payment_statuses');

      if (!mounted) return;

      setState(() {
        _paymentMethods =
            PaymentMethodResponse.fromJson(jsonDecode(methodRes.body)).data;
        _paymentStatuses =
            PaymentStatusResponse.fromJson(jsonDecode(statusRes.body)).data;
      });
    } catch (_) {
      // ตัวเลือกการชำระเงินโหลดไม่ได้ ไม่กระทบการแสดงบิล
    }
  }

  Future<void> _createBill() async {
    // ต้องกดรับงานก่อน
    if (!_accepted) {
      _showMessage('กรุณากดรับงานนี้ก่อน จึงจะออกบิลได้', AppColors.warning);
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final response = await AppAPI.post('/invoice2/create', {
        'order_id': widget.order.oId,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'ออกบิลไม่สำเร็จ', AppColors.danger);
        return;
      }

      _showMessage('ออกบิลเรียบร้อยแล้ว', AppColors.success);
      await _loadInvoice();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // แผงเลือกแหล่งรูป (กล้อง / คลังภาพ) ตามโครงสร้าง WS11
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.info),
                title: const Text('เลือกจากคลังภาพ'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    // ต้องกดรับงานก่อน
    if (!_accepted) {
      _showMessage('กรุณากดรับงานนี้ก่อน จึงจะแนบรูปได้', AppColors.warning);
      return;
    }

    final invoice = _invoice;
    if (invoice == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked == null) return;

      setState(() {
        _busy = true;
      });

      final response = await AppAPI.postMultipart(
        '/invoice2/upload_image',
        fields: {'invoice_id': invoice.id.toString()},
        file: picked,
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'อัปโหลดรูปไม่สำเร็จ', AppColors.danger);
        return;
      }

      _showMessage('แนบรูปเรียบร้อยแล้ว', AppColors.success);
      await _loadInvoice();
    } catch (_) {
      _showMessage('ไม่สามารถแนบรูปได้', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _deleteImage() async {
    // ต้องกดรับงานก่อน
    if (!_accepted) {
      _showMessage('กรุณากดรับงานนี้ก่อน จึงจะลบรูปได้', AppColors.warning);
      return;
    }

    final invoice = _invoice;
    if (invoice == null) return;

    final bool? confirm = await _showConfirm(
      'ลบรูป',
      'ต้องการลบรูปนี้หรือไม่?',
    );
    if (confirm != true) return;

    setState(() {
      _busy = true;
    });

    try {
      final response = await AppAPI.post('/invoice2/delete_image', {
        'invoice_id': invoice.id,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'ลบรูปไม่สำเร็จ', AppColors.danger);
        return;
      }

      await _loadInvoice();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _setPaymentMethod(int methodId, String methodName) async {
    // ต้องกดรับงานก่อน
    if (!_accepted) {
      _showMessage('กรุณากดรับงานนี้ก่อน จึงจะเปลี่ยนวิธีชำระเงินได้', AppColors.warning);
      return;
    }

    final invoice = _invoice;
    if (invoice == null) return;

    final bool? confirm = await _showConfirm(
      'เปลี่ยนวิธีชำระเงิน',
      'ต้องการตั้งวิธีชำระเงินเป็น "$methodName" หรือไม่?',
    );
    if (confirm != true) return;

    await _postInvoiceUpdate('/invoice2/payment_method', {
      'invoice_id': invoice.id,
      'payment_method_id': methodId,
    });
  }

  Future<void> _setPaymentStatus(int statusId, String statusName) async {
    // ต้องกดรับงานก่อน
    if (!_accepted) {
      _showMessage('กรุณากดรับงานนี้ก่อน จึงจะเปลี่ยนสถานะการชำระได้', AppColors.warning);
      return;
    }

    final invoice = _invoice;
    if (invoice == null) return;

    final bool? confirm = await _showConfirm(
      'เปลี่ยนสถานะการชำระเงิน',
      'ต้องการตั้งสถานะเป็น "$statusName" หรือไม่?',
    );
    if (confirm != true) return;

    await _postInvoiceUpdate('/invoice2/payment_status', {
      'invoice_id': invoice.id,
      'payment_status_id': statusId,
    });
  }

  Future<void> _postInvoiceUpdate(String uri, Map<String, dynamic> body) async {
    setState(() {
      _busy = true;
    });

    try {
      final response = await AppAPI.post(uri, body);
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'บันทึกไม่สำเร็จ', AppColors.danger);
        return;
      }

      await _loadInvoice();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _cancelBill() async {
    // ต้องกดรับงานก่อน
    if (!_accepted) {
      _showMessage('กรุณากดรับงานนี้ก่อน จึงจะยกเลิกบิลได้', AppColors.warning);
      return;
    }

    final invoice = _invoice;
    if (invoice == null) return;

    final bool? confirm = await _showConfirm(
      'ยกเลิกบิล',
      'ต้องการยกเลิกบิลนี้หรือไม่? บิลเดิมจะถูกเก็บไว้เป็นประวัติ และออกบิลใหม่ได้',
    );
    if (confirm != true) return;

    setState(() {
      _busy = true;
    });

    try {
      final response = await AppAPI.post('/invoice2/cancel', {
        'invoice_id': invoice.id,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(json['errorMessage'] ?? 'ยกเลิกบิลไม่สำเร็จ', AppColors.danger);
        return;
      }

      _showMessage('ยกเลิกบิลเรียบร้อยแล้ว', AppColors.success);
      await _loadInvoice();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _printPdf() async {
    final invoice = _invoice;
    if (invoice == null) return;

    final pdf = pw.Document();
    final thaiFont = await PdfGoogleFonts.kanitRegular();
    final thaiBoldFont = await PdfGoogleFonts.kanitBold();

    final subTaskOrder = _subTaskOrder(invoice);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: thaiFont, bold: thaiBoldFont),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        _shopName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'ใบเสร็จรับเงิน / RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'เลขที่ใบเสร็จ: INV-${invoice.id.toString().padLeft(6, '0')}',
                    ),
                    pw.Text('วันที่: ${_formatThaiDate(invoice.createdAt)}'),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ลูกค้า: ${invoice.customerName}   โทร: ${invoice.customerPhone}',
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ทะเบียนรถ: ${invoice.licensePlate}   รุ่น: ${invoice.vehicleName}',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'ลำดับ',
                    'รายการ',
                    'จำนวน',
                    'ราคา/หน่วย',
                    'จำนวนเงิน (บาท)',
                  ],
                  data: _buildPdfTableData(invoice, subTaskOrder),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(32),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FixedColumnWidth(40),
                    3: const pw.FixedColumnWidth(75),
                    4: const pw.FixedColumnWidth(90),
                  },
                ),
                pw.SizedBox(height: 14),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 6),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ค่าแรงรวม: ${_currency.format(invoice.laborTotal)} บาท',
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'ค่าอะไหล่รวม: ${_currency.format(invoice.partsTotal)} บาท',
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'ยอดรวมทั้งสิ้น: ${_currency.format(invoice.total)} บาท',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 6),
                pw.Text(
                  'วิธีชำระเงิน: ${invoice.paymentMethod ?? "ยังไม่ระบุ"}',
                ),
                pw.SizedBox(height: 3),
                pw.Text('สถานะการชำระ: ${invoice.paymentStatus}'),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ใบเสร็จ_#${invoice.id}.pdf',
    );
  }

  List<List<String>> _buildPdfTableData(
    Invoice2Model invoice,
    List<int?> subTaskOrder,
  ) {
    final data = <List<String>>[];
    int index = 1;
    for (final subTaskId in subTaskOrder) {
      final laborLines = _laborLinesOf(invoice, subTaskId);
      final partLines = _partLinesOf(invoice, subTaskId);

      final title = laborLines.isNotEmpty ? laborLines.first.name : 'งานซ่อมย่อย';
      final laborTotal = laborLines.fold<double>(0, (sum, l) => sum + l.total);

      data.add([
        '$index',
        'ค่าแรง: $title',
        '-',
        '-',
        _currency.format(laborTotal),
      ]);
      index++;

      for (final part in partLines) {
        data.add([
          '',
          '   - ${_partLabel(part)}',
          '${part.quantity}',
          _currency.format(part.unitPrice),
          _currency.format(part.total),
        ]);
      }
    }
    return data;
  }

  // เรียงลำดับงานซ่อมย่อยตามที่ปรากฏในบรรทัดบิล
  List<int?> _subTaskOrder(Invoice2Model invoice) {
    final seen = <int?>{};
    final order = <int?>[];
    for (final line in invoice.lines) {
      if (!seen.contains(line.subTaskId)) {
        seen.add(line.subTaskId);
        order.add(line.subTaskId);
      }
    }
    return order;
  }

  List<Invoice2LineModel> _laborLinesOf(Invoice2Model invoice, int? subTaskId) {
    return invoice.lines
        .where((line) => line.isLabor && line.subTaskId == subTaskId)
        .toList();
  }

  List<Invoice2LineModel> _partLinesOf(Invoice2Model invoice, int? subTaskId) {
    return invoice.lines
        .where((line) => !line.isLabor && line.subTaskId == subTaskId)
        .toList();
  }

  // ป้ายชื่ออะไหล่ (ชื่อ + แบรนด์) ใช้ทั้งการ์ดบิลและ PDF (จำนวนมีคอลัมน์แยกอยู่แล้ว)
  String _partLabel(Invoice2LineModel line) {
    final brand = line.brand;
    if (brand != null && brand.trim().isNotEmpty) {
      return '${line.name} ($brand)';
    }
    return line.name;
  }

  Future<bool?> _showConfirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  // แปลง timestamp (ISO) เป็นรูปแบบไทย พ.ศ. เช่น 10/10/2569 14:30 น.
  String _formatThaiDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final thaiYear = dt.year + 543;
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$thaiYear $hour:$minute น.';
    } catch (_) {
      return dateStr;
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // แบนเนอร์เตือนตอนยังไม่กดรับงาน
  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ต้องกดรับงานก่อน จึงจะออกบิล/แก้ไขบิลได้',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.warningText,
              ),
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
                const Text(
                  'บิล',
                  style: TextStyle(
                    fontSize: AppFontSizes.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                if (_invoice != null)
                  IconButton(
                    onPressed: _busy ? null : _printPdf,
                    icon: const Icon(Icons.print, color: AppColors.info),
                    tooltip: 'พิมพ์ PDF',
                  ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_invoice == null)
              _buildNoBill()
            else
              _buildBill(_invoice!),

            // ถ้ายังไม่รับงาน ให้แสดงคำเตือน
            if (!_accepted) ...[
              const SizedBox(height: 16),
              _buildWarningBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoBill() {
    if (widget.order.oOrderStatusId != _orderStatusFinished) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(
            'ยังออกบิลไม่ได้ ต้องซ่อมเสร็จสิ้นก่อน',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: (!_accepted || _busy) ? null : _createBill,
        icon: const Icon(Icons.receipt_long),
        label: const Text(
          'สร้างบิล',
          style: TextStyle(
            fontSize: AppFontSizes.button,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBill(Invoice2Model invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'เลขที่บิล #${invoice.id}',
                style: const TextStyle(
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            _statusBadge(invoice.paymentStatusId, invoice.paymentStatus),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'วันที่: ${_formatThaiDate(invoice.createdAt)}',
          style: const TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textMuted,
          ),
        ),
        const Divider(height: 20, thickness: 0.8),

        // รายการเส้นเงิน จัดกลุ่มตามงานซ่อมย่อย
        const Text(
          'รายการ',
          style: TextStyle(
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        if (invoice.lines.isEmpty)
          const Text(
            'ไม่มีรายการ',
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textMuted,
            ),
          )
        else
          _buildLineTable(invoice),

        const Divider(height: 20, thickness: 0.8),
        _totalRow('ค่าแรงรวม', invoice.laborTotal),
        _totalRow('ค่าอะไหล่รวม', invoice.partsTotal),
        const SizedBox(height: 4),
        _totalRow('ยอดรวมทั้งสิ้น', invoice.total, emphasize: true),

        const Divider(height: 20, thickness: 0.8),
        _buildPaymentMethod(invoice),
        const SizedBox(height: 12),
        _buildPaymentStatus(invoice),

        const Divider(height: 20, thickness: 0.8),
        _buildImages(invoice),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: (!_accepted || _busy) ? null : _cancelBill,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text(
              'ยกเลิกบิล',
              style: TextStyle(
                fontSize: AppFontSizes.button,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ตารางรายการในบิล จัดกลุ่มตามงานซ่อมย่อย (ค่าแรงเป็นแถวแม่ อะไหล่เป็นแถวลูก)
  Widget _buildLineTable(Invoice2Model invoice) {
    final rows = <TableRow>[_buildTableHeader()];
    int index = 1;

    for (final subTaskId in _subTaskOrder(invoice)) {
      final laborLines = _laborLinesOf(invoice, subTaskId);
      final partLines = _partLinesOf(invoice, subTaskId);

      final title = laborLines.isNotEmpty ? laborLines.first.name : 'งานซ่อมย่อย';
      final laborTotal = laborLines.fold<double>(0, (sum, l) => sum + l.total);

      rows.add(
        TableRow(
          children: [
            _buildCell('$index', align: TextAlign.center, bold: true),
            _buildCell('ค่าแรง: $title', bold: true),
            _buildCell('-', align: TextAlign.center),
            _buildCell('-', align: TextAlign.right),
            _buildCell(
              _currency.format(laborTotal),
              align: TextAlign.right,
              bold: true,
            ),
          ],
        ),
      );
      index++;

      for (final part in partLines) {
        rows.add(
          TableRow(
            children: [
              _buildCell('', align: TextAlign.center),
              _buildCell('   • ${_partLabel(part)}'),
              _buildCell('${part.quantity}', align: TextAlign.center),
              _buildCell(
                _currency.format(part.unitPrice),
                align: TextAlign.right,
              ),
              _buildCell(_currency.format(part.total), align: TextAlign.right),
            ],
          ),
        );
      }
    }

    return Table(
      border: TableBorder.all(color: AppColors.border, width: 0.8),
      columnWidths: const {
        0: FixedColumnWidth(26),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(34),
        3: FixedColumnWidth(64),
        4: FixedColumnWidth(70),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: AppColors.inputBackground),
      children: [
        _buildHeaderCell('ลำดับ', TextAlign.center),
        _buildHeaderCell('รายการ', TextAlign.left),
        _buildHeaderCell('จำนวน', TextAlign.center),
        _buildHeaderCell('ราคา/หน่วย', TextAlign.right),
        _buildHeaderCell('จำนวนเงิน', TextAlign.right),
      ],
    );
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: AppFontSizes.caption,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildCell(
    String text, {
    TextAlign align = TextAlign.left,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: AppFontSizes.caption,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasize
                    ? AppFontSizes.title
                    : AppFontSizes.subtitle,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            '฿${_currency.format(value)}',
            style: TextStyle(
              fontSize: emphasize ? AppFontSizes.title : AppFontSizes.subtitle,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              color: emphasize ? AppColors.primaryGreen : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(Invoice2Model invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'วิธีชำระเงิน: ${invoice.paymentMethod ?? "ยังไม่ระบุ"}',
          style: const TextStyle(
            fontSize: AppFontSizes.subtitle,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _paymentMethods.map((method) {
            final match = invoice.paymentMethodId == method.id;
            return ElevatedButton(
              onPressed: (!_accepted || _busy)
                  ? null
                  : () => _setPaymentMethod(method.id, method.name),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    match ? AppColors.primaryGreen : AppColors.inputBackground,
                foregroundColor: match ? Colors.white : AppColors.textDark,
                elevation: 0,
              ),
              child: Text(method.name),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentStatus(Invoice2Model invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สถานะการชำระ: ${invoice.paymentStatus}',
          style: const TextStyle(
            fontSize: AppFontSizes.subtitle,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _paymentStatuses.map((status) {
            final match = invoice.paymentStatusId == status.id;
            return ElevatedButton(
              onPressed: (!_accepted || _busy)
                  ? null
                  : () => _setPaymentStatus(status.id, status.name),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    match ? AppColors.success : AppColors.inputBackground,
                foregroundColor: match ? Colors.white : AppColors.textDark,
                elevation: 0,
              ),
              child: Text(status.name),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImages(Invoice2Model invoice) {
    final imageUrl = invoice.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รูปบิล/สลิป',
          style: TextStyle(
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        if (imageUrl == null || imageUrl.trim().isEmpty)
          _buildAddImageTile()
        else
          _buildImageTile(imageUrl),
      ],
    );
  }

  // รูปบิล/สลิป (รูปเดียว) — กดรูปเพื่อเปลี่ยน หรือกากบาทเพื่อลบ
  Widget _buildImageTile(String imageUrl) {
    final fullUrl = AppConfig.getImageUrl(imageUrl);

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: (!_accepted || _busy) ? null : _showImageSourcePicker,
              borderRadius: BorderRadius.circular(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.disabled,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: (!_accepted || _busy) ? null : _deleteImage,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: InkWell(
              onTap: (!_accepted || _busy) ? null : _showImageSourcePicker,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile() {
    return InkWell(
      onTap: (!_accepted || _busy) ? null : _showImageSourcePicker,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted),
            SizedBox(height: 4),
            Text(
              'แนบรูป',
              style: TextStyle(
                fontSize: AppFontSizes.caption,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(int statusId, String statusName) {
    Color bg = AppColors.disabledBg;
    Color fg = AppColors.textDark;

    if (statusId == 1) {
      bg = AppColors.warningBg;
      fg = AppColors.warningText;
    } else if (statusId == 2) {
      bg = AppColors.successBg;
      fg = AppColors.successText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusName,
        style: TextStyle(
          fontSize: AppFontSizes.body,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
