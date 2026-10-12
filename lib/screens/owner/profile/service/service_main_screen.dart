import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/service_model.dart';
import 'package:my_app/screens/owner/profile/service/service_add_screen.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Service/service_list_widget.dart';

// หน้าจอจัดการบริการมาตรฐาน
class ServiceMainScreen extends StatefulWidget {
  const ServiceMainScreen({super.key});

  @override
  State<ServiceMainScreen> createState() => _ServiceMainScreenState();
}

class _ServiceMainScreenState extends State<ServiceMainScreen> {
  final TextEditingController _searchController = TextEditingController();

  // รายการทั้งหมดจากเซิร์ฟเวอร์ และรายการที่ผ่านการกรอง
  List<ServiceModel> _serviceStore = [];
  List<ServiceModel> _filteredServices = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AppAPI.get('/service');
      final json = jsonDecode(response.body);

      if (!mounted) return;

      if (json['isError'] == true) {
        setState(() {
          _errorMessage = json['errorMessage'] ?? 'โหลดรายการบริการไม่สำเร็จ';
          _isLoading = false;
        });
        return;
      }

      final serviceResponse = ServiceResponse.fromJson(json);
      setState(() {
        _serviceStore = serviceResponse.data;
        _filterServices();
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

  // กรองตามคำค้นหา (ชื่อบริการ / รายละเอียด)
  void _filterServices([String? query]) {
    final String keyword = (query ?? _searchController.text).trim().toLowerCase();

    setState(() {
      _filteredServices = _serviceStore.where((service) {
        if (keyword.isEmpty) return true;

        final bool nameMatch = service.name.toLowerCase().contains(keyword);
        final bool detailMatch =
            (service.detail ?? '').toLowerCase().contains(keyword);

        return nameMatch || detailMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ข้อมูลบริการ',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: AppFontSizes.appBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: _fetchServices,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'เพิ่มบริการ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ServiceAddScreen(onRefresh: _fetchServices);
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

  // ช่องค้นหาบริการ
  Widget _buildSearchBox() {
    Widget? suffixIcon;
    if (_searchController.text.isNotEmpty) {
      suffixIcon = IconButton(
        icon: const Icon(Icons.clear, size: 20),
        tooltip: 'ล้างคำค้นหา',
        onPressed: () {
          _searchController.clear();
          _filterServices();
        },
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _filterServices,
        style: const TextStyle(fontSize: AppFontSizes.input),
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อบริการ, รายละเอียด...',
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
                onPressed: _fetchServices,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return ServiceListWidget(
      services: _filteredServices,
      onRefresh: _fetchServices,
    );
  }
}
