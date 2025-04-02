import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/all_admin_attendee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageAllAppointments extends StatefulWidget {
  const ManageAllAppointments({super.key});

  @override
  State<ManageAllAppointments> createState() => _ManageAllAppointmentsState();
}

class _ManageAllAppointmentsState extends State<ManageAllAppointments> {
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
            isLoading = false;

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
                            String createdBy = data['createdBy'] ?? 'N/A';

                            return Card(
                              color: Colors.grey.shade200,
                              elevation: 2,
                              child: ListTile(
                                title: Text(
                                  createdBy,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(agenda),
                                Text("Scheduled: ${formatDate(data['schedule'])}"),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllDeptAttendee(selectedAgenda: agenda),
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
