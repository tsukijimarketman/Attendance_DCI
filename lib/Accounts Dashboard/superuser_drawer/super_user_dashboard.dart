import 'dart:async';
import 'dart:io';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/UserMasterlist.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/departmentMasterlist.dart';
import 'package:attendance_app/Appointment/add_client.dart';
import 'package:attendance_app/Appointment/schedule_appointment.dart';
import 'package:attendance_app/analytical_report/reports.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/auditSU.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/notification_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/settings_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/sidebar_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/sidebarx_usage.dart';
import 'package:attendance_app/Animation/Animation.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/references_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/usermanagement_su.dart';
import 'package:attendance_app/Auth/login.dart';
import 'package:attendance_app/Auth/showDialogSignOut.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:toastification/toastification.dart';

class SuperUserDashboard extends StatefulWidget {
  const SuperUserDashboard({super.key});

  @override
  State<SuperUserDashboard> createState() => _SuperUserDashboardState();
}

class _SuperUserDashboardState extends State<SuperUserDashboard> {
  // Start with Dashboard

  Color color1 = Colors.grey;
  Color color2 = Colors.grey;
  Color color3 = Colors.grey;
  Color color4 = Colors.grey;

  IconData iconSettings = Icons.settings;

  bool _hasShownProfileToast = false;

  @override
  void initState() {
    super.initState();
    _subscribeToUserData();
    _fetchProfileImage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
    });
  }

  bool isHeadersClicked = false;
  String selectedOption = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _userSubscription;

  String firstName = "Loading...";
  String lastName = "";
  String role = "Fetching...";
  bool isLoading = true;

  void _subscribeToUserData() {
    final String? currentUserUid = _auth.currentUser?.uid;
    if (currentUserUid == null) return;

    _userSubscription = _firestore
        .collection("users")
        .where("uid", isEqualTo: currentUserUid)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          firstName = userData['first_name'] ?? "No Name";
          lastName = userData['last_name'] ?? "";
          role = userData['roles'] ?? "Unknown Role";
          isLoading = false;
        });
      } else {
        setState(() {
          firstName = "No Data";
          lastName = "";
          role = "N/A";
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel(); // Cancel subscription to prevent memory leaks
    super.dispose();
  }

  final supabase = Supabase.instance.client;
  File? _image;
  String? _imageUrl;

  Future<void> _fetchProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final filePrefix =
        'profile_${user.uid}'; // Match all files starting with this
    final response = await supabase.storage.from('profile-pictures').list();

    FileObject? userFile;
    try {
      userFile =
          response.firstWhere((file) => file.name.startsWith(filePrefix));
    } catch (e) {
      userFile = null; // Handle case where no file is found
    }

    if (userFile != null) {
      String imageUrl =
          supabase.storage.from('profile-pictures').getPublicUrl(userFile.name);

      // 🛠️ Ensure URL does NOT contain an extra ":http:"
      if (imageUrl.contains(':http:')) {
        imageUrl = imageUrl.replaceAll(':http:', ''); // Fix malformed URL
      }

      // 🔄 Add timestamp to force refresh
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      imageUrl = "$imageUrl?t=$timestamp";

      setState(() {
        _imageUrl = imageUrl;
      });

      print("✅ Fixed Profile Image URL: $_imageUrl");
    } else {
      print("❌ No profile image found for user: ${user.uid}");
    }
  }


void _checkProfileCompletion() async {
  final user = _auth.currentUser;
  if (user == null) {
    print("❌ No current user found");
    return;
  }

  try {
    print("🔍 Checking profile for UID: ${user.uid}");
    print("👤 Email: ${user.email}");
    
    // First approach: Try to find by direct document ID
    var doc = await _firestore.collection("users").doc(user.uid).get();
    print("📄 Direct lookup result: ${doc.exists ? 'Found' : 'Not found'}");
    
    // Second approach: Query by uid field
    if (!doc.exists) {
      print("⚠️ Document not found by direct ID, trying query by uid field");
      final querySnapshot = await _firestore
          .collection("users")
          .where("uid", isEqualTo: user.uid)
          .limit(1)
          .get();
          
      print("🔎 Query results: ${querySnapshot.docs.length} documents found");
      
      if (querySnapshot.docs.isNotEmpty) {
        doc = querySnapshot.docs.first;
        print("✅ Found document via query with ID: ${doc.id}");
      }
    }

    if (!doc.exists) {
      print("❌ User document doesn't exist anywhere");
      _showProfileCompletionToast();
      return;
    }

    // Document exists, now check fields
    try {
      final userData = doc.data() as Map<String, dynamic>;
      print("📝 Document data retrieved: ${userData.keys.toList()}");
      
      // List of required fields
      final requiredFields = [
        'birthdate',
        'sex',
        'civil_status',
        'place_of_birth',
        'mobile_number',
        'first_name',
        'last_name',
        'citizenship',
        'dual_citizen',
      ];

      bool isProfileComplete = true;
      List<String> missingFields = [];

      // Check each required field
      for (String field in requiredFields) {
        final hasField = userData.containsKey(field);
        final fieldValue = userData[field];
        final isEmpty = fieldValue == null || 
                      (fieldValue is String && fieldValue.isEmpty);
        
        print("🔍 Field '$field': exists=$hasField, value='$fieldValue', isEmpty=$isEmpty");
        
        if (!hasField || isEmpty) {
          isProfileComplete = false;
          missingFields.add(field);
        }
      }

      // Final result
      print("📋 Profile check - Complete: $isProfileComplete");
      if (!isProfileComplete) {
        print("❌ Missing fields: $missingFields");
        _showProfileCompletionToast();
      } else {
        print("✅ All required fields present");
        
        // Save preference to avoid future checks if profile is complete
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isProfileCompleted_${user.uid}', true);
          print("💾 Saved preference for completed profile");
        } catch (e) {
          print("⚠️ Failed to save preference: $e");
        }
      }
    } catch (e) {
      print("❌ Error processing document data: $e");
      _showProfileCompletionToast();
    }
  } catch (e) {
    print("❌ Error checking profile completion: $e");
    _showProfileCompletionToast();
  }
}

// Simplify the toast method
void _showProfileCompletionToast() {
  // Delay showing toast slightly to ensure UI is ready
  Future.delayed(Duration(milliseconds: 800), () {
    toastification.show(
      context: context,
      alignment: Alignment.topRight,
      icon: Icon(Icons.info_outline, color: Colors.black87),
      title: Text('Profile Incomplete', style: TextStyle(fontFamily: "B", 
          fontSize: MediaQuery.of(context).size.width / 80)),
      description: Text(
        "Please go to Settings to complete your profile information",
        style: TextStyle(
          color: Colors.black87,
          fontSize: MediaQuery.of(context).size.width / 90,
          fontFamily: "M",
        ),
      ),
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored, // Light yellow color
      autoCloseDuration: const Duration(seconds: 6),
      animationDuration: const Duration(milliseconds: 300),
    );
  });
}

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final sidebarProvider = Provider.of<SidebarProvider>(context);
    return Scaffold(
        backgroundColor: Color(0xFFf2edf3),
        appBar: AppBar(
          toolbarHeight: MediaQuery.of(context).size.width / 20,
          backgroundColor: Colors.white,
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuperUserDashboard(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width / 13),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width / 140),
                    child: Image.asset("assets/bp.png",
                        height: MediaQuery.of(context).size.width / 20),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 50,
                  ),
                  Text("BAGONG PILIPINAS",
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width / 45,
                          fontFamily: "BL",
                          fontStyle: FontStyle.italic,
                          color: const Color.fromARGB(255, 20, 94, 155))),
                ],
              ),
            ).showCursorOnHover,
            Spacer(),
            Row(
              children: [
                CircleAvatar(
                  radius: MediaQuery.of(context).size.width / 58,
                  backgroundColor: Colors.grey,
                  backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? NetworkImage(_imageUrl!)
                      : null,
                  child: _imageUrl == null || _imageUrl!.isEmpty
                      ? Icon(Icons.person,
                          size: MediaQuery.of(context).size.width / 45,
                          color: Colors.white)
                      : null,
                ),
                SizedBox(width: MediaQuery.of(context).size.width / 60),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoading ? "Loading..." : "$firstName $lastName",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: MediaQuery.of(context).size.height / 50,
                          fontFamily: "M"),
                    ),
                    Text(
                      isLoading ? "Fetching..." : role,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: MediaQuery.of(context).size.height / 70,
                          fontFamily: "R"),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 50,
            ),
            GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedOption == "Settings") {
                          // If Settings is clicked again, toggle the visibility of the page
                          if (isHeadersClicked) {
                            isHeadersClicked = false;
                          } else {
                            selectedOption = "Settings";
                            isHeadersClicked = true;
                          }
                        } else {
                          // If a different option is clicked, set it as the selected option
                          selectedOption = "Settings";
                          isHeadersClicked = true;
                        }
                      });
                    },
                    child: selectedOption == "Settings" &&
                            isHeadersClicked == false
                        ? MouseRegion(
                            onEnter: (event) {
                              setState(() {
                                color2 = Color.fromARGB(255, 11, 55, 99);
                              });
                            },
                            onExit: (event) {
                              setState(() {
                                color2 = Colors.grey;
                              });
                            },
                            child: Tooltip(
                              message: 'Settings',
                              preferBelow: false,
                              decoration:
                                  BoxDecoration(color: Colors.transparent),
                              textStyle: TextStyle(
                                  color: Color.fromARGB(255, 11, 55, 99),
                                  fontFamily: "B",
                                  fontSize:
                                      MediaQuery.of(context).size.width / 140),
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width / 120,
                                  vertical:
                                      MediaQuery.of(context).size.width / 160),
                              child: Icon(
                                Icons.settings_outlined,
                                color: color2,
                                size: MediaQuery.of(context).size.width / 60,
                              ),
                            ),
                          )
                        : Tooltip(
                            message: 'Settings',
                            preferBelow: false,
                            decoration:
                                BoxDecoration(color: Colors.transparent),
                            textStyle: TextStyle(
                                color: Color.fromARGB(255, 11, 55, 99),
                                fontFamily: "B",
                                fontSize:
                                    MediaQuery.of(context).size.width / 140),
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width / 120,
                                vertical:
                                    MediaQuery.of(context).size.width / 160),
                            child: Icon(
                              isHeadersClicked == true &&
                                      selectedOption == "Settings"
                                  ? iconSettings
                                  : Icons.settings_outlined,
                              color: isHeadersClicked == true &&
                                      selectedOption == "Settings"
                                  ? Color.fromARGB(255, 11, 55, 99)
                                  : Colors.grey,
                              size: MediaQuery.of(context).size.width / 60,
                            ),
                          ))
                .showCursorOnHover,
            SizedBox(
              width: MediaQuery.of(context).size.width / 40,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (selectedOption == "Audit Logs") {
                    // If Audit Logs is clicked again, toggle the visibility of the page
                    if (isHeadersClicked) {
                      isHeadersClicked = false;
                    } else {
                      selectedOption = "Audit Logs";
                      isHeadersClicked = true;
                    }
                  } else {
                    // If a different option is clicked, set it as the selected option
                    selectedOption = "Audit Logs";
                    isHeadersClicked = true;
                  }
                });
              },
              child: Tooltip(
                message: 'Audit Logs',
                preferBelow: false,
                decoration: BoxDecoration(color: Colors.transparent),
                textStyle: TextStyle(
                    color: Color.fromARGB(255, 11, 55, 99),
                    fontFamily: "B",
                    fontSize: MediaQuery.of(context).size.width / 140),
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 120,
                    vertical: MediaQuery.of(context).size.width / 160),
                child: Icon(
                  Icons.history,
                  color:
                      isHeadersClicked == true && selectedOption == "Audit Logs"
                          ? Color.fromARGB(255, 11, 55, 99)
                          : Colors.grey,
                  size: MediaQuery.of(context).size.width / 60,
                ),
              ),
            ).showCursorOnHover,
            SizedBox(
              width: MediaQuery.of(context).size.width / 40,
            ),
            GestureDetector(
              onTap: () {
                showSignOutDialog(context);
              },
              child: Tooltip(
                message: 'Sign Out',
                preferBelow: false,
                decoration: BoxDecoration(color: Colors.transparent),
                textStyle: TextStyle(
                    color: Color.fromARGB(255, 11, 55, 99),
                    fontFamily: "B",
                    fontSize: MediaQuery.of(context).size.width / 140),
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 120,
                    vertical: MediaQuery.of(context).size.width / 160),
                child: Icon(
                  Icons.logout_outlined,
                  color: color4,
                  size: MediaQuery.of(context).size.width / 60,
                ),
              ),
            ).showCursorOnHover,
            SizedBox(
              width: MediaQuery.of(context).size.width / 40,
            ),
          ],
        ),
        body: Row(
          children: [
            SideBarXUsage(),

            /// Page Content Area
            Expanded(
              child: isHeadersClicked
                  ? Row(
                      children: [
                        selectedOption == "Settings"
                            ? SettingsSU()
                            : selectedOption == "Audit Logs"
                                ? AuditSU()
                                : Container(
                                    child: Center(
                                      child: Text("Unexpected Error"),
                                    ),
                                  ),
                      ],
                    )
                  : Center(
                      child: _buildPageContent(sidebarProvider.selectedIndex)),
            ),
          ],
        ));
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return Reports();
      case 1:
        return const UserManagement();
      case 2:
        return const References();
      case 3:
        return const ScheduleAppointment();
      case 4:
        return const AddClient();
      case 5:
        return const Masterlist();
      case 6:
        return const DepartmentMasterlist();
      default:
        return const Text('Select an option from the menu.',
            style: TextStyle(fontSize: 20));
    }
  }
}
