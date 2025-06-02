import 'package:attendance_app/Auth/SessionManager.dart';
import 'package:flutter/material.dart';

class SessionWrapper extends StatelessWidget {
  final Widget child;

  const SessionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => SessionManager().resetSession(context),
      onPanDown: (_) => SessionManager().resetSession(context),
      child: child,
    );
  }
}
