
import 'package:attendance_app/Animation/Animation.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/manager_dash.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/make_a_form.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class Manager_Dashboard extends StatefulWidget {
  const Manager_Dashboard({super.key});

  @override
  State<Manager_Dashboard> createState() => _Manager_DashboardState();
}

class _Manager_DashboardState extends State<Manager_Dashboard> {
  final _controller = SidebarXController(
    selectedIndex: 0,
  ); // Start with Dashboard

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
      backgroundColor: Colors.blue.shade700,
      body: Row(
        children: [
          /// Sidebar Menu
          SidebarX(
            controller: _controller,
            extendedTheme: SidebarXTheme(
              itemPadding: EdgeInsets.all(10),
              hoverColor: Colors.amber,
              width: 200,
            ),
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(color: Colors.white),
              selectedTextStyle: const TextStyle(color: Colors.amber),
              itemTextPadding: const EdgeInsets.symmetric(horizontal: 20),
              selectedItemDecoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              iconTheme: const IconThemeData(color: Colors.white, size: 24),
              selectedIconTheme: const IconThemeData(
                color: Colors.amber,
                size: 26,
              ),
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
            items: const [
              SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
              SidebarXItem(icon: Icons.description, label: 'User Management'),
              SidebarXItem(icon: Icons.room_preferences, label: 'References'),
              SidebarXItem(icon: Icons.logout, label: 'Logout'),
            ],
          ),

          /// Page Content Area
          Expanded(child: Center(child: _buildPageContent())),
        ],
      ),
    );
  }

  /// Function to render different pages based on sidebar selection
  Widget _buildPageContent() {
    switch (_controller.selectedIndex) {
      case 0:
        return const Manager_Dash();
      case 1:
        return const MakeAForm();
      case 2:
        return const Text('HEHE');
      case 3:
        return const Text(
          'Logging out...',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        );
      default:
        return const Text(
          'Select an option from the menu.',
          style: TextStyle(fontSize: 20),
        );
    }
  }
}
