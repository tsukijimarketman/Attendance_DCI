import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:share_plus/share_plus.dart';

class DeptAttendee extends StatefulWidget {
    final String selectedAgenda;

  const DeptAttendee({
    super.key,
    required this.selectedAgenda,});  

  @override
  State<DeptAttendee> createState() => _DeptAttendeeState();
}

class _DeptAttendeeState extends State<DeptAttendee> {

  final TextEditingController agendaController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();
  final TextEditingController descriptionAgendaController =
      TextEditingController();
  String Status = '';
  String userDepartment = "";
String fullName = "";
bool isLoading = true;

  List<Map<String, dynamic>> attendanceList = [];

  List<Map<String, dynamic>> guests = [];
  List<Map<String, dynamic>> users = [];

@override
void initState() {
  super.initState();
  fetchUserDepartment().then((_) {
    fetchAppointmentData();
    fetchAttendancetData();
  });
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
          .where('department', isEqualTo: userDepartment)
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

           if (data.containsKey('internal_users') && data['internal_users'] is List) {
            users = List<Map<String, dynamic>>.from(data['internal_users']);
          }
        });
      } else {
        print("No appointment data found.");
      }
    } catch (e) {
      print("Error fetching appointment data: $e");
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
           var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
 
           setState(() {
             userDepartment = userData['department'] ?? "";
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

  Future<void> fetchAttendancetData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .where('department', isEqualTo: userDepartment)
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

  Future<Uint8List?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes; // Convert response to bytes
      }
    } catch (e) {
      print("Error fetching image: $e");
    }
    return null;
  }

  Future<Uint8List> loadAssetImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  void _generatePDF() async {
    final pdf = pw.Document();
    List<Map<String, dynamic>> attendeesWithSignatures = [];

    // **Fetch images before generating the PDF**
    for (var attendee in attendanceList) {
      Uint8List? imageBytes = await _fetchImage(attendee['signature_url']);
      attendeesWithSignatures.add({...attendee, 'signature_bytes': imageBytes});
    }

    Uint8List logoBytes = await loadAssetImage('assets/bag.png');
    Uint8List logoBytess = await loadAssetImage('assets/dci.jpg');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
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
                              child: pw.Text(attendee['contact_num'] ?? 'N/A')),
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

    final pdfBytes = await pdf.save();
    await Printing.sharePdf(bytes: pdfBytes, filename: 'attendance_report.pdf');
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


  Future<void> _generateCSV() async {
    List<List<String>> rows = [];

    // CSV Header
    rows.add(['Name', 'Company', 'Email Address', 'Contact No.']);

    // Data Rows
    for (var attendee in attendanceList) {

      rows.add([
        attendee['name'] ?? 'N/A',
        attendee['company'] ?? 'N/A',
        attendee['email_address'] ?? 'N/A',
        attendee['contact_num'] ?? 'N/A',
      ]);
    }

    // Convert to CSV String
    String csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      // ✅ Download CSV in Flutter Web
      final blob = html.Blob([csv], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "attendance_report.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // ✅ Save CSV on Android/iOS/Desktop
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/attendance_report.csv';

      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'Attendance Report CSV');
    }
  }

  void showcsvpdfdialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Download Attendance"),
          content: Text("Do you want to download the attendance in PDF or CSV?"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Image.asset('assets/pdf.png', width: 50, height: 50),
                  onPressed: () {
                                    _generatePDF();
                
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Image.asset("assets/csv.png", width: 50, height: 50),
                  onPressed: () {
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
                                  ? '${formatDate(scheduleController.text)}'
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



                          Divider(
                            thickness: 1,
                            height: 1,
                            color: Colors.black,
                          ),
                          SizedBox(
                            child: users.isEmpty
                                ? Center(child: Text("No users invited"))
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Invited Internal Users",
                                      style: TextStyle(color: Colors.black, fontSize: 18),
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
                                  padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                                  child: Card(
                                    margin: EdgeInsets.all(2),
                                    child: ListTile(
                                      title: Text(user["fullName"] ?? "Unknown"),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "📧 Email: ${user["email"] ?? "N/A"}"),
                                          Text(
                                              "🏢 Department: ${user["department"] ?? "N/A"}"),
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
                                                                                        Container(
                                              width: 800,
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 10),
                                              child: Column(
                                                children: [
                                                  IconButton(
                                                      icon: Icon(
                                                          Icons.download_sharp),
                                                      onPressed: () {
                                                        showcsvpdfdialog();
                                                      }),
                                                  Text("Download Attendance")
                                                ],
                                              ),
                                            ),
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
