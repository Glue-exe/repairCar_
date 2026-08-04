import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/dashboard_summary_model.dart';
import 'package:my_app/models/monthly_income_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/home/income_summary_card.dart';
import 'package:my_app/widgets/owner/home/vehicles_summary_card.dart';
import 'package:my_app/widgets/owner/home/active_jobs_card.dart';
import 'package:my_app/widgets/owner/home/pending_approvals_card.dart';
import 'package:my_app/widgets/owner/home/income_chart_widget.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  DashboardSummaryModel dashboardSummaryStore = DashboardSummaryModel(
    monthlyIncome: 0.0,
    vehiclesThisMonth: 0,
    activeJobsCount: 0,
    pendingApprovalsCount: 0,
  );

  List<MonthlyIncomeModel> monthlyIncomeHistoryStore = [];

  void _fetchData() async {
    var response = await Future.wait([
      AppAPI.get("/dashboard/summary"),
      AppAPI.get("/income/monthly_history"),
    ]);

    Map<String, dynamic> summaryJson = jsonDecode(response[0].body);
    DashboardSummaryResponse dashboardSummaryResponse =
        DashboardSummaryResponse.fromJson(summaryJson);

    Map<String, dynamic> historyJson = jsonDecode(response[1].body);
    MonthlyIncomeResponse monthlyIncomeResponse =
        MonthlyIncomeResponse.fromJson(historyJson);

    setState(() {
      dashboardSummaryStore = dashboardSummaryResponse.data;
      monthlyIncomeHistoryStore = monthlyIncomeResponse.data;
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
        title: const Text('Dashboard'),
        backgroundColor: Colors.teal.shade50,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Expanded(
                    child: IncomeSummaryCard(
                      summaryData: dashboardSummaryStore,
                    ),
                  ),
                  Expanded(
                    child: VehiclesSummaryCard(
                      summaryData: dashboardSummaryStore,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ActiveJobsCard(summaryData: dashboardSummaryStore),
                  ),
                  Expanded(
                    child: PendingApprovalsCard(
                      summaryData: dashboardSummaryStore,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              IncomeChartWidget(incomeList: monthlyIncomeHistoryStore),
            ],
          ),
        ),
      ),
    );
  }
}
