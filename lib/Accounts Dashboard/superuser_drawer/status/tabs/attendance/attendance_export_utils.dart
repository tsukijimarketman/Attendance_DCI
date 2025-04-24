import 'dart:convert';
import 'dart:typed_data';
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
  // Helper method to fetch images from URLs
  static Future<Uint8List?> fetchImage(String? url) async {
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

  // Helper method to load images from assets
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
      print("Error formatting date: $e");
      return "Invalid date";
    }
  }

  // Generate and share PDF
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
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
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
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
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
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Company',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Email Address',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Contact No.',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(5),
                              child: pw.Text('Signature',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
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
                              child: pw.Text(attendee['email_address'] ?? 'N/A')),
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
                                      pw.MemoryImage(attendee['signature_bytes']!),
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

  // Generate and share CSV
  static Future<void> generateCSV(List<Map<String, dynamic>> attendanceList) async {
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