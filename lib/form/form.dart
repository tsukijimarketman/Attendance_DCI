import 'dart:async';

import 'package:attendance_app/404.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
  late Timer _timer;
  int remainingTime = 0; // Time in seconds
  late DateTime scheduledTime; // Moved initialization inside initState()

 @override
void initState() {
  super.initState();
  scheduledTime = DateTime.fromMillisecondsSinceEpoch(widget.selectedScheduleTime);

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
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  void submitForm() async {
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
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Form submitted successfully!")));
  }

  String formatDateTime(DateTime dateTime) {
  return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
         "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Form')),
      body: Padding(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  )
                : Text(
                    "Form has expired",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
            SizedBox(
              height: 50,
              width: 400, 
            child: CupertinoTextField(
              controller: nameController, 
              placeholder: 'Name',
              decoration: BoxDecoration(
              border:Border.all(color: Colors.amber, width: 1),
              borderRadius: BorderRadius.circular(10),
              ),
            )
          ),
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
                border:Border.all(color: Colors.amber, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
            )
          ),
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
                border:Border.all(color: Colors.amber, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
            )
          ),
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
                border:Border.all(color: Colors.amber, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
            )
          ),
            SizedBox(height: 20),
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
    );
  }
}
