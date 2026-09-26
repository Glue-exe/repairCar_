import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/salary_history_model.dart';
import 'package:my_app/utils/app_api.dart';

class SalaryHistoryIncreaseScreen extends StatefulWidget {
  final SalaryHistoryModel salaryHistory;

  const SalaryHistoryIncreaseScreen({
    super.key,
    required this.salaryHistory,
  });

  @override
  State<SalaryHistoryIncreaseScreen> createState() =>
      _SalaryHistoryIncreaseScreenState();
}

class _SalaryHistoryIncreaseScreenState
    extends State<SalaryHistoryIncreaseScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedSalary;
  DateTime _effectiveDate = DateTime.now();

  final List<int> _salaryList = [
    11500,
    12000,
    13000,
    14000,
    15000,
    15500,
    16000,
    16500,
    17000,
    17500,
    18000,
    18500,
    19000,
    19500,
    20000,
    21000,
    22000,
    25000,
    30000,
    35000,
    40000,
    50000,
    68000,
  ];

  @override
  void initState() {
    super.initState();
    int? salary =
        double.tryParse(widget.salaryHistory.empCurrentSalary)?.toInt();
    if (_salaryList.contains(salary)) {
      _selectedSalary = salary;
    }
  }

  // แปลงตัวเลขเป็นรูปแบบมีคอมม่า เช่น 15,000
  String _formatNumber(int number) {
    return NumberFormat('#,##0').format(number);
  }

  // จัดรูปแบบยอดเงิน เช่น 20,000 
  String _formatMoney(String amountStr) {
    final amount = double.tryParse(amountStr);
    if (amount != null) {
      return '${NumberFormat('#,##0').format(amount)} ';
    } else {
      return '$amountStr ';
    }
  }

  // จัดรูปแบบวันที่ เช่น 25/09/2026
  String _formatDate(DateTime dt) {
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    String year = dt.year.toString();
    return '$day/$month/$year';
  }

  // กล่องข้อความแจ้งเตือนยืนยันการบันทึก
  Future<bool> _showConfirmDialog() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มเงินเดือน'),
          content: Text(
            'ต้องการปรับเงินเดือนของ ${widget.salaryHistory.tName}${widget.salaryHistory.empFirstName} ${widget.salaryHistory.empLastName} หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      return true;
    } else {
      return false;
    }
  }

  // ฟังก์ชันบันทึกข้อมูล
  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      bool confirm = await _showConfirmDialog();

      if (confirm == true) {
        Map<String, dynamic> data = {
          'sh_emp_id': widget.salaryHistory.shEmpId,
          'sh_salary_amount': _selectedSalary,
          'sh_effective_date':
              _effectiveDate.toIso8601String().split('T')[0],
        };

        var response = await AppAPI.put('/salary_history', data);
        var responseBody = jsonDecode(response.body);

        if (responseBody['isError'] == false) {
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseBody['errorMessage'])),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ปรับเพิ่มเงินเดือน'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // การ์ดแสดงข้อมูลพนักงาน
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: const Icon(Icons.person),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.salaryHistory.tName}${widget.salaryHistory.empFirstName} ${widget.salaryHistory.empLastName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ตำแหน่ง: ${widget.salaryHistory.arName}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'เงินเดือนปัจจุบัน: ${_formatMoney(widget.salaryHistory.empCurrentSalary)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // เลือกเงินเดือนใหม่
              DropdownButtonFormField<int>(
                initialValue: _selectedSalary,
                validator: (value) {
                  if (value == null) {
                    return 'กรุณาเลือกเงินเดือน';
                  } else {
                    return null;
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'เงินเดือนใหม่ *',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _salaryList.map((int salary) {
                  return DropdownMenuItem<int>(
                    value: salary,
                    child: Text('${_formatNumber(salary)} บาท'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSalary = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // เลือกวันที่มีผล
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() {
                      _effectiveDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'วันที่มีผล',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatDate(_effectiveDate)),
                ),
              ),

              const SizedBox(height: 28),

              // ปุ่มบันทึก
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text(
                    'บันทึกการปรับเงินเดือน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _saveData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}