import 'dart:typed_data';
import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/form/make_a_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:share_plus/share_plus.dart';
import 'package:attendance_app/Calendar/calendar.dart';

class AppointmentDetails extends StatefulWidget {
  final String selectedAgenda;

  AppointmentDetails({super.key, required this.selectedAgenda});

  @override
  State<AppointmentDetails> createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {
  // This is all the variables that will be used in the appointment details page
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();
  final TextEditingController descriptionAgendaController =
      TextEditingController();
  String Status = '';
  String userDepartment = "";
  String fullName = "";
  bool isLoading = true;

  DateTime? selectedScheduleTime; // To store the selected date and time

  List<Map<String, dynamic>> attendanceList = [];

  List<Map<String, dynamic>> guests = [];
  List<Map<String, dynamic>> users = [];

  String firstName = "";
  String lastName = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isEditing =
      false; // Keeps track of whether the button is in Edit or Save mode

  // InitState method to fetch user department and appointment data and attendance data
  // The initState method is called when the widget is first created
  @override
  void initState() {
    super.initState();
    fetchUserDepartment().then((_) {
      fetchAppointmentData();
      fetchAttendancetData();
    });
  }

  // Function to parse the schedule string into a DateTime object
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

  // Function to format the date string into a readable format
  String formatDate(String timestamp) {
    try {
      DateTime parsedDate = DateTime.parse(timestamp);
      return DateFormat("MMMM d yyyy 'at' h:mm a").format(parsedDate);
    } catch (e) {
      return "Invalid date";
    }
  }

  // Function to fetch appointment data from Firestore
  Future<void> fetchAppointmentData() async {
    try {
      // Fetch the appointment data based on the selected agenda and user department
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(
              'appointment') // Assuming the collection name is 'appointments'
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .where('department', isEqualTo: userDepartment)
          .where('createdBy', isEqualTo: fullName)
          .limit(1)
          .get();

      // Check if any documents were returned
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first document
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;

        // Set the state with the fetched data
        setState(() {
          // Set the text fields with the fetched data
          agendaController.text = data['agenda'] ?? "N/A";
          descriptionAgendaController.text = data['agendaDescript'] ?? "N/A";
          departmentController.text = data['department'] ?? "N/A";
          scheduleController.text = data['schedule'] ?? "N/A";
          Status = data['status'] ?? "N/A";

          // Fetch guests array from Firestore
          if (data.containsKey('guest') && data['guest'] is List) {
            // Convert the guest list to a List<Map<String, dynamic>>
            guests = List<Map<String, dynamic>>.from(data['guest']);
          }

          // Fetch internal users array from Firestore
          if (data.containsKey('internal_users') &&
              data['internal_users'] is List) {
            // Convert the internal users list to a List<Map<String, dynamic>>
            users = List<Map<String, dynamic>>.from(data['internal_users']);
          }
        });
      } else {
        // No documents found for the given criteria
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching appointment data: $e")),
      );
    }
  }

  // Function to fetch user data from Firestore
  Future<void> fetchUserData() async {
    // Get the current user from Firebase Auth
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is logged in
    if (user != null) {
      // Fetch user data from Firestore based on the UID
      try {
        // Query the Firestore collection 'users' where 'uid' matches the current user's UID
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        // Check if any documents were returned
        if (querySnapshot.docs.isNotEmpty) {
          // Get the first document
          var userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;

          // Set the state with the fetched user data
          setState(() {
            //  Set the state with the fetched user data
            firstName = userData['first_name'] ?? "N/A";
            lastName = userData['last_name'] ?? "N/A";
          });
        } else {
          //  No documents found for the given UID
        }
      } catch (e) {
        // Handle any errors that occur during the fetch
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching user data: $e")),
        );
      }
    } else {
      // User is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No user is logged in.")),
      );
    }
  }

  // Function to fetch user department from Firestore
  Future<void> fetchUserDepartment() async {
    // Get the current user from Firebase Auth
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is logged in
    if (user != null) {
      // Fetch user data from Firestore based on the UID
      try {
        // Query the Firestore collection 'users' where 'uid' matches the current user's UID
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        // Check if any documents were returned
        if (querySnapshot.docs.isNotEmpty) {
          // Get the first document
          var userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;

          // Set the state with the fetched user data
          setState(() {
            // Set the user department and full name
            userDepartment = userData['department'] ?? "";
            fullName = "${userData['first_name']} ${userData['last_name']}";
            isLoading = false;
          });
        } else {
          // No documents found for the given UID
          setState(() => isLoading = false);
        }
      } catch (e) {
        // Handle any errors that occur during the fetch
        setState(() => isLoading = false);
      }
    } else {
      // User is not logged in
      setState(() => isLoading = false);
    }
  }

  // Function to update the appointment status in Firestore
  Future<void> updateAppointmentStatus(String newStatus,
      {String? remark}) async {
    try {
      // Query for the document matching the agenda and user department
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .where('department', isEqualTo: userDepartment)
          .where('createdBy', isEqualTo: fullName)
          .limit(1)
          .get();

      // Check if any documents were returned
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first document
        String docId = querySnapshot.docs.first.id;

        // Prepare the data to update
        Map<String, dynamic> updateData = {
          // Update the status field
          'status': newStatus,
        };

        // Add remark and cancellation details if applicable
        if (newStatus == 'Cancelled' && remark != null) {
          // Add remark and cancellation details
          updateData.addAll({
            'remark': remark,
            'cancelledBy': fullName,
            'cancelledAt': FieldValue.serverTimestamp(),
          });
        }

        // Update the Firestore document
        await FirebaseFirestore.instance
            .collection('appointment')
            .doc(docId)
            .update(updateData);
        
        // Set the state with the new status
        setState(() {
          Status = newStatus;
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status updated to $newStatus")),
        );

      } else {
        // No documents found for the given criteria
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No matching appointment found.")),
        );
      }
    } catch (e) {
      // Handle any errors that occur during the update
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating appointment status: $e")),
      );
     }
  }

  // Function to fetch attendance data from Firestore
  Future<void> fetchAttendancetData() async {
    try {
      // Query for the attendance data based on the selected agenda and user department
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .where('department', isEqualTo: userDepartment)
          .where('createdBy', isEqualTo: fullName) // Fil
          .get(); // Remove limit(1) to fetch all related records

      // Check if any documents were returned
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first document
        setState(() {
          // Set the attendance list with the fetched data
          attendanceList = querySnapshot.docs
          // Convert the documents to a List<Map<String, dynamic>>
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      } else {
        // No documents found for the given criteria
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No attendance records found.")),
        );
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching attendance data: $e")),
      );
    }
  }

  // Function to fetch image from URL
  Future<Uint8List?> _fetchImage(String? url) async {
    // Check if the URL is valid
    if (url == null || url.isEmpty) return null;
    try {
      // Fetch the image from the URL
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Image fetched successfully
        return response.bodyBytes; // Convert response to bytes
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching image: $e")),
      );
    }
    // Return null if the image could not be fetched
    return null;
  }

  // Function to load an asset image
  Future<Uint8List> loadAssetImage(String path) async {
    // Load the image from the asset bundle
    final ByteData data = await rootBundle.load(path);
    // Convert the image data to Uint8List
    return data.buffer.asUint8List();
  }

  // Function to generate the PDF report
  void _generatePDF() async {
    // Create a new PDF document
    final pdf = pw.Document();
    // Create a list to hold attendees with their signatures
    List<Map<String, dynamic>> attendeesWithSignatures = [];

    // **Fetch images before generating the PDF**
    for (var attendee in attendanceList) {
      // Fetch the image bytes for each attendee's signature URL
      Uint8List? imageBytes = await _fetchImage(attendee['signature_url']);
      // Add the attendee data along with the image bytes to the list
      attendeesWithSignatures.add({...attendee, 'signature_bytes': imageBytes});
    }

    // **Load asset images for the header and footer**
    Uint8List logoBytes = await loadAssetImage('assets/bag.png');
    Uint8List logoBytess = await loadAssetImage('assets/dci.jpg');

    // **Add a new page to the PDF document**
    pdf.addPage(
      // Create a new page with landscape orientation and margins
      pw.MultiPage(
        // Set the page format to A4 landscape
        pageFormat: PdfPageFormat.a4.landscape,
        // Set the margins for the page
        margin: pw.EdgeInsets.all(30),

        // ✅ HEADER - This will appear on every page
        header: (context) => pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start, // Align text to the left
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(pw.MemoryImage(logoBytess)),
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(pw.MemoryImage(logoBytes)),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Attendance Sheet',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerLeft, // Align to the left
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Date & Time: ${scheduleController.text.isNotEmpty ? formatDate(scheduleController.text) : "No Schedule"}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Agenda: ${widget.selectedAgenda}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ FOOTER - This will appear on every page
        footer: (context) => pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 5),
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Doc ID DCI-ATTENDANCE-FRM v.0.0",
                    style: pw.TextStyle(
                      fontSize: 8,
                    ),
                  )),
              pw.Text(
                "DBP Data Center, Inc.",
                style:
                    pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(
                thickness: 1,
                height: 1,
                indent: 4,
                endIndent: 4,
                color: PdfColors.grey,
              ),
              pw.Text(
                "9/F DBP Building, Sen. Gil Puyat Avenue, Makati City, Philippines.",
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                "Tel No. 8818-9511 local 2913 | www.dci.com.ph",
                style: pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),

        // ✅ CONTENT - The table will auto-continue on new pages
        build: (context) => [
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: attendanceList.isEmpty
                ? pw.Center(
                    child: pw.Text(
                      "No attendance records available.",
                      style: pw.TextStyle(fontSize: 16),
                    ),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(2),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(2),
                      4: pw.FlexColumnWidth(2),
                    },
                    children: [
                      // Table Header
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Name',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Company',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Email Address',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Contact No.',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Signature',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                        ],
                      ),

                      // Attendees Data
                      // Loop through each attendee and create a table row
                      for (var attendee in attendeesWithSignatures)
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text(attendee['name'] ?? 'N/A')),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text(attendee['company'] ?? 'N/A')),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child:
                                  pw.Text(attendee['email_address'] ?? 'N/A')),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text(
                              () {
                                final contact = attendee['contact_num'];
                                if (contact is List) {
                                  return contact.join(', ');
                                } else if (contact is String) {
                                  return contact;
                                } else {
                                  return 'N/A';
                                }
                              }(),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: attendee['signature_bytes'] != null
                                  ? pw.Image(
                                      pw.MemoryImage(
                                          attendee['signature_bytes']!),
                                      width: 60,
                                      height: 25)
                                  : pw.Text("No Signature"),
                            ),
                          )
                        ]),
                    ],
                  ),
          )
        ],
      ),
    );

    // Save the PDF document to a file or share it
    final pdfBytes = await pdf.save();
    // Save the PDF to a file or share it
    await Printing.sharePdf(bytes: pdfBytes, filename: 'attendance_report.pdf');
  }

  // Function to generate the CSV report
  Future<void> _generateCSV() async {
    // Create a list to hold the CSV rows
    List<List<String>> rows = [];

    // CSV Header
    rows.add(['Name', 'Company', 'Email Address', 'Contact No.']);

    // Data Rows
    for (var attendee in attendanceList) {
      // Add each attendee's data to the rows
      rows.add([
        // Use null-aware operators to handle missing data
        attendee['name'] ?? 'N/A',
        attendee['company'] ?? 'N/A',
        attendee['email_address'] ?? 'N/A',
        (() {
          // Use a function to handle the contact number
          final contact = attendee['contact_num'];
          if (contact is List) {
            // If contact is a list, join the elements with a comma
            return contact.join(', ');
          } else if (contact is String) {
            // If contact is a string, return it directly
            return contact;
          } else {
            // If contact is neither, return 'N/A'
            return 'N/A';
          }
        })(),
      ]);
    }

    // Convert to CSV String
    String csv = const ListToCsvConverter().convert(rows);

    // Check if the platform is web
    if (kIsWeb) {
      // ✅ Download CSV in Flutter Web
      final blob = html.Blob([csv], 'text/csv');
      // Create a URL for the blob and trigger a download
      final url = html.Url.createObjectUrlFromBlob(blob);
      // Create an anchor element and trigger a download
      final anchor = html.AnchorElement(href: url)
      // Set the download attribute to specify the file name
        ..setAttribute("download", "attendance_report.csv")
        ..click();
        // Revoke the object URL after download
      html.Url.revokeObjectUrl(url);
    } else {
      // ✅ Save CSV on Android/iOS/Desktop
      final directory = await getApplicationDocumentsDirectory();
      // Create a path for the CSV file
      final path = '${directory.path}/attendance_report.csv';
      // Write the CSV string to the file
      final file = File(path);
      // Check if the file exists, if not create it
      await file.writeAsString(csv);
      // Share the CSV file using the share_plus package
      await Share.shareXFiles([XFile(path)], text: 'Attendance Report CSV');
    }
  }

  // Show a dialog to confirm the download format (PDF or CSV)
  void showcsvpdfdialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Download Attendance"),
          content:
              Text("Do you want to download the attendance in PDF or CSV?"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Image.asset('assets/pdf.png', width: 50, height: 50),
                  onPressed: () {
                    // This will trigger the PDF generation
                    _generatePDF();

                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Image.asset("assets/csv.png", width: 50, height: 50),
                  onPressed: () {
                    // this will trigger the CSV generation
                    _generateCSV();

                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // This will show a dialog to confirm the cancellation of the appointment
  void _showCancelDialog(String agenda) {
    // Create a TextEditingController for the remark input field
    TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cancel Appointment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Please provide a reason for cancellation:"),
              SizedBox(height: 12),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Cancellation Remark",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text("Dismiss"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () => 
              // Close the dialog without any action
              Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Confirm"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // Validate the remark input
                String remark = remarkController.text.trim();
                if (remark.isEmpty) {
                  // Show a snackbar if the remark is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Remark is required.")),
                  );
                  // Don't proceed with cancellation
                  return;
                }

                Navigator.of(context).pop(); // Close dialog
                deleteEvent(agenda); // 👈 Call delete here
                // Call the function to update the appointment status
                // Pass the remark to the function
                updateAppointmentStatus('Cancelled',
                    remark: remark); // 👈 Update status
              },
            ),
          ],
        );
      },
    );
  }

  // Function to pick a date and time for scheduling
  void pickScheduleDateTime() async {
    // Show date and time picker dialogs
    DateTime now = DateTime.now();
    // Show date picker dialog
    DateTime? pickedDate = await showDatePicker(
      // Show date picker dialog
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    // Check if the user picked a date
    // If the user cancels the date picker, pickedDate will be null
    if (pickedDate == null) return;


    // Show time picker dialog
    TimeOfDay? pickedTime = await showTimePicker(
      // Show time picker dialog
      context: context,
      initialTime: TimeOfDay.now(),
    );

    // Check if the user picked a time
    // If the user cancels the time picker, pickedTime will be null
    if (pickedTime == null) return;

    // Combine Date and Time
    DateTime fullDateTime = DateTime(
      // Create a new DateTime object with the picked date and time
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Format the date and time for display
    setState(() {
      // Update the selected schedule time and the text field
      selectedScheduleTime = fullDateTime;
      scheduleController.text =
          fullDateTime.toIso8601String(); // Store in ISO format
    });
  }

// Function to format date-time
  String formatDateTime(DateTime dateTime) {
    return "${_monthName(dateTime.month)} ${dateTime.day} ${dateTime.year} at "
        "${_formatHour(dateTime.hour)}:${_formatMinute(dateTime.minute)} "
        "${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  // Function to get the month name from the month number
  // This function takes an integer month (1-12) and returns the corresponding month name
  // For example, if month is 1, it returns "January"
  String _monthName(int month) {
    List<String> months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month];
  }

  // Function to format the hour for display
  // This function takes an integer hour (0-23) and returns the formatted hour (1-12)
  // For example, if hour is 14, it returns "2"
  // If hour is 0, it returns "12"
  String _formatHour(int hour) {
    int formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return formattedHour.toString();
  }

  // Function to format the minute for display
  // This function takes an integer minute (0-59) and returns the formatted minute (00-59)
  // For example, if minute is 5, it returns "05"
  // If minute is 30, it returns "30"
  // If minute is 0, it returns "00"
  String _formatMinute(int minute) {
    return minute.toString().padLeft(2, '0');
  }


  // The saveDataToFirestore function is responsible for saving the appointment data to Firestore
  // It updates the appointment details and also updates the Google Calendar event  
  // Function to Save data to Firestore
  Future<void> saveDataToFirestore() async {
    // Check if the agenda is empty
    try {
      // Query for the document matching the agenda
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .limit(1)
          .get();

      // Check if any documents were returned
      if (snapshot.docs.isNotEmpty) {
        // Get the first document
      String docId = snapshot.docs.first.id;
        var appointmentData =
            snapshot.docs.first.data() as Map<String, dynamic>;
        String eventId =
            appointmentData['googleEventId']; // Retrieve the eventId

        // Update the appointment data in Firestore
        await FirebaseFirestore.instance
            .collection('appointment')
            .doc(docId)
            .update({
          'agenda': agendaController.text,
          'schedule': scheduleController.text,
          'agendaDescript': descriptionAgendaController.text,
        });

        // Log the audit trail
        await logAuditTrail("Updated Appointment",
            "User $fullName updated the appointment with agenda: ${agendaController.text}");

        // Show a success message
        // Show a snackbar message to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Form submitted successfully!")));

        // 🌟 Retrieve or Authenticate Google Token
        GoogleCalendarService googleCalendarService = GoogleCalendarService();
        // Authenticate the user and get the access token
        String? accessToken = await googleCalendarService.authenticateUser();

        // Check if the access token is null
        if (accessToken == null) {
          // Show a snackbar message to indicate authentication failure
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Google authentication required!")));
              // Exit the function if authentication fails
          return;
        }

        // Ensure to parse the updated schedule to DateTime
        DateTime startDateTime = DateTime.parse(scheduleController.text);
        DateTime endDateTime = startDateTime.add(Duration(hours: 1));

        // Make sure the updated guest list is included (if any changes were made)
        List<String> guestEmails = (guests ?? [])
            .map((guest) => guest['emailAdd'] as String?)
            .whereType<String>()
            .toList();


        // 🌟 Update Google Calendar Event
        await googleCalendarService.updateCalendarEvent(
          accessToken,
          eventId, // The eventId from Firestore for updating
          agendaController.text,
          startDateTime,
          endDateTime,
          guestEmails,
        );

        // Show a snackbar message to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Appointment updated successfully")),
        );
      } else {
        // No matching document found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No matching appointment found.")),
        );
      }
    } catch (e) {

      // Handle any errors that occur during the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update appointment")),
      );
    }
  }

  /// This method deletes the event from Google Calendar and Firestore
  /// It first retrieves the eventId from Firestore, then deletes the event from Google Calendar using the GoogleCalendarService.
  /// Finally, it deletes the appointment document from Firestore.
  Future<void> deleteEvent(String agenda) async {
    try {
      // Step 1: Get the document and the Google eventId
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .where('agenda', isEqualTo: agenda)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      var appointmentData = snapshot.docs.first.data() as Map<String, dynamic>;
      String eventId =
          appointmentData['googleEventId']; // ✅ Get the Google event ID

      // Step 2: Authenticate with Google
      GoogleCalendarService googleCalendarService = GoogleCalendarService();
      String? accessToken = await googleCalendarService.authenticateUser();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google authentication required!")),
        );
        return;
      }

      // Step 3: Delete the event from Google Calendar
      await googleCalendarService.deleteCalendarEvent(accessToken, eventId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event deleted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
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
                            "Appointment Details",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          // Agenda
                          Container(
                            height: 50,
                            width: 400,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: isEditing
                                ? TextField(
                                    controller: agendaController,
                                    decoration:
                                        InputDecoration.collapsed(hintText: ""),
                                  )
                                : Text(
                                    agendaController.text.isNotEmpty
                                        ? agendaController.text
                                        : "Loading...",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  ),
                          ),
                          SizedBox(height: 10),
                          // Description
                          Container(
                            height: 50,
                            width: 400,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: isEditing
                                ? TextField(
                                    controller: descriptionAgendaController,
                                    decoration:
                                        InputDecoration.collapsed(hintText: ""),
                                  )
                                : Text(
                                    descriptionAgendaController.text.isNotEmpty
                                        ? descriptionAgendaController.text
                                        : "Loading...",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  ),
                          ),
                          SizedBox(height: 10),
                          // Department
                          Container(
                            height: 50,
                            width: 400,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: isEditing
                                ? TextField(
                                    controller: departmentController,
                                    decoration:
                                        InputDecoration.collapsed(hintText: ""),
                                  )
                                : Text(
                                    departmentController.text.isNotEmpty
                                        ? departmentController.text
                                        : "Loading...",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  ),
                          ),
                          SizedBox(height: 10),
                          // Schedule Date Picker
                          GestureDetector(
                            onTap: isEditing
                                ? pickScheduleDateTime
                                : null, // Only editable when in edit mode
                            child: Container(
                              height: 50,
                              width: 400,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.amber, width: 1),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[200],
                              ),
                              child: Text(
                                selectedScheduleTime != null
                                    ? formatDateTime(selectedScheduleTime!
                                        .toLocal()) // Nicely formatted

                                    : "${formatDate(scheduleController.text)}",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          // Edit / Save Button
                          (Status == "Scheduled")
  ?
                          Container(
                            height: 50,
                            width: 400,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (isEditing) {
                                    // Save data to Firestore when save button is clicked
                                    saveDataToFirestore();
                                  }
                                  isEditing =
                                      !isEditing; // Toggle between Edit and Save
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isEditing ? Colors.blue : Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                isEditing ? "Save" : "Edit",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            
                          )
                            : SizedBox.shrink(), // returns nothing if not "Scheduled"

                          // External Guest
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
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 18),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(50, 0, 50, 0),
                                  child: Card(
                                    margin: EdgeInsets.all(2),
                                    child: ListTile(
                                      title:
                                          Text(guest["fullName"] ?? "Unknown"),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                          // Internal Users
                          SizedBox(
                            height: 10,
                          ),
                          Divider(
                            thickness: 1,
                            height: 1,
                            color: Colors.black,
                          ),
                          SizedBox(
                            child: users.isEmpty
                                ? Center(
                                    child: Text("No Internal Users invited"))
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Internal Users",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 18),
                                    ),
                                  ),
                          ),
                          Expanded(
                            // ✅ Wrap ListView.builder in Expanded
                            child: ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                var user = users[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(50, 0, 50, 0),
                                  child: Card(
                                    margin: EdgeInsets.all(2),
                                    child: ListTile(
                                      title:
                                          Text(user["fullName"] ?? "Unknown"),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "📧 Email: ${user["email"] ?? "N/A"}"),
                                          Text(
                                              "📞 Department: ${user["department"] ?? "N/A"}"),
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
                                                itemCount:
                                                    attendanceList.length,
                                                itemBuilder: (context, index) {
                                                  var attendee =
                                                      attendanceList[index];
                                                  final List<dynamic> contacts =
                                                      attendee["contact_num"] ??
                                                          [];

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(50, 0, 50, 0),
                                                    child: Card(
                                                      margin: EdgeInsets.all(2),
                                                      child: ListTile(
                                                        title: Text(
                                                            attendee["name"] ??
                                                                "Unknown"),
                                                        subtitle: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                "📧 Email: ${attendee["email_address"] ?? "N/A"}"),
                                                            Text(
                                                              contacts.isNotEmpty
                                                                  ? "📞 Contact: ${contacts.join(', ')}"
                                                                  : "📞 Contact: N/A",
                                                            ),
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
                                                                  ? Image
                                                                      .network(
                                                                      attendee[
                                                                          "signature_url"], // Use attendee-specific signature URL
                                                                      fit: BoxFit
                                                                          .contain,
                                                                      loadingBuilder: (context,
                                                                          child,
                                                                          loadingProgress) {
                                                                        if (loadingProgress ==
                                                                            null)
                                                                          return child;
                                                                        return Center(
                                                                            child:
                                                                                CircularProgressIndicator());
                                                                      },
                                                                      errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) {
                                                                        return Center(
                                                                            child:
                                                                                Text("Failed to load signature"));
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              (Status == "Cancelled" ||
                                                      Status == "Completed")
                                                  ? SizedBox
                                                      .shrink() // returns an empty widget
                                                  : IconButton(
                                                      icon: Icon(
                                                        Icons.close,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                      // This will trigger the cancelAppointment function
                                                          _showCancelDialog(widget
                                                              .selectedAgenda),
                                                    ),
                                              (Status == "Cancelled" ||
                                                      Status == "Completed")
                                                  ? SizedBox
                                                      .shrink() // returns an empty widget
                                                  : IconButton(
                                                      icon: Icon(
                                                        Icons.check_sharp,
                                                        color: Colors.blue,
                                                      ),
                                                      onPressed: () =>
                                                      // This will trigger the updateAppointmentStatus function
                                                          updateAppointmentStatus(
                                                              "Completed"))
                                            ],
                                          ),
                                          Text("Current Status: ${Status}"),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                              icon: Icon(Icons.download_sharp),
                                              onPressed: Status == "Cancelled"
                                                  ? null
                                                  : () {
                                                    // this will trigger the showcsvpdfdialog function
                                                      showcsvpdfdialog();
                                                    }),
                                          Text("Download Attendance")
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                              icon:
                                                  Icon(Icons.upload_file_sharp),
                                              onPressed: Status == "Cancelled"
                                                  ? null
                                                  : () {}),
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
                                            icon: Icon(
                                                Icons.qr_code_scanner_sharp),
                                            onPressed: (Status == "In Progress")
                                                ? () {
                                                  // This will trigger the QR code scanner and it will pass the agenda to the scanner
                                                  // and the agenda will be used to scan the QR code
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    MakeAForm(
                                                                      agenda:
                                                                          agendaController,
                                                                    )));
                                                  }
                                                : null, // Disables the button if condition is not met
                                          ),
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
