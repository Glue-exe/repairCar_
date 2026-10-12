import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/order_pool_main_model.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_button_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_customer_data_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_images_data_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_invoice2_data_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_symptom_data_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_sub_task_data_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_technician_data_widget.dart';
import 'package:my_app/widgets/shared/order_pool_main_widget/order_detail_widget/order_detail_vehicle_data_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderPoolMainModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  // เพิ่มขึ้นเมื่อกดรับ/ยกเลิกงาน เพื่อบังคับให้การ์ดรายชื่อช่างโหลดใหม่
  int _technicianReloadToken = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ใบรับซ่อม #${widget.order.oId}',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OrderDetailButtonWidget(
            orderId: widget.order.oId,
            isMyOrder: widget.order.acceptByMe,
            onAccepted: () {
              setState(() {
                widget.order.acceptByMe = true;
                _technicianReloadToken++;
              });
            },
            onCancelled: () {
              setState(() {
                widget.order.acceptByMe = false;
                _technicianReloadToken++;
              });
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนที่ 1: ข้อมูลลูกค้า (Customer Data Widget)
            OrderDetailCustomerDataWidget(order: widget.order),
            const SizedBox(height: 12),

            // ส่วนที่ 2: ข้อมูลรถยนต์ (Vehicle Data Widget)
            OrderDetailVehicleDataWidget(order: widget.order),
            const SizedBox(height: 12),

            // ส่วนที่ 3: ข้อมูลอาการเสียและปัญหาที่แจ้ง (Symptom Data Widget)
            OrderDetailSymptomDataWidget(order: widget.order),
            const SizedBox(height: 12),

            // งานซ่อมย่อย (Sub-task Data Widget)
            OrderDetailSubTaskDataWidget(
              order: widget.order,
              onOrderChanged: () {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // ส่วนที่ 4: รูปถ่ายสภาพรถ (Images Data Widget)
            OrderDetailImagesDataWidget(order: widget.order),
            const SizedBox(height: 12),

            // ส่วนที่ 5: ช่างผู้รับผิดชอบ (Technician Data Widget)
            OrderDetailTechnicianDataWidget(
              key: ValueKey(_technicianReloadToken),
              orderId: widget.order.oId,
            ),
            const SizedBox(height: 12),

            // ส่วนที่ 6: บิลของ Order (ค่าแรง + อะไหล่ที่อนุมัติแล้ว)
            OrderDetailInvoice2DataWidget(order: widget.order),
          ],
        ),
      ),
    );
  }
}
