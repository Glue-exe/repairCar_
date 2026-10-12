import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_main_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_pool_list_widget.dart';

class OrderPoolMainScreen extends StatefulWidget {
  const OrderPoolMainScreen({super.key});

  @override
  State<OrderPoolMainScreen> createState() => _OrderPoolMainScreenState();
}

class _OrderPoolMainScreenState extends State<OrderPoolMainScreen> {
  bool _acceptByMe = false;

  List<OrderPoolMainModel> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AppAPI.get('/order3');
      final Map<String, dynamic> json = jsonDecode(response.body);
      final orderResponse = OrderPoolMainResponse.fromJson(json);

      if (mounted) {
        setState(() {
          if (!orderResponse.isError) {
            _orders = orderResponse.data;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // กรองรายการ
    final filteredOrders = _acceptByMe
        ? _orders.where((order) => order.acceptByMe).toList()
        : _orders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'ศูนย์รวมงานซ่อม',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ปุ่มกดสลับ: งานของฉัน / งานทั้งหมด
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _acceptByMe ? AppColors.primaryGreen : AppColors.inputBackground,
                        foregroundColor: _acceptByMe ? Colors.white : AppColors.textDark,
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _acceptByMe = true;
                        });
                      },
                      child: const Text('งานของฉัน'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_acceptByMe ? AppColors.primaryGreen : AppColors.inputBackground,
                        foregroundColor: !_acceptByMe ? Colors.white : AppColors.textDark,
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _acceptByMe = false;
                        });
                      },
                      child: const Text('งานทั้งหมด'),
                    ),
                  ),
                ],
              ),
            ),
            // รายการงานซ่อม
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : OrderPoolListWidget(
                      orders: filteredOrders,
                      onRefresh: _fetchOrders,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}