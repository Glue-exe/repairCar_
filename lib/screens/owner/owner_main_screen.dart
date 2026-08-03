import 'package:flutter/material.dart';
import 'package:my_app/screens/owner/owner_home_screen.dart';
import 'package:my_app/widgets/common/custom_bottom_navbar.dart';

class OwnerMainScreen extends StatefulWidget {
  const OwnerMainScreen({super.key});

  @override
  State<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends State<OwnerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OwnerHomeScreen(),
    const Center(
      child: Text(
        'หน้างานรวม',
        style: TextStyle(fontSize: 18),
      ),
    ),
    const Center(
      child: Text(
        'หน้ารับรถ',
        style: TextStyle(fontSize: 18),
      ),
    ),
    const Center(
      child: Text(
        'หน้าอะไหล่',
        style: TextStyle(fontSize: 18),
      ),
    ),
    const Center(
      child: Text(
        'หน้าโปรไฟล์',
        style: TextStyle(fontSize: 18),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'งานรวม',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'รับรถ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build),
            label: 'อะไหล่',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
