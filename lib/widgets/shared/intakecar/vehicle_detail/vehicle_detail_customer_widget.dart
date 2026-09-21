import 'package:flutter/material.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';

class VehicleDetailCustomerWidget extends StatelessWidget {
  final VehicleSearchResultModel vehicle;

  const VehicleDetailCustomerWidget({
    super.key,
    required this.vehicle,
  });

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, size: 20),
                SizedBox(width: 8),
                Text(
                  'ข้อมูลเจ้าของรถ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildRow('ชื่อเจ้าของรถ:', vehicle.fullName),
            const SizedBox(height: 8),
            _buildRow('เบอร์โทรศัพท์:', vehicle.cusPhone),
          ],
        ),
      ),
    );
  }
}
