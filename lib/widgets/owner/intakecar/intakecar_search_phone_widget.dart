import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/vehicle_search_phone_model.dart';
import 'package:my_app/screens/owner/owner_customer_vehicles_screen.dart';

class IntakecarSearchPhoneWidget extends StatefulWidget {
  const IntakecarSearchPhoneWidget({super.key});

  @override
  State<IntakecarSearchPhoneWidget> createState() =>
      _IntakecarSearchPhoneWidgetState();
}

class _IntakecarSearchPhoneWidgetState
    extends State<IntakecarSearchPhoneWidget> {
  final TextEditingController _searchPhoneController = TextEditingController();

  String _errorMessage = '';
  List<PhoneSearchResultModel> _cus = [];

  @override
  void dispose() {
    _searchPhoneController.dispose();
    super.dispose();
  }

  Future<void> _searchPhone() async {
    final query = _searchPhoneController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _cus = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
    });

    try {
      final response = await AppAPI.post('/vehicle_search_phone', {
        'phone': query,
      });

      final Map<String, dynamic> resJson = jsonDecode(response.body);
      final phoneRes = PhoneSearchResultResponse.fromJson(resJson);

      setState(() {
        if (phoneRes.isError == false) {
          if (phoneRes.data.isNotEmpty) {
            _cus = phoneRes.data;
          } else {
            _cus = [];
            _errorMessage = 'ไม่พบข้อมูลลูกค้า';
          }
        } else {
          _errorMessage = phoneRes.errorMessage;
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
          const Text('ค้นหาด้วยเบอร์โทรศัพท์'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchPhoneController,
                  decoration: const InputDecoration(
                    hintText: 'กรอกเบอร์โทรศัพท์',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _searchPhone,
            child: const Text('ค้นหา'),
            ),
            const SizedBox(height: 16),
            if (_cus.isNotEmpty)
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    'ชื่อลูกค้า: ${_cus.first.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('เบอร์โทร: ${_cus.first.cusPhone} (${_cus.length} คัน)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerCustomerVehiclesScreen(
                          vehicles: _cus,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
        ],
      ),
    );
  }
}
