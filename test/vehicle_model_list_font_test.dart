import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/vehicle_model_model.dart';
import 'package:my_app/screens/owner/profile/vehicle/vehicle_model/vehicle_model_screen.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Vehicle/vehicle_model_list_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

// เทสชั่วคราว: ตรวจว่าข้อความในหน้าจอรุ่นรถเรนเดอร์ด้วยฟอนต์อะไรจริง ๆ
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ชื่อรุ่น + ยี่ห้อ ใน list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Kanit'),
        home: Scaffold(
          body: VehicleModelListWidget(
            models: [
              VehicleModelModel(
                vmId: 1,
                vmName: 'Accord',
                vmBrandId: 2,
                vbName: 'Honda',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final titleEff =
        tester.renderObject<RenderParagraph>(find.text('Accord')).text.style;
    final subEff = tester
        .renderObject<RenderParagraph>(find.text('ยี่ห้อ: Honda'))
        .text
        .style;

    debugPrint('LIST title    : family=${titleEff?.fontFamily} size=${titleEff?.fontSize}');
    debugPrint('LIST subtitle : family=${subEff?.fontFamily} size=${subEff?.fontSize}');
  });

  testWidgets('ตัวกรองยี่ห้อ (DropdownButton) ในหน้ารุ่นรถ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Kanit'),
        home: const VehicleModelScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final eff = tester
        .renderObject<RenderParagraph>(find.text('ทุกยี่ห้อ'))
        .text
        .style;

    debugPrint('DROPDOWN item : family=${eff?.fontFamily} size=${eff?.fontSize} weight=${eff?.fontWeight}');
  });

  // เทียบให้เห็น: dropdown ที่ "ไม่ใส่ fontFamily" (แบบเดิม) จะหลุดจาก Kanit
  testWidgets('เทียบ — dropdown แบบเดิม (ไม่มี fontFamily)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Kanit'),
        home: Scaffold(
          body: DropdownButton<int>(
            value: 0,
            isExpanded: true,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            items: const [
              DropdownMenuItem<int>(value: 0, child: Text('ทดสอบ')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final eff =
        tester.renderObject<RenderParagraph>(find.text('ทดสอบ')).text.style;
    debugPrint('BEFORE (ไม่มี fontFamily) : family=${eff?.fontFamily}');
  });
}
