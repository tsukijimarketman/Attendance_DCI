import 'dart:async';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/Manager_DB.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/currentappointment.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/maintenance/maintenance.dart';
import 'package:attendance_app/Appointment/add_client.dart';
import 'package:attendance_app/Appointment/schedule_appointment.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/superuser_analytical_report/reports.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/auditSU.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/settings_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/sidebar_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/sidebarx_usage.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/profile.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/usermanagement_su.dart';
import 'package:attendance_app/Auth/showDialogSignOut.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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

  bool _hasShownProfileToast = false;
  bool isHeadersClicked = false;
  String selectedOption = "";
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _userSubscription;
  StreamSubscription? _profileImageSubscription;

  String firstName = "Loading...";
  String lastName = "";
  String role = "Fetching...";
  bool isLoading = true;
  
  String? _imageUrl;
  DateTime _lastImageRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _subscribeToUserData();
    _fetchProfileImage();
    
    // Listen for profile image updates from the Profile component
    _profileImageSubscription = profileImageUpdateController.stream.listen((imageUrl) {
      if (mounted && imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
        });
      }
    });

    // Executes the profile completion check after the widget has been rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
    });
    
    // Set up periodic refresh of profile image (every 30 seconds)
    _setupProfileImageRefresh();
  }
  
  // Set up a timer to periodically check if the profile image needs refreshing
  void _setupProfileImageRefresh() {
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      _checkProfileImageUpdate();
    });
  }
  
  // Check if the profile image has been updated elsewhere
  Future<void> _checkProfileImageUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateTimestamp = prefs.getInt('profile_image_timestamp') ?? 0;
      
      // If stored timestamp is newer than our last refresh time, fetch the image again
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdateTimestamp);
      if (lastUpdateTime.isAfter(_lastImageRefresh)) {
        await _fetchProfileImage();
        _lastImageRefresh = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error checking profile image update: $e');
    }
  }

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
    _userSubscription?.cancel();
    _profileImageSubscription?.cancel();
    super.dispose();
  }

  // This function uses the ProfileImageUtil class to fetch the profile image
  Future<void> _fetchProfileImage() async {
    final imageUrl = await ProfileImageUtil.fetchProfileImage();
    
    if (mounted && imageUrl != null) {
      setState(() {
        _imageUrl = imageUrl;
      });
    }
  }

  void _checkProfileCompletion() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // First approach: Try fetching the user's document directly by their UID
      var doc = await _firestore.collection("users").doc(user.uid).get();

      // Second approach: If the document doesn't exist, try querying by UID field
      if (!doc.exists) {
        final querySnapshot = await _firestore
            .collection("users")
            .where("uid", isEqualTo: user.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          doc = querySnapshot.docs.first;
        }
      }

      if (!doc.exists) {
        _showProfileCompletionToast();
        return;
      }

      try {
        final userData = doc.data() as Map<String, dynamic>;

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

        for (String field in requiredFields) {
          final hasField = userData.containsKey(field);
          final fieldValue = userData[field];
          final isEmpty = fieldValue == null ||
              (fieldValue is String && fieldValue.isEmpty);

          if (!hasField || isEmpty) {
            isProfileComplete = false;
            missingFields.add(field);
          }
        }

        if (!isProfileComplete) {
          _showProfileCompletionToast();
        } else {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isProfileCompleted_${user.uid}', true);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        }
      } catch (e) {
        _showProfileCompletionToast();
      }
    } catch (e) {
      _showProfileCompletionToast();
    }
  }

  void _showProfileCompletionToast() {
    if (!mounted) return;
    
    // Delay showing toast slightly to ensure UI is ready
    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      toastification.show(
        context: context,
        alignment: Alignment.topRight,
        icon: Icon(Icons.info_outline, color: Colors.black87),
        title: Text('Profile Incomplete',
            style: TextStyle(
                fontFamily: "B",
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
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 6),
        animationDuration: const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
        return const ScheduleAppointment();
      case 3:
        return const AddClient();
      case 4:
        return const Maintenance();
      case 5:
        return const AppointmentManager();
      case 6:
        return const ManagerDB();
      case 7:
        return const SettingsSU();
      case 8:
        return const AuditSU();
      default:
        return const Text('Select an option from the menu.',
            style: TextStyle(fontSize: 20));
    }
  }
}