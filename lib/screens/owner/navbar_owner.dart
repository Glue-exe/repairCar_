import 'package:flutter/material.dart';
import 'package:my_app/screens/owner/owner_home_screen.dart';
import 'package:my_app/screens/owner/owner_intakecar_screen.dart';
import 'package:my_app/screens/owner/owner_jobpool_screen.dart';
import 'package:my_app/screens/owner/owner_part_screen.dart';
import 'package:my_app/screens/owner/owner_profile_screen.dart';

class NavbarOwner extends StatefulWidget {
  const NavbarOwner({super.key});

  @override
  State<NavbarOwner> createState() => _NavbarOwnerState();
}

class _NavbarOwnerState extends State<NavbarOwner> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    OwnerHomeScreen(),
    OwnerJobpoolScreen(),
    OwnerIntakecarScreen(),
    OwnerPartScreen(),
    OwnerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'งานรวม',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'รับรถ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'อะไหล่'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
