import 'package:attendance_app/Appointment/appointment_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduledAppointments extends StatefulWidget {
  const ScheduledAppointments({super.key});

  @override
  State<ScheduledAppointments> createState() => _ScheduledAppointmentsState();
}

class _ScheduledAppointmentsState extends State<ScheduledAppointments> {
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDepartment();
  }

  // Function to check and update appointment statuses
  Future<void> updateAppointmentStatuses() async {
    try {
      // Get all scheduled appointments for the user's department
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('department', isEqualTo: userDepartment)
          .where('status', isEqualTo: "Scheduled") // Only check scheduled ones
          .get();

      DateTime now = DateTime.now();

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        if (data['schedule'] != null) {
          DateTime? appointmentDate = _parseSchedule(data['schedule']);

          if (appointmentDate != null && appointmentDate.isBefore(now)) {
            // If the scheduled date has passed, update status to "In Progress"
            await FirebaseFirestore.instance
                .collection('appointment')
                .doc(doc.id)
                .update({'status': "In Progress"});
            print("Updated ${data['agenda']} to In Progress");
          }
        }
      }
    } catch (e) {
      print("Error updating appointment statuses: $e");
    }
  }

  String formatDate(String timestamp) {
    try {
      DateTime parsedDate = DateTime.parse(timestamp);
      return DateFormat("MMMM d yyyy 'at' h:mm a").format(parsedDate);
    } catch (e) {
      print("Error formatting date: $e");
      return "Invalid date";
    }
  }

  DateTime? _parseSchedule(String schedule) {
    try {
      return DateTime.tryParse(schedule)?.toLocal(); // Convert from ISO format
    } catch (e) {
      print("Error parsing schedule: $e | Input: $schedule");
      return null;
    }
  }

  Future<void> fetchUserDepartment() async {
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
            userDepartment = userData['department'] ?? "";
            first_name = userData['first_name'] ?? "";
            last_name = userData['last_name'] ?? "";
            isLoading = false;
          });

          updateAppointmentStatuses();
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String fullName = "$first_name $last_name".trim(); // Generate fullName

    return Scaffold(
      appBar: AppBar(
        title: Text("Scheduled Appointments", style: TextStyle(fontSize: MediaQuery.of(context).size.width/80),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointment')
                    .where('status', isEqualTo: "Scheduled")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No scheduled appointments"));
                  }

                  var appointmentDocs = snapshot.data!.docs;
                  Set<String> uniqueAgendas = {};
                  List<QueryDocumentSnapshot> uniqueAppointments = [];

                  for (var doc in appointmentDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String agenda = data['agenda'] ?? 'N/A';

                    if (!uniqueAgendas.contains(agenda)) {
                      uniqueAgendas.add(agenda);
                      uniqueAppointments.add(doc);
                    }
                  }

                  return ListView.builder(
                    itemCount: uniqueAppointments.length,
                    itemBuilder: (context, index) {
                      var data = uniqueAppointments[index].data()
                          as Map<String, dynamic>;
                      String agenda = data['agenda'] ?? 'N/A';
                      String schedule = formatDate(data['schedule']);

                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            agenda,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Scheduled: $schedule",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AppointmentDetails(selectedAgenda: agenda),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}