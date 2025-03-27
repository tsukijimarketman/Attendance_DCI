import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/department_head_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/manager_dashoard.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/super_user_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/Auth/login.dart';

class AuthPersistent extends StatelessWidget {
  const AuthPersistent({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return FutureBuilder(
            future: checkUserRole(snapshot.data!, context), // Pass context
            builder: (context, AsyncSnapshot<Widget> roleScreen) {
              if (roleScreen.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return roleScreen.data ?? Login();
              }
            },
          );
        } else {
          return Login();
        }
      },
    );
  }

  Future<Widget> checkUserRole(User user, BuildContext context) async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("User not found in Firestore");
        return Manager_Dashboard();
      }

      DocumentSnapshot userDoc = userSnapshot.docs.first;
      String role = userDoc['roles'];

      switch (role) {
        case "Manager":
          return Manager_Dashboard();
        case "DepartmentHead":
          return Deparment_Head_Dashboard();
        case "Admin":
          return Admin_Dashboard();
        case "Superuser":
          return SuperUserDashboard();
        default:
          print("Unknown role");
          return Login();
      }
    } catch (e) {
      print("Error checking user role: $e");
      return Login();
    }
  }
}
