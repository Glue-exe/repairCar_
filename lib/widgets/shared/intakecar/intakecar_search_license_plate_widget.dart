import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/screens/shared/intakecar/vehicle_detail_screen.dart';

class IntakecarSearchWidget extends StatefulWidget {
  const IntakecarSearchWidget({super.key});

  @override
  State<IntakecarSearchWidget> createState() => _IntakecarSearchWidgetState();
}

class _IntakecarSearchWidgetState extends State<IntakecarSearchWidget> {
  final TextEditingController _searchController = TextEditingController();

  String _errorMessage = '';
  VehicleSearchResultModel? _vehicle;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchVehicle() async {
    final query = _searchController.text.replaceAll(RegExp(r'\s+'), '').trim();

    if (query.isEmpty) {
      setState(() {
        _vehicle = null;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _vehicle = null;
    });

    try {
      final response = await AppAPI.post('/vehicle_search_license_plate', {
        'v_license_plate': query,
      });

      final Map<String, dynamic> resJson = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          _isLoading = false;
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ไม่สามารถเชื่อมต่อระบบได้';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ค้นหาทะเบียนรถ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'ทะเบียนรถ',
                  hintText: 'กรอกทะเบียนรถ เช่น กข1234สงขลา',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchVehicle,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('ค้นหา'),
              ),
              if (_vehicle != null) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleDetailScreen(
                            vehicle: _vehicle!,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      'ทะเบียน: ${_vehicle!.licensePlate}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${_vehicle!.brandName} ${_vehicle!.modelName} (ปี ${_vehicle!.year})\n'
                      'เจ้าของรถ: ${_vehicle!.fullName}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ],
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
