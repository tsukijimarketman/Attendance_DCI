import 'dart:async';
import 'dart:typed_data';

import 'package:attendance_app/404.dart';
import 'package:attendance_app/form/signature.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceForm extends StatefulWidget {
  final String roles;
  final String department;
  final String agenda;
  final String firstName;
  final String lastName;
  final int expiryTime;
  final int selectedScheduleTime;

  const AttendanceForm({
    required this.expiryTime,
    required this.roles,
    required this.department,
    required this.agenda,
    required this.firstName,
    required this.lastName,
    required this.selectedScheduleTime,
    super.key,
  });

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController emailAddController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  late Timer _timer;
  int remainingTime = 0; // Time in seconds
  late DateTime scheduledTime; // Moved initialization inside initState()

  @override
  void initState() {
    super.initState();
    scheduledTime =
        DateTime.fromMillisecondsSinceEpoch(widget.selectedScheduleTime);

    int now = DateTime.now().millisecondsSinceEpoch;

    // Check if QR Code expired (30 minutes limit)
    int qrExpiryTime = widget.expiryTime - (30 * 60 * 1000);
    if (now > qrExpiryTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NotFoundPage()),
        );
      });
      return;
    }

    // Check if form expired (1-hour limit)
    if (widget.expiryTime < now) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NotFoundPage()),
        );
      });
      return;
    }

    _startCountdown();
  }

  void _startCountdown() {
    int now = DateTime.now().millisecondsSinceEpoch;
    remainingTime = ((widget.expiryTime - now) / 1000).round();

    if (remainingTime > 0) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            remainingTime--;
          });

          if (remainingTime <= 0) {
            _timer.cancel();
            _showExpiredDialog();
          }
        }
      });
    } else {
      _showExpiredDialog();
    }
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("The Form Has Expired"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    companyController.dispose();
    emailAddController.dispose();
    contactController.dispose();
    _signatureController.dispose();
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  void submitForm() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add a signature!")));
      return;
    }

    // Convert signature to PNG bytes
    final Uint8List? signatureImage = await _signatureController.toPngBytes();
if (signatureImage == null || signatureImage.isEmpty) {
  print("⚠️ Signature image is empty or null.");
  return;
}
print("✅ Signature image size: ${signatureImage.length} bytes");

    // Upload to Supabase Storage
    final String? signatureUrl = await _uploadToSupabase(signatureImage);
    if (signatureUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save signature!")));
      return;
    }

    // Save form data to Firestore
    await FirebaseFirestore.instance.collection('attendance').add({
      'name': nameController.text,
      'company': companyController.text,
      'email_address': emailAddController.text,
      'contact_num': contactController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'agenda': widget.agenda,
      'department': widget.department,
      'createdBy': "${widget.firstName} ${widget.lastName}",
      'selectedScheduleTime': widget.selectedScheduleTime,
      'signature_url': signatureUrl, // Save signature URL
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Form submitted successfully!")));

    // Clear fields after submission
    nameController.clear();
    companyController.clear();
    emailAddController.clear();
    contactController.clear();
    _signatureController.clear();
  }

  Future<String?> _uploadToSupabase(Uint8List imageBytes) async {
  try {
    final client = Supabase.instance.client;
    final String fileName = "signature_${DateTime.now().millisecondsSinceEpoch}.png";

    print("🚀 Uploading signature: $fileName");

    final response = await client.storage
        .from("signatures") // Ensure this is the correct bucket
        .uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));

    print("📂 Upload Response: $response");

    // CHECK IF UPLOAD FAILED
    if (response.isEmpty) {
      print("❌ Supabase upload failed: No file path returned.");
      return null;
    }

    final String publicUrl = client.storage.from("signatures").getPublicUrl(fileName);
    print("✅ Upload successful: $publicUrl");

    return publicUrl;
  } catch (e) {
    print("❌ Error uploading to Supabase: $e");
    return null;
  }
}

  String formatDateTime(DateTime dateTime) {
    return DateFormat("MMMM d, yyyy 'at' h:mm a").format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Form')),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Agenda: ${widget.agenda}"),
              Text("Department: ${widget.department}"),
              Text("Schedule Appointment: ${formatDateTime(scheduledTime)}"),
              Text("Created by: ${widget.firstName} ${widget.lastName}"),
              remainingTime > 0
                  ? Text(
                      "Expires in: ${_formatTime(remainingTime)} minutes",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    )
                  : Text(
                      "Form has expired",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
              SizedBox(
                  height: 50,
                  width: 400,
                  child: CupertinoTextField(
                    controller: nameController,
                    placeholder: 'Name',
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                  height: 50,
                  width: 400,
                  child: CupertinoTextField(
                    controller: companyController,
                    placeholder: 'Company',
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                  height: 50,
                  width: 400,
                  child: CupertinoTextField(
                    controller: emailAddController,
                    placeholder: 'Email Address',
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                  height: 50,
                  width: 400,
                  child: CupertinoTextField(
                    controller: contactController,
                    placeholder: 'Contact Number',
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
              SizedBox(height: 20),
              Text('Please '),
              SizedBox(height: 300, child: SignatureApp(controller: _signatureController)),
              SizedBox(
                height: 50,
              ),
              SizedBox(
                  height: 50,
                  width: 300,
                  child: ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.all(Colors.amber),
                      ),
                      onPressed: submitForm,
                      child: Text("Submit"))),
            ],
          ),
        ),
      ),
    );
  }
}
