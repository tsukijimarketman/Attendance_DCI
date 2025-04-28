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

class _MeetingTabsState extends State<MeetingTabs>
    with SingleTickerProviderStateMixin {
  late TextTheme textTheme;

  @override
  void didChangeDependencies() {
    textTheme = Theme.of(context).textTheme;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        
        decoration: BoxDecoration(color: Color(0xFFf2edf3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TabContainer(
          radius: 20,
          tabEdge: TabEdge.bottom,
          tabCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            animation =
                CurvedAnimation(curve: Curves.easeIn, parent: animation);
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
          colors: const <Color>[
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
            fontFamily: "SB", fontSize: MediaQuery.of(context).size.width / 90),
      ),
      Text(
        'Minutes of Meeting',
        style: TextStyle(
            fontFamily: "SB", fontSize: MediaQuery.of(context).size.width / 90),
      ),
      Text(
        'Generate QR',
        style: TextStyle(
            fontFamily: "SB", fontSize: MediaQuery.of(context).size.width / 90),
      ),
    ];
  }

  List<Widget> _getChildren() {
    return <Widget>[
      DetailPage(
        selectedAgenda: widget.selectedAgenda, statusType: widget.statusType,
      ),
      Attendance(
        selectedAgenda: widget.selectedAgenda,
      ),
      MinutesOfMeeting(
        selectedAgenda: widget.selectedAgenda,
      ),
      QrCode(
        selectedAgenda: widget.selectedAgenda,
      ),
    ];
  }

  Widget _buildAgendaItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        item,
        style: textTheme.bodyLarge,
      ),
    );
  }
}
