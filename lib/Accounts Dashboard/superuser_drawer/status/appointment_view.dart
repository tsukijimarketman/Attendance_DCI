import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/status/tabs/tabs.dart';
import 'package:attendance_app/Animation/loader.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentView extends StatefulWidget {
  final String statusType; // This will hold the selected status type

  const AppointmentView({super.key, required this.statusType});

  @override
  State<AppointmentView> createState() => _AppointmentViewState();
}

class _AppointmentViewState extends State<AppointmentView> {
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  // Add selectedAgenda state variable
  String selectedAgenda = '';

  // Add boolean to track if an appointment is selected
  bool isAppointmentSelected = false;

  // Pagination variables
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;

  // Search functionality
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  TextEditingController itemsPerPageController = TextEditingController();

  // Store all appointments to manage pagination locally
  List<QueryDocumentSnapshot> allUniqueAppointments = [];

  // Status-specific colors and icons
  late Color statusColor;
  late IconData statusIcon;
  late String statusTitle;

  @override
  void initState() {
    super.initState();
    fetchUserDepartment();
    itemsPerPageController.text = itemsPerPage.toString();

    // Set status-specific properties
    setStatusProperties();
  }

  void setStatusProperties() {
    switch (widget.statusType) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusTitle = "Completed Appointments";
        break;
      case 'Scheduled':
        statusColor = Color(0xFF082649);
        statusIcon = Icons.schedule_rounded;
        statusTitle = "Scheduled Appointments";
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        statusTitle = "In Progress Appointments";
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusTitle = "Cancelled Appointments";
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.calendar_today;
        statusTitle = "All Appointments";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    itemsPerPageController.dispose();
    super.dispose();
  }

  String formatDate(String timestamp) {
    try {
      DateTime parsedDate = DateTime.parse(timestamp);
      return DateFormat("MMMM d yyyy 'at' h:mm a").format(parsedDate);
    } catch (e) {
      print("Error formatting date: $e");
      return "Invalid date";
    }
  }

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
            first_name = userData['first_name'] ?? "";
            last_name = userData['last_name'] ?? "";
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  // Filter appointments based on search query
  List<QueryDocumentSnapshot> getFilteredAppointments() {
    if (searchQuery.isEmpty) {
      return allUniqueAppointments;
    }

    return allUniqueAppointments.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String agenda = (data['agenda'] ?? '').toString().toLowerCase();
      return agenda.contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Get current page items
  List<QueryDocumentSnapshot> getCurrentPageItems() {
    List<QueryDocumentSnapshot> filteredAppointments =
        getFilteredAppointments();
    totalPages = (filteredAppointments.length / itemsPerPage).ceil();

    if (totalPages == 0) {
      totalPages = 1;
    }

    // Ensure current page is within bounds
    if (currentPage > totalPages) {
      currentPage = totalPages;
    }

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (endIndex > filteredAppointments.length) {
      endIndex = filteredAppointments.length;
    }

    if (startIndex >= filteredAppointments.length) {
      return [];
    }

    return filteredAppointments.sublist(startIndex, endIndex);
  }

  void updateItemsPerPage() {
    int? newValue = int.tryParse(itemsPerPageController.text);
    if (newValue != null && newValue > 0) {
      setState(() {
        itemsPerPage = newValue;
        currentPage = 1; // Reset to first page when changing items per page
      });
    } else {
      // Reset to default if invalid input
      itemsPerPageController.text = itemsPerPage.toString();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid number greater than 0')));
    }
  }

  // Toggle selection for an appointment
  void toggleAppointmentSelection(String agenda) {
    setState(() {
      // If the currently selected agenda is tapped again, deselect it
      if (selectedAgenda == agenda) {
        selectedAgenda = '';
        isAppointmentSelected = false;
      } else {
        // Otherwise, select the new agenda
        selectedAgenda = agenda;
        isAppointmentSelected = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String fullName = "$first_name $last_name".trim(); // Generate fullName
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          statusTitle,
          style: TextStyle(fontSize: screenWidth / 80),
        ),
      ),
      body: Container(
        height: screenHeight,
        width: screenWidth,
        color: Color(0xFFf2edf3),
        child: Padding(
          padding: EdgeInsets.all(screenWidth / 80),
          child: isLoading
              ? Center(child: CustomLoader())
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      // Adjust width based on whether an appointment is selected
                      width: isAppointmentSelected
                          ? screenWidth / 3.5
                          : screenWidth / 3.5,
                      height: screenHeight / 1.155,
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            width: screenWidth / 3.5,
                            height: screenWidth / 20,
                            color: Color(0xFF0E2643),
                            child: Center(
                              child: Text(
                                "List of ${widget.statusType} Appointments",
                                style: TextStyle(
                                  fontSize: screenWidth / 100,
                                  fontFamily: "B",
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: screenWidth / 80,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth / 70),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: screenWidth / 6.6,
                                  height: screenWidth / 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        screenWidth / 160),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: searchController,
                                    decoration: InputDecoration(
                                      hintStyle: TextStyle(
                                          fontSize: screenWidth / 120,
                                          color: Colors.grey,
                                          fontFamily: "R"),
                                      hintText: 'Search by agenda...',
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: screenWidth / 70,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: screenWidth / 80,
                                          vertical: screenWidth / 120),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        searchQuery = value;
                                        currentPage =
                                            1; // Reset to first page when searching
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: screenWidth / 100,
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: screenWidth / 25,
                                      height: screenWidth / 30,
                                      child: TextField(
                                        controller: itemsPerPageController,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 0),
                                        ),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: screenWidth / 120),
                                        onSubmitted: (value) =>
                                            updateItemsPerPage(),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth / 100),
                                    GestureDetector(
                                      onTap: updateItemsPerPage,
                                      child: Container(
                                        width: screenWidth / 23,
                                        height: screenWidth / 30,
                                        decoration: BoxDecoration(
                                            color: Color(0xFF2184D6),
                                            borderRadius: BorderRadius.circular(
                                                screenWidth / 160)),
                                        child: Center(
                                          child: Text(
                                            'Apply',
                                            style: TextStyle(
                                              fontSize: screenWidth / 150,
                                              fontFamily: "SB",
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ).showCursorOnHover,
                                  ],
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: screenWidth / 80),

                          // Appointments List
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth / 90),
                            child: Container(
                              width: screenWidth / 3.8,
                              height: screenHeight / 1.56,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('appointment')
                                    .where('status',
                                        isEqualTo: widget.statusType)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(child: CustomLoader());
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return Center(
                                        child: Text(
                                            "No ${widget.statusType.toLowerCase()} appointments"));
                                  }

                                  var appointmentDocs = snapshot.data!.docs;
                                  Set<String> uniqueAgendas = {};
                                  allUniqueAppointments = [];

                                  for (var doc in appointmentDocs) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;
                                    String agenda = data['agenda'] ?? 'N/A';

                                    if (!uniqueAgendas.contains(agenda)) {
                                      uniqueAgendas.add(agenda);
                                      allUniqueAppointments.add(doc);
                                    }
                                  }

                                  var currentItems = getCurrentPageItems();

                                  if (currentItems.isEmpty &&
                                      searchQuery.isNotEmpty) {
                                    return Center(
                                        child: Text(
                                            "No appointments match your search"));
                                  } else if (currentItems.isEmpty) {
                                    return Center(
                                        child: Text(
                                            "No appointments on this page"));
                                  }

                                  return Column(
                                    children: [
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: currentItems.length,
                                          itemBuilder: (context, index) {
                                            var data = currentItems[index]
                                                .data() as Map<String, dynamic>;
                                            String agenda =
                                                data['agenda'] ?? 'N/A';
                                            String schedule =
                                                formatDate(data['schedule']);

                                            bool isSelected =
                                                selectedAgenda == agenda;

                                            return Container(
                                              color: Colors.white,
                                              height: screenWidth / 18,
                                              child: Card(
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          screenWidth / 160),
                                                ),
                                                color: isSelected
                                                    ? statusColor.withOpacity(
                                                        0.2) // Highlight selected item with status color
                                                    : Colors.white,
                                                child: InkWell(
                                                  // Proper InkWell implementation
                                                  onTap: () {
                                                    toggleAppointmentSelection(
                                                        agenda);
                                                  },
                                                  hoverColor: statusColor
                                                      .withOpacity(0.1),
                                                  splashColor: statusColor
                                                      .withOpacity(0.3),
                                                  highlightColor: statusColor
                                                      .withOpacity(0.2),
                                                  child: ListTile(
                                                    title: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            agenda,
                                                            style: TextStyle(
                                                                fontSize:
                                                                    screenWidth /
                                                                        90,
                                                                fontFamily:
                                                                    "B"),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    subtitle: Text(
                                                      "Scheduled: $schedule",
                                                      style: TextStyle(
                                                          fontSize:
                                                              screenWidth / 110,
                                                          fontFamily: "R"),
                                                    ),
                                                    leading: Icon(
                                                      statusIcon,
                                                      color: statusColor,
                                                      size: screenWidth / 40,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      // Pagination controls
                                      Container(
                                        width: screenWidth / 4,
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenWidth / 100),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              screenWidth / 160),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Previous page button
                                            IconButton(
                                              icon: Icon(Icons.chevron_left),
                                              onPressed: currentPage > 1
                                                  ? () => setState(
                                                      () => currentPage--)
                                                  : null,
                                              iconSize: screenWidth / 50,
                                              color: currentPage > 1
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),

                                            // Page numbers
                                            SizedBox(
                                              height: screenWidth / 25,
                                              width: screenWidth / 5.5,
                                              child: Center(
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: List.generate(
                                                      totalPages,
                                                      (index) {
                                                        int pageNumber =
                                                            index + 1;
                                                        bool isCurrentPage =
                                                            pageNumber ==
                                                                currentPage;

                                                        return Container(
                                                          margin: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      4),
                                                          child: InkWell(
                                                            onTap: () => setState(
                                                                () => currentPage =
                                                                    pageNumber),
                                                            child: Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                horizontal:
                                                                    screenWidth /
                                                                        100,
                                                                vertical:
                                                                    screenWidth /
                                                                        200,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: isCurrentPage
                                                                    ? Colors
                                                                        .blue
                                                                    : Colors
                                                                        .white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                                border:
                                                                    Border.all(
                                                                  color: isCurrentPage
                                                                      ? Colors
                                                                          .blue
                                                                      : Colors
                                                                          .grey
                                                                          .shade300,
                                                                ),
                                                              ),
                                                              child: Text(
                                                                '$pageNumber',
                                                                style:
                                                                    TextStyle(
                                                                  color: isCurrentPage
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontWeight: isCurrentPage
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal,
                                                                  fontSize:
                                                                      screenWidth /
                                                                          120,
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
                                                  currentPage < totalPages
                                                      ? () => setState(
                                                          () => currentPage++)
                                                      : null,
                                              iconSize: screenWidth / 50,
                                              color: currentPage < totalPages
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Page info text
                                      Padding(
                                        padding: EdgeInsets.only(
                                            top: screenWidth / 160),
                                        child: Text(
                                          'Page $currentPage of $totalPages (${getFilteredAppointments().length} total items)',
                                          style: TextStyle(
                                            fontSize: screenWidth / 120,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    isAppointmentSelected == false
                        ? Container(
                            width: screenWidth / 1.5,
                            height: screenHeight / 2,
                            color: Colors.transparent,
                            child: Center(
                              child: Text(
                                "Select an Appointment to view details",
                                style: TextStyle(
                                  fontSize: screenWidth / 60,
                                  fontFamily: "B",
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                        : Visibility(
                            visible: isAppointmentSelected,
                            child: Container(
                              color: Colors.transparent,
                              width: screenWidth / 1.5,
                              height: screenHeight,
                              child: MeetingTabs(
                                selectedAgenda: selectedAgenda,
                                statusType: widget.statusType,
                              ),
                            ),
                          )
                  ],
                ),
        ),
      ),
    );
  }
}
