import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MakeAForm extends StatefulWidget {
  const MakeAForm({super.key});

  @override
  State<MakeAForm> createState() => _MakeAFormState();
}

class _MakeAFormState extends State<MakeAForm> {
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();

  String firstName = "";
  String middleName = "";
  String lastName = "";
  DateTime? selectedExpiryTime; // Store selected date-time

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
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
            firstName = userData['first_name'] ?? "N/A";
            middleName = userData['middle_name'] ?? "N/A";
            lastName = userData['last_name'] ?? "N/A";
            departmentController.text = userData['department'] ?? ""; // Set department field
          });
        } else {
          print("No user document found.");
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    } else {
      print("No user is logged in.");
    }
  }

  void generateQRCode() {
  if (selectedExpiryTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select an expiration date and time")),
    );
    return;
  }

  int expiryTime = selectedExpiryTime!.millisecondsSinceEpoch;

  String qrUrl = "https://dci-attendance-0123.web.app//#/attendance_form"
      "?agenda=${Uri.encodeComponent(agendaController.text)}"
      "&department=${Uri.encodeComponent(departmentController.text)}"
      "&first_name=${Uri.encodeComponent(firstName)}"
      "&middle_name=${Uri.encodeComponent(middleName)}"
      "&last_name=${Uri.encodeComponent(lastName)}"
      "&expiryTime=${expiryTime}";

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => QRCodeScreen(
        qrData: qrUrl,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        expiryTime: expiryTime,
      ),
    ),
  );
}


  void pickExpiryDateTime() async {
  DateTime now = DateTime.now();

  // Show Date Picker
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now,
    lastDate: DateTime(2100),
  );

  if (pickedDate == null) return; // User canceled

  // Show Time Picker
  TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (pickedTime == null) return; // User canceled

  // Combine Date & Time
  DateTime fullDateTime = DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );

  setState(() {
    selectedExpiryTime = fullDateTime;
    expiryController.text = "${fullDateTime.toLocal()}".split('.')[0]; // Format display
  });
}

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Make a Attendance Form',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w400)),
            Text('User: $firstName $middleName $lastName',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Container(
  height: 50,
  width: 400,
  decoration: BoxDecoration(
    border: Border.all(color: Colors.amber, width: 1),
    borderRadius: BorderRadius.circular(10),
    color: Colors.grey[200], // Light grey background to indicate it's non-editable
  ),
  child: CupertinoTextField(
                controller: agendaController,
                placeholder: 'Agenda',
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
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
    color: Colors.grey[200], // Light grey background to indicate it's non-editable
  ),
  child: Text(
    departmentController.text.isNotEmpty ? departmentController.text : "Loading...",
    style: TextStyle(fontSize: 16, color: Colors.black),
  ),
),

            SizedBox(
              height: 10,
            ),
            GestureDetector(
  onTap: pickExpiryDateTime,
  child: Container(
    height: 50,
    width: 400,
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.amber, width: 1),
      borderRadius: BorderRadius.circular(10),
      color: Colors.grey[200], // Non-editable look
    ),
    child: Text(
      selectedExpiryTime != null
          ? "${selectedExpiryTime!.toLocal()}".split('.')[0]
          : "Select Expiration Date & Time",
      style: TextStyle(fontSize: 16, color: Colors.black),
    ),
  ),
),

            SizedBox(
              height: 10,
            ),
            SizedBox(
                height: 50,
                width: 400,
                child: ElevatedButton(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.all(Colors.amber),
                    ),
                    onPressed: generateQRCode,
                    child: const Text(
                      "Generate QR Code",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ))),
          ],
        ),
      ),
    );
  }
}

class QRCodeScreen extends StatefulWidget {
  final int expiryTime;
  final String qrData;
  final String firstName;
  final String middleName;
  final String lastName;

  const QRCodeScreen({
    super.key, 
    required this.expiryTime,
    required this.qrData,
    required this.firstName,
    required this.middleName,
    required this.lastName
    });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  late Timer _timer;
  int remainingTime = 0; // Time in seconds

  @override
  void initState() {
    super.initState();
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
        title: Text("QR Code Expired"),
        content: Text("The QR Code has expired. Please generate a new one."),
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
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  
 @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scan the QR Code to fill the form',
              style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w400),
            ),
            Text('Created By: ${widget.firstName} ${widget.middleName} ${widget.lastName}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 20),
            Center(child: QrImageView(data: widget.qrData, size: 300)),
            SizedBox(height: 20),
            remainingTime > 0
                ? Text(
                    "Expires in: ${_formatTime(remainingTime)} minutes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  )
                : Text(
                    "QR Code Expired",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
          ],
        ),
      ),
    );
  }
}