import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/app_api.dart';

class OwnerJobpoolScreen extends StatefulWidget {
  const OwnerJobpoolScreen({super.key});

  @override
  State<OwnerJobpoolScreen> createState() => _OwnerJobpoolScreenState();
}

class _OwnerJobpoolScreenState extends State<OwnerJobpoolScreen> {
  List<dynamic> _allJobs = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await AppAPI.get('/orders');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['isError'] == false) {
          setState(() {
            _allJobs = responseData['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการดึงข้อมูล';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการติดต่อสื่อสาร: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusName(int statusId) {
    switch (statusId) {
      case 1:
        return 'รับรถ';
      case 2:
        return 'รออะไหล่';
      case 3:
        return 'กำลังซ่อม';
      case 4:
        return 'ซ่อมสำเร็จ';
      case 5:
        return 'ส่งรถคืน';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Color _getStatusColor(int statusId) {
    switch (statusId) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber.shade800;
      case 4:
        return Colors.green;
      case 5:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityName(int priorityId) {
    switch (priorityId) {
      case 1:
        return 'ด่วน';
      case 2:
        return 'ปานกลาง';
      case 3:
        return 'ระยะยาว';
      default:
        return 'ปกติ';
    }
  }

  Color _getPriorityColor(int priorityId) {
    switch (priorityId) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'งานรวม',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primaryGreen,
            tabs: [
              Tab(text: 'ทั้งหมด'),
              Tab(text: 'ด่วน'),
              Tab(text: 'ปานกลาง'),
              Tab(text: 'ระยะยาว'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _fetchJobs,
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildJobList(_allJobs), // ทั้งหมด
                      _buildJobList(_allJobs.where((job) => job['orders_priority_id'] == 1).toList()), // ด่วน
                      _buildJobList(_allJobs.where((job) => job['orders_priority_id'] == 2).toList()), // ปานกลาง
                      _buildJobList(_allJobs.where((job) => job['orders_priority_id'] == 3).toList()), // ระยะยาว
                    ],
                  ),
      ),
    );
  }

  Widget _buildJobList(List<dynamic> jobs) {
    if (jobs.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีรายการงานซ่อม',
          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final int priorityId = job['orders_priority_id'] ?? 2;
          final int statusId = job['status_id'] ?? 1;

          return Card(
            color: Colors.white,
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: const BorderSide(color: Colors.black12, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${job['brand_name'] ?? ''} ${job['model_name'] ?? 'รถลูกค้า'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(statusId).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusName(statusId),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(statusId),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ทะเบียน: ${job['veh_licenseplate'] ?? ''} | สี: ${job['veh_color'] ?? ''}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const Divider(height: 20),
                  Text(
                    'อาการที่แจ้ง: ${job['order_symptom'] ?? 'ไม่ได้ระบุ'}',
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'เจ้าของ: ${job['cus_firstname'] ?? ''} ${job['cus_lastname'] ?? ''} | โทร: ${job['cus_phone'] ?? ''}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ความสำคัญ: ',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priorityId).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getPriorityName(priorityId),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(priorityId),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'ค่าแรง: ${job['labor_cost'] ?? '0.00'} บาท',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
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
    );
  }
}