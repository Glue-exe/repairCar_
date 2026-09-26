import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/image_widget.dart';

class PartAddScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const PartAddScreen({super.key, this.onRefresh});

  @override
  State<PartAddScreen> createState() => _PartAddScreenState();
}

class _PartAddScreenState extends State<PartAddScreen> {
  final _formKey = GlobalKey<FormState>();

  XFile? _imageFile;
  final TextEditingController _partNameController = TextEditingController();
  final TextEditingController _partPriceController = TextEditingController();

  List<Map<String, dynamic>> _vehicleModels = [];
  int? _selectedModelId;
  bool _isLoadingModels = false;

  List<Map<String, dynamic>> _partCategories = [];
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _partBrands = [];
  int? _selectedBrandId;

  @override
  void initState() {
    super.initState();
    _fetchVehicleModels();
    _fetchCategories();
    _fetchPartBrands();
  }

  void _fetchVehicleModels() async {
    setState(() {
      _isLoadingModels = true;
    });
    try {
      final response = await AppAPI.get('/vehicle_model');
      final Map<String, dynamic> resJson = jsonDecode(response.body);
      if (resJson['isError'] == false && resJson['data'] is List) {
        setState(() {
          _vehicleModels = List<Map<String, dynamic>>.from(resJson['data']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching vehicle models: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await AppAPI.get(
        '/category',
      ); // หรือ /part_category ก็ได้
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['isError'] == false && data['data'] != null) {
          setState(() {
            _partCategories = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchPartBrands() async {
    try {
      final response = await AppAPI.get('/brand');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['isError'] == false && data['data'] != null) {
          setState(() {
            _partBrands = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      print('Error fetching part brands: $e');
    }
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _partPriceController.dispose();
    super.dispose();
  }

  // ตรวจสอบข้อมูลบังคับกรอกทั่วไป
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกข้อมูลให้ครบ';
    }
    return null;
  }

  // Alert ยืนยัน
  Future<bool> _showConfirmDialog(String title, String message) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
    return confirm == true;
  }

  // บันทึกการเพิ่มข้อมูล
  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      bool confirm = await _showConfirmDialog(
        'ยืนยันการเพิ่มข้อมูล',
        'คุณต้องการยืนยันการเพิ่มข้อมูลอะไหล่หรือไม่?',
      );

      if (confirm) {
        Map<String, String> fields = {
          'part_name': _partNameController.text.trim(),
          'part_price': _partPriceController.text.trim(),
          'part_category_id': _selectedCategoryId.toString(),
          'part_brand_id': _selectedBrandId.toString(),
          'veh_model_id': _selectedModelId.toString(),
        };

        await AppAPI.postMultipart(
          '/postPart',
          fields: fields,
          file: _imageFile,
        );

        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลอะไหล่'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ImageWidget(
                  imageFile: _imageFile,
                  label: 'เพิ่มรูปภาพอะไหล่',
                  onImageSelected: (file) {
                    setState(() {
                      _imageFile = file;
                    });
                  },
                  onImageRemoved: () {
                    setState(() {
                      _imageFile = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ข้อมูลอะไหล่',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // ชื่ออะไหล่
              TextFormField(
                controller: _partNameController,
                validator: _validateRequired,
                decoration: const InputDecoration(
                  labelText: 'ชื่ออะไหล่ *',
                  hintText: 'กรอกชื่ออะไหล่',
                  prefixIcon: Icon(Icons.build_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ยี่ห้อ
              DropdownButtonFormField<int>(
                initialValue: _selectedBrandId,
                decoration: const InputDecoration(
                  labelText: 'ยี่ห้ออะไหล่ *',
                  hintText: 'เลือกยี่ห้ออะไหล่',
                  prefixIcon: Icon(Icons.branding_watermark_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: _partBrands.map((item) {
                  final id = item['pb_id'] ?? item['id'];
                  final name = item['pb_name'] ?? item['name'] ?? '';
                  return DropdownMenuItem<int>(
                    value: id is int ? id : int.parse(id.toString()),
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedBrandId = val;
                  });
                },
                validator: (val) =>
                    val == null ? 'กรุณาเลือกยี่ห้ออะไหล่' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่อะไหล่ *',
                  hintText: 'เลือกหมวดหมู่อะไหล่',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: _partCategories.map((item) {
                  final id = item['pc_id'] ?? item['id'];
                  final name = item['pc_name'] ?? item['name'] ?? '';
                  return DropdownMenuItem<int>(
                    value: id is int ? id : int.parse(id.toString()),
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
                validator: (val) =>
                    val == null ? 'กรุณาเลือกหมวดหมู่อะไหล่' : null,
              ),
              const SizedBox(height: 16),

              _isLoadingModels
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: _selectedModelId,
                      decoration: const InputDecoration(
                        labelText: 'รุ่นรถที่รองรับ (Model) *',
                        hintText: 'เลือกรุ่นรถที่รองรับ',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: _vehicleModels.map((item) {
                        final id = item['veh_model_id'] ?? item['id'];
                        final brand = item['brand_name'] ?? '';
                        final model = item['model_name'] ?? item['name'] ?? '';
                        return DropdownMenuItem<int>(
                          value: id is int ? id : int.parse(id.toString()),
                          child: Text(
                            brand.isNotEmpty ? '$brand - $model' : model,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedModelId = val;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'กรุณาเลือกรุ่นรถ' : null,
                    ),
              const SizedBox(height: 16),

              // ราคา
              TextFormField(
                controller: _partPriceController,
                validator: _validateRequired,
                maxLength: 10,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'ราคา (บาท) *',
                  hintText: 'กรอกราคาอะไหล่',
                  counterText: '',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ปุ่มบันทึกข้อมูล
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'บันทึกข้อมูล',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveData,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
