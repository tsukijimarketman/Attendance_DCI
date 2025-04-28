import 'package:attendance_app/Auth/audit_function.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/Auth/login.dart';

/// This function handles user sign-out and navigates to the login screen.
/// It logs the sign-out event and clears the navigation stack.

// Function to log out the user and navigate to login screen
Future<void> signOut(BuildContext context) async {
  // Log the sign-out event
  try {
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;
    String email = user?.email ?? "Unknown Email"; // Get user email before logout

    // Log the sign-out event BEFORE signing the user out
    await logAuditTrail("User Logged Out", "User with email $email logged out.");

    await FirebaseAuth.instance.signOut(); // Sign out the user

    // Navigate to login screen and clear navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
      (route) => false,
    );

    // Show a success message
  } catch (e) {
    // Handle any errors that occur during sign-out
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error signing out. Please try again.")),
    );
  }
}
