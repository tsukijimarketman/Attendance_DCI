import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_appointment.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_audit.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/manage_all_appointments.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/auditSU.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/notification_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/settings_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/super_user_dashboard.dart';
import 'package:attendance_app/Animation/Animation.dart';
import 'package:attendance_app/Appointment/add_client.dart';
import 'package:attendance_app/Appointment/schedule_appointment.dart';
import 'package:attendance_app/Auth/showDialogSignOut.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class Admin_Dashboard extends StatefulWidget {
  const Admin_Dashboard({super.key});

  @override
  State<Admin_Dashboard> createState() => _Admin_DashboardState();
}

class _Admin_DashboardState extends State<Admin_Dashboard> {
   var _controller =
      SidebarXController(selectedIndex: 0); // Start with Dashboard

  Color color1 = Colors.grey;
  Color color2 = Colors.grey;
  Color color3 = Colors.grey;
  Color color4 = Colors.grey;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _controller.addListener(() {
      setState(() {}); // Rebuild UI when selected index changes
    });
  }

  bool isHeadersClicked = false;
  String selectedOption = "";
  String fullName = 'Loading...';
  String email = 'Loading...';

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⚠️ No authenticated user found.");
        return;
      }

      String uid = user.uid;
      String? userEmail = user.email;

      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection("users")
          .where("uid", isEqualTo: uid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        var userDoc = userQuery.docs.first;
        String fetchedFullName =
            "${userDoc["first_name"] ?? ""} ${userDoc["last_name"] ?? ""}".trim();

        print("✅ Found User: ${userDoc.id}, Name: $fetchedFullName, Email: ${userEmail ?? 'N/A'}");

        if (mounted) {
          setState(() {
            fullName = fetchedFullName.isNotEmpty ? fetchedFullName : "Unknown User";
            email = userEmail ?? "No Email Available";
          });
        }
      } else {
        print("⚠️ No user document found for UID: $uid");
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }


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
                    child: Image.asset("assets/dci_logo.png",
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: MediaQuery.of(context).size.height / 50,
                        fontFamily: "M")),
                Text(email,
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
                SidebarXItem(icon: Icons.schedule_send_outlined, label: 'Scheduled Appointments'),
                SidebarXItem(icon: Icons.schedule_outlined, label: 'Schedule a Appointment'), 
                SidebarXItem(icon: Icons.person_2_outlined, label: 'Clients'),
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
                                    ? AdminAudit()
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
        return const ManageAllAppointments();
      case 1:
        return const AdminAppointment();
       case 2:
        return const ScheduleAppointment();
       case 3: 
        return const AddClient();
      default:
        return const Text('Select an option from the menu.',
            style: TextStyle(fontSize: 20));
    }
  }
}
