import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/service_model.dart';
import 'package:my_app/models/sub_task_status_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderAddSubTaskWidget extends StatefulWidget {
  final int orderId;

  const OrderAddSubTaskWidget({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderAddSubTaskWidget> createState() => _OrderAddSubTaskWidgetState();
}

class _OrderAddSubTaskWidgetState extends State<OrderAddSubTaskWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _laborCostController = TextEditingController();

  List<ServiceModel> _services = [];
  int? _selectedServiceId;

  List<SubTaskStatusModel> _subTaskStatuses = [];
  int? _selectedSubTaskStatusId;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchSubTaskStatuses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _laborCostController.dispose();
    super.dispose();
  }

  // fetch Services
  Future<void> _fetchServices() async {
    final response = await AppAPI.get('/service');
    final res = ServiceResponse.fromJson(jsonDecode(response.body));
    setState(() {
      _services = res.data;
      if (_services.isNotEmpty && _selectedServiceId == null) {
        _selectedServiceId = _services.first.id;
        _nameController.text = _services.first.name;
        _laborCostController.text = _services.first.laborCost.toString();
      }
    });
  }

  // fetch Status SubTask
  Future<void> _fetchSubTaskStatuses() async {
    final response = await AppAPI.get('/sub_task_status');
    final res = SubTaskStatusResponse.fromJson(jsonDecode(response.body));
    setState(() {
      _subTaskStatuses = res.data;
      if (_subTaskStatuses.isNotEmpty && _selectedSubTaskStatusId == null) {
        _selectedSubTaskStatusId = _subTaskStatuses.first.id;
      }
    });
  }

  // save subtask
  Future<void> _saveSubTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการเพิ่มรายการซ่อม'),
        content: Text('ต้องการบันทึกรายการ ${_nameController.text.trim()} หรือไม่?'),
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

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int accId = prefs.getInt('user_id')!;
    final response = await AppAPI.post('/sub_task', {

      'st_order_id': widget.orderId,
      'st_service_id': _selectedServiceId,
      'st_name': _nameController.text.trim(),
      'st_labor_cost': double.parse(_laborCostController.text.trim()),
      'st_sub_task_status_id': _selectedSubTaskStatusId,
      'accId': accId,
    });

    final Map<String, dynamic> resJson = jsonDecode(response.body);
    if (resJson['isError'] == false) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('แจ้งเตือน'),
            content: Text(resJson['data'].toString()),
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
        _errorMessage = resJson['errorMessage'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('เพิ่มรายการซ่อม'),
            Text('Order #${widget.orderId}'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('เลือกบริการ:'),
            const SizedBox(height: 8),
            DropdownButton<int>(
              hint: const Text('เลือกบริการ'),
              value: _selectedServiceId,
              isExpanded: true,
              items: _services.map((item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: (value) {
                final selected = _services.firstWhere((item) => item.id == value);
                setState(() {
                  _selectedServiceId = value;
                  _nameController.text = selected.name;
                  _laborCostController.text = selected.laborCost.toString();
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('เลือกสถานะงานย่อย:'),
            const SizedBox(height: 8),
            DropdownButton<int>(
              hint: const Text('เลือกสถานะงานย่อย'),
              value: _selectedSubTaskStatusId,
              isExpanded: true,
              items: _subTaskStatuses.map((item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubTaskStatusId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('ชื่องานซ่อม:'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(  
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: 'ชื่องานซ่อม',
              ),
            ),
            const SizedBox(height: 16),
            const Text('ค่าแรง:'),
            const SizedBox(height: 8),
            TextField(
              controller: _laborCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: 'ค่าแรง',
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveSubTask,
                child: const Text('บันทึกข้อมูล'),
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
