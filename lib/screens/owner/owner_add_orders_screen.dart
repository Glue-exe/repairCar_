import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';


class OwnerAddOrdersScreen extends StatefulWidget {
  const OwnerAddOrdersScreen({super.key});

  @override
  State<OwnerAddOrdersScreen> createState() => _OwnerAddOrdersScreenState();
}

class _OwnerAddOrdersScreenState extends State<OwnerAddOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'เปิดงานซ้อม',
          style: TextStyle(color: AppColors.textDark, fontSize: 20),
        ),
      ),
    );
  }
}
