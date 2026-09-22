import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/appoval_part_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/part/appoval_part_detail_widget.dart';

class AppovalPartMainWidget extends StatefulWidget {
  const AppovalPartMainWidget({super.key});

  @override
  State<AppovalPartMainWidget> createState() => _AppovalPartMainWidgetState();
}

class _AppovalPartMainWidgetState extends State<AppovalPartMainWidget> {
  int _selectedStatus = 1; // 1 = รออนุมัติ, 2 = อนุมัติแล้ว, 3 = ไม่อนุมัติ

  List<AppovalPartModel> _pendingList = [];
  List<AppovalPartModel> _approvedList = [];
  List<AppovalPartModel> _disapprovedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    try {
      var resPending = await AppAPI.get("/approval_part_status_one");
      var jsonPending = jsonDecode(resPending.body);
      AppovalPartResponse pendingResponse = AppovalPartResponse.fromJson(jsonPending);

      var resApproved = await AppAPI.get("/approval_part_status_two");
      var jsonApproved = jsonDecode(resApproved.body);
      AppovalPartResponse approvedResponse = AppovalPartResponse.fromJson(jsonApproved);

      var resDisapproved = await AppAPI.get("/approval_part_status_three");
      var jsonDisapproved = jsonDecode(resDisapproved.body);
      AppovalPartResponse disapprovedResponse = AppovalPartResponse.fromJson(jsonDisapproved);

      if (mounted) {
        setState(() {
          _pendingList = pendingResponse.data;
          _approvedList = approvedResponse.data;
          _disapprovedList = disapprovedResponse.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<AppovalPartModel> get _currentList {
    if (_selectedStatus == 1) return _pendingList;
    if (_selectedStatus == 2) return _approvedList;
    return _disapprovedList;
  }

  String get _emptyMessage {
    if (_selectedStatus == 1) return "ไม่มีรายการอะไหล่ที่รออนุมัติ";
    if (_selectedStatus == 2) return "ไม่มีรายการอะไหล่ที่อนุมัติแล้ว";
    return "ไม่มีรายการอะไหล่ที่ไม่อนุมัติ";
  }

  Widget _buildButton(int status, String label, int count) {
    bool isSelected = _selectedStatus == status;

    return Expanded(
      child: isSelected
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: () {},
              child: Text(
                '$label ($count)',
                style: const TextStyle(fontSize: 13),
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: () {
                setState(() {
                  _selectedStatus = status;
                });
              },
              child: Text(
                '$label ($count)',
                style: const TextStyle(fontSize: 13),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentItems = _currentList;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              _buildButton(1, 'รออนุมัติ', _pendingList.length),
              const SizedBox(width: 8),
              _buildButton(2, 'อนุมัติแล้ว', _approvedList.length),
              const SizedBox(width: 8),
              _buildButton(3, 'ไม่อนุมัติ', _disapprovedList.length),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _fetchData(),
            child: currentItems.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Text(_emptyMessage),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: currentItems.length,
                    itemBuilder: (context, index) {
                      final item = currentItems[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.build),
                          title: Text('${item.partName} x ${item.quantity}'),
                          subtitle: Text(
                            'ทะเบียน: ${item.licensePlate}\nงาน: ${item.subTaskName}\nผู้ขอ: ${item.empFirstName} ${item.empLastName}',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AppovalPartDetailWidget(item: item),
                              ),
                            );
                            _fetchData();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
