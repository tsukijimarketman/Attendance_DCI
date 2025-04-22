import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/details/guest.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/details/users.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailPage extends StatefulWidget {
  final String selectedAgenda;

  const DetailPage({super.key, required this.selectedAgenda});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String agendaTitle = "N/A";
  String agendaDescription = "N/A";
  String department = "N/A";
  String schedule = "N/A";
  String status = "N/A";
  String organizer = "N/A";
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
      print("Error formatting date: $e");
      return scheduleString; // Return the original string if parsing fails
    }
  }

  @override
  void initState() {
    super.initState();
    // This should be replaced with actual user data fetching
    // For example, from a user authentication service
    fullName = "John Doe"; // Replace with actual user name
    userDepartment =
        "Quality Management System"; // Replace with actual user department

    fetchAppointmentData();
  }

  Future<void> fetchAppointmentData() async {
    try {
      print("Selected agenda: ${widget.selectedAgenda}");

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
        print("No appointment data found for agenda: ${widget.selectedAgenda}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching appointment data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(DetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the selectedAgenda prop has changed
    if (widget.selectedAgenda != oldWidget.selectedAgenda) {
      print(
          "Agenda changed from ${oldWidget.selectedAgenda} to ${widget.selectedAgenda}");
      // Reset state and fetch new data
      setState(() {
        isLoading = true;
        agendaTitle = "N/A";
        agendaDescription = "N/A";
        department = "N/A";
        schedule = "N/A";
        status = "N/A";
        organizer = "N/A";
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
        height: MediaQuery.of(context).size.width / 1.65,
        width: MediaQuery.of(context).size.width / 1.5,
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Details',
              style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width / 60,
                  fontFamily: "B",
                  color: Colors.white),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 80),
            _buildDetailRow('Title:', agendaTitle),
            _buildDetailRow('Description:', agendaDescription),
            _buildDetailRow('Organizer:', organizer),
            _buildDetailRow('Department:', department),
            _buildDetailRow('Date & Time:', schedule),
            _buildDetailRow('Status:', status),
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
                    ),
                  ],
                  SizedBox(width: MediaQuery.of(context).size.width / 80),
                  if (users.isNotEmpty) ...[
                    InternalUsers(selectedAgenda: widget.selectedAgenda,),
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
      child: Row(
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
    );
  }
}
