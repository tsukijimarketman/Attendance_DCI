import 'package:attendance_app/Animation/loader.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InternalUsers extends StatefulWidget {
  final String selectedAgenda;
  const InternalUsers({super.key, required this.selectedAgenda});

  @override
  State<InternalUsers> createState() => _InternalUsersState();
}

class _InternalUsersState extends State<InternalUsers> {
  // Pagination variables
  int currentPage = 1;
  int itemsPerPage = 4; // Default to 4 items per page same as guest.dart
  int totalPages = 1;

  // Search functionality
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  TextEditingController itemsPerPageController = TextEditingController();

  // Store all internal users to manage pagination locally
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

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

  // Filter users based on search query
  void filterUsers() {
    if (searchQuery.isEmpty) {
      filteredUsers = List.from(allUsers);
    } else {
      filteredUsers = allUsers.where((user) {
        String fullName = (user['fullName'] ?? '').toString().toLowerCase();
        String department = (user['department'] ?? '').toString().toLowerCase();
        String email = (user['email'] ?? '').toString().toLowerCase();
        return fullName.contains(searchQuery.toLowerCase()) ||
            department.contains(searchQuery.toLowerCase()) ||
            email.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Update total pages
    totalPages = (filteredUsers.length / itemsPerPage).ceil();
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

    if (endIndex > filteredUsers.length) {
      endIndex = filteredUsers.length;
    }

    if (startIndex >= filteredUsers.length) {
      return [];
    }

    return filteredUsers.sublist(startIndex, endIndex);
  }

  void updateItemsPerPage() {
    int? newValue = int.tryParse(itemsPerPageController.text);
    if (newValue != null && newValue > 0) {
      setState(() {
        itemsPerPage = newValue;
        currentPage = 1; // Reset to first page when changing items per page
        filterUsers();
      });
    } else {
      // Reset to default if invalid input
      itemsPerPageController.text = itemsPerPage.toString();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid number greater than 0')));
    }
  }

  String getInitial(String fullName) {
    if (fullName.isNotEmpty) {
      return fullName[0].toUpperCase();
    }
    return '?';
  }

  // Custom vertical divider widget
  Widget verticalDivider(double screenWidth) {
    return Container(
      height: screenWidth / 130,
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: screenWidth / 200),
      color: Colors.grey.shade400,
    );
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Expanded(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              width: screenWidth,
              height: screenWidth / 20,
              color: Color(0xFF0E2643),
              child: Center(
                child: Text(
                  "Internal Users for ${widget.selectedAgenda}",
                  style: TextStyle(
                    fontSize: screenWidth / 100,
                    fontFamily: "B",
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenWidth / 80),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 70),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: screenWidth / 6,
                    height: screenWidth / 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth / 160),
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
                        hintText: 'Search user details...',
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
                          currentPage = 1; // Reset to first page when searching
                          filterUsers();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: screenWidth / 100),
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
                          style: TextStyle(fontSize: screenWidth / 120),
                          onSubmitted: (value) => updateItemsPerPage(),
                        ),
                      ),
                      SizedBox(width: screenWidth / 100),
                      GestureDetector(
                        // This will trigger the updateItemsPerPage method
                        onTap: updateItemsPerPage,
                        child: Container(
                          width: screenWidth / 23,
                          height: screenWidth / 30,
                          decoration: BoxDecoration(
                              color: Color(0xFF2184D6),
                              borderRadius:
                                  BorderRadius.circular(screenWidth / 160)),
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

            // Internal Users List
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth / 90),
                child: widget.selectedAgenda.isEmpty
                    ? Center(child: Text("No appointment selected"))
                    // This StreamBuilder listens to real-time updates from the 'appointment' collection in Firestore. 
// It filters appointments by the selected agenda (from `widget.selectedAgenda`) and by a status of "Completed".
// If the snapshot does not contain any data or the list of documents is empty, a message is displayed stating that 
// no appointments matching the given agenda are found.
// Once data is available, the code retrieves the first document from the snapshot and extracts the appointment data 
// into a Map<String, dynamic> for easier handling.
// It checks whether the 'internal_users' field exists and is a list. If this condition is met, 
// it assigns the list of internal users to the `allUsers` variable. The `filterUsers()` function is called to
// If no internal users are found in the appointment, the UI displays a message indicating that no users exist for 
// this appointment.
// Next, the code retrieves the items to be displayed on the current page using the `getCurrentPageItems()` function.
// If the current page has no items and the search query is not empty, a message is shown to indicate that no users 
// match the search. If there are no items but no search query is entered, a message is displayed saying "No users on this page".
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('appointment')
                            .where('agenda', isEqualTo: widget.selectedAgenda)
                            .where('status', isEqualTo: "Completed")
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
                                    "No appointment found with this agenda"));
                          }

                          // Extract the internal user data from the appointment document
                          var appointmentDoc = snapshot.data!.docs.first;
                          var appointmentData =
                              appointmentDoc.data() as Map<String, dynamic>;

                          // Check if the internal_users field exists and is a list
                          if (appointmentData.containsKey('internal_users') &&
                              appointmentData['internal_users'] is List &&
                              allUsers.isEmpty) {
                            // Extract all internal users from the appointment
                            List<dynamic> userList =
                                appointmentData['internal_users'];
                            allUsers = userList.map((user) {
                              if (user is Map<String, dynamic>) {
                                return user;
                              }
                              return <String, dynamic>{};
                            }).toList();

                            // Initial filtering
                            filterUsers();
                          }

                          // If we have no users
                          if (allUsers.isEmpty) {
                            return Center(
                                child: Text(
                                    "No internal users found for this appointment"));
                          }

                          var currentItems = getCurrentPageItems();

                          if (currentItems.isEmpty && searchQuery.isNotEmpty) {
                            return Center(
                                child: Text("No users match your search"));
                          } else if (currentItems.isEmpty) {
                            return Center(child: Text("No users on this page"));
                          }

                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: currentItems.length,
                                  itemBuilder: (context, index) {
                                    var user = currentItems[index];
                                    String fullName =
                                        user['fullName'] ?? 'Unnamed User';
                                    String department =
                                        user['department'] ?? 'No Department';
                                    String email = user['email'] ?? 'No Email';
                                    String initialLetter = getInitial(fullName);

                                    // Calculate available widths for text fields
                                    double nameMaxWidth = screenWidth / 2;
                                    double emailMaxWidth = screenWidth / 2;
                                    double departmentMaxWidth = screenWidth / 2;

                                    return Container(
                                      height: screenWidth / 17,
                                      child: Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              screenWidth / 160),
                                        ),
                                        color: Colors.green.shade50,
                                        child: ListTile(
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: textWithTooltip(
                                                  fullName,
                                                  TextStyle(
                                                    fontSize: screenWidth / 90,
                                                    fontFamily: "B",
                                                  ),
                                                  maxWidth: nameMaxWidth,
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Email with tooltip
                                              textWithTooltip(
                                                email,
                                                TextStyle(
                                                  fontSize: screenWidth / 120,
                                                  fontFamily: "R",
                                                ),
                                                maxWidth: emailMaxWidth,
                                              ),

                                              // Department with tooltip
                                              textWithTooltip(
                                                department,
                                                TextStyle(
                                                  fontSize: screenWidth / 120,
                                                  fontFamily: "R",
                                                ),
                                                maxWidth: departmentMaxWidth,
                                              ),
                                            ],
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.green,
                                            radius: screenWidth / 60,
                                            child: Text(
                                              initialLetter,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: screenWidth / 80,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Only show pagination if we have items
                              if (filteredUsers.isNotEmpty) ...[
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
                                            ? () =>
                                                setState(() => currentPage--)
                                            : null,
                                        iconSize: screenWidth / 50,
                                        color: currentPage > 1
                                            ? Colors.green
                                            : Colors.grey,
                                      ),

                                      // Page numbers
                                      SizedBox(
                                        height: screenWidth / 25,
                                        width: screenWidth / 5.5,
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
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 4),
                                                    child: InkWell(
                                                      onTap: () => setState(
                                                          () => currentPage =
                                                              pageNumber),
                                                      child: Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal:
                                                              screenWidth / 100,
                                                          vertical:
                                                              screenWidth / 200,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isCurrentPage
                                                              ? Colors.green
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          border: Border.all(
                                                            color: isCurrentPage
                                                                ? Colors.green
                                                                : Colors.grey
                                                                    .shade300,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '$pageNumber',
                                                          style: TextStyle(
                                                            color: isCurrentPage
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontWeight:
                                                                isCurrentPage
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
                                        // This is Pagination
                                        currentPage < totalPages
                                            ? () =>
                                                setState(() => currentPage++)
                                            : null,
                                        iconSize: screenWidth / 50,
                                        color: currentPage < totalPages
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),

                                // Page info text
                                Padding(
                                  padding:
                                      EdgeInsets.only(top: screenWidth / 160),
                                  child: Text(
                                    'Page $currentPage of $totalPages (${filteredUsers.length} total items)',
                                    style: TextStyle(
                                      fontSize: screenWidth / 120,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
