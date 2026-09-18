import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/priority_model.dart';
import 'package:my_app/models/order_status_model.dart';

class OrderPoolFilterHeaderWidget extends StatelessWidget {
  final int totalCount;

  // ตัวแปรเก็บค่าตัวกรองปัจจุบัน
  final int techFilterIndex; // 0 = ทั้งหมด, 1 = ยังไม่มีคนรับ, 2 = มีคนรับแล้ว, 3 = งานที่ฉันกดรับ
  final int? selectedPriorityId; // null = ทั้งหมด
  final int? selectedStatusId; // null = ทั้งหมด

  // ข้อมูลตัวเลือกที่ดึงมาจากฐานข้อมูล
  final List<PriorityModel> priorities;
  final List<OrderStatusModel> statuses;

  // Callback ส่งค่ากลับไปหน้าหลักเมื่อผู้ใช้กดเลือก
  final Function(int) onTechFilterChanged;
  final Function(int?) onPriorityChanged;
  final Function(int?) onStatusChanged;

  const OrderPoolFilterHeaderWidget({
    super.key,
    required this.totalCount,
    required this.techFilterIndex,
    required this.selectedPriorityId,
    required this.selectedStatusId,
    required this.priorities,
    required this.statuses,
    required this.onTechFilterChanged,
    required this.onPriorityChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ จำนวนรายการทั้งหมด
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ตัวกรองข้อมูล',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'พบ $totalCount รายการ',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // แถวที่ 1 สถานะช่างรับงาน
          _buildFilterRow(
            title: 'สถานะช่าง',
            chips: [
              _buildChip('ทั้งหมด', techFilterIndex == 0, () => onTechFilterChanged(0)),
              _buildChip('ยังไม่มีคนรับ', techFilterIndex == 1, () => onTechFilterChanged(1)),
              _buildChip('มีคนรับแล้ว', techFilterIndex == 2, () => onTechFilterChanged(2)),
              _buildChip('งานที่ฉันกดรับ', techFilterIndex == 3, () => onTechFilterChanged(3)),
            ],
          ),
          const SizedBox(height: 8),

          // แถวที่ 2 ระดับความสำคัญ
          _buildFilterRow(
            title: 'ความสำคัญ',
            chips: [
              _buildChip('ทั้งหมด', selectedPriorityId == null, () => onPriorityChanged(null)),
              ...priorities.map((p) => _buildChip(
                    p.name,
                    selectedPriorityId == p.id,
                    () => onPriorityChanged(p.id),
                  )),
            ],
          ),
          const SizedBox(height: 8),

          // แถวที่ 3 สถานะงานซ่อม
          _buildFilterRow(
            title: 'สถานะงาน',
            chips: [
              _buildChip('ทั้งหมด', selectedStatusId == null, () => onStatusChanged(null)),
              ...statuses.map((s) => _buildChip(
                    s.name,
                    selectedStatusId == s.id,
                    () => onStatusChanged(s.id),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  /// ฟังก์ชันช่วยสร้างแถวหัวข้อ + ปุ่มตัวเลือกแบบแนวนอน
  Widget _buildFilterRow({
    required String title,
    required List<Widget> chips,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ชื่อหัวข้อ (ความกว้างคงที่เพื่อให้ตรงแนวกัน)
        SizedBox(
          width: 70,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        // รายการปุ่มตัวเลือกแนวนอน
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips
                  .map((chip) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: chip,
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// ฟังก์ชันช่วยสร้างปุ่ม ChoiceChip แต่ละตัว
  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen,
      backgroundColor: Colors.grey[100],
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => onTap(),
    );
  }
}
