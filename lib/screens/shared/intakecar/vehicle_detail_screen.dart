import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/models/order_model.dart';
import 'package:my_app/screens/shared/intakecar/create_order_screen.dart';
import 'package:my_app/widgets/shared/intakecar/vehicle_detail/vehicle_detail_info_widget.dart';
import 'package:my_app/widgets/shared/intakecar/vehicle_detail/vehicle_detail_customer_widget.dart';
import 'package:my_app/widgets/shared/intakecar/vehicle_detail/vehicle_detail_orders_widget.dart';

class VehicleDetailScreen extends StatefulWidget {
  final VehicleSearchResultModel vehicle;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  List<OrderModel> _orderList = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _getOrders();
  }

  // ดึงประวัติการซ่อมของรถคันนี้จาก orders
  Future<void> _getOrders() async {
    final vehicleId = widget.vehicle.vId;

    try {
      final response = await AppAPI.post('/vehicle_orders', {
        'vehicle_id': vehicleId,
      });

      final Map<String, dynamic> resJson = jsonDecode(response.body);
      final orderRes = OrderResponse.fromJson(resJson);

      if (orderRes.isError == false) {
        setState(() {
          _orderList = orderRes.data;
          _isLoadingOrders = false;
        });
      } else {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingOrders = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดรถยนต์'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนที่ 1: ข้อมูลรถยนต์
            VehicleDetailInfoWidget(vehicle: vehicle),
            const SizedBox(height: 16),

            // ส่วนที่ 2: ข้อมูลเจ้าของรถ
            VehicleDetailCustomerWidget(vehicle: vehicle),
            const SizedBox(height: 16),

            // ส่วนที่ 3: ประวัติการซ่อม
            VehicleDetailOrdersWidget(
              orderList: _orderList,
              isLoading: _isLoadingOrders,
              vehicle: vehicle,
            ),
            const SizedBox(height: 24),

            // ส่วนที่ 4: ปุ่มสร้างใบรับซ่อม
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateOrderScreen(
                        vehicle: vehicle,
                      ),
                    ),
                  );

                  // ถ้ารับซ่อมสำเร็จ ให้โหลดประวัติการซ่อมใหม่ทันที
                  if (result == true) {
                    _getOrders();
                  }
                },
                icon: const Icon(Icons.note_add),
                label: const Text(
                  'สร้างใบรับซ่อม',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
