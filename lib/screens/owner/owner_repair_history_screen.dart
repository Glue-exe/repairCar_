import 'package:flutter/material.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_status_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_vehicle_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_symptom_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_images_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_technician_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_sub_task_widget.dart';
import 'package:my_app/widgets/owner/intakecar/repair_history/repair_history_invoice_widget.dart';

class OwnerRepairHistoryScreen extends StatelessWidget {
  final OrderModel order;
  final VehicleSearchResultModel vehicle;

  const OwnerRepairHistoryScreen({
    super.key,
    required this.order,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ใบรับซ่อม #${order.orderId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนที่ 1: สถานะและวันที่ใบรับซ่อม
            RepairHistoryStatusWidget(order: order),
            const SizedBox(height: 16),

            // ส่วนที่ 2: ข้อมูลรถยนต์และเจ้าของรถ
            RepairHistoryVehicleWidget(vehicle: vehicle),
            const SizedBox(height: 16),

            // ส่วนที่ 3: อาการเสีย / รายการที่ต้องซ่อม
            RepairHistorySymptomWidget(symptom: order.symptom),
            const SizedBox(height: 16),

            // ส่วนที่ 4: รูปถ่ายชิ้นส่วน / สภาพรถ
            RepairHistoryImagesWidget(images: order.images),
            const SizedBox(height: 16),

            // ส่วนที่ 5: ช่างผู้รับผิดชอบ (ตาราง order_technician)
            const RepairHistoryTechnicianWidget(),
            const SizedBox(height: 16),

            // ส่วนที่ 6: รายการงานซ่อมย่อย (ตาราง sub_task)
            const RepairHistorySubTaskWidget(),
            const SizedBox(height: 16),

            // ส่วนที่ 7: ใบเสร็จรับเงิน / สรุปค่าบริการ (ตาราง invoice)
            const RepairHistoryInvoiceWidget(),
          ],
        ),
      ),
    );
  }
}
