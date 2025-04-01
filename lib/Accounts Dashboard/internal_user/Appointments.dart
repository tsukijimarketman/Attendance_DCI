import 'package:attendance_app/Accounts%20Dashboard/internal_user/appointment_details.dart';
import 'package:attendance_app/Appointment/appointment_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Appointments extends StatefulWidget {
  const Appointments({super.key});

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
      fetchUserDepartment(); // This will call updateAppointmentStatuses once completed

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
            first_name = userData['first_name'] ?? "";
            last_name = userData['last_name'] ?? "";
            isLoading = false;
          });
                  
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
      .where('status', isEqualTo: status) // Use dynamic status
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(child: Text("No records"));
    }

    // ✅ Correctly filter documents
    var filteredDocs = snapshot.data!.docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;

      if (data['internal_users'] == null) return false; // Prevent null error

      List<dynamic> users = data['internal_users']; // Extract users array safely

      return users.any((user) => user['fullName'] == fullName); // ✅ Check if fullName exists inside objects
    }).toList();

    if (filteredDocs.isEmpty) {
      return Center(child: Text("No records"));
    }

    return ListView.builder(
      itemCount: filteredDocs.length, // ✅ Use filteredDocs, not snapshot.data!.docs
      itemBuilder: (context, index) {
        var data = filteredDocs[index].data() as Map<String, dynamic>; // ✅ Use filtered data
        String agenda = data['agenda'] ?? 'N/A';

        return Card(
          color: Colors.grey.shade200,
          elevation: 2,
          child: ListTile(
            title: Text(
              agenda,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Scheduled: ${formatDate(data['schedule'])}"),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentofUsers(selectedAgenda: agenda),
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
