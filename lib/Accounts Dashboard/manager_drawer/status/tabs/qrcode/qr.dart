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

class _QrCodeState extends State<QrCode> with AutomaticKeepAliveClientMixin {
   static bool _isQrGenerated = false;
  static bool _isFormCreated = false;
  static String _qrUrl = "";
  static String _lastAgenda = ""; // ✅ Tracks which agenda QR was made for


  final TextEditingController agendaController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();

  bool isQrGenerated = false;
  bool isFormCreated = false;
  String firstName = "";
  String lastName = "";
  String qrUrl = "";
    String department ="";


  // The initState method is called when the widget is first created. It initializes the state of the widget by setting the agendaController's text to the selected agenda passed via the widget's constructor.
  // It also triggers the fetchUserData method to fetch and load the current user's data from Firebase into the state.
  // This ensures that the necessary data is available when the widget is displayed.
  @override
  void initState() {
    super.initState();
     if (_lastAgenda != widget.selectedAgenda) {
    _isQrGenerated = false;
    _isFormCreated = false;
    _qrUrl = "";
    _lastAgenda = widget.selectedAgenda;
  }

  isQrGenerated = _isQrGenerated;
  isFormCreated = _isFormCreated;
  qrUrl = _qrUrl;

    agendaController.text = widget.selectedAgenda;
    fetchUserData();
  }

   @override
  bool get wantKeepAlive => true;

  // This function is responsible for fetching the current user's data from Firebase Firestore.
  // It first checks if the user is logged in by retrieving the current user from FirebaseAuth.
  // If a user is logged in, it queries the 'users' collection in Firestore to find the document matching the user's UID.
  // If the user data is found, the first name, last name, and department are retrieved and updated in the state.
  // If no user document is found, a SnackBar message is displayed to inform the user.
  // If there's an error during the data fetch, another SnackBar is shown with the error message.
  // If no user is logged in, a SnackBar is displayed notifying that no user is logged in.
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
                            String deptID = userData['deptID'] ?? '';


          setState(() {
            firstName = userData['first_name'] ?? "N/A";
            lastName = userData['last_name'] ?? "N/A";
          departmentController.text = deptID;

          });
                            await fetchDepartmentNameByID(deptID);


        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("No user document found.")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching user data: $e")));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No user is logged in.")));
    }
  }

  void generateQrCode() {
    setState(() {
      isQrGenerated = true;
            _isQrGenerated = true;

    });
  }

  // This function is responsible for creating an attendance form.
  // First, it checks if the agenda text field is empty and displays a SnackBar message if it is.
  // Then, it calculates the current timestamp and sets expiration times for both the QR code and the form.
  // The QR URL is then generated with the provided agenda, department, first and last names, and expiry times encoded as URL parameters.
  // After the URL is created, it logs an audit trail for the QR code generation event, noting the user's first and last names, agenda, and department.
  // Finally, the state is updated to show the form has been created, and a countdown timer is started.
  void createForm() async {
    if (agendaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please provide an agenda")),
      );
      return;
    }

     qrUrl = "https://attendance-dci.web.app//#/attendance_form"
        "?agenda=${Uri.encodeComponent(agendaController.text)}"
        "&department=${Uri.encodeComponent(departmentController.text)}"
        "&first_name=${Uri.encodeComponent(firstName)}"
        "&last_name=${Uri.encodeComponent(lastName)}";

    try {
      // Audit Trail: Log when a user generates a QR Code
      await logAuditTrail("Generated Attendance Form",
          "User $firstName $lastName generated a QR code for agenda: ${agendaController.text} in department: ${departmentController.text}");

      setState(() {
        isFormCreated = true;
  isQrGenerated = true;
  _isFormCreated = true;
  _isQrGenerated = true;
  _qrUrl = qrUrl;
  _lastAgenda = widget.selectedAgenda; // ✅ Track agenda used
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }


  Future<void> fetchDepartmentNameByID(String deptID) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('references')
        .where('deptID', isEqualTo: deptID)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var deptData = querySnapshot.docs.first.data() as Map<String, dynamic>;

      setState(() {
        department = deptData['name'] ?? 'Unknown Department';
      });
    } else {
      setState(() {
        department = 'Unknown Department';
      });
      print("No department found for deptID: $deptID");
    }
  } catch (e) {
    print("Error fetching department name: $e");
  }
}

 
  @override
  Widget build(BuildContext context) {
        super.build(context); // Required when using AutomaticKeepAliveClientMixin
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
            // This will Triggered the generateQrCode where it will generate a QrCode For Attendance
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
                       department.isNotEmpty
                          ? department
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
                          // This will Trigger the createForm Method
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
                      embeddedImageStyle: QrEmbeddedImageStyle(
                        size: Size(60, 60),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
