import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/all_dept_attendee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageAllAppointments extends StatefulWidget {
  const ManageAllAppointments({super.key});

  @override
  State<ManageAllAppointments> createState() => _ManageAllAppointmentsState();
}

class _ManageAllAppointmentsState extends State<ManageAllAppointments> {
  // Function to format timestamp
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    DateTime date = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No attendance records found"));
          }

          var attendanceDocs = snapshot.data!.docs;

          // 🔥 Debugging: Print all fetched documents
          print("Total Attendance Records: ${attendanceDocs.length}");
          
          // 🔥 Use a Set to track unique agendas
          Set<String> uniqueAgendas = {};
          List<QueryDocumentSnapshot> uniqueAttendanceDocs = [];

          for (var doc in attendanceDocs) {
            var data = doc.data() as Map<String, dynamic>?;

            if (data == null) continue; // Skip if data is null

            String agenda = data['agenda'] ?? 'N/A';

            // If agenda is not in the set, add it and keep this document
            if (!uniqueAgendas.contains(agenda)) {
              uniqueAgendas.add(agenda);
              uniqueAttendanceDocs.add(doc);
            }
          }

          print("Unique Agendas Count: ${uniqueAttendanceDocs.length}");

          return ListView.builder(
            itemCount: uniqueAttendanceDocs.length, // 🔥 Show only unique agendas
            itemBuilder: (context, index) {
              var data = uniqueAttendanceDocs[index].data() as Map<String, dynamic>?;

              if (data == null) return SizedBox(); // Skip if data is null

              String agenda = data['agenda'] ?? 'N/A';
              String dept = data['department'] ?? 'N/A';
              Timestamp? timestamp = data['timestamp'] as Timestamp?;

              return ListTile(
                title: Text(
                  agenda,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Created on: ${formatTimestamp(timestamp)}",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black),
                    ),
                    Text(
                      "Department: $dept",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black),
                    ),
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
              );
            },
          );
        },
      ),
    );
  }
}
