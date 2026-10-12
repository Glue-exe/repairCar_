import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/vehicle_brand_model.dart';
import 'package:my_app/screens/owner/profile/vehicle/vehicle_brand/vehicle_brand_add_screen.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Vehicle/vehicle_brand_list_widget.dart';

// หน้าจอจัดการยี่ห้อรถ
class VehicleBrandScreen extends StatefulWidget {
  const VehicleBrandScreen({super.key});

  @override
  State<VehicleBrandScreen> createState() => _VehicleBrandScreenState();
}

class _VehicleBrandScreenState extends State<VehicleBrandScreen> {
  final TextEditingController _searchController = TextEditingController();

  // รายการทั้งหมดจากเซิร์ฟเวอร์ และรายการที่ผ่านการกรอง
  List<VehicleBrandModel> _brandStore = [];
  List<VehicleBrandModel> _filteredBrands = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBrands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AppAPI.get('/vehicle_brand');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        setState(() {
          _errorMessage = json['errorMessage'] ?? 'โหลดรายการยี่ห้อรถไม่สำเร็จ';
          _isLoading = false;
        });
        return;
      }

      final brandResponse = VehicleBrandResponse.fromJson(json);
      setState(() {
        _brandStore = brandResponse.data;
        _filterBrands();
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

  // กรองตามคำค้นหา (ชื่อยี่ห้อ)
  void _filterBrands([String? query]) {
    final String keyword = (query ?? _searchController.text).trim().toLowerCase();

    setState(() {
      _filteredBrands = _brandStore.where((brand) {
        if (keyword.isEmpty) return true;

        return brand.vbName.toLowerCase().contains(keyword);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ข้อมูลยี่ห้อรถ', style: AppTextStyles.appBar),
        centerTitle: true,
        backgroundColor: AppColors.card,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: _fetchBrands,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'เพิ่มยี่ห้อรถ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return VehicleBrandAddScreen(onRefresh: _fetchBrands);
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

  // ช่องค้นหายี่ห้อรถ
  Widget _buildSearchBox() {
    Widget? suffixIcon;
    if (_searchController.text.isNotEmpty) {
      suffixIcon = IconButton(
        icon: const Icon(Icons.clear, size: 20),
        tooltip: 'ล้างคำค้นหา',
        onPressed: () {
          _searchController.clear();
          _filterBrands();
        },
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _filterBrands,
        style: const TextStyle(fontSize: AppFontSizes.input),
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อยี่ห้อรถ...',
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
                onPressed: _fetchBrands,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return VehicleBrandListWidget(
      brands: _filteredBrands,
      onRefresh: _fetchBrands,
    );
  }
}
