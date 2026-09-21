import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/employee_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Emp/emp_list_widget.dart';
import 'package:my_app/screens/owner/profile/emp_add_screen.dart';

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

    if (mounted) {
      setState(() {
        employeeModelStore = employeeResponse.data;
      });
    }
  }

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.lightGreen,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ข้อมูลพนักงาน'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmpAddScreen(onRefresh: _fetchData),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: EmpListWidget(
                  employeeModelStore: employeeModelStore,
                  onRefresh: _fetchData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
