import 'package:attendance_app/head/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui'; // For the BackdropFilter

class LogoutSU extends StatefulWidget {
  const LogoutSU({super.key});

  @override
  State<LogoutSU> createState() => _LogoutSUState();
}

class _LogoutSUState extends State<LogoutSU> {
  bool isLoggingOut = false; // Track if logging out is in progress

  // Method to log the user out
  Future<void> logout() async {
    setState(() {
      isLoggingOut = true; // Start the logging out process
    });

    // Wait for 1 second before proceeding with the logout
    await Future.delayed(const Duration(seconds: 1));

    try {
      await FirebaseAuth.instance.signOut();
      // After signing out, navigate to the login screen or wherever you need
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      // Handle logout error (if any)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    } finally {
      setState(() {
        isLoggingOut = false; // End the logout process
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super User Dashboard'),
      ),
      body: Stack(
        children: [
          // Main content
          Center(
            child: ElevatedButton(
              onPressed: isLoggingOut ? null : logout, // Disable button if logging out
              child: const Text('Logout'),
            ),
          ),
          
          // If logging out, show the animation and background blur
          if (isLoggingOut)
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Background blur
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  // Lottie animation
                  Lottie.asset(
                    'assets/lda.json',
                    width: MediaQuery.of(context).size.width / 7,
                    height: MediaQuery.of(context).size.width / 7,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Logging Out...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
