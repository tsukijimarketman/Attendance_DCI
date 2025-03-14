import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/all_attendee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Manager_Dash extends StatefulWidget {
  const Manager_Dash({super.key});

  @override
  State<Manager_Dash> createState() => _Manager_DashState();
}

class _Manager_DashState extends State<Manager_Dash> {
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  @override
  void initState() {
      super.initState();
      fetchUserDepartment();
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
          var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;

          setState(() {
            userDepartment = userData['department'] ?? "";
            first_name = userData['first_name'] ?? "";
          last_name = userData['last_name'] ?? "";
          isLoading = false;
          });
        } else {
          print("No user document found.");
          setState(() => isLoading = false);
        }
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() => isLoading = false);
      }
    } else {
      print("No user is logged in.");
      setState(() => isLoading = false);
    }
  }

    
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    DateTime date = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy HH:mm:ss').format(date);
  }

  @override
Widget build(BuildContext context) {
  String fullName = "$first_name $last_name".trim(); // Generate fullName

  return isLoading
      ? SafeArea(child: Center(child: CircularProgressIndicator()))
      : SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .where('department', isEqualTo: userDepartment)
                .where('createdBy', isEqualTo: fullName)  // Filter by created user
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No attendance records found"));
              }

              var attendanceDocs = snapshot.data!.docs;

              // 🔥 Use a Set to store unique agendas
              Set<String> uniqueAgendas = {};
              List<QueryDocumentSnapshot> uniqueAttendanceDocs = [];

              for (var doc in attendanceDocs) {
                var data = doc.data() as Map<String, dynamic>;
                String agenda = data['agenda'] ?? 'N/A';

                if (!uniqueAgendas.contains(agenda)) {
                  uniqueAgendas.add(agenda);
                  uniqueAttendanceDocs.add(doc);
                }
              }

              return ListView.builder(
                itemCount: uniqueAttendanceDocs.length,
                itemBuilder: (context, index) {
                  var data = uniqueAttendanceDocs[index].data() as Map<String, dynamic>;
                  String agenda = data['agenda'] ?? 'N/A';

                  return ListTile(
                    title: Text(
                      agenda,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Created on: ${formatTimestamp(data['timestamp'] as Timestamp?)}",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllAttendee(selectedAgenda: agenda),
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