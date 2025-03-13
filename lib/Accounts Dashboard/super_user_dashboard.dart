import 'package:attendance_app/Animation/Animation.dart';
import 'package:attendance_app/superuser_drawer/logout.dart';
import 'package:attendance_app/superuser_drawer/references.dart';
import 'package:attendance_app/superuser_drawer/usermanagement.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class SuperUserDashboard extends StatefulWidget {
  const SuperUserDashboard({super.key});

  @override
  State<SuperUserDashboard> createState() => _SuperUserDashboardState();
}

class _SuperUserDashboardState extends State<SuperUserDashboard> {
  final _controller = SidebarXController(selectedIndex: 0); // Start with Dashboard

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Rebuild UI when selected index changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf2edf3),
      body: Row(
        children: [
          /// Sidebar Menu
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
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              iconTheme:
                  const IconThemeData(color: Color(0xFFbeabc2), size: 24),
              selectedIconTheme:
                  const IconThemeData(color: Colors.amber, size: 26),
              selectedItemTextPadding: const EdgeInsets.symmetric(horizontal: 20),
              
            ),
            headerDivider: const Divider(thickness: 2, color: Colors.black12),
            items: [
              SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
              SidebarXItem(icon: Icons.person_2, label: 'User Management'),
              SidebarXItem(icon: Icons.room_preferences, label: 'References'),
              SidebarXItem(icon: Icons.logout, label: 'Logout'),
            ],
          ),

          /// Page Content Area
          Expanded(
            child: Center(
              child: _buildPageContent(),
            ),
          ),
        ],
      ),
    );
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
      case 3:
        return LogoutSU();
      default:
        return const Text('Select an option from the menu.',
            style: TextStyle(fontSize: 20));
    }
  }
}
