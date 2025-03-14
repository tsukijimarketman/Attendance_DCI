import 'package:flutter/material.dart';

class AuditSU extends StatefulWidget {
  const AuditSU({super.key});

  @override
  State<AuditSU> createState() => _AuditSUState();
}

class _AuditSUState extends State<AuditSU> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
        child: Container(
          color: Colors.red,
          child: Center(
            child: Text('Audit Page'),
          ),
        ),
      ),
    );
  }
}