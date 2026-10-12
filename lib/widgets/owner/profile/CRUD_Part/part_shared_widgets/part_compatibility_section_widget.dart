import 'package:flutter/material.dart';
import 'package:my_app/models/part_model.dart';

class PartCompatibilitySectionWidget extends StatelessWidget {
  final List<SelectedVehicleModel> selectedModels;
  final List<Map<String, dynamic>> vehicleModels;
  final bool isLoadingModels;
  final ValueChanged<List<SelectedVehicleModel>> onChanged;

  const PartCompatibilitySectionWidget({
    super.key,
    required this.selectedModels,
    required this.vehicleModels,
    required this.isLoadingModels,
    required this.onChanged,
  });

  /// คำนวณช่วงปี ค.ศ. อัตโนมัติ (ตั้งแต่ปีปัจจุบัน + 1 ย้อนหลังไปถึง 1980)
  List<int> get _availableYears {
    final int currentYear = DateTime.now().year;
    List<int> years = [];
    for (int y = currentYear + 1; y >= 1980; y--) {
      years.add(y);
    }
    return years;
  }

  /// เปิด Dialog เลือกรุ่นรถและแปลงผลลัพธ์เป็น SelectedVehicleModel โดยอัตโนมัติ
  Future<void> _handleSelectModels(BuildContext context) async {
    final currentSelectedIds = selectedModels.map((m) => m.modelId).toList();
    final List<int>? selectedIds = await PartVehicleSelectDialog.show(
      context,
      vehicleModels: vehicleModels,
      initialSelectedModelIds: currentSelectedIds,
      isLoadingModels: isLoadingModels,
    );

    if (selectedIds != null) {
      List<SelectedVehicleModel> updatedList = [];
      for (int id in selectedIds) {
        // ถ้ารุ่นนี้มีอยู่ในรายการเดิมแล้ว ให้เก็บค่าปีเดิมไว้
        SelectedVehicleModel? existing;
        for (var m in selectedModels) {
          if (m.modelId == id) {
            existing = m;
            break;
          }
        }

        if (existing != null) {
          updatedList.add(existing);
        } else {
          // หากเป็นรุ่นใหม่ ให้ค้นหาชื่อแบรนด์และรุ่นจาก vehicleModels
          Map<String, dynamic> found = {};
          for (var vm in vehicleModels) {
            final vmId = vm['vm_id'] as int;
            if (vmId == id) {
              found = vm;
              break;
            }
          }
          final brand = (found['vb_name'] ?? '').toString();
          final model = (found['vm_name'] ?? '').toString();
          updatedList.add(
            SelectedVehicleModel(
              modelId: id,
              modelName: model,
              brandName: brand,
              yearFrom: null,
              yearTo: null,
            ),
          );
        }
      }
      onChanged(updatedList);
    }
  }

  void _removeModel(int index) {
    final updatedList = List<SelectedVehicleModel>.from(selectedModels);
    updatedList.removeAt(index);
    onChanged(updatedList);
  }

  void _updateYearFrom(int index, int? val) {
    final updatedList = List<SelectedVehicleModel>.from(selectedModels);
    final current = updatedList[index];
    updatedList[index] = SelectedVehicleModel(
      modelId: current.modelId,
      modelName: current.modelName,
      brandName: current.brandName,
      yearFrom: val,
      yearTo: current.yearTo,
    );
    onChanged(updatedList);
  }

  void _updateYearTo(int index, int? val) {
    final updatedList = List<SelectedVehicleModel>.from(selectedModels);
    final current = updatedList[index];
    updatedList[index] = SelectedVehicleModel(
      modelId: current.modelId,
      modelName: current.modelName,
      brandName: current.brandName,
      yearFrom: current.yearFrom,
      yearTo: val,
    );
    onChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final years = _availableYears;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'รุ่นรถและช่วงปีที่รองรับ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (selectedModels.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Text(
                      '${selectedModels.length} รุ่น',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _handleSelectModels(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('เลือกรุ่นรถ', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 20),

            if (selectedModels.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.all_inclusive,
                        size: 36,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'อะไหล่ทั่วไป',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ถ้าเป็นอะไหล่ทั่วไปไม่จำเป็นต้องเลือกรุ่นที่รองรับ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _handleSelectModels(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('ระบุรุ่นรถเฉพาะ (ถ้ามี)'),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedModels.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
                itemBuilder: (context, index) {
                  final modelItem = selectedModels[index];
                  final isInvalidYear = modelItem.isYearRangeInvalid;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isInvalidYear
                          ? Colors.red.shade50.withValues(alpha: 0.3)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isInvalidYear
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                        width: isInvalidYear ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isInvalidYear
                                    ? Colors.red.shade50
                                    : Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_car,
                                size: 16,
                                color: isInvalidYear
                                    ? Colors.redAccent
                                    : Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modelItem.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: Colors.redAccent,
                              tooltip: 'ลบรุ่นนี้',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _removeModel(index);
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'ช่วงปีที่รองรับเฉพาะรุ่นนี้:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // ปีเริ่มต้น
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              key: ValueKey('from_${modelItem.modelId}_${modelItem.yearFrom}'),
                              initialValue: modelItem.yearFrom,
                              isExpanded: true,
                              menuMaxHeight: 280,
                              decoration: InputDecoration(
                                labelText: 'ปีเริ่มต้น',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isInvalidYear
                                        ? Colors.red.shade300
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('ไม่ระบุ', style: TextStyle(fontSize: 13)),
                                ),
                                ...years.map((int y) {
                                  return DropdownMenuItem<int?>(
                                    value: y,
                                    child: Text(y.toString(), style: const TextStyle(fontSize: 13)),
                                  );
                                }),
                              ],
                              onChanged: (int? val) {
                                _updateYearFrom(index, val);
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('ถึง', style: TextStyle(color: Colors.grey)),
                          ),
                          // ถึงปี
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              key: ValueKey('to_${modelItem.modelId}_${modelItem.yearTo}'),
                              initialValue: modelItem.yearTo,
                              isExpanded: true,
                              menuMaxHeight: 280,
                              decoration: InputDecoration(
                                labelText: 'ถึงปี (สิ้นสุด)',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isInvalidYear
                                        ? Colors.red.shade300
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('ไม่ระบุ', style: TextStyle(fontSize: 13)),
                                ),
                                ...years.map((int y) {
                                  return DropdownMenuItem<int?>(
                                    value: y,
                                    child: Text(y.toString(), style: const TextStyle(fontSize: 13)),
                                  );
                                }),
                              ],
                              onChanged: (int? val) {
                                _updateYearTo(index, val);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (isInvalidYear) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'ปีสิ้นสุด (${modelItem.yearTo}) ต้องมากกว่าหรือเท่ากับปีเริ่มต้น (${modelItem.yearFrom})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
  }
}

/// Dialog ค้นหาและติ๊กเลือกรุ่นรถที่รองรับแบบหลายรายการ (Multi-select)
class PartVehicleSelectDialog extends StatefulWidget {
  final List<Map<String, dynamic>> vehicleModels;
  final List<int> initialSelectedModelIds;
  final bool isLoadingModels;

  const PartVehicleSelectDialog({
    super.key,
    required this.vehicleModels,
    required this.initialSelectedModelIds,
    required this.isLoadingModels,
  });

  static Future<List<int>?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> vehicleModels,
    required List<int> initialSelectedModelIds,
    required bool isLoadingModels,
  }) {
    return showDialog<List<int>>(
      context: context,
      builder: (context) {
        return PartVehicleSelectDialog(
          vehicleModels: vehicleModels,
          initialSelectedModelIds: initialSelectedModelIds,
          isLoadingModels: isLoadingModels,
        );
      },
    );
  }

  @override
  State<PartVehicleSelectDialog> createState() => _PartVehicleSelectDialogState();
}

class _PartVehicleSelectDialogState extends State<PartVehicleSelectDialog> {
  late List<int> _tempSelectedIds;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = List<int>.from(widget.initialSelectedModelIds);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = [];
    if (_searchKeyword.trim().isEmpty) {
      filteredList = List.from(widget.vehicleModels);
    } else {
      final q = _searchKeyword.trim().toLowerCase();
      for (var item in widget.vehicleModels) {
        final brand = (item['vb_name'] ?? '').toString().toLowerCase();
        final model = (item['vm_name'] ?? '').toString().toLowerCase();
        final full = '$brand $model';
        if (brand.contains(q) || model.contains(q) || full.contains(q)) {
          filteredList.add(item);
        }
      }
    }

    Widget dialogContent;
    if (widget.isLoadingModels) {
      dialogContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (filteredList.isEmpty) {
      dialogContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'ไม่พบรุ่นรถที่ค้นหา',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    } else {
      dialogContent = ListView.builder(
        shrinkWrap: true,
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final item = filteredList[index];
          final idInt = item['vm_id'] as int;

          final brand = (item['vb_name'] ?? '').toString();
          final model = (item['vm_name'] ?? '').toString();
          final displayName = brand.isNotEmpty ? '$brand - $model' : model;
          final isChecked = _tempSelectedIds.contains(idInt);

          return CheckboxListTile(
            dense: true,
            title: Text(
              displayName,
              style: const TextStyle(fontSize: 14),
            ),
            value: isChecked,
            activeColor: Theme.of(context).colorScheme.primary,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? checked) {
              setState(() {
                if (checked == true) {
                  if (!_tempSelectedIds.contains(idInt)) {
                    _tempSelectedIds.add(idInt);
                  }
                } else {
                  _tempSelectedIds.remove(idInt);
                }
              });
            },
          );
        },
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_outlined, size: 22),
              const SizedBox(width: 8),
              const Text(
                'เลือกรุ่นรถที่รองรับ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'เลือกได้หลายรุ่น (กำหนดช่วงปีเฉพาะแต่ละรุ่นได้ในหน้าจอหลัก)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'ค้นหารุ่นรถ หรือ ยี่ห้อ...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (text) {
              setState(() {
                _searchKeyword = text;
              });
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: dialogContent,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _tempSelectedIds);
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _tempSelectedIds.isEmpty
                ? 'ตกลง (อะไหล่ทั่วไป)'
                : 'ตกลง (${_tempSelectedIds.length})',
          ),
        ),
      ],
    );
  }
}
