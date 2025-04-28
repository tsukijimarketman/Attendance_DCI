import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For base64Encoding
import 'package:attendance_app/secrets.dart';
import 'package:flutter_html/flutter_html.dart';

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
  String _savedEmailContent = '';
  String _fileAttachmentName = '';
  Uint8List? _fileBytes;
  bool _isUploading = false;
  bool _isSendingEmail = false;
  String _fileUrl = ''; // Store the URL after upload

  final String _senderName = 'DBP-Data Center Inc.';

  bool _isEditingEmailTemplate = false; // Track edit mode

  // Email composition fields
  TextEditingController _recipientsController = TextEditingController();
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  TextEditingController _htmlEditorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMeetingData();
    _initializeSupabase().then((_) {
      if (_supabase == null) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _initializeSupabase();
          }
        });
      }
    });

    // Initialize with default content only if we don't have saved content
    if (_messageController.text.isEmpty) {
      _messageController.text = _getEmailContent();
    }
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
    _htmlEditorController.dispose();
    super.dispose();
  }

  Future<void> _fetchMeetingData() async {
    setState(() => isLoading = true);

    if (_messageController.text.isEmpty) {
      String emailContent = _getEmailContent();
      _messageController.text = emailContent;
      _htmlEditorController.text = emailContent;
    }

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

      // Set up email body for the editable version
      String emailContent = _getEmailContent();
      _messageController.text = emailContent;
      _htmlEditorController.text = emailContent;
    } catch (e) {
      print("Error fetching meeting data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getEmailContent() {
    return '''Dear Attendees,

Thank you for attending the meeting titled "${widget.selectedAgenda}" held on $_meetingDate.

We have prepared the official minutes of the meeting, which includes key points discussed, decisions made, and relevant information for your reference.

You can download the document using the link below:
[DOWNLOAD_LINK]

If you have any questions or require further information, feel free to reply to this email.

Best regards,
DBP-Data Center Inc.''';
  }

  String _getEmailTemplate() {
    // Process the email content to keep the user's edits
    String userContent =
        _messageController.text; // Use the current edited content

    // Replace [DOWNLOAD_LINK] with the actual button HTML
    String downloadButton =
        '''<a href="${_fileUrl}" class="button" style="display: inline-block; background-color: #8B0000; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0;">📄 Download Meeting Minutes</a>''';

    String processedContent =
        userContent.replaceAll('[DOWNLOAD_LINK]', downloadButton);

    // Convert plain text to HTML paragraphs
    processedContent = processedContent
        .split('\n\n')
        .map((paragraph) => '<p>${paragraph.replaceAll('\n', '<br/>')}</p>')
        .join('');

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
    $processedContent
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
          _fileBytes = result.files.single.bytes;
          _fileUrl = ''; // Reset file URL when new file is selected
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
    if (_fileBytes == null || _fileAttachmentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$_fileAttachmentName';

      await _supabase!.storage
          .from('meetingminutes')
          .uploadBinary(fileName, _fileBytes!);

      final fileUrl =
          _supabase!.storage.from('meetingminutes').getPublicUrl(fileName);

      // Store the URL for later use
      setState(() {
        _fileUrl = fileUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File uploaded successfully!')),
      );
    } catch (e) {
      print("Error uploading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Validate email addresses
  bool _validateEmails(List<String> emails) {
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    bool allValid = true;
    for (String email in emails) {
      String trimmedEmail = email.trim();
      if (trimmedEmail.isNotEmpty && !emailRegex.hasMatch(trimmedEmail)) {
        allValid = false;
        break;
      }
    }
    return allValid;
  }

  Future<void> _sendEmail() async {
    // Check if file has been uploaded
    if (_fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please upload a file first before sending the email')),
      );
      return;
    }

    // Get and validate recipients
    List<String> recipients = _recipientsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one recipient')),
      );
      return;
    }

    if (!_validateEmails(recipients)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('One or more email addresses are invalid')),
      );
      return;
    }

    setState(() => _isSendingEmail = true);

    try {
      // Create a Dio instance for API request
      final dio = Dio();

      // Get the current email content
      String emailBody = _getEmailTemplate();

      // Prepare template parameters for EmailJS API
      final Map<String, dynamic> templateParams = {
        'to_emails': recipients.join(', '),
        'subject': _subjectController.text,
        'message_html': emailBody, // Already processed HTML content
        'sender_name': _senderName,
        'meeting_agenda': widget.selectedAgenda,
        'meeting_date': _meetingDate,
        'file_url': _fileUrl,
      };

      // Prepare data for EmailJS API
      final Map<String, dynamic> emailJsData = {
        'service_id': AppSecrets.emailJsServiceId,
        'template_id': AppSecrets.emailJsTemplateId,
        'template_params': templateParams,
        'user_id': AppSecrets
            .emailJsUserId, // Make sure to include this from the second file
      };

      // Add debug prints to check API request details
      print('Sending request to EmailJS API');
      print('Email data: $emailJsData');

      // Send the request to EmailJS API
      final response = await dio.post(
        'https://api.emailjs.com/api/v1.0/email/send',
        data: emailJsData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) =>
              status! < 500, // Accept all status codes less than 500
        ),
      );

      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Try to create a record in Firestore for tracking
        try {
          await _firestore.collection('email_logs').add({
            'agenda': widget.selectedAgenda,
            'recipients': recipients,
            'sent_at': FieldValue.serverTimestamp(),
            'file_url': _fileUrl,
            'subject': _subjectController.text,
            'message_content':
                _messageController.text, // Save the edited content
            'provider': 'EmailJS',
          });
          print("Successfully logged email to Firestore");
        } catch (firestoreError) {
          print("Warning: Could not log email to Firestore: $firestoreError");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Email sent successfully to ${recipients.length} recipients!')),
        );
      } else {
        print('EmailJS API error response: ${response.data}');
        throw Exception(
            'Failed to send email: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print("Error sending email: $e");

      // More detailed error handling
      if (e is DioException) {
        print("Dio error type: ${e.type}");
        print("Dio error message: ${e.message}");
        print("Dio error response: ${e.response?.data}");

        // Handle different types of Dio errors
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Connection timeout. Please check your internet connection.')),
            );
            break;
          case DioExceptionType.receiveTimeout:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Receive timeout. The server took too long to respond.')),
            );
            break;
          case DioExceptionType.connectionError:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Connection error. Please check your internet connection.')),
            );
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send email: ${e.message}')),
            );
            break;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email: $e')),
        );
      }
    } finally {
      setState(() => _isSendingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildMinutesOfMeeting();
  }

  Widget _buildMinutesOfMeeting() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Responsive font sizes
    double titleFontSize = screenWidth * 0.015;
    double bodyFontSize = screenWidth * 0.012;
    double smallFontSize = screenWidth * 0.01;
    double headerFontSize = screenWidth * 0.018;

    // Responsive spacing
    double verticalPadding = screenHeight * 0.02;
    double horizontalPadding = screenWidth * 0.02;
    double elementSpacing = screenHeight * 0.015;

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        height: screenWidth / 1.35,
        width: screenWidth * 0.7,
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Meeting Minutes - Email Composer',
              style: TextStyle(
                fontSize: titleFontSize,
                fontFamily: "B",
                color: Colors.white,
              ),
            ),
            SizedBox(height: elementSpacing),

            // Email Composition Form (Gmail-like)
            Expanded(
              child: Container(
                padding: EdgeInsets.all(horizontalPadding),
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
                          width: screenWidth * 0.05,
                          child: Text(
                            'To:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: bodyFontSize,
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
                            style: TextStyle(fontSize: bodyFontSize),
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
                          width: screenWidth * 0.05,
                          child: Text(
                            'Subject:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(),
                            ),
                            style: TextStyle(fontSize: bodyFontSize),
                          ),
                        ),
                      ],
                    ),
                    Divider(),

                    // File Attachment
                    Row(
                      children: [
                        SizedBox(
                          width: screenWidth * 0.05,
                          child: Text(
                            'Attach:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.attach_file,
                                    size: screenWidth * 0.012),
                                label: Text('Select File',
                                    style: TextStyle(fontSize: smallFontSize)),
                                onPressed: _selectFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.black87,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.01,
                                    vertical: screenHeight * 0.008,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.01),
                              if (_fileAttachmentName.isNotEmpty)
                                Chip(
                                  label: Text(_fileAttachmentName,
                                      style:
                                          TextStyle(fontSize: smallFontSize)),
                                  deleteIcon: Icon(Icons.close,
                                      size: screenWidth * 0.01),
                                  onDeleted: () {
                                    setState(() {
                                      _fileAttachmentPath = '';
                                      _fileAttachmentName = '';
                                      _fileUrl = '';
                                      _fileBytes = null;
                                    });
                                  },
                                ),
                              Spacer(),
                              if (_fileAttachmentName.isNotEmpty &&
                                  !_isUploading)
                                TextButton.icon(
                                  icon: Icon(Icons.cloud_upload,
                                      size: screenWidth * 0.012),
                                  label: Text('Upload to Supabase',
                                      style:
                                          TextStyle(fontSize: smallFontSize)),
                                  onPressed: _uploadFileToSupabase,
                                ),
                              if (_isUploading)
                                Row(
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.015,
                                      height: screenWidth * 0.015,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Text('Uploading...',
                                        style:
                                            TextStyle(fontSize: smallFontSize)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(),

                    // Email Body - Now showing as a styled, editable preview
                    SizedBox(height: elementSpacing * 0.5),
                    // Email Body section with edit button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Email Body:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: bodyFontSize,
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(
                              _isEditingEmailTemplate ? Icons.save : Icons.edit,
                              size: screenWidth * 0.012),
                          label: Text(
                              _isEditingEmailTemplate
                                  ? 'Save Template'
                                  : 'Edit Template',
                              style: TextStyle(fontSize: smallFontSize)),
                          onPressed: () {
                            if (_isEditingEmailTemplate) {
                              // Save mode - save the changes
                              setState(() {
                                _savedEmailContent = _messageController.text;
                                _isEditingEmailTemplate = false;
                              });

                              // Show confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Template saved successfully')),
                              );
                            } else {
                              // Edit mode - enable editing
                              setState(() {
                                _isEditingEmailTemplate = true;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: elementSpacing * 0.3),

// Email body with styled preview and editable content based on edit mode
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 7),
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: EdgeInsets.all(horizontalPadding),
                              decoration: BoxDecoration(
                                color: Color(0xFF0e2643),
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                              width: double.infinity,
                              child: Column(
                                children: [
                                  Text(
                                    'DBP-Data Center Inc.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: elementSpacing * 0.3),
                                  Text(
                                    'Meeting Summary Notification',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: bodyFontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Editable content area or preview based on edit mode
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(horizontalPadding),
                                child: _isEditingEmailTemplate
                                    ? TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.all(8),
                                          hintText: 'Type your message here...',
                                        ),
                                        style:
                                            TextStyle(fontSize: bodyFontSize),
                                        maxLines: null,
                                        expands: true,
                                      )
                                    : SingleChildScrollView(
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            _messageController.text.replaceAll(
                                                '[DOWNLOAD_LINK]',
                                                '[Download Button Will Appear Here]'),
                                            style: TextStyle(
                                                fontSize: bodyFontSize),
                                          ),
                                        ),
                                      ),
                              ),
                            ),

                            // Footer
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(horizontalPadding),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(4)),
                              ),
                              child: Text(
                                '© 2025 DBP-Data Center Inc. All rights reserved.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: smallFontSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Actions
                    SizedBox(height: elementSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_fileUrl.isNotEmpty)
                          Chip(
                            avatar: Icon(Icons.check_circle,
                                color: Colors.green, size: screenWidth * 0.012),
                            label: Text('File Ready',
                                style: TextStyle(fontSize: smallFontSize)),
                            backgroundColor: Colors.green.withOpacity(0.1),
                          ),
                        SizedBox(width: screenWidth * 0.01),
                        ElevatedButton(
                          onPressed: _isSendingEmail ? null : _sendEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0e2643),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.015,
                              vertical: screenHeight * 0.01,
                            ),
                          ),
                          child: _isSendingEmail
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.012,
                                      height: screenWidth * 0.012,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.008),
                                    Text('Sending...',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "M",
                                            fontSize: bodyFontSize)),
                                  ],
                                )
                              : Text('Send Email',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "M",
                                      fontSize: bodyFontSize)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
