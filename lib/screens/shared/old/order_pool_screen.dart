import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/priority_model.dart';
import 'package:my_app/models/order_status_model.dart';
import 'package:my_app/models/order_pool_model.dart';
import 'package:my_app/widgets/shared/old/order_pool_filter_widget.dart';
import 'package:my_app/widgets/shared/old/order_pool_card_widget.dart';

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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('user_id');

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
    String url = '/all_orders?user_id=$_currentUserId';
    if (_techFilterIndex > 0) {
      url += '&tech_filter=$_techFilterIndex';
    }
    if (_selectedPriorityId != null) {
      url += '&priority_id=$_selectedPriorityId';
    }
    if (_selectedStatusId != null) {
      url += '&status_id=$_selectedStatusId';
    }

    final response = await AppAPI.get(url);
    final Map<String, dynamic> json = jsonDecode(response.body);
    final res = OrderPoolResponse.fromJson(json);
    setState(() {
      _allOrders = res.data;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            totalCount: _allOrders.length,
            techFilterIndex: _techFilterIndex,
            onTechFilterChanged: (index) {
              setState(() {
                _techFilterIndex = index;
              });
              _fetchOrders();
            },
            selectedPriorityId: _selectedPriorityId,
            priorities: _priorities,
            onPriorityChanged: (priorityId) {
              setState(() {
                _selectedPriorityId = priorityId;
              });
              _fetchOrders();
            },
            selectedStatusId: _selectedStatusId,
            statuses: _statuses,
            onStatusChanged: (statusId) {
              setState(() {
                _selectedStatusId = statusId;
              });
              _fetchOrders();
            },
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_allOrders.isEmpty) {
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
        itemCount: _allOrders.length,
        itemBuilder: (context, index) {
          final order = _allOrders[index];
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
