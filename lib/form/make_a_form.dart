import 'dart:async';
import 'package:attendance_app/Animation/Animation.dart';
import 'package:attendance_app/Auth/audit_function.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MakeAForm extends StatefulWidget {
  final TextEditingController agenda;

  MakeAForm({super.key, required this.agenda});

  @override
  State<MakeAForm> createState() => _MakeAFormState();
}

class _MakeAFormState extends State<MakeAForm> {
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();

  String firstName = "";
  String lastName = "";

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
            lastName = userData['last_name'] ?? "N/A";
            departmentController.text =
                userData['department'] ?? ""; // Set department field
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

  void generateQRCode() async {
    if (widget.agenda.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an expiration date and time")),
      );
      return;
    }

    int now = DateTime.now().millisecondsSinceEpoch;

    int qrExpiryTime = now + (30 * 60 * 1000);
    // Form expires in 1 hour
    int formExpiryTime = now + (60 * 60 * 1000);

    String qrUrl = "https://attendance-dci.web.app//#/attendance_form"
        "?agenda=${Uri.encodeComponent(widget.agenda.text)}"
        "&department=${Uri.encodeComponent(departmentController.text)}"
        "&first_name=${Uri.encodeComponent(firstName)}"
        "&last_name=${Uri.encodeComponent(lastName)}"
        "&expiryTime=${formExpiryTime}";

    try {
      // ✅ Audit Trail: Log when a user generates a QR Code
      await logAuditTrail("Generated Attendance Form",
          "User $firstName $lastName generated a QR code for agenda: ${widget.agenda.text} in department: ${departmentController.text}");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRCodeScreen(
            qrData: qrUrl,
            firstName: firstName,
            lastName: lastName,
            expiryTime: qrExpiryTime,
          ),
        ),
      );
    } catch (e) {
      print("Error logging audit trail: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Center(
        child: Container(
          height: 500,
          width: 800,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Make a Attendance Form',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w400)),
              Text('User: $firstName $lastName',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Container(
                height: 50,
                width: 400,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 1),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[
                      200], // Light grey background to indicate it's non-editable
                ),
                child: Text(
                  '${widget.agenda.text}',
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
                  border: Border.all(color: Colors.blue, width: 1),
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
                        backgroundColor: WidgetStateProperty.all(Colors.blue),
                      ),
                      onPressed: generateQRCode,
                      child: const Text(
                        "Generate QR Code",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ))),
            ],
          ),
        ),
      ),
    ));
  }
}

class QRCodeScreen extends StatefulWidget {
  final int expiryTime;
  final String qrData;
  final String firstName;
  final String lastName;

  const QRCodeScreen(
      {super.key,
      required this.expiryTime,
      required this.qrData,
      required this.firstName,
      required this.lastName});

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
    return Scaffold(
        body: SafeArea(
      child: Center(
        child: Container(
          height: 500,
          width: 800,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Scan the QR Code to fill the form',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w400),
              ),
              Text('Created By: ${widget.firstName} ${widget.lastName}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 20),
              Center(
                child: Container(
                  padding: EdgeInsets.all(15), // Space around the QR code
                  decoration: BoxDecoration(
                    color: Colors.white, // White background surrounding the QR
                    border: Border.all(
                        color: Colors.blue, width: 4), // Outer border
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.qrData,
                    size: 300,
                    backgroundColor: Colors.white, // White behind QR pixels
                    embeddedImage: AssetImage(
                        'assets/dci.jpg'), // Your static logo image here
                    embeddedImageStyle: QrEmbeddedImageStyle(
                      size: Size(70, 70), // Adjust the logo size as needed
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              remainingTime > 0
                  ? Text(
                      "Expires in: ${_formatTime(remainingTime)} minutes",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    )
                  : Text(
                      "QR Code Expired",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
            ],
          ),
        ),
      ),
    ));
  }
}
