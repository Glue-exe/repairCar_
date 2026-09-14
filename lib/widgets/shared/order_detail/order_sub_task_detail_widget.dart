import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/request_part_model.dart';
import 'package:my_app/models/sub_task_model.dart';
import 'package:my_app/models/sub_task_status_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/shared/order_detail/order_sub_task_add_part_widget.dart';

class OrderSubTaskDetailWidget extends StatefulWidget {
  final SubTaskModel subTask;

  const OrderSubTaskDetailWidget({super.key, required this.subTask});

  @override
  State<OrderSubTaskDetailWidget> createState() =>
      _OrderSubTaskDetailWidgetState();
}

class _OrderSubTaskDetailWidgetState extends State<OrderSubTaskDetailWidget> {
  List<RequestPartModel> _partRequests = [];
  int? _currentStatusId;
  List<SubTaskStatusModel> _statuses = [];

  @override
  void initState() {
    super.initState();
    _currentStatusId = widget.subTask.statusId;
    _fetchSubTaskStatuses();
    _fetchPartRequests();
  }

  Future<void> _fetchSubTaskStatuses() async {
    final response = await AppAPI.get('/sub_task_status');
    final res = SubTaskStatusResponse.fromJson(jsonDecode(response.body));
    setState(() {
      _statuses = res.data;
    });
  }

  Future<void> _updateSubTaskStatus(int newStatusId) async {
    final response = await AppAPI.post('/sub_task/update_status', {
      'sub_task_id': widget.subTask.id,
      'status_id': newStatusId,
    });
    final Map<String, dynamic> resJson = jsonDecode(response.body);
    if (resJson['isError'] == false) {
      setState(() {
        _currentStatusId = newStatusId;
      });
    }
  }

  Future<void> _fetchPartRequests() async {
    final response = await AppAPI.get(
      '/request_parts?sub_task_id=${widget.subTask.id}',
    );
    final res = RequestPartResponse.fromJson(jsonDecode(response.body));
    setState(() {
      _partRequests = res.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subTask.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รายละเอียดงานย่อย
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.subTask.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownButton<int>(
                          value: _currentStatusId,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: _statuses.map((status) {
                            return DropdownMenuItem<int>(
                              value: status.id,
                              child: Text(
                                status.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newStatusId) {
                            if (newStatusId != null &&
                                newStatusId != _currentStatusId) {
                              _updateSubTaskStatus(newStatusId);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Order ID: #${widget.subTask.orderId}'),
                    const SizedBox(height: 8),
                    Text(
                      'ค่าแรง: ${widget.subTask.laborCost.toStringAsFixed(2)} บาท',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ช่างผู้รับผิดชอบ: ${widget.subTask.technicians.isEmpty ? "ยังไม่มีช่างรับงาน" : widget.subTask.technicians.map((t) => t.fullName).join(", ")}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // แถบหัวข้อรายการเบิกอะไหล่ + ปุ่มขอเบิก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายการเบิกอะไหล่',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderSubTaskAddPartWidget(
                          subTaskId: widget.subTask.id,
                          subTaskName: widget.subTask.name,
                        ),
                      ),
                    );

                    if (result == true) {
                      _fetchPartRequests();
                    }
                  },
                  child: const Text('ขอเบิกอะไหล่'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // รายการใบเบิกอะไหล่
            _buildPartRequestsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPartRequestsContent() {
    if (_partRequests.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Text(
              'ยังไม่มีรายการขอเบิกอะไหล่สำหรับงานนี้',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _partRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final req = _partRequests[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ใบขอเบิก #${req.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '[${req.statusName}]',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ผู้ขอเบิก: ${req.requesterName.isNotEmpty ? req.requesterName : '-'}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${req.partName} (${req.partBrand}) x ${req.quantity}',
                      ),
                    ),
                    Text(
                      '${req.totalPrice.toStringAsFixed(2)} บาท',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
