import 'dart:async';

import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/auditSU.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/notification_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/settings_su.dart';
import 'package:attendance_app/Animation/Animation.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/references_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/usermanagement_su.dart';
import 'package:attendance_app/Auth/login.dart';
import 'package:attendance_app/Auth/showDialogSignOut.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class SuperUserDashboard extends StatefulWidget {
  const SuperUserDashboard({super.key});

  @override
  State<SuperUserDashboard> createState() => _SuperUserDashboardState();
}

class _SuperUserDashboardState extends State<SuperUserDashboard> {
  final _controller =
      SidebarXController(selectedIndex: 0); // Start with Dashboard

  Color color1 = Colors.grey;
  Color color2 = Colors.grey;
  Color color3 = Colors.grey;
  Color color4 = Colors.grey;

  IconData iconSettings = Icons.settings;

  @override
  void initState() {
    super.initState();
    _subscribeToUserData();
    _controller.addListener(() {
      setState(() {
        
      });
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

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

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
                  // SizedBox(width: MediaQuery.of(context).size.width / 40),
                  // Padding(
                  //   padding: EdgeInsets.symmetric(
                  //       vertical: MediaQuery.of(context).size.width / 140),
                  //   child: Image.asset("assets/dci_logo.png",
                  //       height: MediaQuery.of(context).size.width / 20),
                  // ),
                ],
              ),
            ).showCursorOnHover,
            Spacer(),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: MediaQuery.of(context).size.width / 60,
                  child: Icon(Icons.person,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width / 50),
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
                        fontFamily: "R"),),
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
              child: MouseRegion(
                onEnter: (event) {
                  setState(() {
                    color4 = Color.fromARGB(255, 11, 55, 99);
                  });
                },
                onExit: (event) {
                  setState(() {
                    color4 = Colors.grey;
                  });
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
              ),
            ).showCursorOnHover,
            SizedBox(
              width: MediaQuery.of(context).size.width / 40,
            ),
          ],
        ),
        body: Row(
          children: [
            SidebarX(
              controller: _controller,
              extendedTheme: SidebarXTheme(
                  itemPadding: EdgeInsets.all(10),
                  hoverColor: Colors.amber,
                  width: MediaQuery.of(context).size.width / 5.3),
              theme: SidebarXTheme(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(color: Colors.black),
                selectedTextStyle: const TextStyle(color: Colors.amber),
                itemTextPadding: const EdgeInsets.symmetric(horizontal: 20),
                selectedItemDecoration: BoxDecoration(
                  color: const Color.fromARGB(255, 11, 55, 99),
                  borderRadius: BorderRadius.circular(8),
                ),
                iconTheme:
                    const IconThemeData(color: Color(0xFFbeabc2), size: 24),
                selectedIconTheme:
                    const IconThemeData(color: Colors.amber, size: 26),
                selectedItemTextPadding:
                    const EdgeInsets.symmetric(horizontal: 20),
              ),
              headerDivider: const Divider(thickness: 2, color: Colors.black12),
              items: [
                SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
                SidebarXItem(icon: Icons.person_2, label: 'User Management'),
                SidebarXItem(icon: Icons.room_preferences, label: 'References'),
              ],
            ),

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
                      child: _buildPageContent(),
                    ),
            ),
          ],
        ));
  }

  /// Function to render different pages based on sidebar selection
  Widget _buildPageContent() {
    switch (_controller.selectedIndex) {
      case 0:
        return const Text('Dashboard Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
      case 1:
        return const UserManagement();
      case 2:
        return const References();
      default:
        return const Text('Select an option from the menu.',
            style: TextStyle(fontSize: 20));
    }
  }
}