import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/request_part_model.dart';
import 'package:my_app/utils/app_api.dart';

class PartReceivingDialog extends StatefulWidget {
  final int requestPartId;
  final String subTaskName;
  final List<RequestPartModel> items;
  final VoidCallback onSuccess;

  const PartReceivingDialog({
    super.key,
    required this.requestPartId,
    required this.subTaskName,
    required this.items,
    required this.onSuccess,
  });

  @override
  State<PartReceivingDialog> createState() => _PartReceivingDialogState();
}

class _PartReceivingDialogState extends State<PartReceivingDialog> {
  final Map<int, int> _receivedQuantities = {};
  XFile? _slipImageFile;
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // ค่าเริ่มต้น: ตั้งจำนวนที่ได้รับจริง = จำนวนที่ขอเบิกทุกรายการ
    for (final item in widget.items) {
      _receivedQuantities[item.partId] = item.quantity;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _fillAllComplete() {
    setState(() {
      for (final item in widget.items) {
        _receivedQuantities[item.partId] = item.quantity;
      }
    });
  }

  void _updateQuantity(int partId, int delta, int maxQuantity) {
    final current = _receivedQuantities[partId] ?? maxQuantity;
    final next = current + delta;
    if (next >= 0) {
      setState(() {
        _receivedQuantities[partId] = next;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() {
          _slipImageFile = picked;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเลือกรูปภาพได้: $e';
      });
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'แนบรูปถ่ายใบส่งของ / กล่องพัสดุ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('เลือกจากคลังรูปภาพ'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReceiving() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      // เตรียมข้อมูล items: [{ part_id, received_quantity }]
      final List<Map<String, dynamic>> itemsPayload = widget.items.map((item) {
        return {
          'part_id': item.partId,
          'received_quantity': _receivedQuantities[item.partId] ?? item.quantity,
        };
      }).toList();

      final Map<String, String> fields = {
        'request_part_id': widget.requestPartId.toString(),
        'note': _noteController.text.trim(),
        'items': jsonEncode(itemsPayload),
      };

      dynamic response;
      if (_slipImageFile != null) {
        response = await AppAPI.postMultipart(
          '/request_part/receive',
          fields: fields,
          file: _slipImageFile,
        );
      } else {
        response = await AppAPI.post('/request_part/receive', {
          'request_part_id': widget.requestPartId,
          'note': _noteController.text.trim(),
          'items': itemsPayload,
        });
      }

      final json = jsonDecode(response.body);
      if (json['isError'] == false) {
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('ตรวจรับอะไหล่ใบเบิก #${widget.requestPartId} สำเร็จแล้ว'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage = json['errorMessage'] ?? 'เกิดข้อผิดพลาดในการตรวจรับ';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primaryGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ตรวจรับอะไหล่เข้าอู่',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ใบเบิก #${widget.requestPartId} • ${widget.subTaskName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // แถบ Quick-Fill ปุ่มลัดรับครบทุกรายการ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'รายการอะไหล่ที่ต้องตรวจนับ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _fillAllComplete,
                    icon: const Icon(Icons.done_all, size: 18, color: AppColors.primaryGreen),
                    label: const Text(
                      'รับครบทั้งหมด',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // รายการอะไหล่แต่ละชิ้น
              for (final item in widget.items) ...[
                _buildPartItemRow(item),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 10),
              // ส่วนแนบรูปถ่ายใบส่งของ / กล่อง
              const Text(
                'รูปถ่ายใบส่งของ / กล่องพัสดุ (ถ้ามี)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              _buildImagePickerSection(),

              const SizedBox(height: 16),
              // ส่วนหมายเหตุ
              const Text(
                'หมายเหตุการรับของ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'เช่น กล่องพัสดุสมบูรณ์, อะไหล่ตรงเบอร์รุ่นรถ...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              // ข้อความ Error ถ้ามี
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(fontSize: 13, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              // ปุ่มกดยืนยัน / ยกเลิก
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitReceiving,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        _isSubmitting ? 'กำลังบันทึก...' : 'ยืนยันรับอะไหล่',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartItemRow(RequestPartModel item) {
    final rec = _receivedQuantities[item.partId] ?? item.quantity;
    final isComplete = rec == item.quantity;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isComplete ? AppColors.border : Colors.amber.shade400,
          width: isComplete ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.partName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (item.partBrand.isNotEmpty)
                      Text(
                        'ยี่ห้อ: ${item.partBrand}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isComplete ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isComplete ? Colors.green.shade300 : Colors.amber.shade300,
                  ),
                ),
                child: Text(
                  isComplete
                      ? 'ครบ'
                      : rec > item.quantity
                          ? 'เกิน ${rec - item.quantity} ชิ้น'
                          : 'ขาด ${item.quantity - rec} ชิ้น',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green.shade800 : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ขอเบิก: ${item.quantity} ชิ้น',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (item.receivedQuantity != null && item.receivedQuantity! > 0)
                    Text(
                      'รับรอบก่อนหน้า: ${item.receivedQuantity} ชิ้น',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'ยอดรับรวม: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => _updateQuantity(item.partId, -1, item.quantity),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.remove, size: 18),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '$rec',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _updateQuantity(item.partId, 1, item.quantity),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.add, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    if (_slipImageFile != null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          color: AppColors.inputBackground,
        ),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_slipImageFile!.path),
                  height: 116,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: () => setState(() => _slipImageFile = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _showImageSourceModal,
      icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryGreen, size: 20),
      label: const Text(
        'ถ่ายรูปใบส่งของ / กล่องพัสดุ',
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.primaryGreen, style: BorderStyle.solid),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
