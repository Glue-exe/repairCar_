import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/vehicle_search_phone_model.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/screens/shared/intakecar/vehicle_detail_screen.dart';
import 'package:my_app/screens/shared/intakecar/add_vehicle_for_customer_screen.dart';
import 'package:my_app/utils/app_api.dart';

class OwnerCustomerVehiclesScreen extends StatefulWidget {
  final List<PhoneSearchResultModel> vehicles;

  const OwnerCustomerVehiclesScreen({
    super.key,
    required this.vehicles,
  });

  @override
  State<OwnerCustomerVehiclesScreen> createState() =>
      _OwnerCustomerVehiclesScreenState();
}

class _OwnerCustomerVehiclesScreenState
    extends State<OwnerCustomerVehiclesScreen> {
  late List<PhoneSearchResultModel> _vehicles;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _vehicles = List.from(widget.vehicles);
  }

  String get _customerName {
    if (_vehicles.isNotEmpty) {
      return _vehicles.first.fullName;
    }
    return '';
  }

  String get _customerPhone {
    if (_vehicles.isNotEmpty) {
      return _vehicles.first.cusPhone;
    }
    return '';
  }

  int get _customerId {
    if (_vehicles.isNotEmpty) {
      return _vehicles.first.cusId;
    }
    return 0;
  }

  Future<void> _refreshVehicles() async {
    final phone = _customerPhone;
    if (phone.isEmpty) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final response = await AppAPI.post('/vehicle_search_phone', {
        'phone': phone,
      });

      final Map<String, dynamic> resJson = jsonDecode(response.body);
      final phoneRes = PhoneSearchResultResponse.fromJson(resJson);

      if (mounted) {
        setState(() {
          if (!phoneRes.isError) {
            _vehicles = phoneRes.data;
          }
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _navigateToAddVehicle() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleForCustomerScreen(
          customerId: _customerId,
          customerName: _customerName,
          customerPhone: _customerPhone,
        ),
      ),
    );

    if (result == true) {
      _refreshVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการรถของลูกค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
            onPressed: _isRefreshing ? null : _refreshVehicles,
          ),
        ],
      ),
      body: _isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshVehicles,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ส่วนที่ 1: ข้อมูลลูกค้า
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'ข้อมูลลูกค้า',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('ชื่อลูกค้า: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text(_customerName),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('เบอร์โทรศัพท์: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text(_customerPhone),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _navigateToAddVehicle,
                              icon: const Icon(Icons.add),
                              label: const Text(
                                  'เพิ่มรถคันใหม่สำหรับลูกค้ารายนี้'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ส่วนที่ 2: รายการรถยนต์
                    const Text('เลือกรถที่ต้องการซ่อม',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    if (_vehicles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'ไม่พบข้อมูลรถยนต์ของลูกค้ารายนี้',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _vehicles[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text('ทะเบียน: ${vehicle.vLicensePlate}'),
                              subtitle: Text(
                                '${vehicle.vbName} ${vehicle.vmName} (ปี ${vehicle.vYear}) สี: ${vehicle.vColor}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VehicleDetailScreen(
                                      vehicle: VehicleSearchResultModel(
                                        vId: vehicle.vId,
                                        fullName: vehicle.fullName,
                                        cusPhone: vehicle.cusPhone,
                                        licensePlate: vehicle.vLicensePlate,
                                        modelName: vehicle.vmName,
                                        brandName: vehicle.vbName,
                                        year: vehicle.vYear,
                                        color: vehicle.vColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
