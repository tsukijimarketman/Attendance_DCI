import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/status/tabs/details/guest.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/status/tabs/details/users.dart';
import 'package:attendance_app/Animation/loader.dart';
import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance_app/Calendar/calendar.dart'; // Added for GoogleCalendarService

class DetailPage extends StatefulWidget {
  final String selectedAgenda;
  final String statusType;

  const DetailPage(
      {super.key, required this.selectedAgenda, required this.statusType});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  // Variables for controllers and schedule functionality
  TextEditingController agendaController = TextEditingController();
  TextEditingController scheduleController = TextEditingController();
  TextEditingController descriptionAgendaController = TextEditingController();
  String currentUserEmail = "";
  DateTime? selectedScheduleTime;
  String agendaTitle = "N/A";
  String agendaDescription = "N/A";
  String department = "N/A";
  String schedule = "N/A";
  String status = "N/A";
  String organizer = "N/A";
  String organizerEmail = "N/A";

  String remark = ""; // To store cancellation remark
  List<Map<String, dynamic>> guests = [];
  List<Map<String, dynamic>> users = [];
  String fullName = ""; // This should be set with the current user's name
  String userDepartment =
      ""; // This should be set with the current user's department
  bool isLoading = true;

  String formatSchedule(String scheduleString) {
    try {
      DateTime dateTime = DateTime.parse(scheduleString);
      return DateFormat('yyyy-MM-dd, h:mm a')
          .format(dateTime); // Format as "2024-04-26, 2:00 AM"
    } catch (e) {
      return scheduleString; // Return the original string if parsing fails
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData().then((_) {
      fetchAppointmentData();
    });
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          var userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;

          setState(() {
            fullName = "${userData['first_name']} ${userData['last_name']}";
            userDepartment = userData['department'] ?? "";
            currentUserEmail =
                userData['email'] ?? user.email ?? ""; // Store user's email
          });
        } else {
          print("No user document found.");
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    } else {
      print("No user is logged in.");
      // Set placeholder values for testing
      fullName = "John Doe";
      userDepartment = "Quality Management System";
      currentUserEmail = "john.doe@example.com";
    }
  }

  // Fetches appointment data by agenda from Firestore. Updates state with the appointment details
// such as title, description, department, schedule, and status. Also populates guest and user lists.
// If no data is found or an error occurs, it sets `isLoading` to false.
  Future<void> fetchAppointmentData() async {
    try {
      // First query - just find by agenda
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          agendaTitle = data['agenda'] ?? "N/A";
          agendaDescription = data['agendaDescript'] ?? "N/A";
          department = data['department'] ?? "N/A";
          schedule = formatSchedule(data['schedule'] ?? "N/A");
          status = data['status'] ?? "N/A";
          organizer = data['createdBy'] ?? fullName;
          organizerEmail = data['createdByEmail'] ?? "N/A";
          remark = data['remark'] ?? "No remarks provided";

          // Fetch guests and users arrays
          if (data.containsKey('guest') && data['guest'] is List) {
            guests = List<Map<String, dynamic>>.from(data['guest']);
          }
          if (data.containsKey('internal_users') &&
              data['internal_users'] is List) {
            users = List<Map<String, dynamic>>.from(data['internal_users']);
          }

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showCancelDialog(String agenda) {
    TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Container(
            height: MediaQuery.of(context).size.width / 4.6,
            width: MediaQuery.of(context).size.width / 3,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cancel_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Cancel Appointment",
                      style: TextStyle(
                        fontFamily: "SB",
                        color: Color(0xFF0e2643),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Please provide a reason for cancellation:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "R",
                          fontSize: 16,
                          color: Color(0xFF555555),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: remarkController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Cancellation Remark",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 7,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width / 170),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Dismiss",
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.width / 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 7,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width / 170),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          String remark = remarkController.text.trim();
                          if (remark.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Remark is required.")),
                            );
                            return;
                          }

                          Navigator.of(context).pop(); // Close dialog
                          deleteEvent(agenda); // Call delete here
                          updateAppointmentStatus('Cancelled',
                              remark: remark); // Update status
                        },
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.width / 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompleteDialog(String agenda) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Container(
            height: MediaQuery.of(context).size.width / 6.5,
            width: MediaQuery.of(context).size.width / 3,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Complete Appointment",
                      style: TextStyle(
                        fontFamily: "SB",
                        color: Color(0xFF0e2643),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    "Confirm finishing the appointment?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "R",
                      fontSize: 16,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 7,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width / 170),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Dismiss",
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.width / 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 7,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width / 170),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          updateAppointmentStatus('Completed'); // Update status
                        },
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.width / 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteEvent(String agenda) async {
    try {
      // Step 1: Get the document and the Google eventId
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('agenda', isEqualTo: agenda)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print("❌ No matching appointment found to delete.");
        return;
      }

      var appointmentData = snapshot.docs.first.data() as Map<String, dynamic>;
      String eventId =
          appointmentData['googleEventId']; // Get the Google event ID

      // Step 2: Authenticate with Google
      GoogleCalendarService googleCalendarService = GoogleCalendarService();
      String? accessToken = await googleCalendarService.authenticateUser();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google authentication required!")),
        );
        return;
      }

      // Step 3: Delete the event from Google Calendar
      await googleCalendarService.deleteCalendarEvent(accessToken, eventId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event cancelled successfully!")),
      );
    } catch (e) {
      print("❌ Error deleting event: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> updateAppointmentStatus(String newStatus,
      {String? remark}) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;

        Map<String, dynamic> updateData = {
          'status': newStatus,
        };

        if (newStatus == 'Cancelled' && remark != null) {
          updateData.addAll({
            'remark': remark,
            'cancelledBy': fullName,
            'cancelledAt': FieldValue.serverTimestamp(),
          });
        }

        await FirebaseFirestore.instance
            .collection('appointment')
            .doc(docId)
            .update(updateData);

        setState(() {
          status = newStatus;
          if (remark != null) {
            this.remark = remark;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status updated to $newStatus")),
        );

        print("Status updated to $newStatus");
      } else {
        print("No appointment found to update.");
      }
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  Future<void> _fetchAndEditAppointment() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CustomLoader()),
    );

    try {
      // Query for the document matching the agenda
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .limit(1)
          .get();

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Check if any documents were returned
      if (snapshot.docs.isNotEmpty) {
        var appointmentData =
            snapshot.docs.first.data() as Map<String, dynamic>;

        // Update the controllers with the current data
        agendaController.text = appointmentData['agenda'] ?? "";
        scheduleController.text = appointmentData['schedule'] ?? "";
        descriptionAgendaController.text =
            appointmentData['agendaDescript'] ?? "";

        // Now show the edit dialog with the populated data
        _showEditDetailsDialog(appointmentData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment not found")),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching appointment: ${e.toString()}")),
      );
    }
  }

  void pickScheduleDateTime() async {
    DateTime now = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color.fromARGB(255, 11, 55, 99),
              onPrimary: Colors.white,
              onSurface: Color.fromARGB(255, 11, 55, 99),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 11, 55, 99),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color.fromARGB(255, 11, 55, 99),
              onPrimary: Colors.white,
              onSurface: Color.fromARGB(255, 11, 55, 99),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 11, 55, 99),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    DateTime fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      selectedScheduleTime = fullDateTime;
      scheduleController.text = fullDateTime.toIso8601String();
    });
  }

  String formatDateTime(DateTime dateTime) {
    return "${_monthName(dateTime.month)} ${dateTime.day} ${dateTime.year} at "
        "${_formatHour(dateTime.hour)}:${_formatMinute(dateTime.minute)} "
        "${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  String _monthName(int month) {
    List<String> months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month];
  }

  String _formatHour(int hour) {
    int formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return formattedHour.toString();
  }

  String _formatMinute(int minute) {
    return minute.toString().padLeft(2, '0');
  }

// Dialog for editing details
  void _showEditDetailsDialog(Map<String, dynamic> appointmentData) {
    // Get document ID for later use
    String docId = appointmentData['id'] ?? "";
    String eventId = appointmentData['googleEventId'] ?? "";

    // Parse the initial schedule value to display formatted
    if (appointmentData['schedule'] != null) {
      try {
        selectedScheduleTime = DateTime.parse(appointmentData['schedule']);
      } catch (e) {
        print("Error parsing date: $e");
        selectedScheduleTime = DateTime.now();
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Container(
            height: MediaQuery.of(context).size.width / 3.5,
            width: MediaQuery.of(context).size.width / 3,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_calendar_rounded,
                      color: Colors.blue,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Edit Appointment",
                      style: TextStyle(
                        fontFamily: "SB",
                        color: Color(0xFF0e2643),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Agenda Field
                      TextField(
                        controller: agendaController,
                        decoration: InputDecoration(
                          labelText: "Agenda Title",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Schedule Picker Button
                      InkWell(
                        onTap: pickScheduleDateTime,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedScheduleTime != null
                                    ? formatDateTime(selectedScheduleTime!)
                                    : "Select Schedule Date & Time",
                                style: TextStyle(
                                  fontFamily: "R",
                                  color: selectedScheduleTime != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              Icon(Icons.calendar_today, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Description Field
                      TextField(
                        controller: descriptionAgendaController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 7,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width / 170,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.width / 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 7,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width / 170,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          saveDataToFirestore(docId, eventId); // Save the data
                        },
                        child: Text(
                          "Save Changes",
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.width / 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Modified saveDataToFirestore function
  Future<void> saveDataToFirestore(String docId, String eventId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Query for the document matching the agenda
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .limit(1)
          .get();

      // Check if any documents were returned
      if (snapshot.docs.isNotEmpty) {
        // Get the first document
        String docId = snapshot.docs.first.id;
        var appointmentData =
            snapshot.docs.first.data() as Map<String, dynamic>;
        String eventId = appointmentData['googleEventId'] ?? "";

        // Update the appointment data in Firestore
        await FirebaseFirestore.instance
            .collection('appointment')
            .doc(docId)
            .update({
          'agenda': agendaController.text,
          'schedule': scheduleController.text,
          'agendaDescript': descriptionAgendaController.text,
        });

        // Log the audit trail
        await logAuditTrail("Updated Appointment",
            "User $fullName updated the appointment with agenda: ${agendaController.text}");

        // Authenticate with Google Calendar
        GoogleCalendarService googleCalendarService = GoogleCalendarService();
        String? accessToken = await googleCalendarService.authenticateUser();

        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        if (accessToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google authentication required!")),
          );
          return;
        }

        // Parse schedule to DateTime
        DateTime startDateTime = DateTime.parse(scheduleController.text);
        DateTime endDateTime = startDateTime.add(const Duration(hours: 1));

        // Get guest emails
        List<String> guestEmails = guests
            .map((guest) => guest['emailAdd'] as String?)
            .whereType<String>()
            .toList();

        // Update Google Calendar Event
        await googleCalendarService.updateCalendarEvent(
          accessToken,
          eventId,
          agendaController.text,
          startDateTime,
          endDateTime,
          guestEmails,
        );

        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment updated successfully")),
        );

        // Refresh the data displayed in the widget
        if (mounted) {
          // Store old agenda to be able to fetch updated data
          String oldAgenda = widget.selectedAgenda;

          // Reset state and fetch new data in didUpdateWidget
          setState(() {
            isLoading = true;
            agendaTitle = "N/A";
            agendaDescription = "N/A";
            department = "N/A";
            schedule = "N/A";
            status = "N/A";
            organizer = "N/A";
            organizerEmail = "N/A";
            remark = "";
            guests = [];
            users = [];
          });

          // Fetch updated data with the new agenda title
          fetchAppointmentData();
        }
      } else {
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // No matching document found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No matching appointment found.")),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to update appointment: ${e.toString()}")),
      );
    }
  }

  // `didUpdateWidget` is called when the parent widget rebuilds. It checks if the `selectedAgenda` has changed,
// and if so, it resets the state (e.g., setting values to "N/A" and clearing lists) and triggers a new data fetch
// by calling `fetchAppointmentData()` to update the widget with the latest data.
  @override
  void didUpdateWidget(DetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the selectedAgenda prop has changed
    if (widget.selectedAgenda != oldWidget.selectedAgenda) {
      // Reset state and fetch new data
      setState(() {
        isLoading = true;
        agendaTitle = "N/A";
        agendaDescription = "N/A";
        department = "N/A";
        schedule = "N/A";
        status = "N/A";
        organizer = "N/A";
        organizerEmail = "N/A";
        remark = ""; // Reset remark as well
        guests = [];
        users = [];
      });
      fetchAppointmentData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildAppointmentDetails();
  }

  Widget _buildAppointmentDetails() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.width / 1.57,
        width: MediaQuery.of(context).size.width / 1.5,
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meeting Details',
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 60,
                      fontFamily: "B",
                      color: Colors.white),
                ),
                // Only show cancel button if statusType is "Scheduled" or "In Progress"
                // Replace the if statement for the Edit button with this:
                if (widget.statusType == "Scheduled")
                  Row(
                    children: [
                      // Only show Edit Meeting button if current user is the creator
                      if (currentUserEmail.toLowerCase() == organizerEmail.toLowerCase())
                        GestureDetector(
                          onTap: () {
                            // Check if the status is "Scheduled"
                            if (status == "Scheduled") {
                              // First fetch the data, then show edit dialog
                              _fetchAndEditAppointment();
                            } else {
                              // Show message that editing is only available for scheduled appointments
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Only scheduled appointments can be edited")),
                              );
                            }
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 10,
                            height: MediaQuery.of(context).size.width / 35,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.width / 100),
                            ),
                            child: Center(
                              child: Text(
                                "Edit Meeting",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 120,
                                    fontFamily: "SB",
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        ).showCursorOnHover,
                      // Always show the cancel button regardless of who created the meeting
                      SizedBox(
                        width: currentUserEmail.toLowerCase() == organizerEmail.toLowerCase()
                            ? MediaQuery.of(context).size.width / 120
                            : 0,
                      ),
                      GestureDetector(
                        onTap: () {
                          _showCancelDialog(widget.selectedAgenda);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 10,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 100),
                          ),
                          child: Center(
                            child: Text(
                              "Cancel Meeting",
                              style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 120,
                                  fontFamily: "SB",
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ).showCursorOnHover,
                    ],
                  ),

// Also modify the In Progress section in the same way:
                if (widget.statusType == "In Progress")
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showCompleteDialog(widget.selectedAgenda);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 10,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 100),
                          ),
                          child: Center(
                            child: Text(
                              "Finish Meeting",
                              style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 120,
                                  fontFamily: "SB",
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ).showCursorOnHover,
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 120,
                      ),
                      GestureDetector(
                        onTap: () {
                          _showCancelDialog(widget.selectedAgenda);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 10,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 100),
                          ),
                          child: Center(
                            child: Text(
                              "Cancel Meeting",
                              style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 120,
                                  fontFamily: "SB",
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ).showCursorOnHover,
                    ],
                  ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 80),
            _buildDetailRow('Title:', agendaTitle),
            _buildDetailRow('Description:', agendaDescription),
            _buildOrgRow('Organizer:', organizer, organizerEmail),
            _buildDetailRow('Department:', department),
            _buildDetailRow('Date & Time:', schedule),
            _buildDetailRow('Status:', status),
            // Show remark only if status is Cancelled
            if (status == 'Cancelled') _buildDetailRow('Remark:', remark),
            SizedBox(height: MediaQuery.of(context).size.height / 80),
            Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width / 2.7,
              child: Row(
                children: [
                  if (guests.isNotEmpty) ...[
                    Guest(
                      selectedAgenda: widget.selectedAgenda,
                      statusType: widget.statusType,
                    ),
                  ],
                  SizedBox(width: MediaQuery.of(context).size.width / 80),
                  if (users.isNotEmpty) ...[
                    InternalUsers(
                      selectedAgenda: widget.selectedAgenda,
                      organizerEmail: organizerEmail,
                      organizer: organizer,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 12,
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 90,
                      fontFamily: "R",
                      color: Colors.white),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width / 100),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 90,
                      fontFamily: "SB",
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrgRow(String label, String value, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 12,
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 90,
                      fontFamily: "R",
                      color: Colors.white),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width / 100),
              Expanded(
                child: Text(
                  "$value\n$email",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 90,
                      fontFamily: "SB",
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
