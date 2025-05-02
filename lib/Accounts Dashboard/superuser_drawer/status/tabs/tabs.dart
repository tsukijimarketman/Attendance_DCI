import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/attendance/attendance.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/details/details.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/minutes/minutes_of_meeting.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/qrcode/qr.dart';
import 'package:attendance_app/Appointment/appointment_details.dart';
import 'package:flutter/material.dart';
import 'package:tab_container/tab_container.dart';

class MeetingTabs extends StatefulWidget {
  final String selectedAgenda;
  final String statusType;
  const MeetingTabs({super.key, required this.selectedAgenda, required this.statusType});

  @override
  State<MeetingTabs> createState() => _MeetingTabsState();
}

class _MeetingTabsState extends State<MeetingTabs> with TickerProviderStateMixin {
  late TextTheme textTheme;
  late String currentAgenda;
  late TabController _tabController;
  int _currentIndex = 0;
  
  // Map to store which tabs are available for each status type
  late Map<int, bool> _availableTabs;

  @override
  void initState() {
    super.initState();
    currentAgenda = widget.selectedAgenda;
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _updateAvailableTabs();
  }

  // Update which tabs are available based on statusType
  void _updateAvailableTabs() {
    _availableTabs = {0: true, 1: false, 2: false, 3: false}; // Default all tabs unavailable except Details
    
    switch (widget.statusType) {
      case 'Scheduled':
        _availableTabs = {0: true, 1: false, 2: false, 3: false};
        break;
      case 'In Progress':
        _availableTabs = {0: true, 1: false, 2: false, 3: true}; // Attendance set to false
        break;
      case 'Completed':
        _availableTabs = {0: true, 1: true, 2: true, 3: false};
        break;
      case 'Cancelled':
        _availableTabs = {0: true, 1: false, 2: false, 3: false}; // Attendance set to false
        break;
      default:
        _availableTabs = {0: true, 1: true, 2: true, 3: true}; // All available as fallback
    }
    
    // Make sure current tab is available, otherwise switch to the first available tab
    if (!_availableTabs[_currentIndex]!) {
      _tabController.animateTo(0); // Details tab is always available
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final int newIndex = _tabController.index;
      
      // If the new tab is not available, prevent the change
      if (!_availableTabs[newIndex]!) {
        // Show a snackbar to inform the user
        WidgetsBinding.instance.addPostFrameCallback((_) {
          
          // Revert back to previous tab
          _tabController.animateTo(_currentIndex);
        });
        return;
      }
      
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  @override
  void didUpdateWidget(MeetingTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if selectedAgenda or statusType has changed
    if (oldWidget.selectedAgenda != widget.selectedAgenda || 
    oldWidget.statusType != widget.statusType) {
  setState(() {
    currentAgenda = widget.selectedAgenda;
    _updateAvailableTabs();
    
    // Restore current index if valid
    if (!_availableTabs[_currentIndex]!) {
      _currentIndex = 0;
    }
    _tabController.index = _currentIndex;
  });
}

  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    textTheme = Theme.of(context).textTheme;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFf2edf3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            TabContainer(
              controller: _tabController,
              radius: 20,
              tabEdge: TabEdge.bottom,
              tabCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                animation = CurvedAnimation(curve: Curves.easeIn, parent: animation);
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(0.2, 0.0),
                    end: const Offset(0.0, 0.0),
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              colors: <Color>[
                Color(0xFF0e2643),
                Color(0xFF0e2643),
                Color(0xFF0e2643),
                Color(0xFF0e2643)
              ],
              selectedTextStyle: textTheme.bodyMedium?.copyWith(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              unselectedTextStyle: textTheme.bodyMedium?.copyWith(
                fontSize: 14.0,
                color: Colors.black,
              ),
              tabs: _getTabs(),
              children: _getChildren(),
            ),
            // Add custom tap handlers over unavailable tabs
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                children: List.generate(4, (index) {
                  // Skip available tabs
                  if (_availableTabs[index]!) {
                    return Expanded(child: SizedBox());
                  }
                  
                  // Create tap interceptor for unavailable tabs
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        
                      },
                      child: Container(
                        height: 50, // Match tab height
                        color: Colors.transparent,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getTabs() {
    return <Widget>[
      Text(
        'Appointment Details',
        style: TextStyle(
            fontFamily: "SB", fontSize: MediaQuery.of(context).size.width / 90),
      ),
      Text(
        'Attendance',
        style: TextStyle(
            fontFamily: "SB", 
            fontSize: MediaQuery.of(context).size.width / 90,
            color: _availableTabs[1]! ? null : Colors.grey.withOpacity(0.5)),
      ),
      Text(
        'Minutes of Meeting',
        style: TextStyle(
            fontFamily: "SB", 
            fontSize: MediaQuery.of(context).size.width / 90,
            color: _availableTabs[2]! ? null : Colors.grey.withOpacity(0.5)),
      ),
      Text(
        'Generate QR',
        style: TextStyle(
            fontFamily: "SB", 
            fontSize: MediaQuery.of(context).size.width / 90,
            color: _availableTabs[3]! ? null : Colors.grey.withOpacity(0.5)),
      ),
    ];
  }

  List<Widget> _getChildren() {
    // Use keys to force rebuild when agenda changes
    return <Widget>[
      DetailPage(
        key: ValueKey('details-$currentAgenda'),
        selectedAgenda: currentAgenda,
        statusType: widget.statusType,
      ),
      _availableTabs[1]! 
          ? Attendance(
              key: ValueKey('attendance-$currentAgenda'),
              selectedAgenda: currentAgenda,
            )
          : _buildUnavailableTab('Attendance is not available for ${widget.statusType} meetings'),
      _availableTabs[2]! 
          ? MinutesOfMeeting(
              key: ValueKey('minutes-$currentAgenda'),
              selectedAgenda: currentAgenda,
            )
          : _buildUnavailableTab('Minutes of Meeting is not available for ${widget.statusType} meetings'),
      _availableTabs[3]! 
          ? QrCode(
              key: ValueKey('qr-$currentAgenda'),
              selectedAgenda: currentAgenda,
            )
          : _buildUnavailableTab('QR Code is not available for ${widget.statusType} meetings'),
    ];
  }
  
  // Widget to display when a tab is unavailable
  Widget _buildUnavailableTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}