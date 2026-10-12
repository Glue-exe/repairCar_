import 'package:flutter/material.dart';
import 'package:my_app/screens/accountant/accountant_dashboard_screen.dart';
import 'package:my_app/screens/accountant/accountant_payment_screen.dart';
import 'package:my_app/screens/accountant/accountant_report_screen.dart';
import 'package:my_app/screens/accountant/accountant_profile_screen.dart';

class NavbarAccountant extends StatefulWidget {
  final int initialIndex;
  const NavbarAccountant({super.key, this.initialIndex = 0});

  @override
  State<NavbarAccountant> createState() => _NavbarAccountantState();
}

class _NavbarAccountantState extends State<NavbarAccountant> {
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
    const AccountantDashboardScreen(),
    const AccountantPaymentScreen(),
    const AccountantReportScreen(),
    const AccountantProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'ชำระเงิน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'รายงาน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
