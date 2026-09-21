import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/models/part_model.dart';
import 'package:my_app/screens/owner/part_add_screen.dart';
import 'package:my_app/utils/app_api.dart';
import 'package:my_app/widgets/owner/profile/CRUD_Part/part_list_del_widget.dart';

class OwnerPartScreen extends StatefulWidget {
  const OwnerPartScreen({super.key});

  @override
  State<OwnerPartScreen> createState() => _OwnerPartScreenState();
}

class _OwnerPartScreenState extends State<OwnerPartScreen> {
  List<PartModel> partModelStore = [];

  void _fetchData() async {
    var response = await AppAPI.get("/getPart");
    Map<String, dynamic> json = jsonDecode(response.body);
    PartResponse partResponse = PartResponse.fromJson(json);

    if (!mounted) return;
    setState(() {
      partModelStore = partResponse.data;
    });
  }

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('ข้อมูลอะไหล่'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PartAddScreen(onRefresh: _fetchData),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PartListWidget(
                  partModelStore: partModelStore,
                  onRefresh: _fetchData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
