import 'package:flutter/material.dart';

class SuperuserPanel extends StatefulWidget {
  const SuperuserPanel({super.key});

  @override
  State<SuperuserPanel> createState() => _SuperuserPanelState();
}

class _SuperuserPanelState extends State<SuperuserPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("SuperUser"),),
    );
  }
}