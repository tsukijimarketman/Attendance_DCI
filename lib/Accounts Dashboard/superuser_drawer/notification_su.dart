import 'package:flutter/material.dart';

class NotificationsSU extends StatefulWidget {
  const NotificationsSU({super.key});

  @override
  State<NotificationsSU> createState() => _NotificationsSUState();
}

class _NotificationsSUState extends State<NotificationsSU> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
        child: Container(
          color: Colors.red,
          child: Center(
            child: Text('Notifications Page'),
          ),
        ),
      ),
    );
  }
}
