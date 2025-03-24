import 'package:attendance_app/Auth/log_out.dart';
import 'package:flutter/material.dart';

void showSignOutDialog(BuildContext context){
  showDialog(
    context: context, 
    builder: (BuildContext context){
      return AlertDialog(
        title: Text("---Sign Out---"), 
        content: Text("Do you want to sign out!?"), 
        actions: [
            TextButton(onPressed: () => Navigator.pop(context), 
            child: Text("Cancel", style: TextStyle(color: Colors.red),)),
            TextButton(onPressed: () => signOut(context), 
            child: Text("Yes", style: TextStyle(color: Colors.blue),))
        ],
      );
    });
}