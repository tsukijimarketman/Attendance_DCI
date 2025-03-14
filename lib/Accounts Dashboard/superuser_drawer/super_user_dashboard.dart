import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/auditSU.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/notification_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/settings_su.dart';
import 'package:attendance_app/Animation/Animation.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/references_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/usermanagement_su.dart';
import 'package:attendance_app/head/login.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class SuperUserDashboard extends StatefulWidget {
  const SuperUserDashboard({super.key});

  @override
  State<SuperUserDashboard> createState() => _SuperUserDashboardState();
}

class _SuperUserDashboardState extends State<SuperUserDashboard> {
  var _controller =
      SidebarXController(selectedIndex: 0); // Start with Dashboard

  Color color1 = Colors.grey;
  Color color2 = Colors.grey;
  Color color3 = Colors.grey;
  Color color4 = Colors.grey;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Rebuild UI when selected index changes
    });
  }

  // Show logout confirmation dialog
  Future<void> _showLogoutDialog() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Don't close when tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.info_outline,
                    color: Colors.grey,
                    size: MediaQuery.of(context).size.width / 30),
                Text(
                  'Confirm Logout',
                  style: TextStyle(
                      fontFamily: "SB",
                      fontSize: MediaQuery.of(context).size.width / 60),
                ),
              ],
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
                fontFamily: "R",
                fontSize: MediaQuery.of(context).size.width / 80),
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context, false);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width / 40),
                      color: Colors.red,
                    ),
                    height: MediaQuery.of(context).size.width / 40,
                    width: MediaQuery.of(context).size.width / 10,
                    child: Center(
                        child: Text(
                      'No',
                      style: TextStyle(
                          fontFamily: "R",
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width / 80),
                    )),
                  ),
                ).showCursorOnHover.moveUpOnHover,
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context, true);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width / 40),
                      color: Colors.green,
                    ),
                    height: MediaQuery.of(context).size.width / 40,
                    width: MediaQuery.of(context).size.width / 10,
                    child: Center(
                        child: Text(
                      'Yes',
                      style: TextStyle(
                          fontFamily: "R",
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width / 80),
                    )),
                  ),
                ).showCursorOnHover.moveUpOnHover,
              ],
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await _logout(); // Proceed with logout if user confirms
    }
  }

  // Method to log the user out
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // After signing out, you can directly navigate to the login screen
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Handle logout error (if any)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  bool isHeadersClicked = false;
  String selectedOption = "";

  @override
  Widget build(BuildContext context) {
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
                    ));
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 40,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width / 140),
                    child: Image.asset("dci_logo.png",
                        height: MediaQuery.of(context).size.width / 20),
                  ),
                ],
              ),
            ).showCursorOnHover,
            Spacer(),
            CircleAvatar(
              backgroundColor: Colors.grey,
              radius: MediaQuery.of(context).size.width / 60,
              child: Icon(Icons.person,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width / 50),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 60,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Super User",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: MediaQuery.of(context).size.height / 50,
                        fontFamily: "M")),
                Text("Superuser",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: MediaQuery.of(context).size.height / 70,
                        fontFamily: "R"))
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 30,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isHeadersClicked == false) {
                    setState(() {
                      isHeadersClicked = true;
                      selectedOption = "Notifications";
                      _controller = SidebarXController(selectedIndex: -1);
                    });
                  } else if (isHeadersClicked == true) {
                    setState(() {
                      isHeadersClicked = false;
                      selectedOption = "";

                      _controller = SidebarXController(selectedIndex: 0);
                    });
                  }
                });
              },
              child: MouseRegion(
                onEnter: (event) {
                  setState(() {
                    color1 = Color.fromARGB(255, 11, 55, 99);
                  });
                },
                onExit: (event) {
                  setState(() {
                    color1 = Colors.grey;
                  });
                },
                child: Tooltip(
                  message: 'Notifications',
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
                    Icons.notifications_none,
                    color: color1,
                    size: MediaQuery.of(context).size.width / 58,
                  ),
                ),
              ),
            ).showCursorOnHover,
            SizedBox(
              width: MediaQuery.of(context).size.width / 40,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isHeadersClicked == false) {
                    setState(() {
                      isHeadersClicked = true;
                      selectedOption = "Settings";

                      _controller = SidebarXController(selectedIndex: -1);
                    });
                  } else if (isHeadersClicked == true) {
                    setState(() {
                      isHeadersClicked = false;
                      selectedOption = "";

                      _controller = SidebarXController(selectedIndex: 0);
                    });
                  }
                });
              },
              child: MouseRegion(
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
                  decoration: BoxDecoration(color: Colors.transparent),
                  textStyle: TextStyle(
                      color: Color.fromARGB(255, 11, 55, 99),
                      fontFamily: "B",
                      fontSize: MediaQuery.of(context).size.width / 140),
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width / 120,
                      vertical: MediaQuery.of(context).size.width / 160),
                  child: Icon(
                    Icons.settings_outlined,
                    color: color2,
                    size: MediaQuery.of(context).size.width / 60,
                  ),
                ),
              ),
            ).showCursorOnHover,
            SizedBox(
              width: MediaQuery.of(context).size.width / 40,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isHeadersClicked == false) {
                    setState(() {
                      isHeadersClicked = true;
                      selectedOption = "Audit Logs";

                      _controller = SidebarXController(selectedIndex: -1);
                    });
                  } else if (isHeadersClicked == true) {
                    setState(() {
                      isHeadersClicked = false;
                      selectedOption = "";

                      _controller = SidebarXController(selectedIndex: 0);
                    });
                  }
                });
              },
              child: MouseRegion(
                onEnter: (event) {
                  setState(() {
                    color3 = Color.fromARGB(255, 11, 55, 99);
                  });
                },
                onExit: (event) {
                  setState(() {
                    color3 = Colors.grey;
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
                    color: color3,
                    size: MediaQuery.of(context).size.width / 60,
                  ),
                ),
              ),
            ).showCursorOnHover,
            SizedBox(
              width: MediaQuery.of(context).size.width / 40,
            ),
            GestureDetector(
              onTap: () {
                _showLogoutDialog();
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
              headerBuilder: (context, extended) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 300, // Increase height
                    width: 350, // Increase width
                    child: AnimatedGlbViewer(),
                  ),
                );
              },
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
                        selectedOption == "Notifications"
                            ? NotificationsSU()
                            : selectedOption == "Settings"
                                ? SettingsSU()
                                : selectedOption == "Audit Logs"
                                    ? AuditSU()
                                    : Container(),
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
