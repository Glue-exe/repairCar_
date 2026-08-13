import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/utils/app_api.dart';

class OwnerAddCustomerScreen extends StatefulWidget {
  const OwnerAddCustomerScreen({super.key});

  @override
  State<OwnerAddCustomerScreen> createState() => _OwnerAddCustomerScreenState();
}

class _OwnerAddCustomerScreenState extends State<OwnerAddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _licensePlateController = TextEditingController();
  final _colorController = TextEditingController();

  int? _selectedBrandId;
  String? _selectedModel;
  String? _selectedYear;
  bool _isSubmitting = false;
  bool _isLoadingMetaData = true;

  List<Map<String, dynamic>> _brands = [];
  Map<int, List<String>> _brandModels = {};
  List<String> _years = [];

  List<String> get _filteredModels {
    if (_selectedBrandId == null) return [];
    return _brandModels[_selectedBrandId] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _fetchVehicleMetaData();
  }

  Future<void> _fetchVehicleMetaData() async {
    try {
      final responses = await Future.wait([
        AppAPI.get('/vehicle_brand'),
        AppAPI.get('/vehicle_model'),
        AppAPI.get('/vehicle_year'),
      ]);

      final brandData = jsonDecode(responses[0].body);
      final modelData = jsonDecode(responses[1].body);
      final yearData = jsonDecode(responses[2].body);

      if (brandData['isError'] == false &&
          modelData['isError'] == false &&
          yearData['isError'] == false) {
        
        final List<dynamic> brandsList = brandData['data'] ?? [];
        final List<dynamic> modelsList = modelData['data'] ?? [];
        final List<dynamic> yearsList = yearData['data'] ?? [];

        final List<Map<String, dynamic>> tempBrands = brandsList.map((item) {
          return {
            "id": item['brand_id'] ?? item['id'],
            "name": item['brand_name'] ?? item['name'],
          };
        }).toList();

        final Map<int, List<String>> tempBrandModels = {};
        for (var item in modelsList) {
          final int? brandId = item['brand_id'];
          final String? modelName = item['model_name'];
          if (brandId != null && modelName != null) {
            if (!tempBrandModels.containsKey(brandId)) {
              tempBrandModels[brandId] = [];
            }
            if (!tempBrandModels[brandId]!.contains(modelName)) {
              tempBrandModels[brandId]!.add(modelName);
            }
          }
        }

        final List<String> tempYears = yearsList.map((item) {
          return (item['year'] ?? '').toString();
        }).where((y) => y.isNotEmpty).toList();

        // Sort years descending
        tempYears.sort((a, b) => b.compareTo(a));

        if (mounted) {
          setState(() {
            _brands = tempBrands;
            _brandModels = tempBrandModels;
            _years = tempYears;
            _isLoadingMetaData = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMetaData = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching vehicle meta data: $e");
      if (mounted) {
        setState(() {
          _isLoadingMetaData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final payload = {
        "cus_firstname": _firstNameController.text.trim(),
        "cus_lastname": _lastNameController.text.trim(),
        "cus_phone": _phoneController.text.trim(),
        "veh_licenseplate": _licensePlateController.text.trim(),
        "brand_id": _selectedBrandId,
        "veh_model": _selectedModel,
        "veh_year": _selectedYear,
        "veh_color": _colorController.text.trim(),
      };

      try {
        final response = await AppAPI.post('/addnewcustomer', payload);
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 201 && responseData['isError'] == false) {
          if (mounted) {
            Navigator.pop(context, _licensePlateController.text.trim());
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ฟังก์ชันช่วยสร้างช่องกรอกข้อมูลข้อความธรรมดา
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (value) => value!.trim().isEmpty ? 'กรุณากรอก$label' : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มข้อมูลลูกค้าและรถ')),
      body: _isLoadingMetaData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  _buildSectionTitle('กรอกข้อมูลลูกค้า'),
                  _buildInputField(controller: _firstNameController, label: 'ชื่อ'),
                  _buildInputField(controller: _lastNameController, label: 'นามสกุล'),
                  _buildInputField(
                    controller: _phoneController, 
                    label: 'เบอร์', 
                    keyboardType: TextInputType.phone,
                  ),

                  _buildSectionTitle('กรอกข้อมูลรถ'),
                  _buildInputField(controller: _licensePlateController, label: 'ทะเบียนรถ'),
                  
                  // เปลี่ยนส่วนยี่ห้อรถเป็น Dropdown เพื่อดึง brand_id
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ยี่ห้อรถ', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedBrandId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _brands.map((brand) {
                            return DropdownMenuItem<int>(
                              value: brand['id'] as int,
                              child: Text(brand['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBrandId = value;
                              _selectedModel = null; // รีเซ็ตรุ่นรถเมื่อเปลี่ยนยี่ห้อ
                            });
                          },
                          validator: (value) => value == null ? 'กรุณาเลือกยี่ห้อรถ' : null,
                        ),
                      ],
                    ),
                  ),

                  // เปลี่ยนส่วนรุ่นเป็น Dropdown (กรองตาม brand_id)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('รุ่น', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedModel,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _filteredModels.map((model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
                          onChanged: _selectedBrandId == null ? null : (value) {
                            setState(() {
                              _selectedModel = value;
                            });
                          },
                          validator: (value) => value == null ? 'กรุณาเลือกรุ่น' : null,
                        ),
                      ],
                    ),
                  ),

                  // เปลี่ยนส่วนปีรถเป็น Dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ปีรถ', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedYear,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _years.map((year) {
                            return DropdownMenuItem<String>(
                              value: year,
                              child: Text(year),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedYear = value;
                            });
                          },
                          validator: (value) => value == null ? 'กรุณาเลือกปีรถ' : null,
                        ),
                      ],
                    ),
                  ),

                  _buildInputField(controller: _colorController, label: 'สีรถ'),

                  const SizedBox(height: 20),

                  // ปุ่มบันทึกข้อมูล
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF2EE),
                              foregroundColor: const Color(0xFF588B5B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'บันทึกข้อมูล',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                ],
              ),
            )
    );
  }
}
