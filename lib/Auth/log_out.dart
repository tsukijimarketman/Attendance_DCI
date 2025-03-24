import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/Auth/login.dart';

Future<void> signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
      (route) => false, // Clears the navigation stack
    );
  } catch (e) {
    print("Error signing out: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error signing out. Please try again.")),
    );
  }
}
