import 'dart:async';
import 'package:attendance_app/Auth/audit_function.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MakeAForm extends StatefulWidget {
  /// Controller for the agenda input, passed from the previous screen.
  final TextEditingController agenda;

  MakeAForm({
    super.key, required this.agenda});

  @override
  State<MakeAForm> createState() => _MakeAFormState();
}

class _MakeAFormState extends State<MakeAForm> {
  /// Controller for the schedule input, used to fetch user data.
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();

  /// Variables to store user data.
  String firstName = "";
  String lastName = "";

  // This method is called when the widget is first created.
  // It fetches user data from Firestore and updates the state of the widget.
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  /// Fetches user data from Firestore based on the current user's UID.
  /// Updates the state with the fetched data.
  /// Handles errors and shows a snackbar if no user is logged in.
  Future<void> fetchUserData() async {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    // If the user is not null, fetch their data from Firestore
    // If the user is null (show a snackbar indicating no user is logged in)
    if (user != null) {
      try {
        // Query Firestore to get the user document based on UID
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        // If the query returns documents, extract the first document's data
        // If no documents are found, show a snackbar indicating no user document found
        if (querySnapshot.docs.isNotEmpty) {
          var userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;

          // Update the state with the user's first name, last name, and department
          // If any of these fields are null, set them to "N/A" or an empty string
          setState(() {
            firstName = userData['first_name'] ?? "N/A";
            lastName = userData['last_name'] ?? "N/A";
            departmentController.text =
                userData['department'] ?? ""; // Set department field
          });
        } else {
          // If no user document is found, show a snackbar indicating the issue
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No user document found.")),
          );
        }
        // If any error occurs during the query, catch it and show a snackbar with the error message
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching user data: $e")),
        );
      }
      // If the user is null (not logged in), show a snackbar indicating the issue
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No user is logged in.")),
      );
    }
  }

  /// Generates a QR code with the agenda, department, and user data.
  /// Creates a URL with the data and navigates to the QR code screen.
  void generateQRCode() async {
    // Check if the agenda text is empty
    // If it is, show a snackbar indicating the issue
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

    // Create a URL with the agenda, department, and user data
    // The URL is encoded to ensure it is safe for use in a web context
    // The URL points to the attendance form page with the necessary parameters
    // The parameters include the agenda, department, first name, last name, and expiry time

    String qrUrl = "https://attendance-dci.web.app//#/attendance_form"
        "?agenda=${Uri.encodeComponent(widget.agenda.text)}"
        "&department=${Uri.encodeComponent(departmentController.text)}"
        "&first_name=${Uri.encodeComponent(firstName)}"
        "&last_name=${Uri.encodeComponent(lastName)}"
        "&expiryTime=${formExpiryTime}";
    
    // Log the audit trail when a user generates a QR code
    try {
      // ✅ Audit Trail: Log when a user generates a QR Code
      await logAuditTrail("Generated Attendance Form",
          "User $firstName $lastName generated a QR code for agenda: ${widget.agenda.text} in department: ${departmentController.text}");


      // Navigate to the QR code screen with the generated URL and user data
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
      print('');
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
                      // This will Trigger the QR code generation when pressed
                      // It will also log the audit trail for the QR code generation
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

/// Screen that displays a QR Code and handles expiry logic.
class QRCodeScreen extends StatefulWidget {
  final int expiryTime;    // Time when the QR code expires (milliseconds since epoch)
  final String qrData;     // The data encoded inside the QR code
  final String firstName;  // First name of the user
  final String lastName;   // Last name of the user

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
  late Timer _timer; // Timer for countdown
  int remainingTime = 0; // Time in seconds

  // This method is called when the widget is first created.
  // It initializes the countdown timer and checks if the QR code has expired.
  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  /// Starts the countdown timer based on the expiry time of the QR code.
  /// If the QR code is already expired, it shows an expired dialog.
  /// If the QR code is still valid, it starts a periodic timer to update the remaining time.
  void _startCountdown() {
    // Get the current time in milliseconds since epoch
    // Calculate the remaining time until the QR code expires
    int now = DateTime.now().millisecondsSinceEpoch;
    remainingTime = ((widget.expiryTime - now) / 1000).round();

    // Check if the remaining time is greater than 0
    // If it is, start a periodic timer that updates the remaining time every second
    if (remainingTime > 0) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            remainingTime--;
          });

          // If the remaining time is less than or equal to 0, cancel the timer and show an expired dialog
          // This indicates that the QR code has expired
          // and the user should take appropriate action (e.g., generate a new QR code)
          if (remainingTime <= 0) {
            _timer.cancel();
            _showExpiredDialog();
          }
        }
      });
    } else {
      // If the remaining time is already 0 or less, show the expired dialog immediately
      _showExpiredDialog();
    }
  }

  /// Shows a dialog indicating that the QR code has expired.
  /// The dialog has an "OK" button that allows the user to dismiss it and go back to the previous screen.
  /// This is useful for informing the user that they need to generate a new QR code.
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

  /// Disposes of the timer when the widget is removed from the widget tree.
  /// This is important to prevent memory leaks and ensure that the timer does not continue running after the widget is no longer visible.
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// This is useful for displaying the remaining time in a user-friendly format.
  /// It takes the remaining time in seconds and converts it to a string in the format "minutes:seconds".
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
