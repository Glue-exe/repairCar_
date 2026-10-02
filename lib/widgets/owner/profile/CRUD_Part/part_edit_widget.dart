import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Part/part_shared_widgets/part_compatibility_section_widget.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Part/part_shared_widgets/part_general_info_section_widget.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Part/part_shared_widgets/part_image_section_widget.dart';

class PartEditWidget extends StatefulWidget {
  final PartModel part;
  final VoidCallback? onRefresh;

  const PartEditWidget({
    super.key,
    required this.part,
    this.onRefresh,
  });

  @override
  State<PartEditWidget> createState() => _PartEditWidgetState();
}

class _PartEditWidgetState extends State<PartEditWidget> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _partCodeController;
  late TextEditingController _partNameController;
  late TextEditingController _partPriceController;

  XFile? _imageFile;
  String? _imageUrl;

  List<Map<String, dynamic>> _vehicleModels = [];
  final List<SelectedVehicleModel> _selectedModels = [];
  bool _isLoadingModels = false;

  List<Map<String, dynamic>> _partCategories = [];
  int? _selectedCategoryId;

  List<Map<String, dynamic>> _partBrands = [];
  int? _selectedBrandId;

  bool _isSaving = false;

  final List<String> _unitOptions = [
    'ชิ้น',
    'ชุด',
    'คู่',
    'อัน',
    'เส้น',
    'ลิตร',
    'แกลลอน',
    'ขวด',
    'กระป๋อง',
    'หลอด',
    'กล่อง',
    'เมตร',
  ];
  String _selectedUnit = 'ชิ้น';

  @override
  void initState() {
    super.initState();
    _partCodeController = TextEditingController(text: widget.part.partCode);
    _partNameController = TextEditingController(text: widget.part.name);
    _partPriceController = TextEditingController(
      text: widget.part.partPrice.toStringAsFixed(2),
    );

    if (widget.part.unit.trim().isNotEmpty) {
      _selectedUnit = widget.part.unit.trim();
      if (!_unitOptions.contains(_selectedUnit)) {
        _unitOptions.add(_selectedUnit);
      }
    } else {
      _selectedUnit = 'ชิ้น';
    }

    _selectedCategoryId = widget.part.category;
    _selectedBrandId = widget.part.brand;
    _imageUrl = widget.part.url;

    // เติมรุ่นรถเดิมที่เคยเลือกรองรับไว้
    if (widget.part.compatibleModels.isNotEmpty) {
      for (var compat in widget.part.compatibleModels) {
        _selectedModels.add(SelectedVehicleModel.fromCompatible(compat));
      }
    } else if (widget.part.vehModelId != null) {
      _selectedModels.add(
        SelectedVehicleModel(
          modelId: widget.part.vehModelId!,
          modelName: widget.part.modelName ?? '',
          brandName: widget.part.vehicleBrandName ?? '',
          yearFrom: widget.part.yearFrom,
          yearTo: widget.part.yearTo,
        ),
      );
    }

    _fetchVehicleModels();
    _fetchCategories();
    _fetchPartBrands();
  }

  Future<List<Map<String, dynamic>>> _fetchDropdownData(String endpoint) async {
    try {
      final response = await AppAPI.get(endpoint);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['isError'] == false && data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching $endpoint: $e');
    }
    return [];
  }

  Future<void> _fetchVehicleModels() async {
    setState(() {
      _isLoadingModels = true;
    });
    final list = await _fetchDropdownData('/vehicle_model');
    if (mounted) {
      setState(() {
        _vehicleModels = list;
        _isLoadingModels = false;

        // เสริมชื่อรุ่น/ยี่ห้อให้ครบถ้วนในกรณีที่โหลดมาใหม่
        for (int i = 0; i < _selectedModels.length; i++) {
          _selectedModels[i] = _selectedModels[i].enriched(_vehicleModels);
        }
      });
    }
  }

  Future<void> _fetchCategories() async {
    final list = await _fetchDropdownData('/category');
    if (mounted) {
      setState(() {
        _partCategories = list;
      });
    }
  }

  Future<void> _fetchPartBrands() async {
    final list = await _fetchDropdownData('/brand');
    if (mounted) {
      setState(() {
        _partBrands = list;
      });
    }
  }

  @override
  void dispose() {
    _partCodeController.dispose();
    _partNameController.dispose();
    _partPriceController.dispose();
    super.dispose();
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final bool? confirm = await showDialog<bool>(
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
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );

    return confirm ?? false;
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      for (var m in _selectedModels) {
        if (m.isYearRangeInvalid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'รุ่น ${m.displayName}: ปีสิ้นสุด (${m.yearTo}) ต้องไม่น้อยกว่าปีเริ่มต้น (${m.yearFrom})',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      final bool confirm = await _showConfirmDialog(
        'ยืนยันการแก้ไขข้อมูล',
        'คุณแน่ใจหรือไม่ว่าต้องการบันทึกการแก้ไขนี้?',
      );

      if (confirm) {
        setState(() {
          _isSaving = true;
        });

        try {
          final Map<String, String> fields = {
            'part_id': widget.part.id.toString(),
            'part_code': _partCodeController.text.trim(),
            'part_name': _partNameController.text.trim(),
            'part_price': _partPriceController.text.trim(),
            'unit': _selectedUnit.trim(),
            'part_category_id': _selectedCategoryId?.toString() ?? '',
            'part_brand_id': _selectedBrandId?.toString() ?? '',
            'part_url': _imageUrl ?? '',
            'veh_model_ids': jsonEncode(_selectedModels.map((m) => m.toJson()).toList()),
          };

          final response = await AppAPI.putMultipart(
            '/putPart',
            fields: fields,
            file: _imageFile,
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> resJson = jsonDecode(response.body);
            if (resJson['isError'] == false) {
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('แก้ไขข้อมูลอะไหล่สำเร็จ'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              }
            } else {
              final errMsg = resJson['errorMessage']?.toString() ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล';
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('บันทึกไม่สำเร็จ: $errMsg'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('เซิร์ฟเวอร์ตอบกลับผิดพลาด (HTTP ${response.statusCode})'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลอะไหล่'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PartImageSectionWidget(
                imageFile: _imageFile,
                imageUrl: _imageUrl,
                onImageSelected: (file) {
                  setState(() {
                    _imageFile = file;
                  });
                },
                onImageRemoved: () {
                  setState(() {
                    _imageFile = null;
                    _imageUrl = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              PartGeneralInfoSectionWidget(
                partCodeController: _partCodeController,
                partNameController: _partNameController,
                partPriceController: _partPriceController,
                partBrands: _partBrands,
                selectedBrandId: _selectedBrandId,
                onBrandChanged: (val) {
                  setState(() {
                    _selectedBrandId = val;
                  });
                },
                partCategories: _partCategories,
                selectedCategoryId: _selectedCategoryId,
                onCategoryChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
                unitOptions: _unitOptions,
                selectedUnit: _selectedUnit,
                onUnitChanged: (val) {
                  setState(() {
                    _selectedUnit = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              PartCompatibilitySectionWidget(
                selectedModels: _selectedModels,
                vehicleModels: _vehicleModels,
                isLoadingModels: _isLoadingModels,
                onChanged: (updatedList) {
                  setState(() {
                    _selectedModels.clear();
                    _selectedModels.addAll(updatedList);
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving ? 'กำลังบันทึกการแก้ไข...' : 'บันทึกการแก้ไขข้อมูล',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSaving ? null : _saveData,
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
