import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/priority_model.dart';
import 'package:my_app/models/order_status_model.dart';
import 'package:my_app/models/order_pool_model.dart';
import 'package:my_app/widgets/shared/orderpool/order_pool_filter_widget.dart';
import 'package:my_app/widgets/shared/orderpool/order_pool_card_widget.dart';

class OrderPoolScreen extends StatefulWidget {
  const OrderPoolScreen({super.key});

  @override
  State<OrderPoolScreen> createState() => _OrderPoolScreenState();
}

class _OrderPoolScreenState extends State<OrderPoolScreen> {
  bool _isLoading = false;

  List<OrderPoolItemModel> _allOrders = [];
  List<PriorityModel> _priorities = [];
  List<OrderStatusModel> _statuses = [];

  // ตัวกรอง
  int _techFilterIndex = 0; // 0 = ทั้งหมด, 1 = ยังไม่มีคนรับ, 2 = มีคนรับแล้ว
  int? _selectedPriorityId; // null = ทั้งหมด
  int? _selectedStatusId; // null = ทั้งหมด
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadInitialData();
  }

  Future<void> _loadCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _fetchPriorities(),
      _fetchStatuses(),
      _fetchOrders(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPriorities() async {
    final response = await AppAPI.get('/priority');
    final Map<String, dynamic> json = jsonDecode(response.body);
    final res = PriorityResponse.fromJson(json);
    setState(() {
      _priorities = res.data;
    });
  }

  Future<void> _fetchStatuses() async {
    final response = await AppAPI.get('/order_status');
    final Map<String, dynamic> json = jsonDecode(response.body);
    final res = OrderStatusResponse.fromJson(json);
    setState(() {
      _statuses = res.data;
    });
  }

  Future<void> _fetchOrders() async {
    final response = await AppAPI.get('/all_orders');
    final Map<String, dynamic> json = jsonDecode(response.body);
    final res = OrderPoolResponse.fromJson(json);
    setState(() {
      _allOrders = res.data;
    });
  }

  // คำนวณการกรอง
  List<OrderPoolItemModel> get _filteredOrders {
    List<OrderPoolItemModel> list = _allOrders;

    // กรองตามสถานะช่างรับงาน
    if (_techFilterIndex == 1) {
      list = list.where((order) => order.technicianCount == 0).toList();
    } else if (_techFilterIndex == 2) {
      list = list.where((order) => order.technicianCount > 0).toList();
    }

    // กรองตามระดับความสำคัญ
    if (_selectedPriorityId != null) {
      list = list.where((order) => order.priorityId == _selectedPriorityId).toList();
    }

    // กรองตามสถานะงาน
    if (_selectedStatusId != null) {
      list = list.where((order) => order.orderStatusId == _selectedStatusId).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'งานรวม',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          OrderPoolFilterHeaderWidget(
            totalCount: filteredList.length,
            techFilterIndex: _techFilterIndex,
            onTechFilterChanged: (index) {
              setState(() {
                _techFilterIndex = index;
              });
            },
            selectedPriorityId: _selectedPriorityId,
            priorities: _priorities,
            onPriorityChanged: (priorityId) {
              setState(() {
                _selectedPriorityId = priorityId;
              });
            },
            selectedStatusId: _selectedStatusId,
            statuses: _statuses,
            onStatusChanged: (statusId) {
              setState(() {
                _selectedStatusId = statusId;
              });
            },
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: _buildBodyContent(filteredList),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(List<OrderPoolItemModel> filteredList) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          'ไม่พบรายการงานตามเงื่อนไขที่เลือก',
          style: TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final order = filteredList[index];
          return OrderPoolCardWidget(
            order: order,
            currentUserId: _currentUserId,
            onActionSuccess: _fetchOrders,
          );
        },
      ),
    );
  }
}
