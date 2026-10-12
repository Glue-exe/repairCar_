import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/vehicle_brand_model.dart';
import 'package:my_app/models/vehicle_model_model.dart';
import 'package:my_app/screens/owner/profile/vehicle/vehicle_model/vehicle_model_add_screen.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Vehicle/vehicle_model_list_widget.dart';

// หน้าจอจัดการรุ่นรถ
class VehicleModelScreen extends StatefulWidget {
  const VehicleModelScreen({super.key});

  @override
  State<VehicleModelScreen> createState() => _VehicleModelScreenState();
}

class _VehicleModelScreenState extends State<VehicleModelScreen> {
  final TextEditingController _searchController = TextEditingController();

  // รายการทั้งหมดจากเซิร์ฟเวอร์ และรายการที่ผ่านการกรอง
  List<VehicleModelModel> _modelStore = [];
  List<VehicleModelModel> _filteredModels = [];

  // ตัวกรองยี่ห้อรถ (0 = แสดงทุกยี่ห้อ)
  List<VehicleBrandModel> _brandList = [];
  int _selectedBrandId = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchModels();
    _fetchBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AppAPI.get('/vehicle_model');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        setState(() {
          _errorMessage = json['errorMessage'] ?? 'โหลดรายการรุ่นรถไม่สำเร็จ';
          _isLoading = false;
        });
        return;
      }

      final modelResponse = VehicleModelResponse.fromJson(json);
      setState(() {
        _modelStore = modelResponse.data;
        _filterModels();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
        _isLoading = false;
      });
    }
  }

  // โหลดยี่ห้อรถสำหรับตัวกรอง
  Future<void> _fetchBrands() async {
    try {
      final response = await AppAPI.get('/vehicle_brand');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == false) {
        final brandResponse = VehicleBrandResponse.fromJson(json);
        setState(() {
          _brandList = brandResponse.data;
        });
      }
    } catch (_) {
      // โหลดยี่ห้อไม่ได้ → ตัวกรองเหลือแค่ "ทุกยี่ห้อ"
    }
  }

  // กรองตามยี่ห้อที่เลือก และคำค้นหา (ชื่อรุ่น หรือ ชื่อยี่ห้อ)
  void _filterModels([String? query]) {
    final String keyword = (query ?? _searchController.text).trim().toLowerCase();

    setState(() {
      _filteredModels = _modelStore.where((model) {
        if (_selectedBrandId != 0 && model.vmBrandId != _selectedBrandId) {
          return false;
        }

        if (keyword.isEmpty) return true;

        final bool modelMatch = model.vmName.toLowerCase().contains(keyword);
        final bool brandMatch = model.vbName.toLowerCase().contains(keyword);

        return modelMatch || brandMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ข้อมูลรุ่นรถ', style: AppTextStyles.appBar),
        centerTitle: true,
        backgroundColor: AppColors.card,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: _fetchModels,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'เพิ่มรุ่นรถ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return VehicleModelAddScreen(onRefresh: _fetchModels);
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
            _buildSearchBox(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ส่วนบน: ตัวกรองยี่ห้อ + ช่องค้นหารุ่นรถ
  Widget _buildSearchBox() {
    Widget? suffixIcon;
    if (_searchController.text.isNotEmpty) {
      suffixIcon = IconButton(
        icon: const Icon(Icons.clear, size: 20),
        tooltip: 'ล้างคำค้นหา',
        onPressed: () {
          _searchController.clear();
          _filterModels();
        },
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        children: [
          _buildBrandFilter(),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: _filterModels,
            style: const TextStyle(fontSize: AppFontSizes.input),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อรุ่น หรือชื่อยี่ห้อ...',
              hintStyle: const TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(Icons.search, size: 24),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.card,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ตัวกรองยี่ห้อรถ — กรองฝั่งแอปจากรายการที่โหลดมาแล้ว (ไม่ยิง API ใหม่)
  Widget _buildBrandFilter() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedBrandId,
          isExpanded: true,
          style: const TextStyle(
            fontSize: AppFontSizes.input,
            color: AppColors.textDark,
            fontFamily: 'Kanit',
          ),
          items: [
            const DropdownMenuItem<int>(
              value: 0,
              child: Text('ทุกยี่ห้อ'),
            ),
            ..._brandList.map((brand) {
              return DropdownMenuItem<int>(
                value: brand.vbId,
                child: Text(brand.vbName),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedBrandId = value ?? 0;
              _filterModels();
            });
          },
        ),
      ),
    );
  }

  // เนื้อหาหลัก: กำลังโหลด / ผิดพลาด / ส่งรายการเข้า widget
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppFontSizes.subtitle),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchModels,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return VehicleModelListWidget(
      models: _filteredModels,
      onRefresh: _fetchModels,
    );
  }
}
