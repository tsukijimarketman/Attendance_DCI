import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class ManagerSidebarProvider extends ChangeNotifier {
  final SidebarXController _controller = SidebarXController(selectedIndex: 0);

  SidebarXController get controller => _controller;

  int get selectedIndex => _controller.selectedIndex;

  ManagerSidebarProvider() {
    _controller.addListener(() {
      notifyListeners(); // Notify UI when selection changes
    });
  }
}
