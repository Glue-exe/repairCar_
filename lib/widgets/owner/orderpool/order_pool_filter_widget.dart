import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/models/priority_model.dart';
import 'package:my_app/models/order_status_model.dart';

class OrderPoolFilterHeaderWidget extends StatelessWidget {
  final int totalCount;
  final int techFilterIndex; // 0 = ทั้งหมด, 1 = ยังไม่มีคนรับ, 2 = มีคนรับแล้ว
  final Function(int) onTechFilterChanged;
  
  final int? selectedPriorityId; // null = ทั้งหมด
  final List<PriorityModel> priorities;
  final Function(int?) onPriorityChanged;

  final int? selectedStatusId; // null = ทั้งหมด
  final List<OrderStatusModel> statuses;
  final Function(int?) onStatusChanged;

  const OrderPoolFilterHeaderWidget({
    super.key,
    required this.totalCount,
    required this.techFilterIndex,
    required this.onTechFilterChanged,
    required this.selectedPriorityId,
    required this.priorities,
    required this.onPriorityChanged,
    required this.selectedStatusId,
    required this.statuses,
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
          // 1. หัวข้อ งานทั้งหมด + จำนวนรายการ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'งานทั้งหมด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalCount รายการ',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. ตัวกรองแบบที่ 1: สถานะการรับงาน (ทั้งหมด / ยังไม่มีคนรับ / มีคนรับแล้ว)
          const Text(
            'สถานะช่างรับงาน',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'ทั้งหมด',
                  isSelected: techFilterIndex == 0,
                  onSelected: () => onTechFilterChanged(0),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'ยังไม่มีคนรับ',
                  isSelected: techFilterIndex == 1,
                  onSelected: () => onTechFilterChanged(1),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'มีคนรับแล้ว',
                  isSelected: techFilterIndex == 2,
                  onSelected: () => onTechFilterChanged(2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. ตัวกรองแบบที่ 2: ความสำคัญ (Priority) เรียงต่อกัน
          const Text(
            'ความสำคัญ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'ทั้งหมด',
                  isSelected: selectedPriorityId == null,
                  onSelected: () => onPriorityChanged(null),
                ),
                ...priorities.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildFilterChip(
                      context,
                      label: p.name,
                      isSelected: selectedPriorityId == p.id,
                      onSelected: () => onPriorityChanged(p.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. ตัวกรองแบบที่ 3: สถานะงาน (Order Status) เรียงต่อกัน
          const Text(
            'สถานะงาน',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'ทั้งหมด',
                  isSelected: selectedStatusId == null,
                  onSelected: () => onStatusChanged(null),
                ),
                ...statuses.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildFilterChip(
                      context,
                      label: s.name,
                      isSelected: selectedStatusId == s.id,
                      onSelected: () => onStatusChanged(s.id),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      side: BorderSide(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
