import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/old/vehiclelicenseplate_search.dart';
import 'package:my_app/screens/owner/navbar_owner.dart';
import 'package:my_app/screens/owner/old/owner_add_customer_screen.dart';
import 'package:my_app/screens/owner/old/owner_add_orders_screen.dart';
import 'package:my_app/screens/owner/old/owner_addnewcar_screen.dart';
import 'package:my_app/utils/app_api.dart';

class OwnerIntakecarScreen extends StatefulWidget {
  const OwnerIntakecarScreen({super.key});

  @override
  State<OwnerIntakecarScreen> createState() => _OwnerIntakecarScreen();
}

class _OwnerIntakecarScreen extends State<OwnerIntakecarScreen> {
  final TextEditingController _inputController = TextEditingController();
  List<VehicleLicenseplateSearch> _searchResults = [];
  List<OrderSearchModel> _repairHistory = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int? _selectedVehicleId;

  void _searchVehicle() async {
    var query = _inputController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
      _repairHistory = [];
      _selectedVehicleId = null;
    });

    try {
      var response = await AppAPI.get('/vehicle?searchVehicalOrCustomer=$query');

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

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
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
            ),
            const SizedBox(height: 20),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],

            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 20),
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
                    final isSelected = _selectedVehicleId == vehicle.vehicleId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListTile(
                        title: Text(vehicle.vehicleSummary),
                        subtitle: Text(
                          'เจ้าของ: ${vehicle.customerFullName} | เบอร์โทร: ${vehicle.customerPhone}',
                        ),
                        onTap: () {
                          setState(() {
                            _selectedVehicleId = vehicle.vehicleId;
                          });
                          print('เลือกข้อมูลรถ: ${vehicle.vehicleLicenseplate}');
                        },
                      ),
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

            if (_searchResults.isEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OwnerAddCustomerScreen(),
                      ),
                    );

                    if (result != null && result is String) {
                      _inputController.text = result;
                      _searchVehicle();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('เพิ่มข้อมูลลูกค้าใหม่สำเร็จ'),
                        ),
                      );
                    }
                  },
                  child: const Text('เพิ่มข้อมูลลูกค้าใหม่'),
                ),
              ),
            ],
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 208, 209, 208),
                    foregroundColor: const Color.fromARGB(255, 17, 16, 16),
                  ),
                  
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerAddnewcarScreen(
                          customerId: _searchResults[0].customerId,
                        ),
                      ),
                    );

                    if (result != null && result is String) {
                      _inputController.text = _searchResults[0].customerPhone;
                      _searchVehicle();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('เพิ่มข้อมูลรถใหม่สำเร็จ'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('เพิ่มข้อมูลรถ'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  
                  onPressed: _selectedVehicleId == null
                      ? null
                      : () {
                          final selectedVehicle = _searchResults.firstWhere(
                            (v) => v.vehicleId == _selectedVehicleId,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OwnerAddOrdersScreen(
                                vehicle: selectedVehicle,
                              ),
                            ),
                          ).then((success) {
                            if (success == true) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NavbarOwner(initialIndex: 1),
                                ),
                                (route) => false,
                              );
                            }
                          });
                        },
                  child: const Text('เปิดงานซ่อมใหม่'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
