import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentManager extends StatefulWidget {
  const AppointmentManager({Key? key}) : super(key: key);

  @override
  _AppointmentManagerState createState() => _AppointmentManagerState();
}

class _AppointmentManagerState extends State<AppointmentManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  }

  @override
  void dispose() {
    searchController.dispose();
    itemsPerPageController.dispose();
    super.dispose();
  }

  // Filter appointments based on search query
  List<QueryDocumentSnapshot> getFilteredAppointments(
      List<QueryDocumentSnapshot> allAppointments) {
    if (searchQuery.isEmpty) {
      return allAppointments;
    }

    return allAppointments.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String agenda = (data['agenda'] ?? '').toString().toLowerCase();
      String department = (data['department'] ?? '').toString().toLowerCase();
      String createdBy = (data['createdBy'] ?? '').toString().toLowerCase();

      return agenda.contains(searchQuery.toLowerCase()) ||
          department.contains(searchQuery.toLowerCase()) ||
          createdBy.contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Separate current and history appointments
  Map<String, List<QueryDocumentSnapshot>> separateAppointments(
      List<QueryDocumentSnapshot> filteredAppointments) {
    List<QueryDocumentSnapshot> currentAppointments = [];
    List<QueryDocumentSnapshot> historyAppointments = [];

    for (var doc in filteredAppointments) {
      var data = doc.data() as Map<String, dynamic>;
      String status = (data['status'] ?? '').toString();

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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('appointment').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading appointments',
                          style: TextStyle(fontSize: width / 120),
                        ),
                      );
                    }

                    final allAppointments = snapshot.data?.docs ?? [];
                    final filteredAppointments =
                        getFilteredAppointments(allAppointments);
                    final separatedAppointments =
                        separateAppointments(filteredAppointments);

                    final currentAppointments =
                        separatedAppointments['current'] ?? [];
                    final historyAppointments =
                        separatedAppointments['history'] ?? [];

                    // Calculate pagination without setState
                    final activePagination =
                        calculatePagination(currentAppointments, 'current');
                    final historyPagination =
                        calculatePagination(historyAppointments, 'history');

                    // Use local variables instead of updating state
                    final effectiveCurrentPageActive =
                        activePagination['currentPage'] ?? currentPageActive;
                    final effectiveCurrentPageHistory =
                        historyPagination['currentPage'] ?? currentPageHistory;
                    final effectiveTotalPagesActive =
                        activePagination['totalPages'] ?? 1;
                    final effectiveTotalPagesHistory =
                        historyPagination['totalPages'] ?? 1;

                    final currentPageItemsActive = getCurrentPageItems(
                        currentAppointments, effectiveCurrentPageActive);
                    final currentPageItemsHistory = getCurrentPageItems(
                        historyAppointments, effectiveCurrentPageHistory);

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
                                    color:
                                        const Color.fromARGB(255, 11, 55, 99),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(width * 0.01),
                                      topRight: Radius.circular(width * 0.01),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Current Appointments',
                                        style: TextStyle(
                                          fontSize: width / 80,
                                          fontFamily: 'SB',
                                          color: Colors.white,
                                        ),
                                      ),
                                      _buildPaginationControls(
                                          effectiveCurrentPageActive,
                                          effectiveTotalPagesActive,
                                          (page) => setState(
                                              () => currentPageActive = page),
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
                                                currentPageItemsActive[index]
                                                        .data()
                                                    as Map<String, dynamic>;
                                            return _buildAppointmentCard(
                                              appointmentData,
                                              currentPageItemsActive[index].id,
                                              width,
                                              height,
                                              false,
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
                                      topLeft: Radius.circular(width * 0.01),
                                      topRight: Radius.circular(width * 0.01),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Appointment History',
                                        style: TextStyle(
                                          fontSize: width / 80,
                                          fontFamily: 'SB',
                                          color: Colors.white,
                                        ),
                                      ),
                                      _buildPaginationControls(
                                          effectiveCurrentPageHistory,
                                          effectiveTotalPagesHistory,
                                          (page) => setState(
                                              () => currentPageHistory = page),
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
                                          itemCount:
                                              currentPageItemsHistory.length,
                                          itemBuilder: (context, index) {
                                            final appointmentData =
                                                currentPageItemsHistory[index]
                                                        .data()
                                                    as Map<String, dynamic>;
                                            return _buildAppointmentCard(
                                              appointmentData,
                                              currentPageItemsHistory[index].id,
                                              width,
                                              height,
                                              true,
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
                ),
              ),
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

    return Container(
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
                        color: isHistory ? Colors.grey[500] : Colors.grey[600]),
                    SizedBox(width: width * 0.005),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: bodySize,
                        fontFamily: 'R', // Regular font
                        color: isHistory ? Colors.grey[600] : Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Icon(Icons.access_time,
                        size: bodySize * 1.2,
                        color: isHistory ? Colors.grey[500] : Colors.grey[600]),
                    SizedBox(width: width * 0.005),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: bodySize,
                        fontFamily: 'R', // Regular font
                        color: isHistory ? Colors.grey[600] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),
                Row(
                  children: [
                    Icon(Icons.business,
                        size: bodySize * 1.2,
                        color: isHistory ? Colors.grey[500] : Colors.grey[600]),
                    SizedBox(width: width * 0.005),
                    Text(
                      appointmentData['department'] ?? 'No Department',
                      style: TextStyle(
                        fontSize: bodySize,
                        fontFamily: 'M', // Medium font
                        color: isHistory ? Colors.grey[600] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),
                Row(
                  children: [
                    Icon(Icons.person,
                        size: bodySize * 1.2,
                        color: isHistory ? Colors.grey[500] : Colors.grey[600]),
                    SizedBox(width: width * 0.005),
                    Text(
                      'Created by: ${appointmentData['createdBy'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: bodySize,
                        fontFamily: 'R', // Regular font
                        color: isHistory ? Colors.grey[600] : Colors.grey[700],
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
                        color: isHistory ? Colors.grey[500] : Colors.grey[600],
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
    );
  }
}
