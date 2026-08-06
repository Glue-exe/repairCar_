import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/vehiclelicenseplate_search.dart';
import 'package:my_app/utils/app_api.dart';

class OwnerIntakecarScreen extends StatefulWidget {
  const OwnerIntakecarScreen({super.key});

  @override
  State<OwnerIntakecarScreen> createState() => _OwnerIntakecarScreen();
}

class _OwnerIntakecarScreen extends State<OwnerIntakecarScreen> {
  TextEditingController _inputController = TextEditingController();
  List<VehicleLicenseplateSearch> _searchResults = [];
  List<OrderSearchModel> _repairHistory = [];
  bool _isLoading = false;
  String _errorMessage = '';

  void _searchVehicle() async {
    var query = _inputController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
      _repairHistory = [];
    });

    try {
      // เรียกใช้ API ค้นหา เช่น /vehicle?searchTerm=xxx
      var response = await AppAPI.get('/vehicle?searchTerm=$query');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final searchResponse = VehicleLicenseplateSearchResponse.fromJson(json);

        setState(() {
          _isLoading = false;
          if (searchResponse.isError) {
            _errorMessage = searchResponse.errorMessage;
          } else {
            _searchResults = searchResponse.data;
            _repairHistory = searchResponse.orders;
            if (_searchResults.isEmpty) {
              _errorMessage = 'ไม่พบข้อมูลรถยนต์ในระบบ';
            }
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รับรถ'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'ป้ายทะเบียนรถหรือเบอร์โทรศัพท์',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _searchVehicle,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('ค้นหาข้อมูลในระบบ'),
            ),
            const SizedBox(height: 20),

            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),

            if (_searchResults.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ข้อมูลรถยนต์และเจ้าของ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final vehicle = _searchResults[index];
                    return ListTile(
                      title: Text(vehicle.vehicleSummary),
                      subtitle: Text(
                        'เจ้าของ: ${vehicle.customerFullName} | เบอร์โทร: ${vehicle.customerPhone}',
                      ),
                      onTap: () {
                        print('เลือกข้อมูลรถ: ${vehicle.vehicleLicenseplate}');
                      },
                    );
                  },
                ),
              ),
            ],

            if (_repairHistory.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ประวัติการซ่อมล่าสุด',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: _repairHistory.length,
                  itemBuilder: (context, index) {
                    final order = _repairHistory[index];
                    return ListTile(
                      title: Text('อาการ: ${order.orderSymptom}'),
                      subtitle: Text(
                        'วันที่: ${order.createdAt.split("T")[0]} | ค่าแรงซ่อม: ${order.laborCost ?? "ยังไม่ระบุ"} บาท | สถานะ: ${order.statusId}',
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('เพิ่มข้อมูลลูกค้าใหม่');
              },
              child: const Text('เพิ่มข้อมูลลูกค้าใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}
