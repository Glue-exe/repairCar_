import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/payroll_model.dart';
import 'package:my_app/utils/app_api.dart';

class SalaryPaymentDialog extends StatefulWidget {
  final TechnicianPayrollItem technician;
  final String targetMonth; // e.g. '2026-10'
  final VoidCallback onSuccess;

  const SalaryPaymentDialog({
    super.key,
    required this.technician,
    required this.targetMonth,
    required this.onSuccess,
  });

  @override
  State<SalaryPaymentDialog> createState() => _SalaryPaymentDialogState();
}

class _SalaryPaymentDialogState extends State<SalaryPaymentDialog> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();
  int _selectedMethodId = 2; // Default โอนเงิน (2)
  XFile? _slipImageFile;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.technician.paidAmount > 0
        ? widget.technician.paidAmount
        : widget.technician.baseSalary;
    _amountController = TextEditingController(
      text: initialAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatThaiMonth(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      const months = [
        '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      return '${months[month]} ${year + 543}';
    } catch (_) {
      return monthStr;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _slipImageFile = picked;
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'เลือกวันที่จ่ายเงินเดือน',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryGreen,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return false;
    if (_selectedMethodId == 2 && _slipImageFile == null) return false;
    return true;
  }

  Future<void> _submitPayment() async {
    if (!_canSubmit) {
      if (_selectedMethodId == 2 && _slipImageFile == null) {
        setState(() {
          _errorMessage = 'กรุณาแนบภาพสลิปหลักฐานการโอนเงิน';
        });
      }
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final Map<String, String> fields = {
        'emp_id': widget.technician.empId.toString(),
        'salary_amount': amount.toString(),
        'effective_date': dateStr,
        'payment_method_id': _selectedMethodId.toString(),
      };

      dynamic response;
      if (_selectedMethodId == 2 && _slipImageFile != null) {
        response = await AppAPI.postMultipart(
          '/payroll/pay',
          fields: fields,
          file: _slipImageFile,
        );
      } else {
        response = await AppAPI.post('/payroll/pay', {
          'emp_id': widget.technician.empId,
          'salary_amount': amount,
          'effective_date': dateStr,
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
                  Text('บันทึกการจ่ายเงินเดือน ${widget.technician.fullName} สำเร็จแล้ว'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
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
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาด: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อ Dialog
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'บันทึกจ่ายเงินเดือน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // การ์ดข้อมูลช่างและงวดเดือน
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.technician.fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'ตำแหน่ง: ${widget.technician.roleName}  ·  เบอร์โทร: ${widget.technician.phone}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ประจำงวดเดือน:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _formatThaiMonth(widget.targetMonth),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ฐานเงินเดือนปัจจุบัน:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        Text(
                          '฿${currencyFormatter.format(widget.technician.baseSalary)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ช่องกรอกยอดเงินสุทธิ
              const Text(
                'ยอดเงินเดือนที่จ่ายสุทธิ (฿)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primaryGreen),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // วันที่จ่ายเงิน
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'วันที่จ่ายเงินเดือน',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ช่องทางชำระเงิน
              const Text(
                'ช่องทางการจ่ายเงิน',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMethodId = 2; // โอนเงิน
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMethodId == 2 ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedMethodId == 2 ? Colors.blue : AppColors.border,
                            width: _selectedMethodId == 2 ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              size: 18,
                              color: _selectedMethodId == 2 ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'โอนเงิน',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedMethodId == 2 ? Colors.blue.shade800 : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMethodId = 1; // เงินสด
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMethodId == 1 ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedMethodId == 1 ? AppColors.primaryGreen : AppColors.border,
                            width: _selectedMethodId == 1 ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 18,
                              color: _selectedMethodId == 1 ? AppColors.primaryGreen : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'เงินสด',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedMethodId == 1 ? AppColors.primaryGreen : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // กล่องแนบสลิป (เฉพาะเมื่อเลือกโอนเงิน)
              if (_selectedMethodId == 2) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'แนบภาพสลิปหลักฐานการโอน',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      '* จำเป็นต้องแนบ',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_slipImageFile == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.grey),
                        const SizedBox(height: 6),
                        const Text(
                          'แนบสลิปการโอนเงินเดือน',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined, size: 15),
                              label: const Text('ถ่ายรูป', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined, size: 15),
                              label: const Text('อัลบั้ม', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_slipImageFile!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, size: 16, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _slipImageFile = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
              ],

              // ข้อความ Error ถ้ามี
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // ปุ่มบันทึกยืนยัน
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit ? AppColors.primaryGreen : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSubmitting ? null : _submitPayment,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'ยืนยันการจ่ายเงินเดือน',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
