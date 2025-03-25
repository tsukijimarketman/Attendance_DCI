import 'package:attendance_app/Auth/log_out.dart';
import 'package:flutter/material.dart';

void showSignOutDialog(BuildContext context){
  showDialog(
    context: context, 
    builder: (BuildContext context){
      return AlertDialog(
        title: Container(
            child: Row(
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
                ),
                GestureDetector(
                  onTap: () {
                    signOut(context);                  },
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
                )
              ]
            ),
        ],
      );
    });
}