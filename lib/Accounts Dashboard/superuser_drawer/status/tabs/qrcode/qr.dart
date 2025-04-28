import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance_app/Auth/audit_function.dart';

class QrCode extends StatefulWidget {
  final String selectedAgenda;
  const QrCode({super.key, required this.selectedAgenda});

  @override
  State<QrCode> createState() => _QrCodeState();
}

class _QrCodeState extends State<QrCode> {
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();

  bool isQrGenerated = false;
  bool isFormCreated = false;
  String qrUrl = "";
  int qrExpiryTime = 0;
  String firstName = "";
  String lastName = "";
  int remainingTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    agendaController.text = widget.selectedAgenda;
    fetchUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
            departmentController.text = userData['department'] ?? "";
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

  void generateQrCode() {
    setState(() {
      isQrGenerated = true;
    });
  }

  void createForm() async {
    if (agendaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please provide an agenda")),
      );
      return;
    }

    int now = DateTime.now().millisecondsSinceEpoch;

    qrExpiryTime = now + (30 * 60 * 1000); // QR expires in 30 minutes
    int formExpiryTime = now + (60 * 60 * 1000); // Form expires in 1 hour

    qrUrl = "https://attendance-dci.web.app//#/attendance_form"
        "?agenda=${Uri.encodeComponent(agendaController.text)}"
        "?department=${Uri.encodeComponent(departmentController.text)}"
        "&first_name=${Uri.encodeComponent(firstName)}"
        "&last_name=${Uri.encodeComponent(lastName)}"
        "&expiryTime=${formExpiryTime}";

    try {
      // Audit Trail: Log when a user generates a QR Code
      await logAuditTrail("Generated Attendance Form",
          "User $firstName $lastName generated a QR code for agenda: ${agendaController.text} in department: ${departmentController.text}");

      setState(() {
        isFormCreated = true;
        _startCountdown();
      });
    } catch (e) {
      print("Error logging audit trail: $e");
    }
  }

  void _startCountdown() {
    int now = DateTime.now().millisecondsSinceEpoch;
    remainingTime = ((qrExpiryTime - now) / 1000).round();

    if (remainingTime > 0) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            remainingTime--;
          });

          if (remainingTime <= 0) {
            _timer?.cancel();
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
              setState(() {
                isFormCreated = false;
              });
            },
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isFormCreated
          ? _buildQRCodeView()
          : isQrGenerated
              ? _buildFormView()
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xFF0e2643),
                  ),
                  child: _buildQrCodeScreen()),
    );
  }

  Widget _buildQrCodeScreen() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Meeting QR Code',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),

          // Show placeholder with message when QR is not yet generated
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Generate QR Code for Meeting Attendance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1367b6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Generate QR button
          ElevatedButton.icon(
            onPressed: generateQrCode,
            icon: const Icon(Icons.qr_code),
            label: const Text('Generate QR Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1367b6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xFF0e2643),
      ),
      child: SafeArea(
        child: Center(
          child: Card(
            margin: EdgeInsets.all(16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Make an Attendance Form',
                      style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF1367b6),
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('User: $firstName $lastName',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700])),
                  SizedBox(height: 30),
                  Container(
                    height: 50,
                    width: 400,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF1367b6), width: 1),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[50],
                    ),
                    child: Text(
                      '${agendaController.text}',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 50,
                    width: 400,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF1367b6), width: 1),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[50],
                    ),
                    child: Text(
                      departmentController.text.isNotEmpty
                          ? departmentController.text
                          : "Loading...",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                      height: 50,
                      width: 400,
                      child: ElevatedButton(
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            backgroundColor:
                                MaterialStateProperty.all(Color(0xFF0e2643)),
                            elevation: MaterialStateProperty.all(0),
                          ),
                          onPressed: createForm,
                          child: const Text(
                            "Generate QR Code",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeView() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0e2643),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SafeArea(
        child: Center(
          child: Card(
            margin: EdgeInsets.all(16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Scan the QR Code to fill the form',
                    style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF1367b6),
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Created By: $firstName $lastName',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700])),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xFF1367b6), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: qrUrl,
                      size: 240,
                      backgroundColor: Colors.white,
                      embeddedImage: AssetImage('assets/dci.jpg'),
                      embeddedImageStyle: QrEmbeddedImageStyle(
                        size: Size(60, 60),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
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
        ),
      ),
    );
  }
}
