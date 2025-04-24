import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/attendance/attendance.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/details/details.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/minutes/minutes_of_meeting.dart';
import 'package:attendance_app/Appointment/appointment_details.dart';
import 'package:flutter/material.dart';
import 'package:tab_container/tab_container.dart';

class MeetingTabs extends StatefulWidget {
  final String selectedAgenda;
  const MeetingTabs({super.key, required this.selectedAgenda});

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
        color: Color(0xFFf2edf3),
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
            Color(0xFF134679),
            Color(0xFF125292),
            Color(0xFF5BA4D6),
            Color(0xFF5B8ED6),
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
        selectedAgenda: widget.selectedAgenda,
      ),
      Attendance(
        selectedAgenda: widget.selectedAgenda,
      ),
      MinutesOfMeeting(
        selectedAgenda: widget.selectedAgenda,
      ),
      _buildGenerateQR(),
    ];
  }

  

  Widget _buildGenerateQR() {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width / 1.5,
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Meeting QR Code',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.qr_code, size: 150),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Scan this QR code to:',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _buildQRFeature(
                Icons.calendar_today, 'Add meeting to your calendar'),
            _buildQRFeature(Icons.article, 'Access meeting documents'),
            _buildQRFeature(Icons.check_circle, 'Mark your attendance'),
            _buildQRFeature(Icons.share, 'Share meeting details'),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Download QR Code'),
                ),
                const SizedBox(width: 20),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  label: const Text('Share QR Code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  

  Widget _buildQRFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            text,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
