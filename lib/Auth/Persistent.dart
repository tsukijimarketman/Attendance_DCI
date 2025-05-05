import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/department_head_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/internal_user/internal_user_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawerz/manager_dashoard.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/super_user_dashboard.dart';
import 'package:attendance_app/Animation/loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/Auth/login.dart';

/// This class is responsible for managing the authentication state of the user
/// and redirecting them to the appropriate dashboard based on their role.
/// It uses Firebase Authentication and Firestore to check the user's role.
/// and it is making the auth Persistent to check the authentication state of the user.
/// It uses a StreamBuilder to listen for changes in the authentication state
/// and a FutureBuilder to check the user's role in Firestore.

// This widget is responsible for checking the authentication state of the user
class AuthPersistent extends StatelessWidget {
  const AuthPersistent({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the authentication state changes
    return StreamBuilder<User?>(
      // Use the authStateChanges stream from FirebaseAuth
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is still waiting, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoader());
          // Show a loading indicator while waiting for the authentication state
        } else if (snapshot.hasData) {
          // If the user is authenticated, check their role
          return FutureBuilder(
            future: checkUserRole(snapshot.data!, context), // Pass context
            builder: (context, AsyncSnapshot<Widget> roleScreen) {
              // If the connection is still waiting, show a loading indicator
              if (roleScreen.connectionState == ConnectionState.waiting) {
                return const Center(child: CustomLoader());
              } else {
                // If the user is authenticated and has a role, navigate to the corresponding dashboard
                return roleScreen.data ?? Login();
              }
            },
          );
          // If the user is not authenticated, show the login screen
        } else {
          return Login();
        }
      },
    );
  }

// Function to check the user's role and return the corresponding dashboard
  Future<Widget> checkUserRole(User user, BuildContext context) async {
  try {
    // Fetch the user document from Firestore using the user's UID
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .get();

    // Check if the user document exists
    if (userSnapshot.docs.isEmpty) {
      return Login(); // Instead of defaulting to a dashboard, send back to login
    }

    // Get the first document (assuming UID is unique and only one document will be returned)
    DocumentSnapshot userDoc = userSnapshot.docs.first;
    String? role = userDoc['roles']; // Use null-aware operator

    // Check if the role is null or empty
    if (role == null || role.isEmpty) {
      return Login(); // Prevent defaulting to SuperUserDashboard
    }

    // Navigate to the corresponding dashboard based on the user's role
    switch (role) {
      case "Manager":
        return Manager_Dashboard();
      case "DepartmentHead":
        return Deparment_Head_Dashboard();
      case "Admin":
        return Admin_Dashboard();
      case "Superuser":
        return SuperUserDashboard();
      case "User":
        return InternalUserDashboard();
      default:
        return Login(); // Ensure unknown roles go to Login
    }
  } catch (e) {
    // Handle any errors that occur during the role check
    return Login();
  }
}
}
