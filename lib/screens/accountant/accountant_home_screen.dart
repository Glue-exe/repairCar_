import 'package:flutter/material.dart';
import 'package:my_app/screens/accountant/navbar_accountant.dart';

class AccountantHomeScreen extends StatelessWidget {
  final int initialIndex;
  const AccountantHomeScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return NavbarAccountant(initialIndex: initialIndex);
  }
}
