import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/monthly_income_model.dart';
import 'package:my_app/screens/owner/income_detail_screen.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/income_summary_card.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  List<MonthlyIncomeModel> monthlyIncomeModelStore = [];

  void _fetchData() async {
    var response = await AppAPI.get("/income/monthly");
    Map<String, dynamic> json = jsonDecode(response.body);
    IncomeResponse incomeResponse = IncomeResponse.fromJson(json);

    setState(() {
      monthlyIncomeModelStore = incomeResponse.data;
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
      appBar: AppBar(
        title: const Text('Owner Dashboard (เจ้าของร้าน)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // แถวการ์ดสรุปบนสุด (แบ่งฝั่งซ้าย-ขวา)
            Row(
              children: [
                // 1. การ์ดยอดรวมรายได้ (บนซ้าย)
                Expanded(
                  child: IncomeSummaryCard(
                    incomeList: monthlyIncomeModelStore,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IncomeDetailScreen(
                            incomeList: monthlyIncomeModelStore,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // 2. การ์ดสรุปอื่นๆ (บนขวา)
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.blue.shade700,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "งานกำลังซ่อม",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Icon(
                                Icons.build,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "0 งาน",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

