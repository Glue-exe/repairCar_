import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/models/sub_task_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/shared/order_detail/order_add_sub_task_widget.dart';
import 'package:my_app/widgets/shared/order_detail/order_sub_task_detail_widget.dart';

class OrderSubTaskWidget extends StatefulWidget {
  final int orderId;
  final bool isOrderAccepted;

  const OrderSubTaskWidget({
    super.key,
    required this.orderId,
    this.isOrderAccepted = false,
  });

  @override
  State<OrderSubTaskWidget> createState() => _OrderSubTaskWidgetState();
}

class _OrderSubTaskWidgetState extends State<OrderSubTaskWidget> {
  List<SubTaskModel> _subTasks = [];
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _fetchSubTasks();
  }

  Future<void> _loadCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id') ?? 0;
    });
  }

  Future<void> _fetchSubTasks() async {
    final response = await AppAPI.get('/sub_tasks?order_id=${widget.orderId}');
    final res = SubTaskResponse.fromJson(jsonDecode(response.body));
    setState(() {
      _subTasks = res.data;
    });
  }

  Future<void> _acceptSubTask(int subTaskId) async {
    final response = await AppAPI.post('/sub_task/accept', {
      'sub_task_id': subTaskId,
      'order_id': widget.orderId,
    });
    final res = jsonDecode(response.body);
    if (res['isError'] == false) {
      _fetchSubTasks();
    }
  }

  Future<void> _cancelSubTask(int subTaskId) async {
    final response = await AppAPI.post('/sub_task/cancel', {
      'sub_task_id': subTaskId,
      'order_id': widget.orderId,
    });
    final res = jsonDecode(response.body);
    if (res['isError'] == false) {
      _fetchSubTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายการงานซ่อม',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_subTasks.length} รายการ',
                  style: const TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderAddSubTaskWidget(orderId: widget.orderId),
                      ),
                    );
                    if (result == true) {
                      _fetchSubTasks();
                    }
                  },
                  child: const Text('เพิ่มรายการซ่อม'),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_subTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'ยังไม่มีรายการงานซ่อม',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subTasks.length,
                itemBuilder: (context, index) {
                  final item = _subTasks[index];
                  final isAcceptedByMe = _currentUserId != 0 &&
                      item.technicians.any((tech) => tech.accountId == _currentUserId);
                  final hasTechnicians = item.technicians.isNotEmpty;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: InkWell(
                      onTap: isAcceptedByMe
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OrderSubTaskDetailWidget(subTask: item),
                                ),
                              ).then((_) => _fetchSubTasks());
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                item.statusName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (hasTechnicians)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'ช่าง: ${item.technicians.map((t) => t.firstname).join(", ")}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isAcceptedByMe)
                                const Row(
                                  children: [
                                    SizedBox(width: 4),
                                    Text(
                                      'แตะเพื่อดูรายละเอียดงาน',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox(),
                              if (isAcceptedByMe)
                                OutlinedButton(
                                  onPressed: () => _cancelSubTask(item.id),
                                  child: const Text('ยกเลิก'),
                                )
                              else
                                widget.isOrderAccepted
                                    ? ElevatedButton(
                                        onPressed: () => _acceptSubTask(item.id),
                                        child: const Text('กดรับงาน'),
                                      )
                                    : const Text(
                                        'โปรดกดรับงานซ่อมนี้ก่อน',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
