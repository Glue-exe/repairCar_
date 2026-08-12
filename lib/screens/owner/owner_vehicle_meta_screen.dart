import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/vehicle_edit_brand.dart';
import 'package:my_app/widgets/owner/profile/vehicle_edit_model.dart';

class OwnerVehicleMetaScreen extends StatefulWidget {
  const OwnerVehicleMetaScreen({super.key});

  @override
  State<OwnerVehicleMetaScreen> createState() => _OwnerVehicleMetaScreenState();
}

class _OwnerVehicleMetaScreenState extends State<OwnerVehicleMetaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _models = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchActiveTabData();
      }
    });
    _fetchActiveTabData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveTabData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_tabController.index == 0) {
        final res = await AppAPI.get('/vehicle_brand');
        final data = jsonDecode(res.body);
        if (data['isError'] == false) {
          setState(() {
            _brands = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      } else {
        final res = await AppAPI.get('/vehicle_model');
        final data = jsonDecode(res.body);
        if (data['isError'] == false) {
          setState(() {
            _models = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      print('Error fetching tab data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addNewItem() {
    if (_tabController.index == 0) {
      _showAddDialog(
        title: 'เพิ่มยี่ห้อรถยนต์',
        labelText: 'ชื่อยี่ห้อรถยนต์',
        onSubmit: (val) async {
          final res = await AppAPI.post('/vehicle_brand', {'brand_name': val});
          return jsonDecode(res.body)['isError'] == false;
        },
      );
    } else {
      _showAddModelDialog();
    }
  }

  void _showAddDialog({
    required String title,
    required String labelText,
    required Future<bool> Function(String) onSubmit,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final success = await onSubmit(controller.text.trim());
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  _fetchActiveTabData();
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _showAddModelDialog() async {
    final controller = TextEditingController();
    int? selectedBrandId;
    int? selectedYearId;
    List<Map<String, dynamic>> tempBrands = [];
    List<Map<String, dynamic>> tempYears = [];

    // load brands and years
    final responses = await Future.wait([
      AppAPI.get('/vehicle_brand'),
      AppAPI.get('/vehicle_year'),
    ]);
    
    final brandData = jsonDecode(responses[0].body);
    final yearData = jsonDecode(responses[1].body);

    if (brandData['isError'] == false) {
      tempBrands = List<Map<String, dynamic>>.from(brandData['data']);
    }
    if (yearData['isError'] == false) {
      tempYears = List<Map<String, dynamic>>.from(yearData['data']);
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('เพิ่มรุ่นรถยนต์'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'ยี่ห้อรถยนต์', border: OutlineInputBorder()),
                    initialValue: selectedBrandId,
                    items: tempBrands.map((b) {
                      return DropdownMenuItem<int>(
                        value: b['brand_id'],
                        child: Text(b['brand_name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedBrandId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'ชื่อรุ่นรถยนต์', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'ปีรุ่นรถยนต์ (Year)', border: OutlineInputBorder()),
                    initialValue: selectedYearId,
                    items: tempYears.map((y) {
                      return DropdownMenuItem<int>(
                        value: y['veh_year_id'],
                        child: Text((y['year'] ?? '').toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedYearId = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty || selectedBrandId == null || selectedYearId == null) return;
                  final res = await AppAPI.post('/vehicle_model', {
                    'model_name': controller.text.trim(),
                    'brand_id': selectedBrandId,
                    'veh_year_id': selectedYearId,
                  });
                  final success = jsonDecode(res.body)['isError'] == false;
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      _fetchActiveTabData();
                    }
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _deleteItem(String type, int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบข้อมูล'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      dynamic res;
      if (type == 'brand') {
        res = await AppAPI.delete('/vehicle_brand', {'brand_id': id});
      } else {
        res = await AppAPI.delete('/vehicle_model', {'veh_model_id': id});
      }

      if (jsonDecode(res.body)['isError'] == false) {
        _fetchActiveTabData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการข้อมูลรถยนต์'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ยี่ห้อ'),
            Tab(text: 'รุ่นรถยนต์'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewItem),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchActiveTabData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Brand List
                ListView.builder(
                  itemCount: _brands.length,
                  itemBuilder: (context, index) {
                    final item = _brands[index];
                    return ListTile(
                      title: Text(item['brand_name'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => VehicleEditBrand(brand: item)),
                              );
                              if (updated == true) _fetchActiveTabData();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem('brand', item['brand_id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Model List
                ListView.builder(
                  itemCount: _models.length,
                  itemBuilder: (context, index) {
                    final item = _models[index];
                    final String yearDisplay = item['veh_year'] != null ? " (${item['veh_year']})" : "";
                    return ListTile(
                      title: Text("${item['model_name'] ?? ''}$yearDisplay"),
                      subtitle: Text('ยี่ห้อ: ${item['brand_name'] ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => VehicleEditModel(vehicleModel: item)),
                              );
                              if (updated == true) _fetchActiveTabData();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem('model', item['veh_model_id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
