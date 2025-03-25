import 'package:attendance_app/Appointment/appointment_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminAppointment extends StatefulWidget {
  const AdminAppointment({super.key});

  @override
  State<AdminAppointment> createState() => _AdminAppointmentState();
}

class _AdminAppointmentState extends State<AdminAppointment> {
    String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
      fetchUserDepartment(); // This will call updateAppointmentStatuses once completed

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

DateTime? _parseSchedule(String schedule) {
  try {
    // Remove the " at" portion properly
    String cleanedSchedule = schedule.replaceFirst(" at", "");

    // Now parse the cleaned date
    return DateFormat("MMMM d yyyy h:mm a").parse(cleanedSchedule);
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

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GridView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 12, 
                  mainAxisSpacing: 12, 
                  childAspectRatio: 1.2, 
                ),
                children: [
                  buildStatusCard("Scheduled", "Scheduled", fullName),
                  buildStatusCard("In Progress", "In Progress", fullName),
                  buildStatusCard("Completed", "Completed", fullName),
                  buildStatusCard("Cancelled", "Cancelled", fullName),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget buildStatusCard(String title, String status, String fullName) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Divider(thickness: 1, color: Colors.black),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointment')
                          .where('department', isEqualTo: userDepartment)
                          .where('createdBy', isEqualTo: fullName)
                          .where('status', isEqualTo: status)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text("No records"));
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
                            var data = uniqueAppointments[index].data() as Map<String, dynamic>;
                            String agenda = data['agenda'] ?? 'N/A';

                            return Card(
                              color: Colors.grey.shade200,
                              elevation: 2,
                              child: ListTile(
                                title: Text(
                                  agenda,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text("Scheduled: ${data['schedule']}"),
                                trailing: Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AppointmentDetails(selectedAgenda: agenda),
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
          ],
        ),
      ),
    );
  }
}
