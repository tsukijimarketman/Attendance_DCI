import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Add these additional imports to your file
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentManager extends StatefulWidget {
  const AppointmentManager({Key? key}) : super(key: key);

  @override
  _AppointmentManagerState createState() => _AppointmentManagerState();
}

class _AppointmentManagerState extends State<AppointmentManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add this method to get the current user's email
  Future<String?> _getCurrentUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.email;
    }
    return null;
  }

  // Pagination and search variables
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  int currentPageActive = 1;
  int currentPageHistory = 1;
  int itemsPerPage = 5;
  int totalPagesActive = 1;
  int totalPagesHistory = 1;
  TextEditingController itemsPerPageController = TextEditingController();
  bool isAscending = true; // Default sort direction
  Map<String, String> departmentMap = {};

  // Status colors
  final Map<String, Color> statusColors = {
    'Scheduled': const Color.fromARGB(255, 11, 55, 99),
    'In Progress': Colors.orange,
    'Completed': Colors.green,
    'Cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    itemsPerPageController.text = itemsPerPage.toString();

  fetchDepartmentNames().then((map) {
    setState(() {
      departmentMap = map;
    });
  });
}
  @override
  void dispose() {
    searchController.dispose();
    itemsPerPageController.dispose();
    super.dispose();
  }

  // Add this method to your _AppointmentManagerState class

  // Modified _showAppointmentDetails method to add status-based restriction
  void _showAppointmentDetails(
      Map<String, dynamic> appointmentData, String docId) async {
    final TextEditingController agendaController =
        TextEditingController(text: appointmentData['agenda'] ?? '');
    final TextEditingController departmentController =
        TextEditingController(text: appointmentData['department'] ?? '');
    final String createdBy = appointmentData['createdBy'] ?? 'Unknown';
    final String status = appointmentData['status'] ?? 'Scheduled';

    // Parse schedule string to DateTime
    DateTime scheduleDate = DateTime.parse(appointmentData['schedule']);
    String formattedDate = DateFormat('MMM dd, yyyy').format(scheduleDate);
    String formattedTime = DateFormat('h:mm a').format(scheduleDate);

    final double dialogWidth = MediaQuery.of(context).size.width * 0.7;
    final double dialogHeight = MediaQuery.of(context).size.height * 0.7;


     // ✅ Fetch departmentName before the dialog
  String deptID = appointmentData['deptID'] ?? '';
  String departmentName = 'Unknown Department';

  try {
    QuerySnapshot refSnapshot = await FirebaseFirestore.instance
        .collection('references')
        .where('deptID', isEqualTo: deptID)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    if (refSnapshot.docs.isNotEmpty) {
      var deptData = refSnapshot.docs.first.data() as Map<String, dynamic>;
      departmentName = deptData['name'] ?? 'Unknown Department';
    }
  } catch (e) {
    print("Error fetching department name: $e");
  }

    // QR code states - only used if status is "In Progress"
    bool isGeneratingQR = false;
    bool qrGenerated = false;
    String qrUrl = '';
    String firstName = '';
    String lastName = '';
    int expiryTime = 0;

    showDialog(
      context: context,
      barrierDismissible: true, // User can click outside to dismiss
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to generate QR code - only used if status is "In Progress"
            Future<void> generateQRCode(
                Map<String, dynamic> appointmentData) async {
              try {
                setState(() {
                  isGeneratingQR = true;
                });
                         // ✅ Fetch department name here inside the function
    String deptID = appointmentData['deptID'] ?? '';
                // Get current user details
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .where('uid', isEqualTo: user.uid)
                      .limit(1)
                      .get();

                  if (querySnapshot.docs.isNotEmpty) {
                    var userData =
                        querySnapshot.docs.first.data() as Map<String, dynamic>;
                    firstName = userData['first_name'] ?? "N/A";
                    lastName = userData['last_name'] ?? "N/A";
                  }
                } 


                int now = DateTime.now().millisecondsSinceEpoch;
                int formExpiryTime = now + (60 * 60 * 1000); // 60 minutes

                // Generate QR URL
                qrUrl = "http://192.168.1.78:8081//#/attendance_form"
                    "?agenda=${Uri.encodeComponent(appointmentData['agenda'] ?? '')}"
                  "&department=${Uri.encodeComponent(deptID)}"
                    "&createdBy=${Uri.encodeComponent(appointmentData['createdBy'] ?? '')}"
                    "&first_name=${Uri.encodeComponent(firstName)}"
                    "&last_name=${Uri.encodeComponent(lastName)}"
                    "&expiryTime=${formExpiryTime}";


                setState(() {
                  qrGenerated = true;
                  isGeneratingQR = false;
                });
              } catch (e) {
                print("Error generating QR: $e");
                setState(() {
                  isGeneratingQR = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error generating QR code: $e")),
                );
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                width: dialogWidth,
                height: dialogHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: statusColors[appointmentData['status']] ??
                            const Color.fromARGB(255, 11, 55, 99),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              'Appointment Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'SB',
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: Row(
                        children: [
                          // Left side: Appointment details
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailItem(Icons.title, 'Agenda',
                                      appointmentData['agenda'] ?? 'No Title'),
                                  SizedBox(height: 15),
                                  _buildDetailItem(Icons.calendar_today, 'Date',
                                      formattedDate),
                                  SizedBox(height: 15),
                                  _buildDetailItem(
                                      Icons.access_time, 'Time', formattedTime),
                                  SizedBox(height: 15),
                                  _buildDetailItem(
                                      Icons.business,
                                      'Department',
                                    departmentName),
                                  SizedBox(height: 15),
                                  _buildDetailItem(
                                      Icons.person,
                                      'Created By',
                                      appointmentData['createdBy'] ??
                                          'Unknown'),
                                  SizedBox(height: 15),
                                  _buildDetailItem(Icons.info_outline, 'Status',
                                      appointmentData['status'] ?? 'Scheduled',
                                      color: statusColors[
                                              appointmentData['status']] ??
                                          const Color.fromARGB(
                                              255, 11, 55, 99)),
                                  if (appointmentData['agendaDescript'] !=
                                          null &&
                                      appointmentData['agendaDescript']
                                          .toString()
                                          .isNotEmpty) ...[
                                    SizedBox(height: 20),
                                    Text(
                                      'Description:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'SB',
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        appointmentData['agendaDescript'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'R',
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Vertical divider
                          Container(
                            width: 1,
                            color: Colors.grey[300],
                            margin: EdgeInsets.symmetric(vertical: 20),
                          ),

                          // Right side: Conditional based on status
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: EdgeInsets.all(20),
                              child: status == 'In Progress'
                                  // QR Code generation section for 'In Progress' appointments
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Generate Attendance QR Code',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'SB',
                                            color: Colors.grey[800],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),

                                        // QR code display area
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: isGeneratingQR
                                                ? Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      CircularProgressIndicator(
                                                          color: Colors.amber),
                                                      SizedBox(height: 15),
                                                      Text(
                                                        'Generating QR Code...',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontFamily: 'M',
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : qrGenerated
                                                    ? Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          QrImageView(
                                                            data: qrUrl,
                                                            size: 200,
                                                            backgroundColor:
                                                                Colors.white,
                                                          ),
                                                          SizedBox(height: 10),
                                                          Text(
                                                            'Scan to fill the attendance form',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontFamily: 'M',
                                                              color: Colors
                                                                  .grey[700],
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.qr_code,
                                                            size: 120,
                                                            color: Colors
                                                                .grey[400],
                                                          ),
                                                          SizedBox(height: 15),
                                                          Text(
                                                            'No QR code generated yet',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontFamily: 'M',
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                          ),
                                        ),

                                        SizedBox(height: 20),

                                        // Generate button
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 30, vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: isGeneratingQR
                                              ? null
                                              : () => generateQRCode(
                                                  appointmentData),
                                          child: Text(
                                            qrGenerated
                                                ? 'Regenerate QR Code'
                                                : 'Generate QR Code',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'SB',
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  // Alternative view for non "In Progress" appointments
                                  : _buildAlternativeStatusView(
                                      status, formattedDate, formattedTime),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// New method to build alternative view for appointments that are not "In Progress"
  Widget _buildAlternativeStatusView(
      String status, String formattedDate, String formattedTime) {
    // Choose icon and message based on status
    IconData statusIcon;
    String statusMessage;
    String statusDescription;
    Color statusColor = statusColors[status] ?? Colors.grey;

    switch (status) {
      case 'Scheduled':
        statusIcon = Icons.event_available;
        statusMessage = 'Appointment Scheduled';
        statusDescription =
            'This appointment is scheduled for $formattedDate at $formattedTime but has not started yet.';
        break;
      case 'Completed':
        statusIcon = Icons.check_circle_outline;
        statusMessage = 'Appointment Completed';
        statusDescription = 'This appointment has been marked as completed.';
        break;
      case 'Cancelled':
        statusIcon = Icons.cancel_outlined;
        statusMessage = 'Appointment Cancelled';
        statusDescription =
            'This appointment has been cancelled and is no longer active.';
        break;
      default:
        statusIcon = Icons.info_outline;
        statusMessage = 'Appointment Status: $status';
        statusDescription =
            'This appointment is currently in this status and cannot generate attendance QR codes.';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Status icon
        Icon(
          statusIcon,
          size: 80,
          color: statusColor.withOpacity(0.7),
        ),
        SizedBox(height: 30),

        // Status message
        Text(
          statusMessage,
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'SB',
            color: statusColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),

        // Status description
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Text(
                statusDescription,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'R',
                  height: 1.5,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void debugFilteringProcess(
      List<QueryDocumentSnapshot> allAppointments, String? currentUserEmail) {
    print("DEBUG: All appointments count: ${allAppointments.length}");
    print("DEBUG: Current user email: $currentUserEmail");

    if (currentUserEmail == null) {
      print("DEBUG: User email is null, cannot filter");
      return;
    }

    int createdByUserCount = 0;
    int invitedUserCount = 0;

    for (var doc in allAppointments) {
      var data = doc.data() as Map<String, dynamic>;

      // Check if created by current user
      if (data['createdByEmail'] == currentUserEmail) {
        createdByUserCount++;
        print("DEBUG: Found appointment created by user: ${data['agenda']}");
      }

      // Check if user is in internal_users
      bool isInInternalUsers = false;
      List<dynamic> internalUsers = data['internal_users'] ?? [];
      for (var user in internalUsers) {
        if (user is Map && user['email'] == currentUserEmail) {
          isInInternalUsers = true;
          invitedUserCount++;
          print(
              "DEBUG: Found appointment with user in internal_users: ${data['agenda']}");
          break;
        }
      }

      // Print the internal_users for inspection
      if (!isInInternalUsers && internalUsers.isNotEmpty) {
        print(
            "DEBUG: ${data['agenda']} has internal_users but user not found:");
        for (var user in internalUsers) {
          if (user is Map) {
            print("  - ${user['email']}");
          }
        }
      }
    }

    print("DEBUG: Appointments created by user: $createdByUserCount");
    print("DEBUG: Appointments with user in internal_users: $invitedUserCount");
  }

  Future<Map<String, String>> fetchDepartmentNames() async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('references')
      .where('isDeleted', isEqualTo: false)
      .get();

  Map<String, String> deptMap = {};
  for (var doc in snapshot.docs) {
    var data = doc.data() as Map<String, dynamic>;
    if (data.containsKey('deptID') && data.containsKey('name')) {
      deptMap[data['deptID']] = data['name'];
    }
  }
  return deptMap;
}

  // Modified filter method to check for user invitation
  // Modified filter method to check for user invitation or creation
  List<QueryDocumentSnapshot> getFilteredAppointments(
      List<QueryDocumentSnapshot> 
      allAppointments, 
      String? currentUserEmail,     
      Map<String, String> departmentMap // Add the departmentMap here
) {
    // Debug the filtering process
    debugFilteringProcess(allAppointments, currentUserEmail);

    if (currentUserEmail == null) {
      print("No user email available, returning empty list");
      return [];
    }

    // First filter by search query
    List<QueryDocumentSnapshot> searchFiltered;
    if (searchQuery.isEmpty) {
      searchFiltered = allAppointments;
    } else {
      searchFiltered = allAppointments.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        String agenda = (data['agenda'] ?? '').toString().toLowerCase();
        String deptID = (data['deptID'] ?? '').toString();
        String deptName = departmentMap[deptID]?.toLowerCase() ?? ''; // Get department name from departmentMap
        String createdBy = (data['createdBy'] ?? '').toString().toLowerCase();

        return agenda.contains(searchQuery.toLowerCase()) ||
            deptName.contains(searchQuery.toLowerCase()) ||
            createdBy.contains(searchQuery.toLowerCase());
      }).toList();

      print(
          "DEBUG: After search filter, found ${searchFiltered.length} appointments");
    }

    // Then filter by user invitation status or creation
    List<QueryDocumentSnapshot> userFiltered = searchFiltered.where((doc) {
      var data = doc.data() as Map<String, dynamic>;

      // Case insensitive comparison for email
      String createdByEmail =
          (data['createdByEmail'] ?? '').toString().toLowerCase();
      String userEmail = currentUserEmail.toLowerCase();

      // Check if the current user created the appointment
      if (createdByEmail == userEmail) {
        print(
            "DEBUG: Including appointment created by user: ${data['agenda']}");
        return true;
      }

      // Check if the current user is in internal_users array
      List<dynamic> internalUsers = data['internal_users'] ?? [];
      for (var user in internalUsers) {
        if (user is Map) {
          String internalUserEmail =
              (user['email'] ?? '').toString().toLowerCase();
          if (internalUserEmail == userEmail) {
            print(
                "DEBUG: Including appointment with user in internal_users: ${data['agenda']}");
            return true;
          }
        }
      }

      return false;
    }).toList();

    print("DEBUG: Final filtered appointments count: ${userFiltered.length}");
    return userFiltered;
  }

// Separate current and history appointments based on status
  Map<String, List<QueryDocumentSnapshot>> separateAppointments(
      List<QueryDocumentSnapshot> filteredAppointments) {
    List<QueryDocumentSnapshot> currentAppointments = [];
    List<QueryDocumentSnapshot> historyAppointments = [];

    for (var doc in filteredAppointments) {
      var data = doc.data() as Map<String, dynamic>;
      String status = (data['status'] ?? '').toString();

      // Current: Scheduled and In Progress
      // History: Completed and Cancelled
      if (status == 'Completed' || status == 'Cancelled') {
        historyAppointments.add(doc);
      } else {
        currentAppointments.add(doc);
      }
    }

    // Sort appointments by schedule
    currentAppointments.sort((a, b) {
      DateTime dateA =
          DateTime.parse((a.data() as Map<String, dynamic>)['schedule']);
      DateTime dateB =
          DateTime.parse((b.data() as Map<String, dynamic>)['schedule']);
      return isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    historyAppointments.sort((a, b) {
      DateTime dateA =
          DateTime.parse((a.data() as Map<String, dynamic>)['schedule']);
      DateTime dateB =
          DateTime.parse((b.data() as Map<String, dynamic>)['schedule']);
      return isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return {
      'current': currentAppointments,
      'history': historyAppointments,
    };
  }

  // Calculate pagination values without setState
  Map<String, int> calculatePagination(
      List<QueryDocumentSnapshot> appointments, String type) {
    int totalPages = (appointments.length / itemsPerPage).ceil();
    totalPages = totalPages == 0 ? 1 : totalPages;

    int currentPage =
        type == 'current' ? currentPageActive : currentPageHistory;
    if (currentPage > totalPages) {
      currentPage = totalPages;
    }

    return {
      'totalPages': totalPages,
      'currentPage': currentPage,
    };
  }

  // Get items for the current page
  List<QueryDocumentSnapshot> getCurrentPageItems(
      List<QueryDocumentSnapshot> appointments, int currentPage) {
    int totalPages = (appointments.length / itemsPerPage).ceil();
    totalPages = totalPages == 0 ? 1 : totalPages;

    if (currentPage > totalPages) {
      currentPage = totalPages;
    }

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (endIndex > appointments.length) {
      endIndex = appointments.length;
    }

    if (startIndex >= appointments.length) {
      return [];
    }

    return appointments.sublist(startIndex, endIndex);
  }

  // Update items per page
  void updateItemsPerPage() {
    int? newValue = int.tryParse(itemsPerPageController.text);
    if (newValue != null && newValue > 0) {
      setState(() {
        itemsPerPage = newValue;
        currentPageActive = 1;
        currentPageHistory = 1;
      });
    } else {
      itemsPerPageController.text = itemsPerPage.toString();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid number greater than 0')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(width * 0.02),
          child: Column(
            children: [
              // Top controls bar with search, sort, and pagination controls
              _buildControlsBar(width, height),
              SizedBox(height: height * 0.02),

              // Appointments lists - current and history side by side
              Expanded(
                child: FutureBuilder<String?>(
                  future: _getCurrentUserEmail(),
                  builder: (context, userEmailSnapshot) {
                    if (userEmailSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final currentUserEmail = userEmailSnapshot.data;
                    print(
                        "DEBUG: Current user email from FutureBuilder: $currentUserEmail");

                    if (currentUserEmail == null) {
                      return Center(
                          child: Text('Error: Cannot retrieve user email'));
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('appointment').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          print(
                              "DEBUG: StreamBuilder error: ${snapshot.error}");
                          return Center(
                            child: Text(
                              'Error loading appointments: ${snapshot.error}',
                              style: TextStyle(fontSize: width / 120),
                            ),
                          );
                        }

                        final allAppointments = snapshot.data?.docs ?? [];
                        print(
                            "DEBUG: Total appointments from Firestore: ${allAppointments.length}");

                        // Debug some sample data if available
                        if (allAppointments.isNotEmpty) {
                          var sampleData =
                              allAppointments[0].data() as Map<String, dynamic>;
                          print("DEBUG: Sample appointment data:");
                          print("  - Agenda: ${sampleData['agenda']}");
                          print("  - CreatedBy: ${sampleData['createdBy']}");
                          print(
                              "  - CreatedByEmail: ${sampleData['createdByEmail']}");
                          print("  - Status: ${sampleData['status']}");
                        }

                        final filteredAppointments = getFilteredAppointments(
                            allAppointments, currentUserEmail, departmentMap);
                        final separatedAppointments =
                            separateAppointments(filteredAppointments);

                        final currentAppointments =
                            separatedAppointments['current'] ?? [];
                        final historyAppointments =
                            separatedAppointments['history'] ?? [];

                        print(
                            "DEBUG: Current appointments count: ${currentAppointments.length}");
                        print(
                            "DEBUG: History appointments count: ${historyAppointments.length}");

                        // Calculate pagination without setState
                        final activePagination =
                            calculatePagination(currentAppointments, 'current');
                        final historyPagination =
                            calculatePagination(historyAppointments, 'history');

                        final effectiveCurrentPageActive =
                            activePagination['currentPage'] ??
                                currentPageActive;
                        final effectiveCurrentPageHistory =
                            historyPagination['currentPage'] ??
                                currentPageHistory;
                        final effectiveTotalPagesActive =
                            activePagination['totalPages'] ?? 1;
                        final effectiveTotalPagesHistory =
                            historyPagination['totalPages'] ?? 1;

                        final currentPageItemsActive = getCurrentPageItems(
                            currentAppointments, effectiveCurrentPageActive);
                        final currentPageItemsHistory = getCurrentPageItems(
                            historyAppointments, effectiveCurrentPageHistory);

                        print(
                            "DEBUG: Current page items (active): ${currentPageItemsActive.length}");
                        print(
                            "DEBUG: Current page items (history): ${currentPageItemsHistory.length}");

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current Appointments Section
                            Expanded(
                              child: Container(
                                color: Colors.blueGrey[100],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: height * 0.01,
                                          horizontal: width * 0.01),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 11, 55, 99),
                                        borderRadius: BorderRadius.only(
                                          topLeft:
                                              Radius.circular(width * 0.01),
                                          topRight:
                                              Radius.circular(width * 0.01),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Current Appointments (${currentAppointments.length})',
                                            style: TextStyle(
                                              fontSize: width / 80,
                                              fontFamily: 'SB',
                                              color: Colors.white,
                                            ),
                                          ),
                                          _buildPaginationControls(
                                              effectiveCurrentPageActive,
                                              effectiveTotalPagesActive,
                                              (page) => setState(() =>
                                                  currentPageActive = page),
                                              width,
                                              true),
                                        ],
                                      ),
                                    ),

                                    // List
                                    Expanded(
                                      child: currentAppointments.isEmpty
                                          ? _buildEmptyState(
                                              'No current appointments', width)
                                          : ListView.builder(
                                              itemCount:
                                                  currentPageItemsActive.length,
                                              itemBuilder: (context, index) {
                                                final appointmentData =
                                                    currentPageItemsActive[
                                                                index]
                                                            .data()
                                                        as Map<String, dynamic>;
                                                print(
                                                    "DEBUG: Building active appointment: ${appointmentData['agenda']}");
                                                return _buildAppointmentCard(
                                                  appointmentData,
                                                  currentPageItemsActive[index]
                                                      .id,
                                                  width,
                                                  height,
                                                  false,
                                                    departmentMap, // 👈 add this

                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: width * 0.02),

                            // History Appointments Section
                            Expanded(
                              child: Container(
                                color: Colors.grey[300],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: height * 0.01,
                                          horizontal: width * 0.01),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[600],
                                        borderRadius: BorderRadius.only(
                                          topLeft:
                                              Radius.circular(width * 0.01),
                                          topRight:
                                              Radius.circular(width * 0.01),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Appointment History (${historyAppointments.length})',
                                            style: TextStyle(
                                              fontSize: width / 80,
                                              fontFamily: 'SB',
                                              color: Colors.white,
                                            ),
                                          ),
                                          _buildPaginationControls(
                                              effectiveCurrentPageHistory,
                                              effectiveTotalPagesHistory,
                                              (page) => setState(() =>
                                                  currentPageHistory = page),
                                              width,
                                              true),
                                        ],
                                      ),
                                    ),

                                    // List
                                    Expanded(
                                      child: historyAppointments.isEmpty
                                          ? _buildEmptyState(
                                              'No appointment history', width)
                                          : ListView.builder(
                                              itemCount: currentPageItemsHistory
                                                  .length,
                                              itemBuilder: (context, index) {
                                                final appointmentData =
                                                    currentPageItemsHistory[
                                                                index]
                                                            .data()
                                                        as Map<String, dynamic>;
                                                print(
                                                    "DEBUG: Building history appointment: ${appointmentData['agenda']}");
                                                return _buildAppointmentCard(
                                                  appointmentData,
                                                  currentPageItemsHistory[index]
                                                      .id,
                                                  width,
                                                  height,
                                                  true,
                                                    departmentMap, // 👈 add this

                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsBar(double width, double height) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.015, vertical: height * 0.01),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width / 160),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            flex: 3,
            child: Container(
              height: width / 30,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(width / 160),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintStyle: TextStyle(
                      fontSize: width / 120,
                      color: Colors.grey,
                      fontFamily: "R"),
                  hintText: 'Search appointments...',
                  prefixIcon: Icon(
                    Icons.search,
                    size: width / 70,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: width / 80, vertical: width / 120),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    currentPageActive = 1;
                    currentPageHistory = 1;
                  });
                },
              ),
            ),
          ),

          SizedBox(width: width * 0.01),

          // Sort control
          Container(
            height: width / 30,
            padding: EdgeInsets.symmetric(horizontal: width * 0.01),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(width / 160),
            ),
            child: Row(
              children: [
                Text(
                  'Sort: ',
                  style: TextStyle(
                    fontSize: width / 120,
                    color: Colors.grey[700],
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      isAscending = !isAscending;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        isAscending ? 'Earliest' : 'Latest',
                        style: TextStyle(
                          fontSize: width / 120,
                          fontFamily: 'SB',
                          color: Colors.blue[700],
                        ),
                      ),
                      Icon(
                        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: width / 100,
                        color: Colors.blue[700],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: width * 0.01),

          // Items per page control
          Container(
            height: width / 30,
            padding: EdgeInsets.symmetric(horizontal: width * 0.01),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(width / 160),
            ),
            child: Row(
              children: [
                Text(
                  'Show: ',
                  style: TextStyle(
                    fontSize: width / 120,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  width: width / 25,
                  child: TextField(
                    controller: itemsPerPageController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(width / 200),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: width / 120),
                  ),
                ),
                SizedBox(width: width * 0.005),
                InkWell(
                  onTap: updateItemsPerPage,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.008, vertical: width * 0.004),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2184D6),
                      borderRadius: BorderRadius.circular(width / 160),
                    ),
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: width / 150,
                        fontFamily: "SB",
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalPages,
      Function(int) onPageChange, double width, bool isCompact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: isCompact ? width / 100 : null,
          ),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: isCompact ? width / 80 : width / 40,
            minHeight: isCompact ? width / 80 : width / 40,
          ),
          onPressed:
              currentPage > 1 ? () => onPageChange(currentPage - 1) : null,
          color: currentPage > 1 ? Colors.white : Colors.white38,
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.008,
            vertical: width * 0.004,
          ),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(width / 200),
          ),
          child: Text(
            '$currentPage of $totalPages',
            style: TextStyle(
              fontSize: isCompact ? width / 150 : width / 120,
              fontFamily: 'M',
              color: Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: isCompact ? width / 100 : null,
          ),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: isCompact ? width / 80 : width / 40,
            minHeight: isCompact ? width / 80 : width / 40,
          ),
          onPressed: currentPage < totalPages
              ? () => onPageChange(currentPage + 1)
              : null,
          color: currentPage < totalPages ? Colors.white : Colors.white38,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, double width) {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: width / 20,
              color: Colors.grey[400],
            ),
            SizedBox(height: width * 0.01),
            Text(
              message,
              style: TextStyle(
                fontSize: width / 100,
                color: Colors.grey[600],
                fontFamily: 'M',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointmentData,
    String docId,
    double width,
    double height,
    bool isHistory,
      Map<String, String> departmentMap, // new param

  ) {
    // Parse schedule string to DateTime
    DateTime scheduleDate = DateTime.parse(appointmentData['schedule']);
    String formattedDate = DateFormat('MMM dd, yyyy').format(scheduleDate);
    String formattedTime = DateFormat('h:mm a').format(scheduleDate);

    // Title and body text sizes
    final double titleSize = width / 80;
    final double bodySize = width / 120;
    final double smallSize = width / 140;
    final double statusSize = width / 100;

    return InkWell(
      onTap: () => _showAppointmentDetails(appointmentData, docId),
      borderRadius: BorderRadius.circular(width * 0.01),
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: height * 0.01,
          horizontal: width * 0.005,
        ),
        decoration: BoxDecoration(
          color: isHistory ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(width * 0.01),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isHistory ? 0.1 : 0.2),
              spreadRadius: isHistory ? 0 : 1,
              blurRadius: isHistory ? 3 : 5,
            ),
          ],
          border:
              isHistory ? Border.all(color: Colors.grey[300]!, width: 1) : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(width / 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointmentData['agenda'] ?? 'No Title',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontFamily: 'SB', // Semi-bold font
                      color: isHistory
                          ? Colors.grey[700]
                          : const Color.fromARGB(255, 11, 55, 99),
                    ),
                  ),
                  SizedBox(height: height * 0.01),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: bodySize * 1.2,
                          color:
                              isHistory ? Colors.grey[500] : Colors.grey[600]),
                      SizedBox(width: width * 0.005),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: bodySize,
                          fontFamily: 'R', // Regular font
                          color:
                              isHistory ? Colors.grey[600] : Colors.grey[700],
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Icon(Icons.access_time,
                          size: bodySize * 1.2,
                          color:
                              isHistory ? Colors.grey[500] : Colors.grey[600]),
                      SizedBox(width: width * 0.005),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: bodySize,
                          fontFamily: 'R', // Regular font
                          color:
                              isHistory ? Colors.grey[600] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.01),
                  Row(
                    children: [
                      Icon(Icons.business,
                          size: bodySize * 1.2,
                          color:
                              isHistory ? Colors.grey[500] : Colors.grey[600]),
                      SizedBox(width: width * 0.005),
                      Text(
                       departmentMap[appointmentData['deptID']] ?? 'No Department',
                        style: TextStyle(
                          fontSize: bodySize,
                          fontFamily: 'M', // Medium font
                          color:
                              isHistory ? Colors.grey[600] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.01),
                  Row(
                    children: [
                      Icon(Icons.person,
                          size: bodySize * 1.2,
                          color:
                              isHistory ? Colors.grey[500] : Colors.grey[600]),
                      SizedBox(width: width * 0.005),
                      Text(
                        'Created by: ${appointmentData['createdBy'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: bodySize,
                          fontFamily: 'R', // Regular font
                          color:
                              isHistory ? Colors.grey[600] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  if (appointmentData['agendaDescript'] != null &&
                      appointmentData['agendaDescript'].toString().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: height * 0.01),
                      child: Text(
                        appointmentData['agendaDescript'],
                        style: TextStyle(
                          fontSize: smallSize,
                          fontFamily: 'R', // Regular font
                          color:
                              isHistory ? Colors.grey[500] : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Status indicator at top right
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.015,
                  vertical: height * 0.005,
                ),
                decoration: BoxDecoration(
                  color: statusColors[appointmentData['status']] ??
                      (isHistory
                          ? Colors.grey[600]
                          : const Color.fromARGB(255, 11, 55, 99)),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(width * 0.01),
                    bottomLeft: Radius.circular(width * 0.01),
                  ),
                  boxShadow: isHistory
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                ),
                child: Text(
                  appointmentData['status'] ?? 'Scheduled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: statusSize,
                    fontFamily: 'SB', // Semi-bold font
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build detail item rows
  Widget _buildDetailItem(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.grey[600]),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'R',
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SB',
                  color: color ?? Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
