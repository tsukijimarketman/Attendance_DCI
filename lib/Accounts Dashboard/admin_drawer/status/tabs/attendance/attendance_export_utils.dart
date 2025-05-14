import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:share_plus/share_plus.dart';

class AttendanceExportUtils {
  // The `fetchImage` method is a static asynchronous function designed to fetch an image from a provided URL.
// It takes a nullable string `url` as an argument, which represents the location of the image to be fetched.
// The method first checks if the URL is null or empty and returns null immediately if so, avoiding unnecessary network requests.
// If the URL is valid, it uses the `http.get` method to make an HTTP request to the URL.
// If the response has a successful status code (200), the function converts the response's body into a byte array (Uint8List), which is suitable for image processing or display.
// In case of any exceptions or failed network requests, the method catches the error and returns null.
// Finally, if the image is not successfully fetched or if the URL is invalid, the function will return null.
  static Future<Uint8List?> fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes; // Convert response to bytes
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // The `loadAssetImage` method is a static asynchronous helper function used to load image data from the app's assets.
// It takes a string `path` as an argument, which represents the location of the image within the app's assets directory.
// The method uses `rootBundle.load(path)` to load the image file as raw byte data from the asset bundle.
// The loaded byte data is then converted into a `Uint8List`, which is a suitable format for handling image data in Flutter.
// This function is useful for loading images stored within the app's assets, allowing the image to be processed or displayed within the app.
  static Future<Uint8List> loadAssetImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  // Format timestamp for PDF
  static String formatTimestamp(dynamic timestamp) {
    if (timestamp is DateTime) {
      return DateFormat("MMMM d yyyy 'at' h:mm a").format(timestamp);
    } else {
      return "N/A";
    }
  }

  // Format date string
  static String formatDate(String timestamp) {
    try {
      DateTime parsedDate = DateTime.parse(timestamp);
      return DateFormat("MMMM d yyyy 'at' h:mm a").format(parsedDate);
    } catch (e) {
      return "Invalid date";
    }
  }

  // The `generatePDF` method is a static asynchronous function designed to generate a PDF document containing an attendance sheet.
// It accepts three parameters: `attendanceList`, which is a list of maps containing data for each attendee, `agenda` for the event's agenda,
// and `schedule` for the date and time of the event. The method starts by creating a new PDF document using the `pw.Document()` class from
// the `pdf` package. It then retrieves each attendee's signature image as bytes using the `fetchImage` function and appends these to the
// original attendee data. The method also loads two logo images from the app's assets using `loadAssetImage` and prepares them for inclusion
// in the document header. The document's structure is organized with a header (including logos and event details), a footer (with contact
// and document information), and the main content which is a table listing the attendees' details (name, company, email, contact number, and signature).
// The PDF is saved and shared using the `Printing` package to allow the user to download or share the generated document.
  static Future<void> generatePDF({
    required List<Map<String, dynamic>> attendanceList,
    required String agenda,
    required String schedule,
  }) async {
    final pdf = pw.Document();
    List<Map<String, dynamic>> attendeesWithSignatures = [];

    // Fetch images before generating the PDF
    for (var attendee in attendanceList) {
      Uint8List? imageBytes = await fetchImage(attendee['signature_url']);
      attendeesWithSignatures.add({...attendee, 'signature_bytes': imageBytes});
    }

    Uint8List logoBytes = await loadAssetImage('assets/bag.png');
    Uint8List logoBytess = await loadAssetImage('assets/dci.jpg');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(30),

        // HEADER - This will appear on every page
        header: (context) => pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Date & Time: ${schedule.isNotEmpty ? formatDate(schedule) : "No Schedule"}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Agenda: $agenda',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // FOOTER - This will appear on every page
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

        // CONTENT - The table will auto-continue on new pages
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

    final pdfBytes = await pdf.save();
    await Printing.sharePdf(bytes: pdfBytes, filename: 'attendance_report.pdf');
  }

  // The `generateCSV` method is a static asynchronous function that generates a CSV file containing an attendance report from the provided `attendanceList`.
// The method starts by initializing a list of rows, where each row represents a line in the CSV file. The first row is the header containing the column names
// ('Name', 'Company', 'Email Address', 'Contact No.'). For each attendee in the `attendanceList`, the method creates a new row that includes the attendee's
// details such as name, company, email address, and contact number. If the contact number is a list, it is joined by commas; if it's a string, it is used directly;
// otherwise, it defaults to 'N/A'. The entire list of rows is then converted into a CSV string using the `ListToCsvConverter` from the `csv` package.
// Depending on the platform, the method handles the CSV file differently: on Flutter Web, it creates a downloadable Blob and triggers a download; on mobile (Android/iOS)
// and desktop, it saves the CSV file to the device's documents directory and allows the user to share the file via the `Share` package.
  static Future<void> generateCSV(
      List<Map<String, dynamic>> attendanceList) async {
    List<List<String>> rows = [];

    // CSV Header
    rows.add(['Name', 'Company', 'Email Address', 'Contact No.']);

    // Data Rows
    for (var attendee in attendanceList) {
      rows.add([
        attendee['name'] ?? 'N/A',
        attendee['company'] ?? 'N/A',
        attendee['email_address'] ?? 'N/A',
        (() {
          final contact = attendee['contact_num'];
          if (contact is List) {
            return contact.join(', ');
          } else if (contact is String) {
            return contact;
          } else {
            return 'N/A';
          }
        })(),
      ]);
    }

    // Convert to CSV String
    String csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      // Download CSV in Flutter Web
      final blob = html.Blob([csv], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "attendance_report.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Save CSV on Android/iOS/Desktop
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/attendance_report.csv';

      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'Attendance Report CSV');
    }
  }
}
