import 'package:flutter/material.dart';
import 'package:my_app/models/employee_model.dart';

class EmpListWidget extends StatelessWidget {
  const EmpListWidget({super.key, required this.employeeModelStore});
  final List<EmployeeModel> employeeModelStore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: employeeModelStore.length,
        itemBuilder: (context, index) {
          EmployeeModel item = employeeModelStore[index];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                '${item.empFirstname} ${item.empLastname}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text('เบอร์โทร: ${item.empPhone}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                color: Colors.teal,
                splashColor: Colors.teal.withValues(alpha: 0.1),
                onPressed: () {
                  print('Edit employee: ${item.empId}');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
