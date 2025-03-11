import 'package:flutter/material.dart';

class DepartmentDashboard extends StatefulWidget {
  const DepartmentDashboard({super.key});

  @override
  State<DepartmentDashboard> createState() => _DepartmentDashboardState();
}

class _DepartmentDashboardState extends State<DepartmentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Department Head"),),
    );
  }
}