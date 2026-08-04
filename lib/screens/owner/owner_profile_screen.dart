import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/screens/owner/owner_view_user.dart';

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
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        print('test2');
                      },
                      child: const Text('test2'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
