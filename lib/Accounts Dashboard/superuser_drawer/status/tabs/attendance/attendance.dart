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
  List<Map<String, dynamic>> attendanceList = []; // People who actually attended
  List<Map<String, dynamic>> invitedGuests = []; // External guests invited
  List<Map<String, dynamic>> invitedUsers = []; // Internal users invited
  List<Map<String, dynamic>> consolidatedAttendees = []; // Combined list with present/absent status
  
  // Pagination variables
  int currentPage = 1;
  int itemsPerPage = 4; // Default to 4 items per page
  int totalPages = 1;

  // Search functionality
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  TextEditingController itemsPerPageController = TextEditingController();
  
  // Filtered attendees for search and pagination
  List<Map<String, dynamic>> filteredAttendees = [];
  
  @override
  void initState() {
    super.initState();
    itemsPerPageController.text = itemsPerPage.toString();
    fetchUserDepartment().then((_) {
      fetchAppointmentData();
      fetchAttendanceData();
    });
  }
  
  @override
  void dispose() {
    searchController.dispose();
    itemsPerPageController.dispose();
    super.dispose();
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
          var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;

          setState(() {
            userDepartment = userData['department'] ?? "";
            fullName = "${userData['first_name']} ${userData['last_name']}";
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

        // Fetch internal users array from Firestore
        if (data.containsKey('internal_users') && data['internal_users'] is List) {
          invitedUsers = List<Map<String, dynamic>>.from(data['internal_users']);
        }
        
        // Update the consolidated list after fetching both invited lists
        updateConsolidatedList();
      } else {
        print("No appointment data found.");
      }
    } catch (e) {
      print("Error fetching appointment data: $e");
    }
  }

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
        print("No attendance data found.");
        // Still update consolidated list with everyone marked as absent
        updateConsolidatedList();
      }
    } catch (e) {
      print("Error fetching attendance data: $e");
    }
  }

  void updateConsolidatedList() {
    List<Map<String, dynamic>> consolidated = [];
    
    // Process internal users first
    for (var user in invitedUsers) {
      bool isPresent = false;
      String userEmail = user['email'] ?? '';
      String userName = user['fullName'] ?? '';
      
      // Check if user is in attendance list
      for (var attendee in attendanceList) {
        if ((attendee['email_address'] == userEmail) || 
            (attendee['name'] == userName)) {
          isPresent = true;
          break;
        }
      }
      
      consolidated.add({
        'name': userName,
        'position': user['department'] ?? 'N/A',
        'email': userEmail,
        'present': isPresent,
        'type': 'Internal'
      });
    }
    
    // Then process external guests
    for (var guest in invitedGuests) {
      bool isPresent = false;
      String guestEmail = guest['emailAdd'] ?? '';
      String guestName = guest['fullName'] ?? '';
      
      // Check if guest is in attendance list
      for (var attendee in attendanceList) {
        if ((attendee['email_address'] == guestEmail) || 
            (attendee['name'] == guestName)) {
          isPresent = true;
          break;
        }
      }
      
      consolidated.add({
        'name': guestName,
        'position': guest['companyName'] ?? 'N/A',
        'email': guestEmail,
        'present': isPresent,
        'type': 'External'
      });
    }
    
    // Now add any attendees who were not in the invitation lists
    for (var attendee in attendanceList) {
      String attendeeName = attendee['name'] ?? '';
      String attendeeEmail = attendee['email_address'] ?? '';
      
      // Check if already added to consolidated list
      bool alreadyAdded = false;
      for (var person in consolidated) {
        if ((person['email'] == attendeeEmail && attendeeEmail.isNotEmpty) || 
            (person['name'] == attendeeName && attendeeName.isNotEmpty)) {
          alreadyAdded = true;
          break;
        }
      }
      
      // If not already added, add them as an additional attendee
      if (!alreadyAdded) {
        consolidated.add({
          'name': attendeeName,
          'position': attendee['company'] ?? 'Additional Attendee',
          'email': attendeeEmail,
          'present': true,
          'type': 'Additional'
        });
      }
    }
    
    setState(() {
      consolidatedAttendees = consolidated;
      // Initialize filteredAttendees with all attendees
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
  int get presentCount => consolidatedAttendees.where((p) => p['present'] == true).length;
  int get absentCount => consolidatedAttendees.where((p) => p['present'] == false).length;

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
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width / 1.5,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance for: ${widget.selectedAgenda}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Search and Items per page controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Search Bar
                Container(
                  width: screenWidth / 6,
                  height: screenWidth / 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
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
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      hintText: 'Search attendees...',
                      prefixIcon: Icon(Icons.search, size: 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        currentPage = 1; // Reset to first page when searching
                        filterAttendees();
                      });
                    },
                  ),
                ),
                
                // Items per page control
                Row(
                  children: [
                    Text('Items per page:', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 8),
                    Container(
                      width: 50,
                      height: 30,
                      child: TextField(
                        controller: itemsPerPageController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                        onSubmitted: (value) => updateItemsPerPage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: updateItemsPerPage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        minimumSize: Size(50, 30),
                      ),
                      child: Text('Apply', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Attendee List with Pagination
            Expanded(
              child: filteredAttendees.isEmpty 
                ? Center(child: Text('No attendance data available'))
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
                                onPressed: currentPage > 1
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        totalPages,
                                        (index) {
                                          int pageNumber = index + 1;
                                          bool isCurrentPage = pageNumber == currentPage;

                                          return Container(
                                            margin: EdgeInsets.symmetric(horizontal: 4),
                                            child: InkWell(
                                              onTap: () => setState(() => currentPage = pageNumber),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isCurrentPage
                                                    ? Colors.blue
                                                    : Colors.white,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isCurrentPage
                                                      ? Colors.blue
                                                      : Colors.grey.shade300,
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
                                onPressed: currentPage < totalPages
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
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Page $currentPage of $totalPages (${filteredAttendees.length} total items)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
            ),
            
            const SizedBox(height: 20),
            
            // Statistics and Add Attendee button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: $totalCount | Present: $presentCount | Absent: $absentCount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to add attendee screen
                  },
                  child: const Text('Add Attendee'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeeCard(String name, String position, bool present, String type, String email) {
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
        title: textWithTooltip(
          name,
          TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxWidth: screenWidth / 3,
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
          backgroundColor: present ? Colors.green.shade100 : Colors.red.shade100,
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