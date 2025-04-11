import 'dart:async';

import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/cancelled.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/completed.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/inprogress.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/scheduled.dart';
import 'package:attendance_app/analytical_report/age_distribution.dart';
import 'package:attendance_app/analytical_report/appointment_per_departments.dart';
import 'package:attendance_app/analytical_report/appointment_status_distribution.dart';
import 'package:attendance_app/analytical_report/civil_status.dart';
import 'package:attendance_app/analytical_report/gender_distribution.dart';
import 'package:attendance_app/analytical_report/monthly_appointment_trends.dart';
import 'package:attendance_app/analytical_report/role_ristribution.dart';
import 'package:attendance_app/analytical_report/weekly_attendance_trends.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    // Get current user
    currentUser = _auth.currentUser;
  }

  // Function to get stream of all users
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  Stream<QuerySnapshot> getPendingApprovalsStream() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getClientsStream() {
    return _firestore
        .collection('clients')
        .where('isDeleted', isEqualTo: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getAppointmentsStream() {
    return _firestore.collection('appointment').snapshots();
  }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        return Scaffold(
          body: SingleChildScrollView(
            child: Container(
              width: width,
              padding: EdgeInsets.all(width / 40),
              color: Color(0xFFf2edf3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dashboard",
                      style: TextStyle(
                          fontSize: width / 37,
                          fontFamily: "BL",
                          color: Color.fromARGB(255, 11, 55, 99))),
                  SizedBox.shrink(),
                  Text("View and analyze reports of attendance and other data",
                      style: TextStyle(
                          fontSize: width / 70,
                          fontFamily: "M",
                          color: Colors.grey.withOpacity(0.7))),
                  Container(
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Color.fromARGB(255, 11, 55, 99),
                                width: 2))),
                  ),
                  SizedBox(
                    height: width / 70,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Users Card with StreamBuilder
                      StreamBuilder<QuerySnapshot>(
                        stream: getUsersStream(),
                        builder: (context, snapshot) {
                          // Check connection state
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return buildLoadingUserCard(width);
                          }

                          // Check for errors
                          if (snapshot.hasError) {
                            return buildErrorUserCard(width);
                          }

                          // Get the total count of users
                          int totalUsers = snapshot.data?.docs.length ?? 0;

                          return Container(
                            width: width / 4.6,
                            height: width / 9.5,
                            padding: EdgeInsets.all(width / 80),
                            decoration: BoxDecoration(
                              color: Color(0xFF7dc2fc),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Users",
                                  style: TextStyle(
                                    fontSize: width / 80,
                                    fontFamily: "SB",
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(
                                      Icons.groups_2_rounded,
                                      color: Color(0xFF0354A1),
                                      size: width / 17,
                                    ),
                                    SizedBox(width: width / 80),
                                    Text(
                                      totalUsers
                                          .toString(), // Display the actual count here
                                      style: TextStyle(
                                        fontSize: width / 40,
                                        fontFamily: "SB",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),

                      // Keep the other cards as they were
                      StreamBuilder<QuerySnapshot>(
                        stream: getPendingApprovalsStream(),
                        builder: (context, snapshot) {
                          // Check connection state
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              width: width / 4.6,
                              height: width / 9.5,
                              padding: EdgeInsets.all(width / 80),
                              decoration: BoxDecoration(
                                color: Color(0xFF7dc2fc),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pending Approvals",
                                    style: TextStyle(
                                      fontSize: width / 80,
                                      fontFamily: "SB",
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.pending_actions_rounded,
                                        color: Color(0xFF0354A1),
                                        size: width / 17,
                                      ),
                                      SizedBox(width: width / 80),
                                      SizedBox(
                                        width: width / 15,
                                        height: width / 40,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }

                          // Check for errors
                          if (snapshot.hasError) {
                            return Container(
                              width: width / 4.6,
                              height: width / 9.5,
                              padding: EdgeInsets.all(width / 80),
                              decoration: BoxDecoration(
                                color: Color(0xFF7dc2fc),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pending Approvals",
                                    style: TextStyle(
                                      fontSize: width / 80,
                                      fontFamily: "SB",
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.pending_actions_rounded,
                                        color: Color(0xFF0354A1),
                                        size: width / 17,
                                      ),
                                      SizedBox(width: width / 80),
                                      Text(
                                        "Error",
                                        style: TextStyle(
                                          fontSize: width / 40,
                                          fontFamily: "SB",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }

                          // Get the count of pending approvals
                          int pendingCount = snapshot.data?.docs.length ?? 0;

                          return Container(
                            width: width / 4.6,
                            height: width / 9.5,
                            padding: EdgeInsets.all(width / 80),
                            decoration: BoxDecoration(
                              color: Color(0xFF7dc2fc),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pending Approvals",
                                  style: TextStyle(
                                    fontSize: width / 80,
                                    fontFamily: "SB",
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(
                                      Icons.pending_actions_rounded,
                                      color: Color(0xFF0354A1),
                                      size: width / 17,
                                    ),
                                    SizedBox(width: width / 80),
                                    Text(
                                      pendingCount
                                          .toString(), // Display actual count instead of hardcoded value
                                      style: TextStyle(
                                        fontSize: width / 40,
                                        fontFamily: "SB",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: getClientsStream(),
                        builder: (context, snapshot) {
                          // Check connection state
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return buildLoadingClientCard(width);
                          }

                          // Check for errors
                          if (snapshot.hasError) {
                            return buildErrorClientCard(width);
                          }

                          // Get the total count of clients
                          int totalClients = snapshot.data?.docs.length ?? 0;

                          return Container(
                            width: width / 4.6,
                            height: width / 9.5,
                            padding: EdgeInsets.all(width / 80),
                            decoration: BoxDecoration(
                              color: Color(0xFF7dc2fc),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Clients",
                                  style: TextStyle(
                                    fontSize: width / 80,
                                    fontFamily: "SB",
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(
                                      Icons.groups_3_rounded,
                                      color: Color(0xFF0354A1),
                                      size: width / 17,
                                    ),
                                    SizedBox(width: width / 80),
                                    Text(
                                      totalClients
                                          .toString(), // Display the actual count here
                                      style: TextStyle(
                                        fontSize: width / 40,
                                        fontFamily: "SB",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: getAppointmentsStream(),
                        builder: (context, snapshot) {
                          // Check connection state
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              width: width / 4.6,
                              height: width / 9.5,
                              padding: EdgeInsets.all(width / 80),
                              decoration: BoxDecoration(
                                color: Color(0xFF7dc2fc),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Total Appointments",
                                    style: TextStyle(
                                      fontSize: width / 80,
                                      fontFamily: "SB",
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: Color(0xFF0354A1),
                                        size: width / 17,
                                      ),
                                      SizedBox(width: width / 80),
                                      SizedBox(
                                        width: width / 15,
                                        height: width / 40,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }

                          // Check for errors
                          if (snapshot.hasError) {
                            return Container(
                              width: width / 4.6,
                              height: width / 9.5,
                              padding: EdgeInsets.all(width / 80),
                              decoration: BoxDecoration(
                                color: Color(0xFF7dc2fc),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Total Appointments",
                                    style: TextStyle(
                                      fontSize: width / 80,
                                      fontFamily: "SB",
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: Color(0xFF0354A1),
                                        size: width / 17,
                                      ),
                                      SizedBox(width: width / 80),
                                      Text(
                                        "Error",
                                        style: TextStyle(
                                          fontSize: width / 40,
                                          fontFamily: "SB",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }

                          // Get the total count of appointments
                          int totalAppointments =
                              snapshot.data?.docs.length ?? 0;

                          return Container(
                            width: width / 4.6,
                            height: width / 9.5,
                            padding: EdgeInsets.all(width / 80),
                            decoration: BoxDecoration(
                              color: Color(0xFF7dc2fc),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Appointments",
                                  style: TextStyle(
                                    fontSize: width / 80,
                                    fontFamily: "SB",
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFF0354A1),
                                      size: width / 17,
                                    ),
                                    SizedBox(width: width / 80),
                                    Text(
                                      totalAppointments
                                          .toString(), // Display the actual count here
                                      style: TextStyle(
                                        fontSize: width / 40,
                                        fontFamily: "SB",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: width / 80),
                  buildAppointmentSummary(width),
                  SizedBox(height: width / 80),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          width: width / 2,
                          height: width / 3.5,
                          child: AppointmentsPerDepartmentChart()),
                      Container(
                          height: width / 4,
                          width: width / 2.5,
                          child: AppointmentStatusPieChart()),
                    ],
                  ),
                  SizedBox(height: width / 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          height: width / 4,
                          width: width / 2.5,
                          child: RoleDistributionPieChart()),
                      Container(
                          width: width / 2.5,
                          height: width / 3.5,
                          child: AgeDistributionChart()),
                    ],
                  ),
                  SizedBox(height: width / 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          height: width / 4,
                          width: width / 2.5,
                          child: GenderDistributionPieChart()),
                      Container(
                          height: width / 4,
                          width: width / 2.5,
                          child: CivilStatusPieChart()),
                    ],
                  ),
                  SizedBox(height: width / 40),
                  MonthlyAppointmentTrends(),
                  SizedBox(height: width / 40),
                  WeeklyAttendanceTrends(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildAppointmentSummary(double width) {
    return Container(
      width: width,
      height: width / 5.5,
      padding: EdgeInsets.all(width / 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Appointment Summary",
              style: TextStyle(
                fontSize: width / 80,
                fontFamily: "SB",
              ),
            ),
          ),
          SizedBox(height: width / 80),
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
                        width: width / 5.6,
                        height: width / 9.5,
                        padding: EdgeInsets.all(width / 80),
                        decoration: BoxDecoration(
                          color: Color(0xFF082649),
                          borderRadius: BorderRadius.circular(20),
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
                                builder: (context) => InProgressAppointments()));
                      },
                      child: Container(
                        width: width / 5.6,
                        height: width / 9.5,
                        padding: EdgeInsets.all(width / 80),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
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
                      onTap: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CompletedAppointments()));
                      },
                      child: Container(
                        width: width / 5.6,
                        height: width / 9.5,
                        padding: EdgeInsets.all(width / 80),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
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
                      onTap: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CancelledAppointments()));
                      },
                      child: Container(
                        width: width / 5.6,
                        height: width / 9.5,
                        padding: EdgeInsets.all(width / 80),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget buildLoadingPendingCard(double width) {
    return Container(
      width: width / 4.6,
      height: width / 9.5,
      padding: EdgeInsets.all(width / 80),
      decoration: BoxDecoration(
        color: Color(0xFF7dc2fc),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pending Approvals",
            style: TextStyle(
              fontSize: width / 80,
              fontFamily: "SB",
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.pending_actions_rounded,
                color: Color(0xFF0354A1),
                size: width / 17,
              ),
              SizedBox(width: width / 80),
              SizedBox(
                width: width / 15,
                height: width / 40,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

// Helper method for error state of pending approvals
  Widget buildErrorPendingCard(double width) {
    return Container(
      width: width / 4.6,
      height: width / 9.5,
      padding: EdgeInsets.all(width / 80),
      decoration: BoxDecoration(
        color: Color(0xFF7dc2fc),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pending Approvals",
            style: TextStyle(
              fontSize: width / 80,
              fontFamily: "SB",
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.pending_actions_rounded,
                color: Color(0xFF0354A1),
                size: width / 17,
              ),
              SizedBox(width: width / 80),
              Text(
                "Error",
                style: TextStyle(
                  fontSize: width / 40,
                  fontFamily: "SB",
                  color: Colors.white,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Helper method for loading state
  Widget buildLoadingUserCard(double width) {
    return Container(
      width: width / 4.6,
      height: width / 9.5,
      padding: EdgeInsets.all(width / 80),
      decoration: BoxDecoration(
        color: Color(0xFF7dc2fc),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Users",
            style: TextStyle(
              fontSize: width / 80,
              fontFamily: "SB",
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.groups_2_rounded,
                color: Color(0xFF0354A1),
                size: width / 17,
              ),
              SizedBox(width: width / 80),
              SizedBox(
                width: width / 15,
                height: width / 40,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Helper method for error state
  Widget buildErrorUserCard(double width) {
    return Container(
      width: width / 4.6,
      height: width / 9.5,
      padding: EdgeInsets.all(width / 80),
      decoration: BoxDecoration(
        color: Color(0xFF7dc2fc),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Users",
            style: TextStyle(
              fontSize: width / 80,
              fontFamily: "SB",
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.groups_2_rounded,
                color: Color(0xFF0354A1),
                size: width / 17,
              ),
              SizedBox(width: width / 80),
              Text(
                "Error",
                style: TextStyle(
                  fontSize: width / 40,
                  fontFamily: "SB",
                  color: Colors.white,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// Helper method for loading state of client card
Widget buildLoadingClientCard(double width) {
  return Container(
    width: width / 4.6,
    height: width / 9.5,
    padding: EdgeInsets.all(width / 80),
    decoration: BoxDecoration(
      color: Color(0xFF7dc2fc),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total Clients",
          style: TextStyle(
            fontSize: width / 80,
            fontFamily: "SB",
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              Icons.groups_3_rounded,
              color: Color(0xFF0354A1),
              size: width / 17,
            ),
            SizedBox(width: width / 80),
            SizedBox(
              width: width / 15,
              height: width / 40,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        )
      ],
    ),
  );
}

// Helper method for error state of client card
Widget buildErrorClientCard(double width) {
  return Container(
    width: width / 4.6,
    height: width / 9.5,
    padding: EdgeInsets.all(width / 80),
    decoration: BoxDecoration(
      color: Color(0xFF7dc2fc),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total Clients",
          style: TextStyle(
            fontSize: width / 80,
            fontFamily: "SB",
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              Icons.groups_3_rounded,
              color: Color(0xFF0354A1),
              size: width / 17,
            ),
            SizedBox(width: width / 80),
            Text(
              "Error",
              style: TextStyle(
                fontSize: width / 40,
                fontFamily: "SB",
                color: Colors.white,
              ),
            ),
          ],
        )
      ],
    ),
  );
}
