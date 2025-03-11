import 'package:flutter/material.dart';

class ManagerDashBoard extends StatefulWidget {
  const ManagerDashBoard({super.key});

  @override
  State<ManagerDashBoard> createState() => _ManagerDashBoardState();
}

class _ManagerDashBoardState extends State<ManagerDashBoard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Manager Dashboard"),),
    );
  }
}