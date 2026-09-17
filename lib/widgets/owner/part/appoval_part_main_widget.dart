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
  List<AppovalPartModel> approvalPartStore = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    try {
      var response = await AppAPI.get("/approval_part");
      var json = jsonDecode(response.body);
      AppovalPartResponse res = AppovalPartResponse.fromJson(json);

      setState(() {
        approvalPartStore = res.data;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (approvalPartStore.isEmpty) {
      return const Center(child: Text("ไม่มีรายการอะไหล่ที่รออนุมัติ"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: approvalPartStore.length,
      itemBuilder: (context, index) {
        final item = approvalPartStore[index];

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
                  builder: (context) => AppovalPartDetailWidget(item: item),
                ),
              );
              _fetchData();
            },
          ),
        );
      },
    );
  }
}
