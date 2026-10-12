import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/screens/owner/profile/vehicle/vehicle_brand/vehicle_brand_screen.dart';
import 'package:my_app/screens/owner/profile/vehicle/vehicle_model/vehicle_model_screen.dart';

// หน้าเมนูย่อยของ "ข้อมูลรถยนต์"
// ให้เลือกว่าจะเข้าจัดการ "ยี่ห้อรถ" หรือ "รุ่นรถ"
class VehicleMainScreen extends StatefulWidget {
  const VehicleMainScreen({super.key});

  @override
  State<VehicleMainScreen> createState() => _VehicleMainScreenState();
}

class _VehicleMainScreenState extends State<VehicleMainScreen> {
  // เปิดหน้าจอปลายทาง
  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ข้อมูลรถยนต์', style: AppTextStyles.appBar),
        centerTitle: true,
        backgroundColor: AppColors.card,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // หัวข้อกำกับ บอกว่าหน้านี้ให้ทำอะไร
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 10.0),
              child: Text(
                'เลือกหมวดที่ต้องการจัดการ',
                style: TextStyle(
                  fontSize: AppFontSizes.section,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.sell_outlined,
                    title: 'ยี่ห้อรถ',
                    subtitle: 'จัดการยี่ห้อรถในระบบ เช่น Toyota, Honda, Isuzu',
                    onTap: () => _navigateTo(const VehicleBrandScreen()),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.directions_car_outlined,
                    title: 'รุ่นรถ',
                    subtitle: 'จัดการรุ่นรถภายใต้แต่ละยี่ห้อ เช่น Yaris, Civic, D-Max',
                    onTap: () => _navigateTo(const VehicleModelScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // แถวรายการเมนูแต่ละรายการ (ไอคอนในกรอบสี + ชื่อ + คำอธิบาย)
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 28),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppFontSizes.headline,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: AppFontSizes.subtitle,
            color: AppColors.textMuted,
            height: 1.3,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textMuted,
        size: 28,
      ),
      onTap: onTap,
    );
  }
}
