import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/utils/app_api.dart';

class OrderSubTaskAddPartWidget extends StatefulWidget {
  final int subTaskId;
  final String subTaskName;

  const OrderSubTaskAddPartWidget({
    super.key,
    required this.subTaskId,
    required this.subTaskName,
  });

  @override
  State<OrderSubTaskAddPartWidget> createState() => _OrderSubTaskAddPartWidgetState();
}

class _OrderSubTaskAddPartWidgetState extends State<OrderSubTaskAddPartWidget> {
  final TextEditingController _quantityController = TextEditingController(text: '1');
  List<PartModel> _compatibleParts = [];
  int? _selectedPartId;
  String _selectedPartName = '';
  double _selectedPartPrice = 0.0;
  int? _currentUserId;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _fetchCompatibleParts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> _fetchCompatibleParts() async {
    final response = await AppAPI.get('/compatible_parts?sub_task_id=${widget.subTaskId}');
    final res = PartResponse.fromJson(jsonDecode(response.body));
    setState(() {
      _compatibleParts = res.data;
      if (_compatibleParts.isNotEmpty) {
        _selectedPartId = _compatibleParts.first.id;
        _selectedPartName = _compatibleParts.first.name;
        _selectedPartPrice = _compatibleParts.first.partPrice;
      }
    });
  }

  // ปุ่มยืนยัน
  Future<void> _submitPartRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการเบิกอะไหล่'),
        content: Text('ต้องการขอเบิก $_selectedPartName จำนวน ${_quantityController.text} ชิ้น หรือไม่?'),
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
      ),
    );

    if (confirm != true) return;

    final response = await AppAPI.post('/request_part', {
      'sub_task_id': widget.subTaskId,
      'account_id': _currentUserId,
      'part_id': _selectedPartId,
      'quantity': int.parse(_quantityController.text.trim()),
    });

    final Map<String, dynamic> resJson = jsonDecode(response.body);
    if (resJson['isError'] == false) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('แจ้งเตือน'),
            content: const Text('บันทึกข้อมูลเรียบร้อย'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } else {
      setState(() {
        _errorMessage = resJson['errorMessage'] ?? 'เกิดข้อผิดพลาด';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final qty = double.tryParse(_quantityController.text) ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ขอเบิกอะไหล่'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'งานย่อย: ${widget.subTaskName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(height: 24),
            const Text('เลือกอะไหล่:'),
            const SizedBox(height: 8),
            DropdownButton<int>(
              isExpanded: true,
              value: _selectedPartId,
              hint: const Text('เลือกอะไหล่'),
              items: _compatibleParts.map((p) {
                return DropdownMenuItem<int>(
                  value: p.id,
                  child: Text('${p.name} (${p.brand}) - ${p.partPrice.toStringAsFixed(2)} บาท'),
                );
              }).toList(),
              onChanged: (val) {
                final selected = _compatibleParts.firstWhere((p) => p.id == val);
                setState(() {
                  _selectedPartId = val;
                  _selectedPartName = selected.name;
                  _selectedPartPrice = selected.partPrice;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('จำนวน:'),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            Text('ราคาต่อชิ้น: ${_selectedPartPrice.toStringAsFixed(2)} บาท'),
            const SizedBox(height: 8),
            Text(
              'ยอดรวม: ${(_selectedPartPrice * qty).toStringAsFixed(2)} บาท',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitPartRequest,
                child: const Text('ส่งคำขอเบิก'),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
