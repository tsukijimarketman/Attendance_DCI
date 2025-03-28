import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class SidebarProvider extends ChangeNotifier {
  final SidebarXController _controller = SidebarXController(selectedIndex: 0);

  SidebarXController get controller => _controller;

  int get selectedIndex => _controller.selectedIndex;

  SidebarProvider() {
    _controller.addListener(() {
      notifyListeners(); // Notify UI when selection changes
    });
  }
}
