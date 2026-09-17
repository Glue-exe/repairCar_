import 'package:flutter/material.dart';
import 'package:my_app/screens/owner/owner_home_screen.dart';
import 'package:my_app/screens/owner/part/owner_appoval_part_sreen.dart';
import 'package:my_app/screens/shared/orderpool/order_pool_screen.dart';
import 'package:my_app/screens/owner/profile/owner_profile_screen.dart';
import 'package:my_app/screens/shared/intakecar/intakecar_screen.dart';

class NavbarOwner extends StatefulWidget {
  final int initialIndex;
  const NavbarOwner({super.key, this.initialIndex = 0});

  @override
  State<NavbarOwner> createState() => _NavbarOwnerState();
}

class _NavbarOwnerState extends State<NavbarOwner> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    OwnerHomeScreen(),
    OrderPoolScreen(),
    IntakecarScreen(),
    OwnerAppovalPartSreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'อนุมัติอะไหล่'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
