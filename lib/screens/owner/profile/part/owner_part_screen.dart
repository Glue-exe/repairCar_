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
  List<Map<String, dynamic>> _partCategories = [];
  int? _selectedCategoryId; // null = ทุกประเภทอะไหล่
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  // รายการหมวดหมู่ทั้งหมดสำหรับใส่ใน Select (ใช้จาก API หรือดึงจากรายการอะไหล่)
  List<Map<String, dynamic>> get _availableCategories {
    if (_partCategories.isNotEmpty) {
      return _partCategories;
    }
    final Map<int, String> categoryMap = {};
    for (var part in partModelStore) {
      if (part.partCategoryName != null && part.partCategoryName!.trim().isNotEmpty) {
        categoryMap[part.category] = part.partCategoryName!.trim();
      }
    }
    return categoryMap.entries
        .map((e) => {'pc_id': e.key, 'pc_name': e.value})
        .toList();
  }

  // ดึงข้อมูลอะไหล่และประเภทอะไหล่จาก API
  void _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. ดึงข้อมูลอะไหล่
      final response = await AppAPI.get("/getPart");

      // 2. ดึงข้อมูลประเภทอะไหล่ (ดักจับแยก ไม่ให้กระทบการโหลดข้อมูลอะไหล่หลัก)
      List<Map<String, dynamic>> categoriesList = [];
      try {
        final catRes = await AppAPI.get("/category");
        if (catRes.statusCode == 200) {
          final Map<String, dynamic> catJson = jsonDecode(catRes.body);
          if (catJson['isError'] == false && catJson['data'] is List) {
            categoriesList = List<Map<String, dynamic>>.from(catJson['data']);
          }
        }
      } catch (e) {
        debugPrint("Error fetching categories: $e");
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final PartResponse partResponse = PartResponse.fromJson(json);

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
            _partCategories = categoriesList;
            _filterParts();
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

  // Logic กรองข้อมูลอะไหล่:
  // 1. กรองตามประเภทอะไหล่ที่เลือกจาก Select (ถ้า _selectedCategoryId == null คือแสดงทุกประเภท)
  // 2. กรองตามคำค้นหา 7 ด้าน (ชื่อ, รหัส, ยี่ห้ออะไหล่, หมวดหมู่, รุ่นรถ, ยี่ห้อรถ, ช่วงปี ค.ศ.)
  void _filterParts([String? query]) {
    final String q = (query ?? _searchController.text).trim().toLowerCase();

    setState(() {
      filteredParts = partModelStore.where((item) {
        // เงื่อนไขที่ 1: กรองตามประเภทอะไหล่
        final bool categoryMatch =
            _selectedCategoryId == null || item.category == _selectedCategoryId;

        // เงื่อนไขที่ 2: กรองตามคำค้นหาในช่องค้นหา (ถ้ามี)
        bool queryMatch = true;
        if (q.isNotEmpty) {
          final nameMatch = item.name.toLowerCase().contains(q);
          final codeMatch = item.partCode.toLowerCase().contains(q);

          final String brandText = item.partBrandName ?? '';
          final brandMatch = brandText.toLowerCase().contains(q);

          final String categoryText = item.partCategoryName ?? '';
          final categoryMatchText = categoryText.toLowerCase().contains(q);

          final String modelText = item.modelName ?? '';
          final modelMatch = modelText.toLowerCase().contains(q);

          final String vehBrandText = item.vehicleBrandName ?? '';
          final vehBrandMatch = vehBrandText.toLowerCase().contains(q);

          final compatMatch = item.compatibleModelsSummary.toLowerCase().contains(q);

          queryMatch = nameMatch ||
              codeMatch ||
              brandMatch ||
              categoryMatchText ||
              modelMatch ||
              vehBrandMatch ||
              compatMatch;
        }

        // ต้องผ่านทั้งเงื่อนไขประเภทอะไหล่และเงื่อนไขคำค้นหา
        return categoryMatch && queryMatch;
      }).toList();
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
        icon: const Icon(Icons.clear, size: 20),
        tooltip: 'ล้างคำค้นหา',
        onPressed: () {
          _searchController.clear();
          _filterParts();
        },
      );
    } else {
      suffixIconWidget = null;
    }

    // กำหนดข้อความแสดงคำค้นหาข้างแถบสรุป (ป้องกันการล้นจอด้วย Expanded และ TextOverflow.ellipsis)
    Widget searchResultTextWidget = const SizedBox.shrink();
    if (_searchController.text.trim().isNotEmpty) {
      searchResultTextWidget = Expanded(
        child: Text(
          'ค้นหา: "${_searchController.text.trim()}"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // กำหนดเนื้อหาหลักของหน้าจอแบบแยกกรณีชัดเจน
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
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    } else if (filteredParts.isEmpty == true) {
      final bool hasActiveFilter =
          _searchController.text.trim().isNotEmpty || _selectedCategoryId != null;
      String emptyText;
      if (hasActiveFilter) {
        emptyText = 'ไม่พบอะไหล่ที่ตรงกับเงื่อนไขที่เลือก';
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
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 18),
            if (hasActiveFilter)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedCategoryId = null;
                  });
                  _filterParts();
                },
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('ล้างการค้นหาและตัวกรอง'),
              )
            else
              ElevatedButton.icon(
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
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มอะไหล่ใหม่'),
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
      appBar: AppBar(
        title: const Text('ข้อมูลอะไหล่'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. กล่องค้นหา (Search Box)
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

            // 2. แถบตัวกรองประเภทอะไหล่ (Category Filter) แบบ ChoiceChip เหมือนของ emp
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('ทุกประเภท'),
                    selected: _selectedCategoryId == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                      _filterParts();
                    },
                  ),
                  ..._availableCategories.map((cat) {
                    final int catId = cat['pc_id'] as int;
                    final String catName = (cat['pc_name'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(catName),
                        selected: _selectedCategoryId == catId,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedCategoryId = selected ? catId : null;
                          });
                          _filterParts();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            // 3. แถบสรุปจำนวนรายการ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'รายการอะไหล่ (${filteredParts.length} รายการ)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (_searchController.text.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    searchResultTextWidget,
                  ],
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
