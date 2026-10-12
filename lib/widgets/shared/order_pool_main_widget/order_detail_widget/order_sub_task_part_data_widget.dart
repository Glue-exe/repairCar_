import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/req_part_status_model.dart';
import 'package:my_app/models/request_part_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// การ์ดแสดงรายการเบิกอะไหล่ของงานซ่อมย่อย (1 ใบเบิก มีได้หลายรายการ)
class OrderSubTaskPartDataWidget extends StatefulWidget {
  final int subTaskId;
  final String subTaskName;
  final bool canRequest;
  final VoidCallback onRequestPart;

  const OrderSubTaskPartDataWidget({
    super.key,
    required this.subTaskId,
    required this.subTaskName,
    required this.canRequest,
    required this.onRequestPart,
  });

  @override
  State<OrderSubTaskPartDataWidget> createState() =>
      _OrderSubTaskPartDataWidgetState();
}

class _OrderSubTaskPartDataWidgetState
    extends State<OrderSubTaskPartDataWidget> {
  final NumberFormat _currency = NumberFormat('#,##0.00');

  List<RequestPartModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await AppAPI.get(
        '/request_parts?sub_task_id=${widget.subTaskId}',
      );
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false && json['data'] != null) {
        setState(() {
          _requests = (json['data'] as List)
              .map((e) => RequestPartModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {
      _showMessage('โหลดรายการเบิกไม่สำเร็จ', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // รวมแถวที่เป็นใบเบิกเดียวกัน (group by rp_id)
  List<_PartGroup> get _groups {
    final map = <int, _PartGroup>{};
    for (final request in _requests) {
      final group = map.putIfAbsent(
        request.id,
        () => _PartGroup(
          id: request.id,
          statusId: request.statusId,
          statusName: request.statusName,
          requesterName: request.requesterName,
          requestedAt: request.requestedAt,
        ),
      );
      group.items.add(request);
    }
    return map.values.toList();
  }

  String _formatThaiDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final thaiYear = dt.year + 543;
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month/$thaiYear';
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

  // พิมพ์ใบเบิกเป็น PDF (เปิดได้เฉพาะใบที่อนุมัติแล้ว)
  Future<void> _printPdf(_PartGroup group) async {
    final pdf = pw.Document();
    final thaiFont = await PdfGoogleFonts.kanitRegular();
    final thaiBold = await PdfGoogleFonts.kanitBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: thaiFont, bold: thaiBold),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'ใบขอเบิกอะไหล่ (Parts Requisition Slip)',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('เลขที่ใบเบิก: #${group.id}'),
                    pw.Text('วันที่: ${_formatThaiDate(group.requestedAt)}'),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('งานซ่อมย่อย: ${widget.subTaskName}'),
                pw.SizedBox(height: 8),
                pw.Text('ผู้ขอเบิก: ${group.requesterName}'),
                pw.SizedBox(height: 8),
                pw.Text('สถานะ: ${group.statusName}'),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'รายการอะไหล่ที่ขอเบิก',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'ลำดับ',
                    'ชื่ออะไหล่',
                    'ยี่ห้อ',
                    'จำนวน',
                    'ราคา/หน่วย',
                    'ราคารวม',
                  ],
                  data: [
                    for (int i = 0; i < group.items.length; i++)
                      [
                        '${i + 1}',
                        group.items[i].partName,
                        group.items[i].partBrand,
                        '${group.items[i].quantity}',
                        group.items[i].partPrice.toStringAsFixed(2),
                        group.items[i].totalPrice.toStringAsFixed(2),
                      ],
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.SizedBox(height: 16),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'ยอดรวมสุทธิ: ${group.total.toStringAsFixed(2)} บาท',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
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
      name: 'ใบเบิกอะไหล่_${group.id}.pdf',
    );
  }

  Widget _statusBadge(String statusName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        statusName,
        style: const TextStyle(
          fontSize: AppFontSizes.body,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildGroup(_PartGroup group) {
    // อนุมัติแล้ว → พิมพ์ใบเบิกได้
    final canPrint = group.statusId == ReqPartStatusId.approved;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ใบเบิก #${group.id}',
                style: const TextStyle(
                  fontSize: AppFontSizes.subtitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(group.statusName),
              const Spacer(),
              if (canPrint)
                IconButton(
                  onPressed: () => _printPdf(group),
                  icon: const Icon(Icons.print_outlined),
                  color: AppColors.primaryGreen,
                  tooltip: 'พิมพ์ PDF',
                ),
            ],
          ),
          Text(
            'ผู้ขอเบิก: ${group.requesterName} · ${_formatThaiDate(group.requestedAt)}',
            style: const TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textMuted,
            ),
          ),
          const Divider(height: 18),

          for (final item in group.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '• ${item.partName} (${item.partBrand}) x${item.quantity}',
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '฿${_currency.format(item.totalPrice)}',
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'รวม ฿${_currency.format(group.total)}',
              style: const TextStyle(
                fontSize: AppFontSizes.subtitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final groups = _groups;
    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(
            'ยังไม่มีรายการเบิกอะไหล่',
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Column(children: [for (final group in groups) _buildGroup(group)]);
  }

  @override
  Widget build(BuildContext context) {
    final count = _groups.length;

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
                const Icon(
                  Icons.receipt_long,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'รายการเบิกอะไหล่',
                  style: TextStyle(
                    fontSize: AppFontSizes.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '$count ใบเบิก',
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textMuted,
                  ),
                ),
                if (widget.canRequest)
                  IconButton(
                    onPressed: _loading ? null : widget.onRequestPart,
                    icon: const Icon(Icons.add),
                    color: AppColors.primaryGreen,
                    tooltip: 'ขอเบิกอะไหล่',
                  ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),
            _buildBody(),
          ],
        ),
      ),
    );
  }
}

// ใบเบิก 1 ใบ (รวมรายการอะไหล่ที่อยู่ใต้ rp_id เดียวกัน)
class _PartGroup {
  final int id;
  final int statusId;
  final String statusName;
  final String requesterName;
  final String requestedAt;
  final List<RequestPartModel> items = [];

  _PartGroup({
    required this.id,
    required this.statusId,
    required this.statusName,
    required this.requesterName,
    required this.requestedAt,
  });

  double get total => items.fold(0, (sum, item) => sum + item.totalPrice);
}
