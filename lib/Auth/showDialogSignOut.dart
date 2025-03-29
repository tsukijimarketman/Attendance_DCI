import 'package:attendance_app/Auth/log_out.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:flutter/material.dart';

void showSignOutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.info_outline,
                color: Colors.grey,
                size: MediaQuery.of(context).size.width / 30),
            Text(
              'Confirm Logout',
              style: TextStyle(
                  fontFamily: "SB",
                  fontSize: MediaQuery.of(context).size.width / 60),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
              fontFamily: "R",
              fontSize: MediaQuery.of(context).size.width / 80),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, false);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width / 40),
                    color: Colors.red,
                  ),
                  height: MediaQuery.of(context).size.width / 40,
                  width: MediaQuery.of(context).size.width / 10,
                  child: Center(
                      child: Text(
                    'No',
                    style: TextStyle(
                        fontFamily: "R",
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width / 80),
                  )),
                ),
              ).showCursorOnHover,
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close dialog first
                  signOut(context); // Call signOut function
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width / 40),
                    color: Colors.green,
                  ),
                  height: MediaQuery.of(context).size.width / 40,
                  width: MediaQuery.of(context).size.width / 10,
                  child: Center(
                      child: Text(
                    'Yes',
                    style: TextStyle(
                        fontFamily: "R",
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width / 80),
                  )),
                ),
              ).showCursorOnHover
            ],
          ),
        ],
      );
    },
  );
}
