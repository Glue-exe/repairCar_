import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/models/priority_model.dart';
import 'package:my_app/widgets/image_widget.dart';

class CreateOrderScreen extends StatefulWidget {
  final VehicleSearchResultModel vehicle;

  const CreateOrderScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final TextEditingController _symptomController = TextEditingController();

  int? _priorityId;
  List<PriorityModel> _priorityList = [];
  XFile? _imageFile;
  String _errorMessage = '';
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _getPriorities();
  }

  Future<void> _loadCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> _getPriorities() async {
    try {
      final response = await AppAPI.get('/priority');
      final Map<String, dynamic> resJson = jsonDecode(response.body);
      final priorityRes = PriorityResponse.fromJson(resJson);

      if (priorityRes.isError == false) {
        setState(() {
          _priorityList = priorityRes.data;
          if (_priorityList.isNotEmpty) {
            _priorityId = _priorityList.first.id;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลระดับความเร่งด่วนได้';
      });
    }
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _saveOrder() async {
    final symptom = _symptomController.text.trim();

    if (symptom.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกอาการเสียหรือรายการที่ต้องการซ่อม';
      });
      return;
    }

    if (_priorityId == null) {
      setState(() {
        _errorMessage = 'กรุณาเลือกระดับความเร่งด่วน';
      });
      return;
    }

    if (_currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      if (_currentUserId == null) {
        setState(() {
          _errorMessage = 'ไม่พบข้อมูลผู้ใช้งาน กรุณาเข้าสู่ระบบใหม่';
        });
        return;
      }
    }

    try {
      List<String> images = [];
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        images.add(base64Encode(bytes));
      }

      final response = await AppAPI.post('/create_order', {
        'o_vehicle_id': widget.vehicle.vId,
        'o_symptom': symptom,
        'o_priority_id': _priorityId,
        'o_order_status_id': 1,
        'o_created_by_account_id': _currentUserId!,
        'images': images,
      });

      final Map<String, dynamic> resJson = jsonDecode(response.body);

      if (resJson['isError'] == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('สร้างใบรับซ่อมสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = resJson['errorMessage'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเชื่อมต่อระบบได้';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างใบรับซ่อม'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนที่ 1: สรุปข้อมูลรถที่รับซ่อม
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลรถที่รับซ่อม',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('ทะเบียน: ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(widget.vehicle.licensePlate),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('ยี่ห้อ/รุ่น: ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                            '${widget.vehicle.brandName} ${widget.vehicle.modelName}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('เจ้าของรถ: ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(widget.vehicle.fullName),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ส่วนที่ 2: รายละเอียดการรับซ่อม
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'รายละเอียดการรับซ่อม',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _symptomController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'อาการเสีย / รายการที่ต้องซ่อม *',
                        alignLabelWithHint: true,
                        hintText:
                            'ระบุอาการเสีย หรือสิ่งที่ลูกค้าแจ้ง เช่น เครื่องสั่น, เปลี่ยนถ่ายน้ำมันเครื่อง',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ส่วนถ่ายรูป / แนบรูปภาพ
                    const Text(
                      'รูปถ่ายรถ / ชิ้นส่วนที่เสียหาย',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ImageWidget(
                        imageFile: _imageFile,
                        label: 'เพิ่มรูปภาพรถ / ชิ้นส่วนที่เสียหาย',
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
                    const SizedBox(height: 16),

                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'ระดับความเร่งด่วน',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          hint: const Text('เลือกระดับความเร่งด่วน'),
                          value: _priorityId,
                          isExpanded: true,
                          items: _priorityList.map((item) {
                            return DropdownMenuItem<int>(
                              value: item.id,
                              child: Text(item.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _priorityId = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _saveOrder,
                child: const Text('บันทึกใบรับซ่อม'),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
