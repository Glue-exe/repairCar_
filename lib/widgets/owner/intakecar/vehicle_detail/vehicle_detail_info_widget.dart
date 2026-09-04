import 'package:flutter/material.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';

class VehicleDetailInfoWidget extends StatelessWidget {
  final VehicleSearchResultModel vehicle;

  const VehicleDetailInfoWidget({
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
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.directions_car),
                ),
                const SizedBox(width: 12),
                Text(
                  vehicle.licensePlate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'ยี่ห้อ: ${vehicle.brandName}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'รุ่น: ${vehicle.modelName}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'ปี: ${vehicle.year}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'สี: ${vehicle.color}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
