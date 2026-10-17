import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/models/invoice2_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AccountantReceiptDialog extends StatefulWidget {
  final AccountantOrderItemModel order;

  const AccountantReceiptDialog({super.key, required this.order});

  @override
  State<AccountantReceiptDialog> createState() => _AccountantReceiptDialogState();
}

class _AccountantReceiptDialogState extends State<AccountantReceiptDialog> {
  static final NumberFormat _currency = NumberFormat('#,##0.00');

  Invoice2Model? _invoice;
  bool _loading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _loading = true;
    });

    try {
      final res = await AppAPI.get('/invoice2/${widget.order.orderId}');
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['isError'] == false && j['data'] != null) {
          if (mounted) {
            setState(() {
              _invoice = Invoice2Model.fromJson(j['data'] as Map<String, dynamic>);
              _loading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback หากยังไม่ได้สร้างบิลในระบบ invoice2 ให้ใช้ข้อมูลจาก widget.order
    if (mounted) {
      setState(() {
        _invoice = Invoice2Model(
          id: widget.order.invoiceId ?? widget.order.orderId,
          orderId: widget.order.orderId,
          partsTotal: widget.order.partsTotal,
          laborTotal: widget.order.laborTotal,
          total: widget.order.totalAmount,
          paymentMethodId: widget.order.paymentMethodId,
          paymentMethod: widget.order.paymentMethodName ?? (widget.order.paymentStatusId == 2 ? 'ชำระแล้ว' : 'ยังไม่ระบุ'),
          paymentStatusId: widget.order.paymentStatusId,
          paymentStatus: widget.order.paymentStatusName,
          createdAt: widget.order.paidAt ?? widget.order.createdAt,
          imageUrl: widget.order.invoiceImageUrl,
          customerName: widget.order.customerFullName,
          customerPhone: widget.order.customerPhone,
          licensePlate: widget.order.licensePlate,
          vehicleName: widget.order.carTitle,
          lines: [],
        );
        _loading = false;
      });
    }
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

  String _partLabel(Invoice2LineModel line) {
    final brand = line.brand;
    if (brand != null && brand.trim().isNotEmpty) {
      return '${line.name} ($brand)';
    }
    return line.name;
  }

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

  // ส่งออก / พิมพ์ PDF ตามรูปแบบมาตรฐาน
  Future<void> _printPdf(Invoice2Model invoice) async {
    setState(() {
      _isPrinting = true;
    });

    try {
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
                          'อู่ซ่อมรถยนต์เทคนิคยนต์',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  List<List<String>> _buildPdfTableData(
    Invoice2Model invoice,
    List<int?> subTaskOrder,
  ) {
    final data = <List<String>>[];
    int index = 1;

    if (subTaskOrder.isEmpty && invoice.lines.isNotEmpty) {
      for (final line in invoice.lines) {
        if (line.isLabor) {
          data.add([
            '$index',
            'ค่าแรง: ${line.name}',
            '-',
            '-',
            _currency.format(line.total),
          ]);
          index++;
        } else {
          data.add([
            '',
            '   • ${_partLabel(line)}',
            '${line.quantity}',
            _currency.format(line.unitPrice),
            _currency.format(line.total),
          ]);
        }
      }
      return data;
    }

    if (subTaskOrder.isEmpty && invoice.lines.isEmpty) {
      if (invoice.laborTotal > 0) {
        data.add(['1', 'ค่าแรงงานบริการ', '-', '-', _currency.format(invoice.laborTotal)]);
      }
      if (invoice.partsTotal > 0) {
        data.add(['2', 'ค่าอะไหล่และอุปกรณ์', '-', '-', _currency.format(invoice.partsTotal)]);
      }
      return data;
    }

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
          '   • ${_partLabel(part)}',
          '${part.quantity}',
          _currency.format(part.unitPrice),
          _currency.format(part.total),
        ]);
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(18.0),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ส่วนหัวการ์ดบิล
                    Row(
                      children: [
                        const Text(
                          'บิล',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        if (_invoice != null)
                          IconButton(
                            onPressed: _isPrinting ? null : () => _printPdf(_invoice!),
                            icon: const Icon(Icons.print, color: AppColors.info),
                            tooltip: 'พิมพ์ PDF',
                          ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.grey),
                          tooltip: 'ปิด',
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.8),

                    if (_invoice != null) _buildBillBody(_invoice!),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBillBody(Invoice2Model invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // เลขที่บิล และ สถานะชำระเงิน
        Row(
          children: [
            Expanded(
              child: Text(
                'เลขที่บิล #${invoice.id}',
                style: const TextStyle(
                  fontSize: 18,
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
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const Divider(height: 20, thickness: 0.8),

        // รายการ
        const Text(
          'รายการ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),

        _buildLineTable(invoice),

        const Divider(height: 20, thickness: 0.8),
        _totalRow('ค่าแรงรวม', invoice.laborTotal),
        _totalRow('ค่าอะไหล่รวม', invoice.partsTotal),
        const SizedBox(height: 4),
        _totalRow('ยอดรวมทั้งสิ้น', invoice.total, emphasize: true),

        // ข้อมูลช่องทางชำระเงิน
        if (invoice.paymentMethod != null && invoice.paymentMethod!.isNotEmpty) ...[
          const Divider(height: 20, thickness: 0.8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ช่องทางชำระเงิน:',
                style: TextStyle(fontSize: 13, color: AppColors.textDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  invoice.paymentMethod!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],

        // กล่องข้อมูลลูกค้า & รถยนต์
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ลูกค้า: ${invoice.customerName} (${invoice.customerPhone})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.directions_car_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'รถ: ${invoice.licensePlate} (${invoice.vehicleName})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // แสดงรูปภาพสลิปหลักฐานการโอน (ถ้ามี)
        if (invoice.imageUrl != null && invoice.imageUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
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
                        Icon(Icons.image_outlined, size: 15, color: AppColors.primaryGreen),
                        SizedBox(width: 6),
                        Text(
                          'สลิปหลักฐานการโอนเงิน',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const Text(
                      'แตะเพื่อดูรูปใหญ่',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            AppConfig.getImageUrl(invoice.imageUrl!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      AppConfig.getImageUrl(invoice.imageUrl!),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 50,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Text('ไม่สามารถโหลดภาพสลิปได้', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ปิดหน้าต่าง',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

    final subTaskIds = _subTaskOrder(invoice);

    if (subTaskIds.isEmpty && invoice.lines.isNotEmpty) {
      for (final line in invoice.lines) {
        if (line.isLabor) {
          rows.add(
            TableRow(
              children: [
                _buildCell('$index', align: TextAlign.center, bold: true),
                _buildCell('ค่าแรง: ${line.name}', bold: true),
                _buildCell('-', align: TextAlign.center),
                _buildCell('-', align: TextAlign.right),
                _buildCell(
                  _currency.format(line.total),
                  align: TextAlign.right,
                  bold: true,
                ),
              ],
            ),
          );
          index++;
        } else {
          rows.add(
            TableRow(
              children: [
                _buildCell('', align: TextAlign.center),
                _buildCell('   • ${_partLabel(line)}'),
                _buildCell('${line.quantity}', align: TextAlign.center),
                _buildCell(
                  _currency.format(line.unitPrice),
                  align: TextAlign.right,
                ),
                _buildCell(_currency.format(line.total), align: TextAlign.right),
              ],
            ),
          );
        }
      }
    } else if (subTaskIds.isEmpty && invoice.lines.isEmpty) {
      // กรณีไม่มีบรรทัดย่อย ให้แสดงสรุป 2 แถว
      if (invoice.laborTotal > 0) {
        rows.add(
          TableRow(
            children: [
              _buildCell('1', align: TextAlign.center, bold: true),
              _buildCell('ค่าแรงงานบริการ', bold: true),
              _buildCell('-', align: TextAlign.center),
              _buildCell('-', align: TextAlign.right),
              _buildCell(_currency.format(invoice.laborTotal), align: TextAlign.right, bold: true),
            ],
          ),
        );
      }
      if (invoice.partsTotal > 0) {
        rows.add(
          TableRow(
            children: [
              _buildCell('2', align: TextAlign.center, bold: true),
              _buildCell('ค่าอะไหล่และอุปกรณ์', bold: true),
              _buildCell('-', align: TextAlign.center),
              _buildCell('-', align: TextAlign.right),
              _buildCell(_currency.format(invoice.partsTotal), align: TextAlign.right, bold: true),
            ],
          ),
        );
      }
    } else {
      for (final subTaskId in subTaskIds) {
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
    }

    return Table(
      border: TableBorder.all(color: AppColors.border, width: 0.8),
      columnWidths: const {
        0: FixedColumnWidth(28),
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
          fontSize: 11,
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
          fontSize: 11,
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
                fontSize: emphasize ? 18 : 14,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            '฿${_currency.format(value)}',
            style: TextStyle(
              fontSize: emphasize ? 18 : 14,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              color: emphasize ? AppColors.primaryGreen : AppColors.textDark,
            ),
          ),
        ],
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
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
