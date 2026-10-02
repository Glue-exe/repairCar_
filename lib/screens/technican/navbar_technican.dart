import 'package:flutter/material.dart';
import 'package:my_app/screens/shared/orderpool/order_pool_screen.dart';
import 'package:my_app/screens/shared/intakecar/intakecar_main_screen.dart';
import 'package:my_app/screens/technican/profile_technican_screen.dart';

class NavbarTechnican extends StatefulWidget {
  final int initialIndex;
  const NavbarTechnican({super.key, this.initialIndex = 0});

  @override
  State<NavbarTechnican> createState() => _NavbarTechnicanState();
}

class _NavbarTechnicanState extends State<NavbarTechnican> {
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
    OrderPoolScreen(),
    IntakecarScreen(),
    ProfileTechnicanScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'งานรวม',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'รับรถ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
