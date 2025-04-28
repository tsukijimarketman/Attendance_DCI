import 'dart:async';
import 'dart:typed_data';

import 'package:attendance_app/404.dart';
import 'package:attendance_app/form/signature.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceForm extends StatefulWidget {
  // This is passing the data from the previous screen
  final String roles;
  final String department;
  final String agenda;
  final String firstName;
  final String lastName;
  final String createdBy;
  final int expiryTime;
  final int selectedScheduleTime;

  const AttendanceForm({
    // This is passing the data from the previous screen
    // and requiring the data to be passed
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
  // this is all the variables that are used in the form
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

  // Initialize the controllers and other variables
  // This function is called when the widget is created
  // It sets up the initial state of the widget
  // and prepares the controllers for use
  // It also sets up the scheduled time based on the selected schedule time
  // and checks if the QR code has expired
  // or if the form has expired
  // It also starts the countdown timer to track the remaining time
  // until the form expires
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

  // Start the countdown timer
  // This function is called when the widget is initialized
  // It calculates the remaining time until the form expires
  // and sets up a periodic timer to update the remaining time
  void _startCountdown() {
    // Get the current time in milliseconds since epoch
    // Calculate the remaining time in seconds
    int now = DateTime.now().millisecondsSinceEpoch;
    remainingTime = ((widget.expiryTime - now) / 1000).round();

    // Check if the remaining time is greater than 0
    // If so, set up a periodic timer to update the remaining time
    // If not, show the expired dialog immediately
    if (remainingTime > 0) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        // Check if the widget is still mounted
        // This is important to avoid calling setState on a disposed widget
        // and to ensure that the timer is only active when the widget is visible
        // and not in the background
        if (mounted) {
          setState(() {
            remainingTime--;
          });

          // Check if the remaining time is less than or equal to 0
          // If so, cancel the timer and show the expired dialog
          // This is important to ensure that the dialog is shown only when the time is up
          // and to prevent any further updates to the UI
          // after the form has expired
          if (remainingTime <= 0) {
            _timer.cancel();
            _showExpiredDialog();
          }
        }
      });
    } else {
      // If the remaining time is less than or equal to 0
      // show the expired dialog immediately
      // This is important to ensure that the user is notified of the expiration
      
      _showExpiredDialog();
    }
  }

  // Show a dialog when the form has expired
  // This function is called when the form expires
  // It shows an alert dialog to the user
  // with a message indicating that the form has expired
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

  // Dispose of the controllers to free up resources
  // This function is called when the widget is removed from the widget tree
  // It ensures that all controllers are properly disposed of
  // to prevent memory leaks
  // and to clean up any resources used by the controllers
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

  // Add a new contact field
  // This function is called when the add icon is pressed
  // It adds a new TextEditingController to the list of contact controllers
  // and updates the state to reflect the change in the UI
  void addNewContactField() {
    setState(() {
      contactControllers.add(TextEditingController());
    });
  }

  // Remove a contact field at the specified index
  // This function is called when the remove icon is pressed
  // It removes the TextEditingController at the specified index
  // and updates the state to reflect the change in the UI
  void removeContactField(int index) {
    setState(() {
      contactControllers
          .removeAt(index);
    });
  }

  // Format the time in minutes and seconds
  // Example: "5:30" for 5 minutes and 30 seconds
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  // Validate the form fields
  bool validateForm() {
    // Check if the name, company, and email fields are valid
    // Check if the contact number fields are valid
    // Set the validity state for each field
    // Use trim() to remove leading and trailing spaces
    // Use isNotEmpty to check if the field is not empty
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

  // Check if all fields are valid
  bool allContactsValid = contactFieldValidity.any((valid) => valid);
  if (!isNameValid || !isCompanyValid || !isEmailValid || !allContactsValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please correct the highlighted fields.")),
    );
    return false;
  }

  return true;
}

  // Submit the form data to Firestore and upload the signature to Supabase
  void submitForm() async {
    // Check if the form is valid
    // Early exit if validation fails
      if (!validateForm()) return;

    // Check if the signature is empty
    // Early exit if signature is empty
    if (_signatureController.isEmpty) {
      // Show a message to the user that say Please add a signature
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a signature!")),
      );
      return;
    }

    // Convert the signature to PNG bytes
    final Uint8List? signatureImage = await _signatureController.toPngBytes();
    // Check if the image is null or empty
    // Early exit if the image is null or empty
    if (signatureImage == null || signatureImage.isEmpty) {
      // Show a message to the user that say Failed to convert signature
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to convert signature!")),
      );
      return;
    }
  
    // Upload the signature to Supabase
    final String? signatureUrl = await _uploadToSupabase(signatureImage);
    // Check if the upload was successful
    // Early exit if the upload failed
    if (signatureUrl == null) {
      // Show a message to the user that say Failed to save signature
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save signature!")),
      );
      return;
    }

    // Prepare the form data to be saved in Firestore
    // Use the correct field names as per your Firestore structure
    // Ensure that the keys match your Firestore document structure
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
      'signature_url': signatureUrl,
    };

    // If the role is "User", add `attendanceCreator` field name
    if (widget.roles == "User") {
      formData['attendanceCreator'] = "${widget.firstName} ${widget.lastName}";
    }

    // Save form data to Firestore
    // Ensure the collection name is attendance
    await FirebaseFirestore.instance.collection('attendance').add(formData);

    // Show a success message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Form submitted successfully!")),
    );

    // Clear fields after submission
    nameController.clear();
    companyController.clear();
    emailAddController.clear();
    // Clear all contact number fields after submission
    for (var controller in contactControllers) {
      controller.dispose();
    }

    // Reset to one empty contact field after submission
    setState(() {
      contactControllers = [TextEditingController()];
    });

    // Clear the signature controller after submission
    _signatureController.clear();
  }

  // Upload the signature image to Supabase and return the public URL
  Future<String?> _uploadToSupabase(Uint8List imageBytes) async {
    // Ensure the Supabase client is initialized
    try {
      // Check if Supabase client is initialized
      final client = Supabase.instance.client;
      final String fileName =
          "signature_${DateTime.now().millisecondsSinceEpoch}.png";
      
      // Upload the image to Supabase storage 
      final response = await client.storage
          .from("signatures") // This is the bucket Name
          // Specify the file name and the image bytes
          .uploadBinary(fileName, imageBytes,
              fileOptions: const FileOptions(upsert: true));

      // CHECK IF UPLOAD FAILED
      if (response.isEmpty) {
        // Handle the error if the upload failed
        return null;
      }

      // Get the public URL of the uploaded file
      final String publicUrl =
          client.storage.from("signatures").getPublicUrl(fileName);
      // Check if the public URL is empty
      return publicUrl;
      // Handle the error if the public URL is empty
    } catch (e) {
      return null;
    }
  }

  // Format the date and time
  // to a more readable format
  // Example: "January 1, 2023 at 12:00 PM"
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
                                        // This will Trigger the addNewContactField function
                                onPressed:
                                    addNewContactField, // Add new contact when pressed
                              )
                            : IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors
                                        .red), // Remove icon for subsequent fields
                                        // This will Trigger the removeContactField function
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
                        // This will Trigger the submitForm function
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
