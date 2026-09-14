import 'package:flutter/material.dart';
import 'package:my_app/screens/owner/owner_part_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/screens/owner/profile/owner_view_screen.dart';
import 'package:my_app/screens/auth/login_screen.dart';
import 'package:my_app/screens/owner/owner_vehicle_meta_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  String _fullName = '';
  String _roleName = '';

  void _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? fullName = prefs.getString("full_name");
    String? roleName = prefs.getString("user_role");
    print('Fullname: $fullName');
    print('Role: $roleName');

    setState(() {
      _fullName = fullName ?? '';
      _roleName = roleName ?? '';
    });
  }

  @override
  void initState() {
    _loadProfile();
    super.initState();
  }

  void _logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'โปรไฟล์',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('ชื่อ-นามสกุล: $_fullName'),
                const SizedBox(height: 8),
                Text('ตำแหน่ง: $_roleName'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OwnerViewUser(),
                          ),
                        );
                      },
                      child: const Text('ข้อมูลพนักงาน'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OwnerPartScreen(),
                          ),
                        );
                      },
                      child: const Text('ข้อมูลอะไหล่'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OwnerVehicleMetaScreen(),
                          ),
                        );
                      },
                      child: const Text('ข้อมูลรถยนต์'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('ออกจากระบบ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
