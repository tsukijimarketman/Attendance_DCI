import 'dart:async';
import 'dart:io';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_Manager_DB.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_analytical_report/reports.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_currentappointment.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/maintenance/maintenance.dart';
import 'package:attendance_app/Appointment/add_client.dart';
import 'package:attendance_app/Appointment/schedule_appointment.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/auditSU.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/settings_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_sidebar_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_sidebarx_usage.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_references_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_usermanagement_su.dart';
import 'package:attendance_app/Auth/showDialogSignOut.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class Admin_Dashboard extends StatefulWidget {
  const Admin_Dashboard({super.key});

  @override
  State<Admin_Dashboard> createState() => _Admin_DashboardState();
}

class _Admin_DashboardState extends State<Admin_Dashboard> {
  // Start with Dashboard

  // Color variables are initialized for various UI elements. These colors will likely be dynamically updated based on
// user interaction or some condition in the app. Currently, they are all set to grey, indicating neutral or inactive states.
  Color color1 = Colors.grey;
  Color color2 = Colors.grey;
  Color color3 = Colors.grey;
  Color color4 = Colors.grey;

// Icon for settings is initialized as the settings icon from the material design icons library.
  IconData iconSettings = Icons.settings;

  // Boolean variable to check if a profile completion toast has been shown already. This avoids multiple toasts being shown.
  bool _hasShownProfileToast = false;

  // The initState() method is called when the widget is inserted into the widget tree. It performs several initialization tasks:
// - It subscribes to user data updates using _subscribeToUserData()
// - It fetches the user's profile image asynchronously using _fetchProfileImage()
// - It checks if the user's profile is complete by calling _checkProfileCompletion() after the widget has been laid out
  @override
  void initState() {
    super.initState();
    _subscribeToUserData(); // Starts listening for user data from Firestore
    _fetchProfileImage(); // Fetches the user's profile image

    // Executes the profile completion check after the widget has been rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion(); // Checks if the user profile is complete after the first frame is rendered
    });
  }

  // This variable tracks whether a specific section of the UI (likely headers) has been clicked.
// It is used to toggle the view of options or further details on the dashboard.
  bool isHeadersClicked = false;

  // This variable stores the selected option for some kind of user interaction on the dashboard. It tracks which option is active.
  String selectedOption = "";

  // Firebase authentication and Firestore instances are initialized to interact with Firebase services.
// These are used for authentication (user login, etc.) and to fetch/update user data from Firestore.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // _userSubscription is a subscription to real-time updates from Firestore for the user's data.
// The StreamSubscription will handle updates for any changes in user data while the user is active.
  StreamSubscription<QuerySnapshot>? _userSubscription;

  // These variables are used to store the current user's details, including their first name, last name, role, and loading state.
// The initial values are set to "Loading..." or default values, which will be updated once the user data is retrieved.
  String firstName = "Loading...";
  String lastName = "";
  String role = "Fetching...";

  // The isLoading flag is set to true initially to indicate that user data is being fetched, and UI elements can show loading indicators.
  bool isLoading = true;

  // This method subscribes to real-time updates for the current user's data from the Firestore database.
// It checks if the user is authenticated by retrieving their UID from FirebaseAuth. If the user is logged in,
// it proceeds to listen for changes in the "users" collection where the UID matches the current user's UID.
// The method listens for snapshot changes and updates the local state with the user's first name, last name,
// and role. If data is available, it sets the appropriate values; otherwise, it defaults to "No Data" or "N/A"
// for missing values. The loading state is also managed by setting `isLoading` to false once the data is fetched.
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
    // Cancel the active user subscription to stop receiving updates when the widget is disposed

    _userSubscription?.cancel(); // Cancel subscription to prevent memory leaks
    super.dispose();
  }

  final supabase = Supabase.instance.client;
  File? _image;
  String? _imageUrl;

  // This function fetches the profile image for the currently authenticated user
// from the Supabase storage service. It first checks if the user is authenticated
// and then attempts to retrieve the user's profile image file from the storage bucket
// based on their UID. If the image file exists, it constructs a public URL to access
// the image and ensures it is properly formatted with a timestamp to prevent caching
// issues. The image URL is then set in the state to be displayed. If no image is found,
// the user is notified through a SnackBar.
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
    }
  }

  // Function to check if the user's profile is complete by validating required fields in Firestore
  void _checkProfileCompletion() async {
    final user = _auth.currentUser;
    if (user == null) {
      // If there is no user, exit the function

      return;
    }

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

        // If a matching user is found in the query results, set the document to that user
        if (querySnapshot.docs.isNotEmpty) {
          doc = querySnapshot.docs.first;
        }
      }

      // If the user document doesn't exist, show a toast notification and return
      if (!doc.exists) {
        _showProfileCompletionToast();
        return;
      }

      // Document exists, proceed to check if the profile fields are complete
      try {
        final userData = doc.data() as Map<String, dynamic>;

        // List of required fields that must be present and non-empty in the user's profile
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

        // Flag to track if the profile is complete
        bool isProfileComplete = true;

        // List to store any missing fields
        List<String> missingFields = [];

        // Check each required field to see if it exists and isn't empty
        for (String field in requiredFields) {
          final hasField = userData.containsKey(field);
          final fieldValue = userData[field];
          final isEmpty = fieldValue == null ||
              (fieldValue is String && fieldValue.isEmpty);

          // If the field is missing or empty, mark the profile as incomplete

          if (!hasField || isEmpty) {
            isProfileComplete = false;
            missingFields.add(field); // Add the missing field to the list
          }
        }

        // If the profile is incomplete, show the toast to notify the user
        if (!isProfileComplete) {
          _showProfileCompletionToast();
        } else {
          // If the profile is complete, save a preference to avoid checking it again

          // Save preference to avoid future checks if profile is complete
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isProfileCompleted_${user.uid}',
                true); // Save the profile completion status
          } catch (e) {
            // Show a Snackbar if there was an error saving the preference

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      } catch (e) {
        // If there was an error checking the user data, show the toast notification

        _showProfileCompletionToast();
      }
    } catch (e) {
      // If there was an error fetching user data, show the toast notification
      _showProfileCompletionToast();
    }
  }

// Simplify the toast method
// This will shpw a Toast if the User Have something in his profile that is not completed
  void _showProfileCompletionToast() {
    // Delay showing toast slightly to ensure UI is ready
    Future.delayed(Duration(milliseconds: 800), () {
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
        style: ToastificationStyle.flatColored, // Light yellow color
        autoCloseDuration: const Duration(seconds: 6),
        animationDuration: const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final sidebarProvider = Provider.of<AdminSidebarProvider>(context);
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
                    builder: (context) => Admin_Dashboard(),
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
        return const ScheduleAppointment();
      case 2:
        return const AddClient();
      case 3:
        return const Maintenance();
      case 4:
        return const AppointmentManager();
      case 5:
        return const SettingsSU();
      case 6:
        return const AuditSU();
      default:
        return const Text('Select an option from the menu.',
            style: TextStyle(fontSize: 20));
    }
  }
}
