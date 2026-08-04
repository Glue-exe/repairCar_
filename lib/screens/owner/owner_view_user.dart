import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/employee_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/emp_list_widget.dart';

class OwnerViewUser extends StatefulWidget {
  const OwnerViewUser({super.key});

  @override
  State<OwnerViewUser> createState() => _OwnerViewUserState();
}

class _OwnerViewUserState extends State<OwnerViewUser> {
  List<EmployeeModel> employeeModelStore = [];

  void _fetchData() async {
    var response = await AppAPI.get("/employee");
    Map<String, dynamic> json = jsonDecode(response.body);
    EmployeeResponse employeeResponse = EmployeeResponse.fromJson(json);

    setState(() {
      employeeModelStore = employeeResponse.data;
    });
  }

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('ข้อมูลพนักงาน'),
        backgroundColor: Colors.teal.shade50,
        centerTitle: true,
      ),
      body: EmpListWidget(
        employeeModelStore: employeeModelStore,
      ),
    );
  }
}
