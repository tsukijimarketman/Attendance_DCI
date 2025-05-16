import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointmentconfig extends StatefulWidget {
  final String searchQuery;

  const Appointmentconfig({
    super.key,
    this.searchQuery = '',
  });

  @override
  State<Appointmentconfig> createState() => _AppointmentconfigState();
}

class _AppointmentconfigState extends State<Appointmentconfig> {
  bool googleCalendarEnabled = false;
  bool emailSenderEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchConfig(); // Load initial values from Firestore
  }

  Future<void> fetchConfig() async {
    try {
      final googleDoc = await FirebaseFirestore.instance
          .collection('appointment_config')
          .doc('google_calendar')
          .get();

      final emailDoc = await FirebaseFirestore.instance
          .collection('appointment_config')
          .doc('email_sender')
          .get();

      setState(() {
        googleCalendarEnabled = googleDoc.get('isActive') == true;
        emailSenderEnabled = emailDoc.get('isActive') == true;
      });
    } catch (e) {
      print("Error fetching config: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Enable Google Calendar"),
                value: googleCalendarEnabled,
                onChanged: (bool value) async {
                  setState(() {
                    googleCalendarEnabled = value;
                  });

                  await FirebaseFirestore.instance
                      .collection('appointment_config')
                      .doc('google_calendar')
                      .set({'isActive': value}, SetOptions(merge: true));
                },
                secondary: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text("Enable Email Sender"),
                value: emailSenderEnabled,
                onChanged: (bool value) async {
                  setState(() {
                    emailSenderEnabled = value;
                  });

                  await FirebaseFirestore.instance
                      .collection('appointment_config')
                      .doc('email_sender')
                      .set({'isActive': value}, SetOptions(merge: true));
                },
                secondary: const Icon(Icons.email),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
