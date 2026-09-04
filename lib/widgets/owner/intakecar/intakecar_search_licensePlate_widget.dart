import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/screens/owner/owner_vehicle_detail_screen.dart';

class IntakecarSearchWidget extends StatefulWidget {
  const IntakecarSearchWidget({super.key});

  @override
  State<IntakecarSearchWidget> createState() => _IntakecarSearchWidgetState();
}

class _IntakecarSearchWidgetState extends State<IntakecarSearchWidget> {
  final TextEditingController _searchController = TextEditingController();

  String _errorMessage = '';
  VehicleSearchResultModel? _vehicle;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchVehicle() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _vehicle = null;
      });
      return;
    }

    setState(() {
      _errorMessage = '';
      _vehicle = null;
    });

    try {
      final response = await AppAPI.post('/vehicle_search_licensePlate', {
        'v_license_plate': query,
      });

      final Map<String, dynamic> resJson = jsonDecode(response.body);

      setState(() {
        if (resJson['isError'] == false) {
          final List<dynamic> dataList = resJson['data'];
          if (dataList.isNotEmpty) {
            _vehicle = VehicleSearchResultModel.fromJson(dataList[0]);
          } else {
            _vehicle = null;
            _errorMessage = 'ไม่พบข้อมูลทะเบียนรถนี้ในระบบ';
          }
        } else {
          _errorMessage = resJson['errorMessage'];
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเชื่อมต่อระบบได้';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('ค้นหาทะเบียนรถ'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'กรอกทะเบียน',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _searchVehicle,
            child: const Text('ค้นหา'),
          ),
          const SizedBox(height: 16),
          if (_vehicle != null)
            Card(
              elevation: 2,
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OwnerVehicleDetailScreen(
                        vehicle: _vehicle!,
                      ),
                    ),
                  );
                },
                leading: const CircleAvatar(
                  child: Icon(Icons.directions_car),
                ),
                title: Text(
                  'ทะเบียน: ${_vehicle!.licensePlate}',
                ),
                subtitle: Text(
                  'ยี่ห้อ: ${_vehicle!.brandName} ${_vehicle!.modelName} (ปี ${_vehicle!.year})\n'
                  'สี: ${_vehicle!.color}\n'
                  'เจ้าของรถ: ${_vehicle!.fullName}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}
