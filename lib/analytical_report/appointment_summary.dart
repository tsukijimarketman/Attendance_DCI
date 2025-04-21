import 'dart:async';

import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/cancelled.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/completed.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/inprogress.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/scheduled.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppointmentStatus extends StatefulWidget {
  const AppointmentStatus({super.key});

  @override
  State<AppointmentStatus> createState() => _AppointmentStatusState();
}

class _AppointmentStatusState extends State<AppointmentStatus> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Map<String, int>> getAppointmentStatusCounts() {
    // Get the base collection reference
    final appointmentsRef = _firestore.collection('appointment');

    // Create a stream controller to combine results
    final controller = StreamController<Map<String, int>>();

    // Initialize the counts map
    Map<String, int> statusCounts = {
      'Scheduled': 0,
      'In Progress': 0,
      'Completed': 0,
      'Cancelled': 0
    };

    // Track completion of all queries
    int completedQueries = 0;

    // Function to update counts and check if all queries are done
    void updateAndCheckCompletion() {
      completedQueries++;
      if (completedQueries >= 4) {
        controller.add(statusCounts);
      }
    }

    // Query for Scheduled appointments
    appointmentsRef
        .where('status', isEqualTo: 'Scheduled')
        .get()
        .then((snapshot) {
      statusCounts['Scheduled'] = snapshot.docs.length;
      updateAndCheckCompletion();
    }).catchError((error) {
      print('Error fetching Scheduled appointments: $error');
      updateAndCheckCompletion();
    });

    // Query for In Progress appointments
    appointmentsRef
        .where('status', isEqualTo: 'In Progress')
        .get()
        .then((snapshot) {
      statusCounts['In Progress'] = snapshot.docs.length;
      updateAndCheckCompletion();
    }).catchError((error) {
      print('Error fetching In Progress appointments: $error');
      updateAndCheckCompletion();
    });

    // Query for Completed appointments
    appointmentsRef
        .where('status', isEqualTo: 'Completed')
        .get()
        .then((snapshot) {
      statusCounts['Completed'] = snapshot.docs.length;
      updateAndCheckCompletion();
    }).catchError((error) {
      print('Error fetching Completed appointments: $error');
      updateAndCheckCompletion();
    });

    // Query for Cancelled appointments
    appointmentsRef
        .where('status', isEqualTo: 'Cancelled')
        .get()
        .then((snapshot) {
      statusCounts['Cancelled'] = snapshot.docs.length;
      updateAndCheckCompletion();
    }).catchError((error) {
      print('Error fetching Cancelled appointments: $error');
      updateAndCheckCompletion();
    });

    // Close the stream controller when the stream is no longer needed
    controller.onCancel = () {
      controller.close();
    };

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Column(
      children: [
        buildAppointmentSummary(width),
      ],
    );
  }

  Widget buildAppointmentSummary(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StreamBuilder<Map<String, int>>(
          stream: getAppointmentStatusCounts(),
          builder: (context, snapshot) {
            // Show loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF082649),
                ),
              );
            }
    
            // Handle errors
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading appointment data",
                  style: TextStyle(
                    fontSize: width / 70,
                    fontFamily: "SB",
                    color: Colors.red,
                  ),
                ),
              );
            }
    
            // Get data or provide defaults
            final statusCounts = snapshot.data ??
                {
                  'Scheduled': 0,
                  'In Progress': 0,
                  'Completed': 0,
                  'Cancelled': 0
                };
    
            return Container(
              width: width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Scheduled status card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ScheduledAppointments()));
                    },
                    child: Container(
                      width: width / 5.5,
                      height: width / 9.5,
                      padding: EdgeInsets.all(width / 80),
                      decoration: BoxDecoration(
                        color: Color(0xFF082649),
                        borderRadius: BorderRadius.circular(width / 120),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4), // X, Y
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Scheduled",
                            style: TextStyle(
                              fontSize: width / 80,
                              fontFamily: "SB",
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: Colors.white,
                                size: width / 17,
                              ),
                              SizedBox(width: width / 80),
                              Text(
                                statusCounts['Scheduled'].toString(),
                                style: TextStyle(
                                  fontSize: width / 40,
                                  fontFamily: "SB",
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).showCursorOnHover,
    
                  // Ongoing status card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  InProgressAppointments()));
                    },
                    child: Container(
                      width: width / 5.5,
                      height: width / 9.5,
                      padding: EdgeInsets.all(width / 80),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(width / 120),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4), // X, Y
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "In Progress",
                            style: TextStyle(
                              fontSize: width / 80,
                              fontFamily: "SB",
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white,
                                size: width / 17,
                              ),
                              SizedBox(width: width / 80),
                              Text(
                                statusCounts['In Progress'].toString(),
                                style: TextStyle(
                                  fontSize: width / 40,
                                  fontFamily: "SB",
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).showCursorOnHover,
    
                  // Completed status card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CompletedAppointments()));
                    },
                    child: Container(
                      width: width / 5.5,
                      height: width / 9.5,
                      padding: EdgeInsets.all(width / 80),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(width / 120),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4), // X, Y
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Completed",
                            style: TextStyle(
                              fontSize: width / 80,
                              fontFamily: "SB",
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: width / 17,
                              ),
                              SizedBox(width: width / 80),
                              Text(
                                statusCounts['Completed'].toString(),
                                style: TextStyle(
                                  fontSize: width / 40,
                                  fontFamily: "SB",
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).showCursorOnHover,
    
                  // Cancelled status card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CancelledAppointments()));
                    },
                    child: Container(
                      width: width / 5.5,
                      height: width / 9.5,
                      padding: EdgeInsets.all(width / 80),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(width / 120),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4), // X, Y
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Cancelled",
                            style: TextStyle(
                              fontSize: width / 80,
                              fontFamily: "SB",
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                Icons.cancel_rounded,
                                color: Colors.white,
                                size: width / 17,
                              ),
                              SizedBox(width: width / 80),
                              Text(
                                statusCounts['Cancelled'].toString(),
                                style: TextStyle(
                                  fontSize: width / 40,
                                  fontFamily: "SB",
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).showCursorOnHover,
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
