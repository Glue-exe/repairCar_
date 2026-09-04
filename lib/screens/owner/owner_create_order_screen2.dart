import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/models/vehicle_search_license_plate_model.dart';
import 'package:my_app/models/priority_model.dart';

class OwnerCreateOrderScreen2 extends StatefulWidget {
  final VehicleSearchResultModel vehicle;

  const OwnerCreateOrderScreen2({
    super.key,
    required this.vehicle,
  });

  @override
  State<OwnerCreateOrderScreen2> createState() => _OwnerCreateOrderScreen2State();
}

class _OwnerCreateOrderScreen2State extends State<OwnerCreateOrderScreen2> {
  final TextEditingController _symptomController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int? _priorityId;
  List<PriorityModel> _priorityList = [];
  final List<String> _base64Images = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getPriorities();
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

  // ฟังก์ชันถ่ายรูป หรือเลือกรูป
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _base64Images.add(base64String);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเปิดกล้องหรือเลือกรูปได้';
      });
    }
  }

  // แสดงตัวเลือกว่าจะถ่ายรูป หรือเลือกจากคลังรูป
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากคลังภาพ'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
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

    try {
      final response = await AppAPI.post('/create_order', {
        'o_vehicle_id': widget.vehicle.vId,
        'o_symptom': symptom,
        'o_priority_id': _priorityId,
        'o_order_status_id': 1,
        'o_created_by_account_id': 1,
        'images': _base64Images, // ส่งรายการรูปภาพไปยัง TABLE order_image
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
            // สรุปข้อมูลรถที่รับซ่อม
            Card(
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.directions_car),
                ),
                title: Text('ทะเบียน: ${widget.vehicle.licensePlate}'),
                subtitle: Text(
                  '${widget.vehicle.brandName} ${widget.vehicle.modelName}\n'
                  'เจ้าของรถ: ${widget.vehicle.fullName}',
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'อาการเสีย / รายการที่ต้องซ่อม *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _symptomController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'ระบุอาการเสีย หรือสิ่งที่ลูกค้าแจ้ง เช่น เครื่องสั่น, เปลี่ยนถ่ายน้ำมันเครื่อง',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ส่วนถ่ายรูป / แนบรูปภาพ
            const Text(
              'รูปถ่ายรถ / ชิ้นส่วนที่เสียหาย',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // แสดงรายการรูปที่ถ่าย
            if (_base64Images.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _base64Images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_base64Images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _base64Images.removeAt(index);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            OutlinedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.camera_alt),
              label: const Text('ถ่ายรูป / เพิ่มรูปภาพ'),
            ),
            const SizedBox(height: 16),

            const Text(
              'ระดับความเร่งด่วน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: ValueKey(_priorityId),
              initialValue: _priorityId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              hint: const Text('เลือกระดับความเร่งด่วน'),
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
            const SizedBox(height: 24),

            Center(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveOrder,
                  icon: const Icon(Icons.save),
                  label: const Text('บันทึกใบรับซ่อม', style: TextStyle(fontSize: 16)),
                ),
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
