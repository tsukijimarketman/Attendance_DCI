import 'dart:async';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/appointment_view.dart';
import 'package:attendance_app/Auth/audit_function.dart';
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

  // To store status counts
  Map<String, int> statusCounts = {
    'Scheduled': 0,
    'In Progress': 0,
    'Completed': 0,
    'Cancelled': 0
  };

  // For appointment monitoring
  Timer? _statusCheckTimer;
  StreamSubscription? _appointmentsSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Start monitoring appointments
    _setupAppointmentMonitoring();
    // Set up periodic check for appointments that should be In Progress
    _startStatusCheckTimer();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  // Set up a stream subscription to monitor appointment changes
  void _setupAppointmentMonitoring() {
    _appointmentsSubscription =
        _firestore.collection('appointment').snapshots().listen((snapshot) {
      _fetchStatusCounts();
    });

    // Initial fetch
    _fetchStatusCounts();
  }

  // Set up a timer to check appointment statuses periodically
  void _startStatusCheckTimer() {
    // Check every minute
    _statusCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkAndUpdateAppointmentsStatus();
    });

    // Also run immediately on startup
    _checkAndUpdateAppointmentsStatus();
  }

  // Fetch the counts for each appointment status
  Future<void> _fetchStatusCounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Reset counts
      Map<String, int> tempCounts = {
        'Scheduled': 0,
        'In Progress': 0,
        'Completed': 0,
        'Cancelled': 0
      };

      // Fetch all status counts in parallel
      final futures = tempCounts.keys.map((status) async {
        final snapshot = await _firestore
            .collection('appointment')
            .where('status', isEqualTo: status)
            .get();
        return MapEntry(status, snapshot.docs.length);
      });

      // Wait for all queries to complete
      final results = await Future.wait(futures);

      // Update the status counts map
      for (var entry in results) {
        tempCounts[entry.key] = entry.value;
      }

      // Update state only if component is still mounted
      if (mounted) {
        setState(() {
          statusCounts = tempCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching appointment status counts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check for scheduled appointments that should be changed to In Progress
  Future<void> _checkAndUpdateAppointmentsStatus() async {
    try {
      // Get the current date and time
      final now = DateTime.now();

      // Query for all appointments with "Scheduled" status
      final scheduledAppointments = await _firestore
          .collection('appointment')
          .where('status', isEqualTo: 'Scheduled')
          .get();

      int updatedCount = 0;

      // Check each scheduled appointment
      for (var doc in scheduledAppointments.docs) {
        try {
          // Get the scheduled time
          final scheduleStr = doc.data()['schedule'] as String?;

          if (scheduleStr != null && scheduleStr.isNotEmpty) {
            final scheduledTime = DateTime.parse(scheduleStr);

            // If the scheduled time has passed, update to "In Progress"
            if (now.isAfter(scheduledTime)) {
              await _firestore
                  .collection('appointment')
                  .doc(doc.id)
                  .update({'status': 'In Progress'});

              // Log the automatic status change
                  await logAuditTrail("Auto Status Update", "Appointment with agenda: ${doc.data()['agenda'] ?? 'Unknown'} automatically changed to In Progress");

              updatedCount++;
            }
          }
        } catch (parseError) {
          print('Error parsing date for document ${doc.id}: $parseError');
        }
      }

      // If any appointments were updated, refresh the counts
      if (updatedCount > 0) {
        _fetchStatusCounts();
      }
    } catch (e) {
      print('Error checking appointment statuses: $e');
    }
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
        _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF082649),
                ),
              )
            : Container(
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
                                builder: (context) =>
                                    AppointmentView(statusType: 'Scheduled')));
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
                                builder: (context) => AppointmentView(
                                    statusType: 'In Progress')));
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
                                builder: (context) =>
                                    AppointmentView(statusType: 'Completed')));
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
                                builder: (context) =>
                                    AppointmentView(statusType: 'Cancelled')));
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
              ),
      ],
    );
  }
}
