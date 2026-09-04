import 'package:flutter/material.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';

class VehicleDetailCustomerWidget extends StatelessWidget {
  final VehicleSearchResultModel vehicle;

  const VehicleDetailCustomerWidget({
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
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.person),
                ),
                SizedBox(width: 12),
                Text(
                  'ข้อมูลเจ้าของรถ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'เจ้าของรถ: ${vehicle.fullName}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'เบอร์โทรศัพท์: ${vehicle.cusPhone}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
