import 'package:flutter/material.dart';
import 'package:my_app/models/vehicle_search_phone_model.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/screens/shared/intakecar/vehicle_detail_screen.dart';

class OwnerCustomerVehiclesScreen extends StatelessWidget {
  final List<PhoneSearchResultModel> vehicles;

  const OwnerCustomerVehiclesScreen({
    super.key,
    required this.vehicles,
  });

  @override
  Widget build(BuildContext context) {
    String customerName = '';
    String customerPhone = '';
    if (vehicles.isNotEmpty) {
      customerName = vehicles.first.fullName;
      customerPhone = vehicles.first.cusPhone;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการรถของลูกค้า'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนที่ 1: ข้อมูลลูกค้า
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.person),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'ข้อมูลลูกค้า',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'ชื่อลูกค้า: $customerName',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'เบอร์โทรศัพท์: $customerPhone',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ส่วนที่ 2: รายการรถยนต์
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  'เลือกรถที่ต้องการซ่อม',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${vehicles.length} คัน',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (vehicles.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'ไม่พบข้อมูลรถยนต์ของลูกค้ารายนี้',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.directions_car),
                      ),
                      title: Text(
                        'ทะเบียน: ${vehicle.vLicensePlate}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${vehicle.vbName} ${vehicle.vmName}\n'
                        'ปี: ${vehicle.vYear} | สี: ${vehicle.vColor}',
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
    );
  }
}
