import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/monthly_income_model.dart';
import 'package:my_app/widgets/owner/dashboard/income_chart_widget.dart';

void main() {
  testWidgets('Verify scrollable chart renders all months cleanly', (tester) async {
    final list = [
      MonthlyIncomeModel(monthYear: '2025-10', totalAmount: 89050),
      MonthlyIncomeModel(monthYear: '2025-11', totalAmount: 193800),
      MonthlyIncomeModel(monthYear: '2025-12', totalAmount: 115000),
      MonthlyIncomeModel(monthYear: '2026-01', totalAmount: 111000),
      MonthlyIncomeModel(monthYear: '2026-02', totalAmount: 68630),
      MonthlyIncomeModel(monthYear: '2026-03', totalAmount: 76000),
      MonthlyIncomeModel(monthYear: '2026-04', totalAmount: 142000),
      MonthlyIncomeModel(monthYear: '2026-05', totalAmount: 80000),
      MonthlyIncomeModel(monthYear: '2026-06', totalAmount: 109000),
      MonthlyIncomeModel(monthYear: '2026-07', totalAmount: 88000),
      MonthlyIncomeModel(monthYear: '2026-08', totalAmount: 129000),
      MonthlyIncomeModel(monthYear: '2026-09', totalAmount: 118000),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncomeChartWidget(incomeList: list),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('แนวโน้มรายได้รายเดือน'), findsOneWidget);
    expect(find.text('เลื่อนดูได้'), findsOneWidget);
    expect(find.text('2025-10'), findsOneWidget);
  });
}
