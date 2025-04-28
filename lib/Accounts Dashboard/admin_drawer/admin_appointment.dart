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
  // This is all the variables use in this dart file
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  
  @override
  void initState() {
    super.initState();// Call the parent class's initState() method to ensure proper initialization
  
  // Call the fetchUserDepartment method to initiate the fetching of user department data
  // This will likely involve an API call or database query to retrieve the department information    
    fetchUserDepartment(); // This will call updateAppointmentStatuses once completed
  }

 // Function to check and update the appointment statuses
// This function checks all appointments in the 'appointment' collection in Firestore
// where the 'department' field is equal to the user's department and the status is "Scheduled".
// If the appointment's scheduled time has passed, it updates the status to "In Progress".
Future<void> updateAppointmentStatuses() async {
    try {
      // Get all appointments from the 'appointment' collection where:
    // 1. 'department' field is equal to the user's department.
    // 2. 'status' field is equal to "Scheduled".
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('department', isEqualTo: userDepartment)// Filter by user department
          .where('status', isEqualTo: "Scheduled") // Only check scheduled ones
          .get();

      DateTime now = DateTime.now();// Get the current date and time

      // Iterate through each document (appointment) in the query snapshot
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

          // Check if the 'schedule' field exists and is not null
        if (data['schedule'] != null) {
            // Parse the 'schedule' field to a DateTime object
          DateTime? appointmentDate = _parseSchedule(data['schedule']);

            // If the appointment date is valid and has already passed
          if (appointmentDate != null && appointmentDate.isBefore(now)) {
            // If the scheduled date has passed, update status to "In Progress" 
            await FirebaseFirestore.instance
                .collection('appointment')
                .doc(doc.id) // Reference the specific document by its ID
                .update({'status': "In Progress"}); // Update the status field
          }
        }
      }
    } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
          
  }

  // Function to parse the 'schedule' string (which is expected to be in ISO 8601 format)
// and convert it into a local DateTime object. 
// If the parsing fails, it will catch the error and print the issue.
  DateTime? _parseSchedule(String schedule) {
    try {
       // Attempt to parse the schedule string into a DateTime object.
    // The 'tryParse' method returns null if the string is not a valid DateTime format.
    return DateTime.tryParse(schedule)?.toLocal(); // Convert from ISO format
    } catch (e) {
       // Catch any errors that may occur during parsing and print the error with the input string.
    return null;
    }
  }

  // Function to format a timestamp string into a human-readable date format.
// The timestamp is expected to be in a standard ISO 8601 format string, such as "2025-04-28T14:30:00Z".
  String formatDate(String timestamp) {
    try {
      // Try to parse the timestamp string into a DateTime object.
    DateTime parsedDate = DateTime.parse(timestamp); 
    // Format the DateTime object into a more user-friendly format using 'DateFormat'.
    // This format will display the full month name, day, year, and time in a 12-hour format with AM/PM.
    return DateFormat("MMMM d yyyy 'at' h:mm a").format(parsedDate);
    } catch (e) {
       // Catch any errors that occur during the date formatting process and log the error
      return "Invalid date";
    }
  }

// The `fetchUserDepartment` function is responsible for fetching the department information and user details 
// (such as first name and last name) from the Firestore database for the currently authenticated user. 
// It first checks if the user is logged in by accessing the `currentUser` from FirebaseAuth. If the user is logged in, 
// it queries the Firestore database for the user's data based on the user’s UID. 
// If the data is found, it extracts the `department`, `first_name`, and `last_name` fields from the document and 
// updates the local state with these values. 
// The `isLoading` flag is also updated to `false` to indicate that the loading process is complete. 
// After retrieving the user data, the function triggers the `updateAppointmentStatuses` method to update the statuses 
// of appointments related to the user's department. 
// If any error occurs during the Firestore query or if the user is not logged in, the `isLoading` flag is set to `false`, 
// signaling the end of the loading process without further updates.
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
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                            var data = uniqueAppointments[index].data()
                                as Map<String, dynamic>;
                            String agenda = data['agenda'] ?? 'N/A';
                            String schedule = formatDate(data['schedule']);
                            String? remark =
                                data['remark']; // 👈 get remark if available

                            return Card(
                              color: Colors.grey.shade200,
                              elevation: 2,
                              child: ListTile(
                                title: Text(
                                  agenda,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Scheduled: $schedule"),
                                    if (status == "Cancelled" &&
                                        remark != null &&
                                        remark.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          "Remark: $remark",
                                          style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AppointmentDetails(
                                          selectedAgenda: agenda),
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
