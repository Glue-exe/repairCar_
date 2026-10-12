import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_button_widget.dart';

void main() {
  testWidgets('OrderDetailButtonWidget renders accept button when isMyOrder is false', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: OrderDetailButtonWidget(
            orderId: 101,
            isMyOrder: false,
          ),
        ),
      ),
    );

    // ตรวจสอบว่ามีปุ่ม "กดรับงานซ่อมนี้"
    expect(find.text('กดรับงานซ่อมนี้'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_turned_in_rounded), findsOneWidget);
    expect(find.text('คุณได้รับงานซ่อมนี้แล้ว'), findsNothing);
  });

  testWidgets('OrderDetailButtonWidget renders accepted state banner when isMyOrder is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: OrderDetailButtonWidget(
            orderId: 102,
            isMyOrder: true,
          ),
        ),
      ),
    );

    // ตรวจสอบว่าแสดงแถบสถานะ "คุณได้รับงานซ่อมนี้แล้ว"
    expect(find.text('คุณได้รับงานซ่อมนี้แล้ว'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('กดรับงานซ่อมนี้'), findsNothing);
  });

  testWidgets('Tapping accept button triggers confirmation dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: OrderDetailButtonWidget(
            orderId: 103,
            isMyOrder: false,
          ),
        ),
      ),
    );

    // กดปุ่มรับงาน
    await tester.tap(find.text('กดรับงานซ่อมนี้'));
    await tester.pumpAndSettle();

    // ต้องปรากฏ Confirmation Dialog
    expect(find.text('ยืนยันการรับงาน'), findsOneWidget);
    expect(find.text('คุณต้องการรับงานซ่อม #103 เข้าสู่รายการงานของคุณหรือไม่?'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsOneWidget);
    expect(find.text('ยืนยันรับงาน'), findsOneWidget);

    // กดยกเลิก
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    // Dialog ปิด และปุ่มยังคงอยู่
    expect(find.text('ยืนยันการรับงาน'), findsNothing);
    expect(find.text('กดรับงานซ่อมนี้'), findsOneWidget);
  });
}
