import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/req_part_status_model.dart';
import 'package:my_app/models/request_part_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/technician/part/part_receiving_dialog.dart';
import 'package:my_app/widgets/technician/part/part_delivery_proof_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// แสดงรายการเบิกอะไหล่ของงานซ่อมย่อย 
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
  bool _saving = false;

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

  // รวมแถวที่เป็นใบเบิกเดียวกัน
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
          canCancel: request.canCancel,
          cancelledAt: request.cancelledAt,
          cancelledByName: request.cancelledByName,
          receivedAt: request.receivedAt,
          receivedByName: request.receivedByName,
          receiveSlipImage: request.receiveSlipImage,
          receiveNote: request.receiveNote,
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

  String _cancelledText(_PartGroup group) {
    final date = _formatThaiDate(group.cancelledAt ?? '');
    final text = 'ยกเลิกโดย ${group.cancelledByName ?? '-'}';
    if (date.isEmpty) return text;
    return '$text · $date';
  }

  void _openReceivingDialog(_PartGroup group) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PartReceivingDialog(
        requestPartId: group.id,
        subTaskName: widget.subTaskName,
        items: group.items,
        onSuccess: _loadRequests,
      ),
    );
  }

  void _openProofDialog(_PartGroup group) {
    showDialog(
      context: context,
      builder: (ctx) => PartDeliveryProofDialog(
        requestPartId: group.id,
        subTaskName: widget.subTaskName,
        receivedByName: group.receivedByName,
        receivedAt: group.receivedAt,
        receiveSlipImage: group.receiveSlipImage,
        receiveNote: group.receiveNote,
        items: group.items,
      ),
    );
  }

  // ยกเลิกใบเบิกของตัวเอง
  Future<void> _cancelRequest(_PartGroup group) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการยกเลิกใบเบิก'),
          content: Text(
            'ต้องการยกเลิกใบเบิก #${group.id} หรือไม่?\nใบเดิมจะถูกเก็บเป็นประวัติ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ไม่ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันการยกเลิก'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _saving = true;
    });

    try {
      final response = await AppAPI.post('/request_part/cancel', {
        'request_part_id': group.id,
      });
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        _showMessage(
          json['errorMessage'] ?? 'ยกเลิกใบเบิกไม่สำเร็จ',
          AppColors.danger,
        );
        return;
      }

      _showMessage('ยกเลิกใบเบิกเรียบร้อยแล้ว', AppColors.success);
      _loadRequests();
    } catch (_) {
      _showMessage('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // พิมพ์ใบเบิกเป็น PDF
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

  Widget _statusBadge(int statusId, String statusName) {
    Color bg;
    Color border;
    Color text;
    String label = statusName;

    switch (statusId) {
      case ReqPartStatusId.pending:
        bg = Colors.amber.shade50;
        border = Colors.amber.shade300;
        text = Colors.amber.shade900;
        break;
      case ReqPartStatusId.approved:
        bg = Colors.blue.shade50;
        border = Colors.blue.shade300;
        text = Colors.blue.shade900;
        label = 'อนุมัติแล้ว (รออะไหล่ส่ง)';
        break;
      case ReqPartStatusId.received:
        bg = Colors.green.shade50;
        border = Colors.green.shade400;
        text = Colors.green.shade800;
        label = '✓ ได้รับอะไหล่แล้ว';
        break;
      case ReqPartStatusId.partiallyReceived:
        bg = Colors.amber.shade50;
        border = Colors.amber.shade400;
        text = Colors.amber.shade900;
        label = '⚠️ ได้รับบางส่วน';
        break;
      case ReqPartStatusId.rejected:
        bg = Colors.red.shade50;
        border = Colors.red.shade300;
        text = AppColors.danger;
        break;
      case ReqPartStatusId.cancelled:
      default:
        bg = Colors.grey.shade100;
        border = Colors.grey.shade300;
        text = AppColors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSizes.body,
          fontWeight: FontWeight.bold,
          color: text,
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
              _statusBadge(group.statusId, group.statusName),
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
          if (group.statusId == ReqPartStatusId.received)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'ตรวจรับโดย: ${group.receivedByName ?? 'ช่าง'} · ${_formatThaiDate(group.receivedAt ?? '')}',
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          if (group.statusId == ReqPartStatusId.partiallyReceived)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '⚠️ ได้รับบางส่วน · ตรวจรับโดย: ${group.receivedByName ?? 'ช่าง'} · ${_formatThaiDate(group.receivedAt ?? '')}',
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          if (group.statusId == ReqPartStatusId.cancelled)
            Text(
              _cancelledText(group),
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.danger,
              ),
            ),
          const Divider(height: 18),

          for (final item in group.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${item.partName} (${item.partBrand}) x${item.quantity}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.body,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (item.receivedQuantity != null &&
                            item.receivedQuantity! > 0 &&
                            (group.statusId == ReqPartStatusId.partiallyReceived ||
                             group.statusId == ReqPartStatusId.received))
                          Padding(
                            padding: const EdgeInsets.only(left: 10, top: 2),
                            child: Text(
                              item.receivedQuantity! < item.quantity
                                  ? '└ รับแล้ว ${item.receivedQuantity}/${item.quantity} (ยังขาด ${item.quantity - item.receivedQuantity!} ชิ้น)'
                                  : '└ รับครบแล้ว ${item.quantity} ชิ้น',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.receivedQuantity! < item.quantity
                                    ? Colors.amber.shade900
                                    : Colors.green.shade800,
                              ),
                            ),
                          ),
                      ],
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
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (group.canCancel)
                OutlinedButton(
                  onPressed: _saving ? null : () => _cancelRequest(group),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'ยกเลิกใบเบิก',
                    style: TextStyle(
                      fontSize: AppFontSizes.button,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (group.statusId == ReqPartStatusId.approved)
                ElevatedButton.icon(
                  onPressed: () => _openReceivingDialog(group),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.white),
                  label: const Text(
                    'ตรวจรับอะไหล่',
                    style: TextStyle(
                      fontSize: AppFontSizes.button,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (group.statusId == ReqPartStatusId.received)
                OutlinedButton.icon(
                  onPressed: () => _openProofDialog(group),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primaryGreen),
                  label: const Text(
                    'ดูหลักฐานการรับ',
                    style: TextStyle(
                      fontSize: AppFontSizes.button,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (group.statusId == ReqPartStatusId.partiallyReceived) ...[
                OutlinedButton.icon(
                  onPressed: () => _openProofDialog(group),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18, color: Colors.orange),
                  label: const Text(
                    'ดูหลักฐาน',
                    style: TextStyle(
                      fontSize: AppFontSizes.button,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade900,
                    side: BorderSide(color: Colors.orange.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openReceivingDialog(group),
                  icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                  label: const Text(
                    'ตรวจรับอะไหล่เพิ่ม',
                    style: TextStyle(
                      fontSize: AppFontSizes.button,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
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

// ใบเบิก 1 ใบ
class _PartGroup {
  final int id;
  final int statusId;
  final String statusName;
  final String requesterName;
  final String requestedAt;
  final bool canCancel;
  final String? cancelledAt;
  final String? cancelledByName;
  final String? receivedAt;
  final String? receivedByName;
  final String? receiveSlipImage;
  final String? receiveNote;
  final List<RequestPartModel> items = [];

  _PartGroup({
    required this.id,
    required this.statusId,
    required this.statusName,
    required this.requesterName,
    required this.requestedAt,
    required this.canCancel,
    this.cancelledAt,
    this.cancelledByName,
    this.receivedAt,
    this.receivedByName,
    this.receiveSlipImage,
    this.receiveNote,
  });

  double get total => items.fold(0, (sum, item) => sum + item.totalPrice);
}
