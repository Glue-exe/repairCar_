import 'package:flutter/material.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';

class OrderVehicleWidget extends StatelessWidget {
  final VehicleSearchResultModel vehicle;

  const OrderVehicleWidget({
    super.key,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลรถยนต์และเจ้าของรถ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('ทะเบียนรถ:', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    vehicle.licensePlate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('ยี่ห้อ / รุ่น:', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('${vehicle.brandName} ${vehicle.modelName}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('ปีรถ:', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('${vehicle.year}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('เจ้าของรถ:', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(vehicle.fullName),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('เบอร์โทรศัพท์:', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(vehicle.cusPhone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
