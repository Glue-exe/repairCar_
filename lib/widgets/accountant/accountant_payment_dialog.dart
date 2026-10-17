import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/config/app_config.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/models/invoice2_model.dart';
import 'package:my_app/utils/app_api.dart';

class AccountantPaymentDialog extends StatefulWidget {
  final AccountantOrderItemModel order;
  final VoidCallback onSuccess;

  const AccountantPaymentDialog({
    super.key,
    required this.order,
    required this.onSuccess,
  });

  @override
  State<AccountantPaymentDialog> createState() => _AccountantPaymentDialogState();
}

class _AccountantPaymentDialogState extends State<AccountantPaymentDialog> {
  final ImagePicker _picker = ImagePicker();
  static final NumberFormat _currency = NumberFormat('#,##0.00');

  int _selectedMethodId = 1; // 1 = เงินสด, 2 = โอนเงิน
  bool _isSubmitting = false;
  String _errorMessage = '';

  // รายการเส้นเงินและบิล
  Invoice2Model? _invoice;
  bool _isLoadingInvoice = true;

  // จัดการ QR Code ร้านค้า และสลิปหลักฐานการโอน
  String? _shopQrImage;
  bool _isLoadingQr = false;
  XFile? _slipImageFile;

  List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 1,
      'name': 'เงินสด (Cash)',
      'icon': Icons.payments_rounded,
      'color': Colors.green,
    },
    {
      'id': 2,
      'name': 'โอนเงิน / PromptPay',
      'icon': Icons.account_balance_rounded,
      'color': Colors.blue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInvoice();
    _fetchShopQr();
    _fetchPaymentMethods();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoadingInvoice = true;
    });

    try {
      final res = await AppAPI.get('/invoice2/${widget.order.orderId}');
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['isError'] == false && j['data'] != null) {
          if (mounted) {
            setState(() {
              _invoice = Invoice2Model.fromJson(j['data'] as Map<String, dynamic>);
              _isLoadingInvoice = false;
            });
            return;
          }
        }
      }
    } catch (e, st) {
      debugPrint('Error loading invoice in payment dialog: $e\n$st');
    }

    if (mounted) {
      setState(() {
        _isLoadingInvoice = false;
      });
    }
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final response = await AppAPI.get('/accountant/payment_methods');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['isError'] == false && json['data'] != null) {
          final list = json['data'] as List;
          if (list.isNotEmpty && mounted) {
            setState(() {
              _paymentMethods = list.map((item) {
                final id = item['id'] as int;
                final isTransfer = id == 2;
                return {
                  'id': id,
                  'name': isTransfer ? 'โอนเงิน / PromptPay' : 'เงินสด (Cash)',
                  'icon': isTransfer ? Icons.account_balance_rounded : Icons.payments_rounded,
                  'color': isTransfer ? Colors.blue : Colors.green,
                };
              }).toList();
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchShopQr() async {
    setState(() {
      _isLoadingQr = true;
    });

    try {
      final response = await AppAPI.get('/accountant/shop_qr');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['isError'] == false && json['data'] != null) {
          if (mounted) {
            setState(() {
              _shopQrImage = json['data']['qr_image'];
              _isLoadingQr = false;
            });
            return;
          }
        }
      }
      if (mounted) {
        setState(() {
          _shopQrImage = 'shop_qr_default.png';
          _isLoadingQr = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _shopQrImage = 'shop_qr_default.png';
          _isLoadingQr = false;
        });
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: const [
                    Icon(Icons.receipt_long_rounded, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text(
                      'แนบหลักฐานการโอนเงิน (สลิป)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                ),
                title: const Text('เลือกจากแกลเลอรี (Gallery)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickSlipImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                ),
                title: const Text('ถ่ายภาพใหม่ (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickSlipImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickSlipImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _slipImageFile = pickedFile;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e')),
        );
      }
    }
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_selectedMethodId == 2 && _slipImageFile == null) return false;
    return true;
  }

  Future<void> _submitPayment() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final Map<String, String> fields = {
        'order_id': widget.order.orderId.toString(),
        'payment_method_id': _selectedMethodId.toString(),
      };

      dynamic response;
      if (_selectedMethodId == 2 && _slipImageFile != null) {
        response = await AppAPI.postMultipart(
          '/accountant/pay',
          fields: fields,
          file: _slipImageFile,
        );
      } else {
        response = await AppAPI.post('/accountant/pay', {
          'order_id': widget.order.orderId,
          'payment_method_id': _selectedMethodId,
        });
      }

      final json = jsonDecode(response.body);
      if (json['isError'] == false) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('รับชำระเงินสำหรับ ${widget.order.licensePlate} สำเร็จแล้ว'),
                ],
              ),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = json['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึก';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'การเชื่อมต่อขัดข้อง: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTotal = _invoice?.total ?? widget.order.totalAmount;
    final effectiveLaborTotal = _invoice?.laborTotal ?? widget.order.laborTotal;
    final effectivePartsTotal = _invoice?.partsTotal ?? widget.order.partsTotal;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อ
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'บันทึกการรับชำระเงิน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'งานซ่อม #${widget.order.orderId}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // ข้อมูลรถและลูกค้า
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car, size: 18, color: AppColors.primaryGreen),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.order.licensePlate,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.carTitle,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.order.customerFullName,
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.order.customerPhone,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // รายการค่าบริการและอะไหล่ (Itemized Table)
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primaryGreen),
                  const SizedBox(width: 6),
                  const Text(
                    'รายการ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (_invoice != null && _invoice!.id > 0)
                    Text(
                      'เลขที่บิล #${_invoice!.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoadingInvoice)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.6),
                  ),
                  child: const Column(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'กำลังโหลดรายการงานซ่อมและอะไหล่...',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else if (_invoice != null && _invoice!.lines.isNotEmpty) ...[
                _buildLineTable(_invoice!),
                const SizedBox(height: 10),
                _totalRow('ค่าแรงรวม', _invoice!.laborTotal),
                _totalRow('ค่าอะไหล่รวม', _invoice!.partsTotal),
                const Divider(height: 16, thickness: 0.8),
                _totalRow('ยอดรวมทั้งสิ้น', _invoice!.total, emphasize: true),
              ] else ...[
                _buildFallbackSummaryTable(effectiveLaborTotal, effectivePartsTotal),
                const SizedBox(height: 10),
                _totalRow('ค่าแรงรวม', effectiveLaborTotal),
                _totalRow('ค่าอะไหล่รวม', effectivePartsTotal),
                const Divider(height: 16, thickness: 0.8),
                _totalRow('ยอดรวมทั้งสิ้น', effectiveTotal, emphasize: true),
              ],
              const SizedBox(height: 16),

              // เลือกวิธีชำระเงิน (จัดเรียงเป็นแนวตั้ง)
              const Text(
                'เลือกช่องทางการชำระเงิน:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              Column(
                children: _paymentMethods.map((method) {
                  final bool isSelected = _selectedMethodId == method['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMethodId = method['id'] as int;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? (method['color'] as Color).withValues(alpha: 0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? (method['color'] as Color) : Colors.grey.shade300,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              method['icon'] as IconData,
                              color: method['color'] as Color,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                method['name'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? (method['color'] as Color) : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ========================================================
              // ส่วนที่ 1: แสดง QR Code ร้านค้า (เมื่อเลือกโอนเงิน)
              // ========================================================
              if (_selectedMethodId == 2) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.qr_code_2_rounded, color: Colors.blue, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'สแกน QR Code เพื่อชำระเงิน',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // รูป QR Code ของร้านค้า
                      Container(
                        width: 180,
                        height: 180,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isLoadingQr
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  AppConfig.getImageUrl(_shopQrImage ?? 'shop_qr_default.png'),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text('QR Code ร้านค้า', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ยอดที่ต้องชำระ: ฿${_currency.format(effectiveTotal)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ========================================================
                // ส่วนที่ 2: อัปโหลดภาพหลักฐานการจ่ายเงิน (สลิป)
                // ========================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Flexible(
                            child: Text(
                              'แนบหลักฐานการโอนเงิน (สลิป)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (_slipImageFile != null)
                      TextButton.icon(
                        onPressed: _showImageSourcePicker,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('เปลี่ยนรูป', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // กล่องแสดงตัวอย่างสลิป หรือ กล่องสำหรับแตะเลือกรูป
                if (_slipImageFile == null)
                  InkWell(
                    onTap: _showImageSourcePicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 1.2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, size: 36, color: Colors.red.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'แตะเพื่อถ่ายรูป หรือ เลือกสลิปจากแกลเลอรี',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'จำเป็นต้องแนบภาพสลิปเพื่อปลดล็อกปุ่มยืนยัน',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_slipImageFile!.path),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'แนบสลิปเรียบร้อยแล้ว',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _slipImageFile = null;
                                });
                              },
                              tooltip: 'ลบรูปสลิป',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ปุ่มดำเนินการ
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canSubmit ? AppColors.primaryGreen : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: _canSubmit ? 2 : 0,
                      ),
                      onPressed: _canSubmit ? _submitPayment : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _selectedMethodId == 2 && _slipImageFile == null
                                  ? 'กรุณาแนบภาพสลิปก่อน'
                                  : 'ยืนยันการรับชำระเงิน',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  // --- Helper Methods สำหรับแสดงตารางรายการค่าแรงและอะไหล่ ---

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
    } else {
      for (final subTaskId in subTaskIds) {
        final laborLines = _laborLinesOf(invoice, subTaskId);
        final partLines = _partLinesOf(invoice, subTaskId);

        if (laborLines.isNotEmpty) {
          final title = laborLines.first.name;
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
        }

        for (final part in partLines) {
          rows.add(
            TableRow(
              children: [
                _buildCell(laborLines.isEmpty ? '$index' : '', align: TextAlign.center),
                _buildCell(laborLines.isEmpty ? _partLabel(part) : '   • ${_partLabel(part)}'),
                _buildCell('${part.quantity}', align: TextAlign.center),
                _buildCell(
                  _currency.format(part.unitPrice),
                  align: TextAlign.right,
                ),
                _buildCell(_currency.format(part.total), align: TextAlign.right),
              ],
            ),
          );
          if (laborLines.isEmpty) index++;
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

  Widget _buildFallbackSummaryTable(double laborTotal, double partsTotal) {
    final rows = <TableRow>[_buildTableHeader()];
    int idx = 1;
    if (laborTotal > 0) {
      rows.add(
        TableRow(
          children: [
            _buildCell('$idx', align: TextAlign.center, bold: true),
            _buildCell('ค่าแรงงานบริการ', bold: true),
            _buildCell('-', align: TextAlign.center),
            _buildCell('-', align: TextAlign.right),
            _buildCell(_currency.format(laborTotal), align: TextAlign.right, bold: true),
          ],
        ),
      );
      idx++;
    }
    if (partsTotal > 0) {
      rows.add(
        TableRow(
          children: [
            _buildCell('$idx', align: TextAlign.center, bold: true),
            _buildCell('ค่าอะไหล่และอุปกรณ์', bold: true),
            _buildCell('-', align: TextAlign.center),
            _buildCell('-', align: TextAlign.right),
            _buildCell(_currency.format(partsTotal), align: TextAlign.right, bold: true),
          ],
        ),
      );
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
                fontSize: emphasize ? 16 : 13,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            '฿${_currency.format(value)}',
            style: TextStyle(
              fontSize: emphasize ? 18 : 13,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              color: emphasize ? AppColors.primaryGreen : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
