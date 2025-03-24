import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/make_a_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentDetails extends StatefulWidget {
  final String selectedAgenda;

  AppointmentDetails({super.key, required this.selectedAgenda});

  @override
  State<AppointmentDetails> createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();
  final TextEditingController descriptionAgendaController =
      TextEditingController();
  String Status = '';

  List<Map<String, dynamic>> attendanceList = [];

  List<Map<String, dynamic>> guests = [];

  @override
  void initState() {
    super.initState();
    fetchAppointmentData();
    fetchAttendancetData();
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime date =
          timestamp.toDate(); // Convert Firestore Timestamp to DateTime
      return DateFormat("MMMM d yyyy 'at' h:mm a")
          .format(date); // Format as "March 21 2025 at 3:00 PM"
    } else {
      return "N/A";
    }
  }

  Future<void> fetchAppointmentData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(
              'appointment') // Assuming the collection name is 'appointments'
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;

        setState(() {
          agendaController.text = data['agenda'] ?? "N/A";
          descriptionAgendaController.text = data['agendaDescript'] ?? "N/A";
          departmentController.text = data['department'] ?? "N/A";
          scheduleController.text = data['schedule'] ?? "N/A";
          Status = data['status'] ?? "N/A";

          // Fetch guests array from Firestore
          if (data.containsKey('guest') && data['guest'] is List) {
            guests = List<Map<String, dynamic>>.from(data['guest']);
          }
        });
      } else {
        print("No appointment data found.");
      }
    } catch (e) {
      print("Error fetching appointment data: $e");
    }
  }

  Future<void> updateAppointmentStatus(String newStatus) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('appointment')
        .where('agenda', isEqualTo: widget.selectedAgenda)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String docId = querySnapshot.docs.first.id;

      await FirebaseFirestore.instance
          .collection('appointment')
          .doc(docId)
          .update({'status': newStatus});

      setState(() {
        Status = newStatus; // Update UI
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


  Future<void> fetchAttendancetData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .get(); // Remove limit(1) to fetch all related records

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          attendanceList = querySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      } else {
        print("No attendance data found.");
      }
    } catch (e) {
      print("Error fetching attendance data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
          color: Colors.transparent,
          child: Center(
              child: Column(
                children: [
                  Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Dashboard",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black),
                  Text(
                    "Appointment Details",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
                  Expanded(
                    child: Row(children: [
                              Expanded(
                    child: Card(
                      color: Colors.grey.shade300,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Schedule an Appointment",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            height: 50,
                            width: 400,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[
                                  200], // Light grey background to indicate it's non-editable
                            ),
                            child: Text(
                              agendaController.text.isNotEmpty
                                  ? agendaController.text
                                  : "Loading...",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            height: 50,
                            width: 400,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[
                                  200], // Light grey background to indicate it's non-editable
                            ),
                            child: Text(
                              descriptionAgendaController.text.isNotEmpty
                                  ? descriptionAgendaController.text
                                  : "Loading...",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            height: 50,
                            width: 400,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[
                                  200], // Light grey background to indicate it's non-editable
                            ),
                            child: Text(
                              departmentController.text.isNotEmpty
                                  ? departmentController.text
                                  : "Loading...",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            height: 50,
                            width: 400,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[
                                  200], // Light grey background to indicate it's non-editable
                            ),
                            child: Text(
                              scheduleController.text.isNotEmpty
                                  ? scheduleController.text
                                  : "Loading...",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Divider(
                            thickness: 1,
                            height: 1,
                            color: Colors.black,
                          ),
                          SizedBox(
                            child: guests.isEmpty
                                ? Center(child: Text("No guests invited"))
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Pre-Invited Guests",
                                      style: TextStyle(color: Colors.black, fontSize: 18),
                                    ),
                                  ),
                          ),
                          Expanded(
                            // ✅ Wrap ListView.builder in Expanded
                            child: ListView.builder(
                              itemCount: guests.length,
                              itemBuilder: (context, index) {
                                var guest = guests[index];
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                                  child: Card(
                                    margin: EdgeInsets.all(2),
                                    child: ListTile(
                                      title: Text(guest["fullName"] ?? "Unknown"),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "📧 Email: ${guest["emailAdd"] ?? "N/A"}"),
                                          Text(
                                              "📞 Contact: ${guest["contactNum"] ?? "N/A"}"),
                                          Text(
                                              "🏢 Company: ${guest["companyName"] ?? "N/A"}"),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                              ),
                              Expanded(
                      child: Card(
                          color: Colors.grey.shade300,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: attendanceList.isEmpty
                                      ? Center(
                                          child: Text(
                                          "No attendees recorded",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 18),
                                        ))
                                      : Column(
                                          children: [
                                            Text(
                                              "Attendance List",
                                              style: TextStyle(fontSize: 24),
                                            ),
                                            Expanded(
                                              child: ListView.builder(
                                                itemCount: attendanceList.length,
                                                itemBuilder: (context, index) {
                                                  var attendee = attendanceList[index];
                                                  return Padding(
                                                    padding: const EdgeInsets.fromLTRB(
                                                        50, 0, 50, 0),
                                                    child: Card(
                                                      margin: EdgeInsets.all(2),
                                                      child: ListTile(
                                                        title: Text(attendee["name"] ??
                                                            "Unknown"),
                                                        subtitle: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                                "📧 Email: ${attendee["email_address"] ?? "N/A"}"),
                                                            Text(
                                                                "📞 Contact: ${attendee["contact_num"] ?? "N/A"}"),
                                                            Text(
                                                                "🏢 Company: ${attendee["company"] ?? "N/A"}"),
                                                            Text(
                                                              "🕒 Attendance Time: ${formatTimestamp(attendee["timestamp"])}",
                                                            ),
                                                            SizedBox(
                                                              height: 200,
                                                              width: 300,
                                                              child: attendee["signature_url"] !=
                                                                          null &&
                                                                      attendee[
                                                                              "signature_url"]
                                                                          .isNotEmpty
                                                                  ? Image.network(
                                                                      attendee[
                                                                          "signature_url"], // Use attendee-specific signature URL
                                                                      fit: BoxFit
                                                                          .contain,
                                                                      loadingBuilder:
                                                                          (context,
                                                                              child,
                                                                              loadingProgress) {
                                                                        if (loadingProgress ==
                                                                            null)
                                                                          return child;
                                                                        return Center(
                                                                            child:
                                                                                CircularProgressIndicator());
                                                                      },
                                                                      errorBuilder:
                                                                          (context,
                                                                              error,
                                                                              stackTrace) {
                                                                        return Center(
                                                                            child: Text(
                                                                                "Failed to load signature"));
                                                                      },
                                                                    )
                                                                  : Center(
                                                                      child: Text(
                                                                          "No signature available")),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                            updateAppointmentStatus("Cancelled");

                                                  }),
                                              IconButton(
                                                  icon: Icon(
                                                    Icons.check_sharp,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed: () {
                                                            updateAppointmentStatus("Completed");

                                                  }),
                                            ],
                                          ),
                                          Text("Current Status: ${Status}"),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                              icon: Icon(Icons.upload_file_sharp),
                                              onPressed: () {}),
                                          Text("Upload File")
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                              icon: Icon(Icons.email_sharp),
                                              onPressed: () {}),
                                          Text("Send Email")
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                              icon: Icon(Icons.qr_code_scanner_sharp),
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) => MakeAForm(
                                                              agenda: agendaController,
                                                            )));
                                              }),
                                          Text("Qr-Code"),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ])))
                            ]),
                  ),
                ],
              ))),
    );
  }
}
