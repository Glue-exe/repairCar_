import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/screens/owner/profile/part/part_add_screen.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Part/part_list_del_widget.dart';

class OwnerPartScreen extends StatefulWidget {
  const OwnerPartScreen({super.key});

  @override
  State<OwnerPartScreen> createState() => _OwnerPartScreenState();
}

class _OwnerPartScreenState extends State<OwnerPartScreen> {
  List<PartModel> partModelStore = [];
  List<PartModel> filteredParts = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  void _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var response = await AppAPI.get("/getPart");
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        PartResponse partResponse = PartResponse.fromJson(json);

        if (mounted == false) {
          return;
        }

        if (partResponse.isError == true) {
          String errMsg;
          if (partResponse.errorMessage.isNotEmpty == true) {
            errMsg = partResponse.errorMessage;
          } else {
            errMsg = "เกิดข้อผิดพลาดในการโหลดข้อมูลอะไหล่";
          }

          setState(() {
            _errorMessage = errMsg;
            _isLoading = false;
          });
        } else {
          setState(() {
            partModelStore = partResponse.data;
            _filterParts(_searchController.text);
            _isLoading = false;
          });
        }
      } else {
        if (mounted == false) {
          return;
        }
        setState(() {
          _errorMessage = "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ (Status: ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted == false) {
        return;
      }
      setState(() {
        _errorMessage = "เกิดข้อผิดพลาด: $e";
        _isLoading = false;
      });
    }
  }

  // ฟังก์ชันค้นหาอะไหล่ รองรับการค้นหาได้ทั้งหมด 7 อย่างในช่องค้นหาเดียว:
  // 1. ชื่ออะไหล่ เช่น "ผ้าเบรกหน้า", "ไส้กรองน้ำมันเครื่อง"
  // 2. รหัสอะไหล่ / เบอร์ OEM ข้างกล่อง เช่น "DB1436", "0986AF0029"
  // 3. ยี่ห้ออะไหล่ เช่น "Bosch", "Brembo", "Castrol"
  // 4. หมวดหมู่อะไหล่ เช่น "ระบบเบรก", "ของเหลวและสารหล่อลื่น"
  // 5. ชื่อรุ่นรถยนต์ที่รองรับ เช่น "Vios", "Yaris", "Civic", "D-Max"
  // 6. ยี่ห้อรถยนต์ เช่น "Toyota", "Honda", "Isuzu"
  // 7. ช่วงปี ค.ศ. ของรุ่นรถที่รองรับ เช่น "2008", "2012" (ผ่าน compatibleModelsSummary)
  void _filterParts(String query) {
    String q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty == true) {
        filteredParts = List.from(partModelStore);
      } else {
        filteredParts = partModelStore.where((item) {
          // 1. ค้นหาจากชื่ออะไหล่
          final nameMatch = item.name.toLowerCase().contains(q);

          // 2. ค้นหาจากรหัสอะไหล่ / เบอร์ OEM
          final codeMatch = item.partCode.toLowerCase().contains(q);

          // 3. ค้นหาจากยี่ห้ออะไหล่
          String brandText = '';
          if (item.partBrandName != null) {
            brandText = item.partBrandName!;
          }
          final brandMatch = brandText.toLowerCase().contains(q);

          // 4. ค้นหาจากหมวดหมู่อะไหล่
          String categoryText = '';
          if (item.partCategoryName != null) {
            categoryText = item.partCategoryName!;
          }
          final categoryMatch = categoryText.toLowerCase().contains(q);

          // 5. ค้นหาจากชื่อรุ่นรถ (รุ่นเดี่ยว)
          String modelText = '';
          if (item.modelName != null) {
            modelText = item.modelName!;
          }
          final modelMatch = modelText.toLowerCase().contains(q);

          // 6. ค้นหาจากยี่ห้อรถยนต์
          String vehBrandText = '';
          if (item.vehicleBrandName != null) {
            vehBrandText = item.vehicleBrandName!;
          }
          final vehBrandMatch = vehBrandText.toLowerCase().contains(q);

          // 7. ค้นหาจากรุ่นรถทั้งหมดและช่วงปี ค.ศ. ที่รองรับ
          final compatMatch = item.compatibleModelsSummary.toLowerCase().contains(q);

          if (nameMatch == true ||
              codeMatch == true ||
              brandMatch == true ||
              categoryMatch == true ||
              modelMatch == true ||
              vehBrandMatch == true ||
              compatMatch == true) {
            return true;
          } else {
            return false;
          }
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดปุ่ม suffix สำหรับเคลียร์ข้อความค้นหา (ขนาดใหญ่ กดง่าย)
    Widget? suffixIconWidget;
    if (_searchController.text.isNotEmpty == true) {
      suffixIconWidget = IconButton(
        icon: const Icon(Icons.clear, size: 22),
        onPressed: () {
          _searchController.clear();
          _filterParts('');
        },
      );
    } else {
      suffixIconWidget = null;
    }

    // กำหนดข้อความแสดงสถานะการค้นหาข้างแถบสรุป (ขนาดใหญ่ ชัดเจน)
    Widget searchResultTextWidget;
    if (_searchController.text.isNotEmpty == true) {
      searchResultTextWidget = Text(
        'ผลการค้นหา "${_searchController.text}"',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.teal.shade800,
        ),
      );
    } else {
      searchResultTextWidget = const SizedBox.shrink();
    }

    // กำหนดเนื้อหาหลักของหน้าจอแบบแยกกรณีชัดเจน พร้อมขนาดตัวอักษรและปุ่มขนาดใหญ่
    Widget mainContent;
    if (_isLoading == true) {
      mainContent = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_errorMessage != null) {
      mainContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 54, color: Colors.red),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                onPressed: () {
                  _fetchData();
                },
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('ลองใหม่อีกครั้ง', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
      );
    } else if (filteredParts.isEmpty == true) {
      String emptyText;
      if (_searchController.text.isNotEmpty == true) {
        emptyText = 'ไม่พบอะไหล่ที่ตรงกับคำค้นหา';
      } else {
        emptyText = 'ยังไม่มีข้อมูลอะไหล่ในระบบ';
      }

      mainContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return PartAddScreen(onRefresh: _fetchData);
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 22),
              label: const Text('เพิ่มอะไหล่ใหม่', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    } else {
      mainContent = RefreshIndicator(
        onRefresh: () async {
          _fetchData();
        },
        child: PartListWidget(
          partModelStore: filteredParts,
          onRefresh: _fetchData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          'ข้อมูลอะไหล่',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 26),
            tooltip: 'เพิ่มอะไหล่',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return PartAddScreen(onRefresh: _fetchData);
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 26),
            tooltip: 'รีเฟรช',
            onPressed: () {
              _fetchData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // กล่องค้นหา (ปรับขนาดช่องและฟอนต์ให้ใหญ่ขึ้น 16px อ่านง่าย สบายตา)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filterParts,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อ, เบอร์อะไหล่, ยี่ห้อ, รุ่นรถ...',
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, size: 24),
                  suffixIcon: suffixIconWidget,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),

            // แถบสรุปจำนวน (ตัวหนังสือใหญ่ ชัดเจน 14.5px)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'รายการอะไหล่ทั้งหมด (${filteredParts.length} รายการ)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  searchResultTextWidget,
                ],
              ),
            ),

            // พื้นที่แสดงรายการ
            Expanded(
              child: mainContent,
            ),
          ],
        ),
      ),
    );
  }
}
