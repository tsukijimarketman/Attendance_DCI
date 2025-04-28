import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/attendance/attendance_export_utils.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Attendance extends StatefulWidget {
  final String selectedAgenda;
  const Attendance({super.key, required this.selectedAgenda});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  String userDepartment = "";
  String fullName = "";

  // Lists to store data
  List<Map<String, dynamic>> attendanceList =
      []; // People who actually attended
  List<Map<String, dynamic>> invitedGuests = []; // External guests invited
  List<Map<String, dynamic>> invitedUsers = []; // Internal users invited
  List<Map<String, dynamic>> consolidatedAttendees =
      []; // Combined list with present/absent status

  // Pagination variables
  int currentPage = 1;
  int itemsPerPage = 5;
  int totalPages = 1;

  // Search functionality
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  TextEditingController itemsPerPageController = TextEditingController();

  // Filtered attendees for search and pagination
  List<Map<String, dynamic>> filteredAttendees = [];

  String appointmentSchedule = "";

  // The initState method is called when the widget is first created. It initializes the itemsPerPageController with the current value of itemsPerPage.
  // Then it triggers the fetchUserDepartment method, which fetches the department data for the current user.
  // After the user department data is successfully fetched, it proceeds to fetch the appointment data and attendance data sequentially.
  // This ensures that all necessary data is fetched and ready for use when the widget is displayed.
  @override
  void initState() {
    super.initState();
    itemsPerPageController.text = itemsPerPage.toString();
    fetchUserDepartment().then((_) {
      fetchAppointmentData();
      fetchAttendanceData();
    });
  }

  // Prevent for memory Leaks
  @override
  void dispose() {
    searchController.dispose();
    itemsPerPageController.dispose();
    super.dispose();
  }

  // The fetchUserDepartment method retrieves the department information of the currently logged-in user.
  // It first checks if the user is logged in using FirebaseAuth. If the user is logged in, it queries the 'users' collection in Firestore
  // to fetch the user document using their unique 'uid'. If the user document is found, it extracts the department and full name from the document
  // and updates the state with the fetched data. If no user is logged in or an error occurs, the loading state is set to false.
  Future<void> fetchUserDepartment() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          var userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;

          setState(() {
            userDepartment = userData['department'] ?? "";
            fullName = "${userData['first_name']} ${userData['last_name']}";
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  // The fetchAppointmentData method retrieves appointment-related data from Firestore based on the selected agenda.
  // It queries the 'appointment' collection in Firestore to find the appointment document associated with the selected agenda.
  // If the appointment data is found, it extracts the list of external guests, internal users, and the appointment schedule.
  // These data points are then stored in their respective variables, and the consolidated list of attendees is updated by calling the updateConsolidatedList method.
  // If no data is found or an error occurs during the fetch operation, a Snackbar is displayed to inform the user.
  Future<void> fetchAppointmentData() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('appointment')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;

        // Fetch external guests array from Firestore
        if (data.containsKey('guest') && data['guest'] is List) {
          invitedGuests = List<Map<String, dynamic>>.from(data['guest']);
        }

        // Extract schedule
        if (data.containsKey('schedule')) {
          appointmentSchedule = data['schedule'] ?? "";
        }

        // Fetch internal users array from Firestore
        if (data.containsKey('internal_users') &&
            data['internal_users'] is List) {
          invitedUsers =
              List<Map<String, dynamic>>.from(data['internal_users']);
        }

        // Update the consolidated list after fetching both invited lists
        updateConsolidatedList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No appointment data found.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching appointment data: $e")));
    }
  }

  // The fetchAttendanceData method retrieves attendance data from Firestore based on the selected agenda.
  // It queries the 'attendance' collection to find all attendance records associated with the agenda.
  // If the attendance data is found, it updates the state with the list of attendees and calls the updateConsolidatedList method
  // to update the list of attendees, marking them as present or absent accordingly.
  // If no data is found, a Snackbar is shown to inform the user, and the consolidated list is still updated with everyone marked as absent.
  Future<void> fetchAttendanceData() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('attendance')
          .where('agenda', isEqualTo: widget.selectedAgenda)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          attendanceList = querySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          // Update the consolidated list after fetching attendance data
          updateConsolidatedList();
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("No attendance data found.")));
        // Still update consolidated list with everyone marked as absent
        updateConsolidatedList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching attendance data: $e")));
    }
  }

  // The updateConsolidatedList method creates a complete list of attendees by merging data from invited internal users, external guests,
  // and actual attendance records. It tracks attendance by email, where emails are used as unique identifiers to check if a person attended.
  // First, it processes the attendance list, marking users as present based on whether their email exists in the attendance data.
  // Then it processes the internal users, checking if they attended and adding their details to the consolidated list.
  // The same is done for external guests, using email as the primary key. Afterward, it checks for any additional attendees who might have attended
  // but weren't part of the initial invitation and adds them to the list.
  // Finally, it updates the state with the full consolidated list of attendees and triggers the filterAttendees method to filter the list.
  void updateConsolidatedList() {
    List<Map<String, dynamic>> consolidated = [];

    // Create a map to track attendees by email for quick lookup
    Map<String, bool> attendanceByEmail = {};
    Map<String, String> attendeeNameByEmail = {};
    Map<String, String> attendeeCompanyByEmail = {};

    // First, process the attendance list to know who actually attended
    for (var attendee in attendanceList) {
      String email = (attendee['email_address'] ?? '').toLowerCase();
      if (email.isNotEmpty) {
        attendanceByEmail[email] = true;
        attendeeNameByEmail[email] = attendee['name'] ?? '';
        attendeeCompanyByEmail[email] = attendee['company'] ?? '';
      }
    }

    // Process internal users - use email as primary identifier
    for (var user in invitedUsers) {
      String email = (user['email'] ?? '').toLowerCase();
      bool isPresent = email.isNotEmpty && attendanceByEmail.containsKey(email);

      // Use the actual name from attendance if present, otherwise use invited name
      String displayName = isPresent && attendeeNameByEmail.containsKey(email)
          ? attendeeNameByEmail[email]!
          : user['fullName'] ?? '';

      consolidated.add({
        'name': displayName,
        'position': user['department'] ?? 'N/A',
        'email': email,
        'present': isPresent,
        'type': 'Internal'
      });
    }

    // Process external guests - use email as primary identifier
    for (var guest in invitedGuests) {
      String email = (guest['emailAdd'] ?? '').toLowerCase();
      bool isPresent = email.isNotEmpty && attendanceByEmail.containsKey(email);

      // Use the actual name from attendance if present, otherwise use invited name
      String displayName = isPresent && attendeeNameByEmail.containsKey(email)
          ? attendeeNameByEmail[email]!
          : guest['fullName'] ?? '';

      consolidated.add({
        'name': displayName,
        'position': guest['companyName'] ?? 'N/A',
        'email': email,
        'present': isPresent,
        'type': 'External'
      });
    }

    // Track emails we've already processed to avoid duplicates
    Set<String> processedEmails = {};
    for (var person in consolidated) {
      String email = (person['email'] ?? '').toLowerCase();
      if (email.isNotEmpty) {
        processedEmails.add(email);
      }
    }

    // Now add any attendees who weren't in the invitation lists (Additional)
    for (var attendee in attendanceList) {
      String email = (attendee['email_address'] ?? '').toLowerCase();

      // Skip if we already processed this email
      if (email.isEmpty || processedEmails.contains(email)) {
        continue;
      }

      consolidated.add({
        'name': attendee['name'] ?? '',
        'position': attendee['company'] ?? 'Additional Attendee',
        'email': email,
        'present': true,
        'type': 'Additional'
      });

      // Mark as processed
      processedEmails.add(email);
    }

    setState(() {
      consolidatedAttendees = consolidated;
      filterAttendees();
    });
  }

  // Filter attendees based on search query
  void filterAttendees() {
    if (searchQuery.isEmpty) {
      filteredAttendees = List.from(consolidatedAttendees);
    } else {
      filteredAttendees = consolidatedAttendees.where((attendee) {
        String name = (attendee['name'] ?? '').toString().toLowerCase();
        String position = (attendee['position'] ?? '').toString().toLowerCase();
        String email = (attendee['email'] ?? '').toString().toLowerCase();
        String type = (attendee['type'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase()) ||
            position.contains(searchQuery.toLowerCase()) ||
            email.contains(searchQuery.toLowerCase()) ||
            type.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Update total pages
    totalPages = (filteredAttendees.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    // Ensure current page is within bounds
    if (currentPage > totalPages) {
      currentPage = totalPages;
    }
  }

  // Get current page items
  List<Map<String, dynamic>> getCurrentPageItems() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (endIndex > filteredAttendees.length) {
      endIndex = filteredAttendees.length;
    }

    if (startIndex >= filteredAttendees.length) {
      return [];
    }

    return filteredAttendees.sublist(startIndex, endIndex);
  }

  // Update items per page when user applies changes
  void updateItemsPerPage() {
    int? newValue = int.tryParse(itemsPerPageController.text);
    if (newValue != null && newValue > 0) {
      setState(() {
        itemsPerPage = newValue;
        currentPage = 1; // Reset to first page when changing items per page
        filterAttendees();
      });
    } else {
      // Reset to default if invalid input
      itemsPerPageController.text = itemsPerPage.toString();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid number greater than 0')));
    }
  }

  // Text with ellipsis and tooltip for long text
  Widget textWithTooltip(String text, TextStyle style, {double? maxWidth}) {
    return Tooltip(
      message: text,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: TextStyle(
        fontSize: 12,
        color: Colors.white,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      preferBelow: false,
      child: Container(
        constraints:
            maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
        child: Text(
          text,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  // Count statistics
  int get totalCount => consolidatedAttendees.length;
  int get presentCount =>
      consolidatedAttendees.where((p) => p['present'] == true).length;
  int get absentCount =>
      consolidatedAttendees.where((p) => p['present'] == false).length;

  // This will generate/download a PDF
  void _generatePDF() async {
    await AttendanceExportUtils.generatePDF(
      attendanceList: attendanceList,
      agenda: widget.selectedAgenda,
      schedule: appointmentSchedule,
    );
  }

  // This will generate/download a CSV
  void _generateCSV() async {
    await AttendanceExportUtils.generateCSV(attendanceList);
  }

// The dialog method remains largely the same:
  void showcsvpdfdialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Container(
            height: MediaQuery.of(context).size.width / 4.1,
            width: MediaQuery.of(context).size.width / 3,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      color: Color(0xFF0e2643),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Download Attendance",
                      style: TextStyle(
                        fontFamily: "SB",
                        color: Color(0xFF0e2643),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    "Select your preferred format to download the attendance report:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "R",
                      fontSize: 16,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFormatButton(
                      'PDF',
                      'assets/pdf.png',
                      Colors.red.shade100,
                      Color(0xFFD32F2F),
                      () {
                        // THis will Trigger the Download to PDf Attendance
                        _generatePDF();
                        // This will close the SHow Dialog Box
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildFormatButton(
                      'CSV',
                      'assets/csv.png',
                      Colors.green.shade100,
                      Color(0xFF2E7D32),
                      () {
                        // This will trigger the csv Download of attendance
                        _generateCSV();
                        // This will close the Show Dialog Box
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  width: MediaQuery.of(context).size.width / 3,
                  height: MediaQuery.of(context).size.width / 35,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width / 170),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontFamily: "R",
                        fontSize: MediaQuery.of(context).size.width / 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormatButton(String formatName, String imagePath, Color bgColor,
      Color textColor, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              width: 50,
              height: 50,
            ),
            SizedBox(height: 10),
            Text(
              formatName,
              style: TextStyle(
                fontFamily: "SB",
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildAttendance();
  }

  Widget _buildAttendance() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    double screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.width / 2.55,
        width: MediaQuery.of(context).size.width / 1.5,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: screenWidth / 60,
                    fontFamily: "B",
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: $totalCount | Present: $presentCount | Absent: $absentCount',
                      style: TextStyle(
                          fontFamily: "R",
                          fontSize: screenWidth / 100,
                          color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenWidth / 90),

            // Search and Items per page controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Search Bar
                Row(
                  children: [
                    Container(
                      width: screenWidth / 4,
                      height: screenWidth / 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth / 120),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: TextField(
                          style: TextStyle(
                            fontSize: screenWidth / 90,
                            fontFamily: "R",
                          ),
                          controller: searchController,
                          decoration: InputDecoration(
                            hintStyle: TextStyle(
                              fontSize: screenWidth / 90,
                              fontFamily: "M",
                              color: Colors.grey,
                            ),
                            hintText: 'Search attendees...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                              currentPage =
                                  1; // Reset to first page when searching
                              filterAttendees();
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: screenWidth / 80,
                    ),
                    // Items per page control
                    Row(
                      children: [
                        Container(
                          width: screenWidth / 33,
                          height: screenWidth / 33,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.circular(screenWidth / 120),
                              color: Colors.white),
                          child: TextField(
                            controller: itemsPerPageController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth / 120, vertical: 0),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: screenWidth / 100),
                            onSubmitted: (value) => updateItemsPerPage(),
                          ),
                        ),
                        SizedBox(
                          width: screenWidth / 120,
                        ),
                        GestureDetector(
                          onTap: updateItemsPerPage,
                          child: Container(
                            width: screenWidth / 23,
                            height: screenWidth / 33,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius:
                                    BorderRadius.circular(screenWidth / 120),
                                color: Colors.white),
                            child: Center(
                              child: Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: screenWidth / 140,
                                  fontFamily: "SB",
                                ),
                              ),
                            ),
                          ),
                        ).showCursorOnHover,
                      ],
                    ),
                  ],
                ),

                GestureDetector(
                  // This will show the show Dialog Box for Downloading a pdf or csv of the attendance
                  onTap: showcsvpdfdialog,
                  child: Container(
                    width: screenWidth / 12,
                    height: screenWidth / 33,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF0e2643)),
                      borderRadius: BorderRadius.circular(screenWidth / 120),
                      color: Color(0xFF0e2643),
                    ),
                    child: Center(
                      child: Text(
                        'Generate Report',
                        style: TextStyle(
                          fontSize: screenWidth / 140,
                          fontFamily: "SB",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ).showCursorOnHover,
              ],
            ),

            SizedBox(height: screenWidth / 80),

            // Attendee List with Pagination
            Expanded(
              child: filteredAttendees.isEmpty
                  ? Center(
                      child: Text(
                      'No attendance data available',
                      style: TextStyle(fontFamily: "R", color: Colors.white),
                    ))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: getCurrentPageItems().length,
                            itemBuilder: (context, index) {
                              final attendee = getCurrentPageItems()[index];
                              return _buildAttendeeCard(
                                attendee['name'] ?? 'N/A',
                                attendee['position'] ?? 'N/A',
                                attendee['present'] ?? false,
                                attendee['type'] ?? 'Unknown',
                                attendee['email'] ?? '',
                              );
                            },
                          ),
                        ),

                        // Only show pagination if we have items
                        if (filteredAttendees.isNotEmpty) ...[
                          // Pagination controls
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Previous page button
                                IconButton(
                                  icon: Icon(Icons.chevron_left),
                                  onPressed:
                                      // This is Pagination
                                      currentPage > 1
                                          ? () => setState(() => currentPage--)
                                          : null,
                                  iconSize: 24,
                                  color: currentPage > 1
                                      ? Colors.blue
                                      : Colors.grey,
                                ),

                                // Page numbers
                                SizedBox(
                                  height: 40,
                                  width: 300,
                                  child: Center(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          totalPages,
                                          (index) {
                                            int pageNumber = index + 1;
                                            bool isCurrentPage =
                                                pageNumber == currentPage;

                                            return Container(
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 4),
                                              child: InkWell(
                                                onTap: () => setState(() =>
                                                    currentPage = pageNumber),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isCurrentPage
                                                        ? Colors.blue
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                      color: isCurrentPage
                                                          ? Colors.blue
                                                          : Colors
                                                              .grey.shade300,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '$pageNumber',
                                                    style: TextStyle(
                                                      color: isCurrentPage
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontWeight: isCurrentPage
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Next page button
                                IconButton(
                                  icon: Icon(Icons.chevron_right),
                                  onPressed:
                                      // This is Pagination
                                      currentPage < totalPages
                                          ? () => setState(() => currentPage++)
                                          : null,
                                  iconSize: 24,
                                  color: currentPage < totalPages
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ),

                          // Page info text
                          Padding(
                            padding: EdgeInsets.only(top: screenWidth / 120),
                            child: Text(
                              'Page $currentPage of $totalPages (${filteredAttendees.length} total items)',
                              style: TextStyle(
                                fontFamily: "R",
                                fontSize: screenWidth / 120,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeeCard(
      String name, String position, bool present, String type, String email) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: type == 'Additional' ? Colors.blue.shade50 : Colors.white,
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAvatarColor(type),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            textWithTooltip(
              name,
              TextStyle(
                fontFamily: "SB",
                fontSize: MediaQuery.of(context).size.width / 100,
              ),
              maxWidth: screenWidth / 3,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textWithTooltip(
              position,
              TextStyle(fontSize: 12),
              maxWidth: screenWidth / 3,
            ),
            if (email.isNotEmpty)
              textWithTooltip(
                email,
                TextStyle(fontSize: 12, color: Colors.grey),
                maxWidth: screenWidth / 3,
              ),
            Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getTypeColor(type),
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(present ? 'Present' : 'Absent'),
          backgroundColor:
              present ? Colors.green.shade100 : Colors.red.shade100,
          labelStyle: TextStyle(
            color: present ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String type) {
    switch (type) {
      case 'Internal':
        return Colors.blue;
      case 'External':
        return Colors.orange;
      case 'Additional':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Internal':
        return Colors.blue;
      case 'External':
        return Colors.orange;
      case 'Additional':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
