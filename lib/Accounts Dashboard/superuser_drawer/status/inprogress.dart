import 'package:attendance_app/Appointment/appointment_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InProgressAppointments extends StatefulWidget {
  const InProgressAppointments({super.key});

  @override
  State<InProgressAppointments> createState() => _InProgressAppointmentsState();
}

class _InProgressAppointmentsState extends State<InProgressAppointments> {
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDepartment();
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
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        print("Error fetching user data: $e");
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
        title: Text("In Progress Appointments", style: TextStyle(fontSize: MediaQuery.of(context).size.width/80),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointment')
                    .where('status', isEqualTo: "In Progress")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No in-progress appointments"));
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
                        color: Colors.amber.shade50, // Slight color to indicate "in progress" status
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