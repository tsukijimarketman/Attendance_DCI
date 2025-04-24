import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class MinutesOfMeeting extends StatefulWidget {
  final String selectedAgenda;
  const MinutesOfMeeting({super.key, required this.selectedAgenda});

  @override
  State<MinutesOfMeeting> createState() => _MinutesOfMeetingState();
}

class _MinutesOfMeetingState extends State<MinutesOfMeeting> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SupabaseClient? _supabase;

  // State variables
  bool isLoading = true;
  String _meetingDate = '';
  List<Map<String, dynamic>> attendeesList = [];
  String _fileAttachmentPath = '';
  String _fileAttachmentName = '';
  bool _isUploading = false;

  // Email composition fields
  TextEditingController _recipientsController = TextEditingController();
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMeetingData();
    _initializeSupabase().then((_) {
      if (_supabase == null) {
        // If Supabase couldn't be initialized after the first attempt,
        // try again after a short delay
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _initializeSupabase();
          }
        });
      }
    });
  }

  Future<void> _initializeSupabase() async {
    try {
      // Try to get the client directly without checking the instance first
      _supabase = Supabase.instance.client;
      print("Supabase client retrieved successfully!");
    } catch (e) {
      print("Error getting Supabase client: $e");
      // Only show a snackbar if the widget is mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error connecting to Supabase: $e')));
      }
    }
  }

  @override
  void dispose() {
    _recipientsController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMeetingData() async {
    setState(() => isLoading = true);

    try {
      // Fetch appointment data to get meeting date
      QuerySnapshot appointmentSnapshot = await _firestore
          .collection('appointment')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .limit(1)
          .get();

      if (appointmentSnapshot.docs.isNotEmpty) {
        var appointmentData =
            appointmentSnapshot.docs.first.data() as Map<String, dynamic>;
        if (appointmentData.containsKey('schedule')) {
          // Format the date nicely
          DateTime scheduleDate = DateTime.parse(appointmentData['schedule']);
          _meetingDate = DateFormat('yyyy-MM-dd, h:mm a').format(scheduleDate);
        }
      }

      // Fetch attendance data to get attendees who were present
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .get();

      if (attendanceSnapshot.docs.isNotEmpty) {
        attendeesList = attendanceSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // Create recipient list for the email
        String recipients = attendeesList
            .map((attendee) => attendee['email_address'] ?? '')
            .where((email) => email.isNotEmpty)
            .join(', ');

        _recipientsController.text = recipients;
      }

      // Set up email subject with the agenda and date
      _subjectController.text =
          "Meeting Summary – ${widget.selectedAgenda} – $_meetingDate";

      // Set up email body with the HTML template
      _messageController.text = _getEmailTemplate();
    } catch (e) {
      print("Error fetching meeting data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getEmailTemplate() {
    return '''<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #ffffff;
      color: #333333;
      padding: 20px;
      line-height: 1.6;
    }
    .header {
      background-color: #0e2643;
      padding: 20px;
      text-align: center;
      color: white;
      border-radius: 8px 8px 0 0;
    }
    .content {
      padding: 20px;
      border: 1px solid #e0e0e0;
      border-top: none;
      border-radius: 0 0 8px 8px;
    }
    .button {
      display: inline-block;
      background-color: #8B0000;
      color: white;
      padding: 12px 24px;
      text-decoration: none;
      border-radius: 5px;
      font-weight: bold;
      margin: 20px 0;
    }
    .footer {
      margin-top: 40px;
      font-size: 12px;
      color: #888888;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="header">
    <h2>DBP-Data Center Inc.</h2>
    <p>Meeting Summary Notification</p>
  </div>
  <div class="content">
    <p>Dear <strong>Attendees</strong>,</p>
    <p>Thank you for attending the meeting titled <strong>${widget.selectedAgenda}</strong> held on <strong>$_meetingDate</strong>.</p>
    <p>We have prepared the official minutes of the meeting, which includes key points discussed, decisions made, and relevant information for your reference.</p>
    <p>You can download the document using the button below:</p>
    <a href="[DOWNLOAD_LINK]" class="button">📄 Download Meeting Minutes</a>
    <p>If you have any questions or require further information, feel free to reply to this email.</p>
    <p>Best regards,<br>
    <strong>DBP-Data Center Inc. Secretariat</strong></p>
  </div>
  <div class="footer">
    © 2025 DBP-Data Center Inc. All rights reserved.
  </div>
</body>
</html>''';
  }

  Future<void> _selectFile() async {
    try {
      print("Starting file selection...");

      // Check if Supabase client is initialized
      if (_supabase == null) {
        print("Supabase client is not initialized yet");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please wait, connecting to storage...')));
        await _initializeSupabase(); // Try to initialize again

        // If still not initialized, return
        if (_supabase == null) {
          return;
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      print(
          "File picker result: ${result != null ? 'File selected' : 'No file selected'}");

      if (result != null) {
        setState(() {
          _fileAttachmentPath = result.files.single.path!;
          _fileAttachmentName = result.files.single.name;
        });
        print("Selected file: $_fileAttachmentName");
      }
    } catch (e) {
      print("Error in file selection: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    }
  }

  Future<void> _uploadFileToSupabase() async {
    if (_fileAttachmentPath.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a file first')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final file = File(_fileAttachmentPath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$_fileAttachmentName';

      // Upload to Supabase storage using the existing instance
      await _supabase!.storage.from('meetingminutes').upload(fileName, file);

      // Get public URL
      final fileUrl =
          _supabase!.storage.from('meetingminutes').getPublicUrl(fileName);

      // Update email template with the download link
      String updatedEmailBody =
          _messageController.text.replaceAll('[DOWNLOAD_LINK]', fileUrl);
      _messageController.text = updatedEmailBody;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('File uploaded successfully!')));
    } catch (e) {
      print("Error uploading file: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildMinutesOfMeeting();
  }

  Widget _buildMinutesOfMeeting() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        height: screenWidth / 1.15,
        width: screenWidth / 1.5,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Meeting Minutes - Email Composer',
              style: TextStyle(
                fontSize: screenWidth / 60,
                fontFamily: "B",
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            // Email Composition Form (Gmail-like)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipients Field
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'To:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _recipientsController,
                          decoration: InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: 'Recipients',
                          ),
                          maxLines: null,
                        ),
                      ),
                    ],
                  ),
                  Divider(),

                  // Subject Field
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Subject:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(),

                  // File Attachment
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Attach:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.attach_file),
                              label: Text('Select File'),
                              onPressed: _selectFile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 10),
                            if (_fileAttachmentName.isNotEmpty)
                              Chip(
                                label: Text(_fileAttachmentName),
                                deleteIcon: Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _fileAttachmentPath = '';
                                    _fileAttachmentName = '';
                                  });
                                },
                              ),
                            Spacer(),
                            if (_fileAttachmentName.isNotEmpty && !_isUploading)
                              TextButton.icon(
                                icon: Icon(Icons.cloud_upload),
                                label: Text('Upload to Supabase'),
                                onPressed: _uploadFileToSupabase,
                              ),
                            if (_isUploading)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Uploading...'),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(),

                  // Email Body
                  SizedBox(height: 10),
                  Text(
                    'Email Body:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(8),
                      ),
                      maxLines: null,
                      expands: true,
                    ),
                  ),

                  // Actions
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Placeholder for sending email functionality
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Email sent successfully!')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0e2643),
                        ),
                        child: Text('Send Email'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Preview Section
            SizedBox(height: 20),
            Text(
              'Email Preview:',
              style: TextStyle(
                fontSize: screenWidth / 80,
                fontFamily: "SB",
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10)),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          color: Color(0xFF0e2643),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Text(
                                'DBP-Data Center Inc.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Meeting Summary Notification',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dear Attendees,',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Thank you for attending the meeting titled "${widget.selectedAgenda}" held on $_meetingDate.',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'We have prepared the official minutes of the meeting, which includes key points discussed, decisions made, and relevant information for your reference.',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'You can download the document using the button below:',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),
                            Center(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.file_download),
                                label: Text('Download Meeting Minutes'),
                                onPressed: null, // This is just a preview
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8B0000),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'If you have any questions or require further information, feel free to reply to this email.',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Best regards,',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              'DBP-Data Center Inc.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
