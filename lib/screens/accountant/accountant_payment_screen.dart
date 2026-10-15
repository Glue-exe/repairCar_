import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/accountant_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/accountant/accountant_payment_dialog.dart';
import 'package:my_app/widgets/accountant/accountant_receipt_dialog.dart';

class AccountantPaymentScreen extends StatefulWidget {
  const AccountantPaymentScreen({super.key});

  @override
  State<AccountantPaymentScreen> createState() => _AccountantPaymentScreenState();
}

class _AccountantPaymentScreenState extends State<AccountantPaymentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  String _errorMessage = '';

  List<AccountantOrderItemModel> _pendingOrders = [];
  List<AccountantOrderItemModel> _paidOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final responses = await Future.wait([
        AppAPI.get('/accountant/orders?type=pending'),
        AppAPI.get('/accountant/orders?type=paid'),
      ]);

      if (responses[0].statusCode == 200) {
        final pendingJson = jsonDecode(responses[0].body);
        final pendingRes = AccountantOrdersResponse.fromJson(pendingJson);
        if (!pendingRes.isError) {
          _pendingOrders = pendingRes.data;
        }
      }

      if (responses[1].statusCode == 200) {
        final paidJson = jsonDecode(responses[1].body);
        final paidRes = AccountantOrdersResponse.fromJson(paidJson);
        if (!paidRes.isError) {
          _paidOrders = paidRes.data;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ฟังก์ชันกรองรายการงานตามคำค้นหา
  List<AccountantOrderItemModel> _filterOrders(List<AccountantOrderItemModel> orders) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return orders;

    final queryClean = query.replaceAll(' ', '');

    return orders.where((order) {
      final plate = order.licensePlate.toLowerCase();
      final plateClean = plate.replaceAll(' ', '');
      final carTitle = order.carTitle.toLowerCase();
      final customerName = order.customerFullName.toLowerCase();
      final customerPhone = order.customerPhone.replaceAll(' ', '');
      final orderId = order.orderId.toString();
      final symptom = order.symptom.toLowerCase();

      return plate.contains(query) ||
          plateClean.contains(queryClean) ||
          carTitle.contains(query) ||
          customerName.contains(query) ||
          customerPhone.contains(queryClean) ||
          orderId == query ||
          orderId == queryClean.replaceAll('#', '').replaceAll('งาน', '') ||
          symptom.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPending = _filterOrders(_pendingOrders);
    final filteredPaid = _filterOrders(_paidOrders);

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade50,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Kanit'),
          tabs: [
            Tab(text: 'รอชำระ (${filteredPending.length})'),
            Tab(text: 'ชำระส่งมอบแล้ว (${filteredPaid.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _fetchOrders,
                        child: const Text('ลองใหม่อีกครั้ง'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBox(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrderListView(
                            orders: filteredPending,
                            isPaidTab: false,
                          ),
                          _buildOrderListView(
                            orders: filteredPaid,
                            isPaidTab: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ส่วนกล่องค้นหา (Search Box)
  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'ค้นหาทะเบียนรถ, ยี่ห้อ, รุ่น, ลูกค้า หรือรหัสงาน...',
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, size: 22, color: AppColors.primaryGreen),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  tooltip: 'ล้างคำค้นหา',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade200, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade200, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderListView({
    required List<AccountantOrderItemModel> orders,
    required bool isPaidTab,
  }) {
    final currencyFormatter = NumberFormat('#,##0.00');

    if (orders.isEmpty) {
      final hasSearch = _searchQuery.trim().isNotEmpty;
      return RefreshIndicator(
        onRefresh: _fetchOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasSearch ? Icons.search_off_rounded : Icons.receipt_long_rounded,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasSearch
                          ? 'ไม่พบข้อมูลรถที่ตรงกับ "$_searchQuery"'
                          : (isPaidTab ? 'ไม่มีรายการงานที่ชำระส่งมอบแล้ว' : 'ไม่มีรายการงานที่รอชำระ'),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                    if (hasSearch) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('ล้างคำค้นหา'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ทะเบียนรถ และ รุ่น
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${order.licensePlate} (${order.carTitle})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'งาน #${order.orderId}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ลูกค้า
                  Text(
                    'ลูกค้า: ${order.customerFullName}  เบอร์โทร: ${order.customerPhone}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  if (order.symptom.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'อาการ: ${order.symptom}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Divider(height: 18),

                  // ยอดเงินและปุ่ม
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ค่าแรง: ฿${currencyFormatter.format(order.laborTotal)}  ค่าอะไหล่: ฿${currencyFormatter.format(order.partsTotal)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ยอดสุทธิ: ฿${currencyFormatter.format(order.totalAmount)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPaidTab ? Colors.green.shade800 : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      if (!isPaidTab)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AccountantPaymentDialog(
                                order: order,
                                onSuccess: _fetchOrders,
                              ),
                            );
                          },
                          child: const Text('รับชำระเงิน'),
                        )
                      else
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(color: AppColors.primaryGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AccountantReceiptDialog(order: order),
                            );
                          },
                          child: const Text('ดูใบเสร็จ'),
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
