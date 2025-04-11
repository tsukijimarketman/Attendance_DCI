import 'package:flutter/material.dart';
import 'package:tab_container/tab_container.dart';

class MeetingTabs extends StatefulWidget {
  const MeetingTabs({super.key});

  @override
  State<MeetingTabs> createState() => _MeetingTabsState();
}

class _MeetingTabsState extends State<MeetingTabs> with SingleTickerProviderStateMixin {
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
            animation = CurvedAnimation(
                curve: Curves.easeIn, parent: animation);
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
            Color(0xFF60D1D5), // Teal color similar to credit card
            Color(0xFF5BBCD6),
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
      Text('Appointment Details', style: TextStyle(fontFamily: "SB", fontSize: MediaQuery.of(context).size.width/90),),
      Text('Attendance', style: TextStyle(fontFamily: "SB", fontSize: MediaQuery.of(context).size.width/90),),
      Text('Minutes of Meeting', style: TextStyle(fontFamily: "SB", fontSize: MediaQuery.of(context).size.width/90),),
      Text('Generate QR', style: TextStyle(fontFamily: "SB", fontSize: MediaQuery.of(context).size.width/90),),
    ];
  }

  List<Widget> _getChildren() {
    return <Widget>[
      _buildAppointmentDetails(),
      _buildAttendance(),
      _buildMinutesOfMeeting(),
      _buildGenerateQR(),
    ];
  }

  Widget _buildAppointmentDetails() {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width/1.5,
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Details',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Title:', 'Quarterly Planning Meeting'),
            _buildDetailRow('Date:', 'April 15, 2025'),
            _buildDetailRow('Time:', '10:00 AM - 12:00 PM'),
            _buildDetailRow('Location:', 'Conference Room A'),
            _buildDetailRow('Organizer:', 'John Doe'),
            const SizedBox(height: 20),
            Text(
              'Agenda',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _buildAgendaItem('1. Review of Q1 performance'),
            _buildAgendaItem('2. Q2 targets and strategy'),
            _buildAgendaItem('3. Budget allocation'),
            _buildAgendaItem('4. Open discussion'),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Edit Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendance() {
    return SingleChildScrollView(
      child: Container(
        
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width/1.5,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildAttendeeCard('John Doe', 'CEO', true),
                  _buildAttendeeCard('Jane Smith', 'CTO', true),
                  _buildAttendeeCard('Robert Johnson', 'CFO', false),
                  _buildAttendeeCard('Emily Williams', 'Marketing Director', true),
                  _buildAttendeeCard('Michael Brown', 'HR Manager', true),
                  _buildAttendeeCard('Sarah Davis', 'Product Manager', false),
                  _buildAttendeeCard('James Wilson', 'Sales Director', true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: 7 | Present: 5 | Absent: 2',
                  style: textTheme.bodyLarge,
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Add Attendee'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinutesOfMeeting() {
    return SingleChildScrollView(
      child: Container(
        
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width/1.5,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minutes of Meeting',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMinuteSection(
                      'Opening',
                      'Meeting called to order at 10:05 AM by John Doe. Attendance taken and quorum confirmed.',
                    ),
                    _buildMinuteSection(
                      'Q1 Performance Review',
                      'Jane Smith presented the Q1 results showing a 15% increase in revenue compared to the previous quarter. Key factors contributing to growth included the launch of Product X and expansion into European markets.',
                    ),
                    _buildMinuteSection(
                      'Q2 Strategy',
                      'Discussion led by Michael Brown on targets for Q2. Agreement to focus on APAC region expansion and the development of Product Y. Budget allocation of \$1.2M approved for marketing initiatives.',
                    ),
                    _buildMinuteSection(
                      'Action Items',
                      '1. Emily to prepare marketing plan by April 25\n2. James to contact potential partners in Japan by May 1\n3. Robert to revise Q2 budget allocation by April 20\n4. Sarah to schedule follow-up meeting for product development team',
                    ),
                    _buildMinuteSection(
                      'Closing',
                      'Meeting adjourned at 11:55 AM. Next meeting scheduled for May 15, 2025.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Export as PDF'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Edit Minutes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateQR() {
    return SingleChildScrollView(
      child: Container(
        
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width/1.5,
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
            _buildQRFeature(Icons.calendar_today, 'Add meeting to your calendar'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge,
            ),
          ),
        ],
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

  Widget _buildAttendeeCard(String name, String position, bool present) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(name[0]),
        ),
        title: Text(name),
        subtitle: Text(position),
        trailing: Chip(
          label: Text(present ? 'Present' : 'Absent'),
          backgroundColor: present ? Colors.green.shade100 : Colors.red.shade100,
          labelStyle: TextStyle(color: present ? Colors.green.shade800 : Colors.red.shade800),
        ),
      ),
    );
  }

  Widget _buildMinuteSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: textTheme.bodyMedium,
        ),
        const Divider(height: 30),
      ],
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