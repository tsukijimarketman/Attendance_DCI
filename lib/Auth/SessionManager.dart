import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance_app/Auth/login.dart';

    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  Timer? _timer;
  int _countdown = 6000; // 5 minutes (300 seconds)
  static const int _sessionTimeout = 6000; // in seconds

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  void startSession(BuildContext context) {
    cancelSession(); // Make sure no old timer is running
    _countdown = _sessionTimeout;

    print("Session countdown started: $_countdown seconds"); // ✅ LOG
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;

      print("Countdown: $_countdown"); // ✅ LOG every second

      if (_countdown <= 0) {
        cancelSession();
        _logout();
      }
    });
  }

  void resetSession(BuildContext context) {
    if (_timer != null && _timer!.isActive) {
      _countdown = _sessionTimeout;
      print("Session reset to $_countdown seconds"); // ✅ LOG
    }
  }

  void cancelSession() {
    _timer?.cancel();
    print("Session timer cancelled."); // ✅ LOG
  }

 void _logout() {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
        child: CupertinoAlertDialog(
          // Wrap in Theme to apply transparent background
          insetAnimationDuration: Duration(milliseconds: 150),
          content: Column(
            children: const [
              Text(
                "Session Expired",
                style: TextStyle(
                  color: Color(0xFFFF0066),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Please log in again.",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Login()),
                  (route) => false,
                );
              },
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Color(0xFFFF0066), // pink
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
}