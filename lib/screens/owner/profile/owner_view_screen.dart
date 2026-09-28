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
  // ตัวแปรเก็บรายชื่อพนักงานและสถานะการทำงาน
  List<EmployeeModel> _employeeList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // ดึงข้อมูลพนักงานจาก API
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await AppAPI.get("/get_employee");
      final Map<String, dynamic> json = jsonDecode(response.body);
      final EmployeeResponse employeeResponse = EmployeeResponse.fromJson(json);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!employeeResponse.isError) {
            _employeeList = employeeResponse.data;
          } else {
            _errorMessage = employeeResponse.errorMessage.isNotEmpty
                ? employeeResponse.errorMessage
                : 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
          debugPrint(e.toString());
        });
      }
    }
  }

  // เปิดหน้าเพิ่มพนักงานใหม่
  void _navigateToAddEmployee() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmpAddScreen(onRefresh: _fetchData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลพนักงาน'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: _fetchData,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      // ปุ่มเพิ่มพนักงานที่มุมขวาล่าง
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddEmployee,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มพนักงาน'),
      ),
    );
  }

  // ส่วนแสดงผลเนื้อหาตามสถานะ (กำลังโหลด, เกิดข้อผิดพลาด, แสดงรายการ)
  Widget _buildBody() {
    // 1. สถานะกำลังโหลด
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. สถานะเกิดข้อผิดพลาด
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. แสดงรายการพนักงาน พร้อมรองรับ Pull-to-refresh
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: EmpListWidget(
        employeeModelStore: _employeeList,
        onRefresh: _fetchData,
      ),
    );
  }
}
