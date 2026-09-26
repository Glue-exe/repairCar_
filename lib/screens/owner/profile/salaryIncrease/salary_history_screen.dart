import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/salary_history_model.dart';
import 'package:my_app/screens/owner/profile/salaryIncrease/salary_history_increase_screen.dart';
import 'package:my_app/utils/app_api.dart';

class SalaryHistoryScreen extends StatefulWidget {
  const SalaryHistoryScreen({super.key});

  @override
  State<SalaryHistoryScreen> createState() => _SalaryHistoryScreenState();
}

class _SalaryHistoryScreenState extends State<SalaryHistoryScreen> {
  List<SalaryHistoryModel> salaryHistoryList = [];
  bool _isLoading = true;
  // null = ทั้งหมด, 1 = เจ้าของร้าน, 2 = พนักงานบัญชี, 3 = ช่าง
  int? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final response = await AppAPI.get("/salary_history");
      final Map<String, dynamic> json = jsonDecode(response.body);
      final SalaryHistoryResponse res = SalaryHistoryResponse.fromJson(json);

      if (!mounted) return;
      setState(() {
        salaryHistoryList = res.data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // จัดรูปแบบวันที่ให้อ่านง่าย เช่น 30/06/2026
  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // จัดรูปแบบยอดเงิน เช่น 20,000
  String _formatMoney(String amountStr) {
    final amount = double.tryParse(amountStr);
    if (amount != null) {
      return '${NumberFormat('#,##0').format(amount)} ';
    } else {
      return '$amountStr ';
    }
  }

  Widget _buildList(List<SalaryHistoryModel> filteredList) {
    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          'ไม่พบข้อมูลพนักงานในตำแหน่งนี้',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: const Icon(Icons.person),
                ),
                title: Text(
                  '${item.tName}${item.empFirstName} ${item.empLastName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'ตำแหน่ง: ${item.arName}\nวันที่มีผล: ${_formatDate(item.shEffectiveDate)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMoney(item.empCurrentSalary),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalaryHistoryIncreaseScreen(
                        salaryHistory: item,
                      ),
                    ),
                  );
                  if (result == true) {
                    _fetchData();
                  }
                },
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (salaryHistoryList.isEmpty) {
      return const Center(child: Text('ไม่มีข้อมูลประวัติเงินเดือน'));
    } else {
      List<SalaryHistoryModel> filteredList;

      if (_selectedRoleId == null) {
        filteredList = salaryHistoryList;
      } else {
        filteredList = salaryHistoryList
            .where((item) => item.accRoleId == _selectedRoleId)
            .toList();
      }

      return Column(
        children: [
          // แถบตัวกรองตำแหน่งงาน (Role Filter)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('ทั้งหมด'),
                  selected: _selectedRoleId == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedRoleId = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('เจ้าของร้าน'),
                  selected: _selectedRoleId == 1,
                  onSelected: (_) {
                    setState(() {
                      _selectedRoleId = 1;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('พนักงานบัญชี'),
                  selected: _selectedRoleId == 2,
                  onSelected: (_) {
                    setState(() {
                      _selectedRoleId = 2;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('ช่าง'),
                  selected: _selectedRoleId == 3,
                  onSelected: (_) {
                    setState(() {
                      _selectedRoleId = 3;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildList(filteredList),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ประวัติเงินเดือน'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}