import 'dart:async';
import 'dart:typed_data';

import 'package:attendance_app/404.dart';
import 'package:attendance_app/Animation/Animation.dart';
import 'package:attendance_app/form/signature.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceForm extends StatefulWidget {
  final String roles;
  final String department;
  final String agenda;
  final String firstName;
  final String lastName;
  final String createdBy;
  final int expiryTime;
  final int selectedScheduleTime;

  const AttendanceForm({
    required this.createdBy,
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
  List<TextEditingController> contactControllers = [TextEditingController()];
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  late Timer _timer;
  int remainingTime = 0; // Time in seconds
  late DateTime scheduledTime; // Moved initialization inside initState()

  bool isValidPhone(String input) {
    return RegExp(r'^(09|\+639)\d{9}$|^0\d{7,10}$').hasMatch(input);
  }

  bool isNameValid = true;
bool isCompanyValid = true;
bool isEmailValid = true;
List<bool> contactFieldValidity = [];


  @override
  void initState() {
    super.initState();
    contactControllers = [TextEditingController()];
  contactFieldValidity = [true];
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
    for (var controller in contactControllers) {
      controller.dispose();
    }
    _signatureController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void addNewContactField() {
    setState(() {
      contactControllers.add(TextEditingController()); // Add a new controller
    });
  }

  void removeContactField(int index) {
    setState(() {
      contactControllers
          .removeAt(index); // Remove the controller at the specified index
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  bool validateForm() {
  setState(() {
    isNameValid = nameController.text.trim().isNotEmpty;
    isCompanyValid = companyController.text.trim().isNotEmpty;

    final email = emailAddController.text.trim();
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    isEmailValid = emailRegExp.hasMatch(email);

    contactFieldValidity = contactControllers.map((controller) {
      String number = controller.text.trim();
      return isValidPhone(number);
    }).toList();
  });

  // Check if all are valid
  bool allContactsValid = contactFieldValidity.any((valid) => valid);
  if (!isNameValid || !isCompanyValid || !isEmailValid || !allContactsValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please correct the highlighted fields.")),
    );
    return false;
  }

  return true;
}


  void submitForm() async {
      if (!validateForm()) return; // Early exit if validation fails

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a signature!")),
      );
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
        const SnackBar(content: Text("Failed to save signature!")),
      );
      return;
    }

    // Prepare data to save
    Map<String, dynamic> formData = {
      'name': nameController.text,
      'company': companyController.text,
      'email_address': emailAddController.text,
      'contact_num': contactControllers
          .map((controller) => controller.text)
          .toList(), // Collect all contact numbers
      'timestamp': FieldValue.serverTimestamp(),
      'agenda': widget.agenda,
      'department': widget.department,
      'createdBy': widget.roles == "User"
          ? widget.createdBy // If User, store the original creator
          : "${widget.firstName} ${widget.lastName}", // Otherwise, store current user
      'selectedScheduleTime': widget.selectedScheduleTime,
      'signature_url': signatureUrl, // Save signature URL
    };

    // If the role is "User", add `attendanceCreator`
    if (widget.roles == "User") {
      formData['attendanceCreator'] = "${widget.firstName} ${widget.lastName}";
    }

    // Save form data to Firestore
    await FirebaseFirestore.instance.collection('attendance').add(formData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Form submitted successfully!")),
    );

    // Clear fields after submission
    nameController.clear();
    companyController.clear();
    emailAddController.clear();
    for (var controller in contactControllers) {
      controller.dispose();
    }

// Reset to one empty contact field
    setState(() {
      contactControllers = [TextEditingController()];
    });

    _signatureController.clear();
  }

  Future<String?> _uploadToSupabase(Uint8List imageBytes) async {
    try {
      final client = Supabase.instance.client;
      final String fileName =
          "signature_${DateTime.now().millisecondsSinceEpoch}.png";

      print("🚀 Uploading signature: $fileName");

      final response = await client.storage
          .from("signatures") // Ensure this is the correct bucket
          .uploadBinary(fileName, imageBytes,
              fileOptions: const FileOptions(upsert: true));

      print("📂 Upload Response: $response");

      // CHECK IF UPLOAD FAILED
      if (response.isEmpty) {
        print("❌ Supabase upload failed: No file path returned.");
        return null;
      }

      final String publicUrl =
          client.storage.from("signatures").getPublicUrl(fileName);
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
      appBar: AppBar(
        title: Text("Attendance"), // Disable default title if needed
        centerTitle: true,
        flexibleSpace: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                  'assets/Dciwobg.png'), // Ensure the path is correct and image exists
              Image.asset(
                  'assets/bag.png'), // Ensure the path is correct and image exists
            ],
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.event_note,
                            color: Colors.blue,
                            size: 18,
                          ),
                          title: Text(
                            "Agenda",
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            widget.agenda,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.account_tree_outlined,
                              size: 18, color: Colors.green),
                          title: Text(
                            "Department",
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            widget.department,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.schedule,
                            color: Colors.orange,
                            size: 18,
                          ),
                          title: Text(
                            "Scheduled at",
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            formatDateTime(scheduledTime),
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.person_outline,
                              size: 18, color: Colors.purple),
                          title: Text(
                            "Created By",
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            "${widget.firstName} ${widget.lastName}",
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Text(
                            remainingTime > 0
                                ? "Expires in: ${_formatTime(remainingTime)} minutes"
                                : "Form has expired",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  remainingTime > 0 ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                    height: 50,
                    width: 400,
                    child: CupertinoTextField(
                      
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      controller: nameController,
                      placeholder: 'Name',
                      decoration: BoxDecoration(
    border: Border.all(color: isNameValid ? Colors.blue : Colors.red),
                        
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
                      textCapitalization: TextCapitalization.words,
                      controller: companyController,
                      placeholder: 'Company',
                      decoration: BoxDecoration(
    border: Border.all(color: isCompanyValid ? Colors.blue : Colors.red),
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
                      keyboardType: TextInputType.emailAddress,
                      controller: emailAddController,
                      placeholder: 'Email Address',
                      decoration: BoxDecoration(
    border: Border.all(color: isEmailValid ? Colors.blue : Colors.red),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onChanged: (value) {
                        final isValid =
                            RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                .hasMatch(value);
                        if (!isValid) {
                          // You can show a message or visual feedback if needed
                        }
                      },
                    )),
                SizedBox(
                  height: 10,
                ),
                ...contactControllers.asMap().entries.map((entry) {
  int index = entry.key;
  TextEditingController controller = entry.value;
  bool isValid = index < contactFieldValidity.length ? contactFieldValidity[index] : true;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: SizedBox(
                      height: 50,
                      child: CupertinoTextField(
                        controller: controller,
                        placeholder: 'Contact Number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\+]')), // Allow only digits and "+"
                          LengthLimitingTextInputFormatter(
                              12), // limit to max 13 digits (adjust as needed)
                        ],
                        decoration: BoxDecoration(
          border: Border.all(color: isValid ? Colors.blue : Colors.red),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffix: index == 0
                            ? IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: Colors
                                        .blue), // Size and color of the icon
                                onPressed:
                                    addNewContactField, // Add new contact when pressed
                              )
                            : IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors
                                        .red), // Remove icon for subsequent fields
                                onPressed: () {
                                  removeContactField(
                                      index); // Remove specific contact field
                                },
                              ),
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 10),
                Text('Please provide your signature:'),
                SizedBox(
                    height: 300,
                    child: SignatureApp(controller: _signatureController)),
                SizedBox(
                  height: 50,
                ),
                SizedBox(
                    height: 50,
                    width: 400,
                    child: ElevatedButton(
                        style: ButtonStyle(
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all(Colors.blue),
                        ),
                        onPressed: submitForm,
                        child: Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
