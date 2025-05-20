import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';
import 'admin_sidebar_provider.dart'; // Import the provider

class SideBarXUsage extends StatelessWidget {
  const SideBarXUsage({super.key});

  @override
  Widget build(BuildContext context) {
    final sidebarProvider = Provider.of<AdminSidebarProvider>(context);

    return SidebarX(
      controller: sidebarProvider.controller,
      extendedTheme: SidebarXTheme(
        itemPadding: const EdgeInsets.all(10),
        width: MediaQuery.of(context).size.width / 5.3,
      ),
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.black),
        selectedTextStyle: const TextStyle(color: Colors.white),
        itemTextPadding: const EdgeInsets.symmetric(horizontal: 20),
        selectedItemDecoration: BoxDecoration(
          color: const Color.fromARGB(255, 11, 55, 99),
          borderRadius: BorderRadius.circular(8),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbeabc2), size: 24),
        selectedIconTheme: const IconThemeData(
            color: Color.fromARGB(255, 255, 76, 63), size: 26),
        selectedItemTextPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      headerDivider: const Divider(thickness: 2, color: Colors.black12),
      items: [
        SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
        SidebarXItem(icon: Icons.event, label: 'Appointment Creation'),
        SidebarXItem(icon: Icons.group, label: 'Clients'),
        SidebarXItem(icon: Icons.build, label: 'Maintenance'),
        SidebarXItem(icon: Icons.event_note, label: 'Current Appointments'),
        SidebarXItem(icon: Icons.settings, label: 'Settings'),
        SidebarXItem(icon: Icons.history, label: 'Audit Logs'),
      ],
    );
  }
}
