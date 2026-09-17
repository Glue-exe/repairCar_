import 'package:flutter/material.dart';
import 'package:my_app/widgets/owner/part/appoval_part_main_widget.dart';

class OwnerAppovalPartSreen extends StatefulWidget {
  const OwnerAppovalPartSreen({super.key});

  @override
  State<OwnerAppovalPartSreen> createState() => _OwnerAppovalPartSreenState();
}

class _OwnerAppovalPartSreenState extends State<OwnerAppovalPartSreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(
        'รายการอะไหล่ที่สั่งเบิก'
      ),
      ),
      body: AppovalPartMainWidget(),
    );
  }
}