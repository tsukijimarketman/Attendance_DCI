import 'package:attendance_app/Animation/loader.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Guest extends StatefulWidget {
  final String selectedAgenda;
  final String statusType;

  const Guest({
    super.key,
    required this.selectedAgenda, required this.statusType,
  });

  @override
  State<Guest> createState() => _GuestState();
}

class _GuestState extends State<Guest> {
  // Pagination variables
  int currentPage = 1;
  int itemsPerPage = 4; // Default to 4 items per page as requested
  int totalPages = 1;

  // Search functionality
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  TextEditingController itemsPerPageController = TextEditingController();

  // Store all guests to manage pagination locally
  List<Map<String, dynamic>> allGuests = [];
  List<Map<String, dynamic>> filteredGuests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    itemsPerPageController.text = itemsPerPage.toString();
  }

  @override
  void didUpdateWidget(Guest oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear the lists when the selectedAgenda changes
    if (oldWidget.selectedAgenda != widget.selectedAgenda) {
      setState(() {
        allGuests = [];
        filteredGuests = [];
        currentPage = 1;
        searchQuery = '';
        searchController.text = '';
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    itemsPerPageController.dispose();
    super.dispose();
  }

  // Filter guests based on search query
  void filterGuests() {
    if (searchQuery.isEmpty) {
      filteredGuests = List.from(allGuests);
    } else {
      filteredGuests = allGuests.where((guest) {
        String fullName = (guest['fullName'] ?? '').toString().toLowerCase();
        String company = (guest['companyName'] ?? '').toString().toLowerCase();
        String email = (guest['emailAdd'] ?? '').toString().toLowerCase();
        String contact = (guest['contactNum'] ?? '').toString().toLowerCase();
        return fullName.contains(searchQuery.toLowerCase()) ||
            company.contains(searchQuery.toLowerCase()) ||
            email.contains(searchQuery.toLowerCase()) ||
            contact.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Update total pages
    totalPages = (filteredGuests.length / itemsPerPage).ceil();
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

    if (endIndex > filteredGuests.length) {
      endIndex = filteredGuests.length;
    }

    if (startIndex >= filteredGuests.length) {
      return [];
    }

    return filteredGuests.sublist(startIndex, endIndex);
  }

  void updateItemsPerPage() {
    int? newValue = int.tryParse(itemsPerPageController.text);
    if (newValue != null && newValue > 0) {
      setState(() {
        itemsPerPage = newValue;
        currentPage = 1; // Reset to first page when changing items per page
        filterGuests();
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
                  "Guests for ${widget.selectedAgenda}",
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
                        hintText: 'Search guest details...',
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
                          filterGuests();
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

            // Guest List
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth / 90),
                child: widget.selectedAgenda.isEmpty
                    ? Center(child: Text("No appointment selected"))
                    // This StreamBuilder listens for real-time updates from the 'appointment' collection in Firestore,
// specifically filtering appointments by the selected agenda (from `widget.selectedAgenda`) and the 
// selected status type (`widget.statusType`).
// If the connection is still waiting for data, a custom loading indicator (`CustomLoader`) is shown.
// If no data is available or if the appointment document list is empty, a message is displayed indicating 
// that no appointment with the selected agenda was found.
// When appointment data is available, the code extracts the first document and maps the appointment data 
// into a `Map<String, dynamic>`. It then checks if the 'guest' field exists and whether it is a list. If 
// the field exists and the `allGuests` list is empty, it proceeds to extract the list of guests and 
// assigns it to the `allGuests` variable, where each guest is mapped to a Map<String, dynamic> for easy processing.
// After that, the `filterGuests()` function is called to apply any initial filtering on the list of guests (not shown).
// If no guests are found for the appointment, a message is displayed stating that no guests are available.
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('appointment')
                            .where('agenda', isEqualTo: widget.selectedAgenda)
                            .where('status', isEqualTo: widget.statusType)
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
                                    "No guests found"));
                          }

                          // Extract the guest data from the appointment document
                          var appointmentDoc = snapshot.data!.docs.first;
                          var appointmentData =
                              appointmentDoc.data() as Map<String, dynamic>;

                          // Check if the guest field exists and is a list
                          if (appointmentData.containsKey('guest') &&
                              appointmentData['guest'] is List &&
                              allGuests.isEmpty) {
                            // Extract all guests from the appointment
                            List<dynamic> guestList = appointmentData['guest'];
                            allGuests = guestList.map((guest) {
                              if (guest is Map<String, dynamic>) {
                                return guest;
                              }
                              return <String, dynamic>{};
                            }).toList();

                            // Initial filtering
                            filterGuests();
                          }

                          // If we have no guests
                          if (allGuests.isEmpty) {
                            return Center(
                                child: Text(
                                    "No guests found for this appointment"));
                          }

                          var currentItems = getCurrentPageItems();

                          if (currentItems.isEmpty && searchQuery.isNotEmpty) {
                            return Center(
                                child: Text("No guests match your search"));
                          } else if (currentItems.isEmpty) {
                            return Center(
                                child: Text("No guests on this page"));
                          }

                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: currentItems.length,
                                  itemBuilder: (context, index) {
                                    var guest = currentItems[index];
                                    String fullName =
                                        guest['fullName'] ?? 'Unnamed Guest';
                                    String company = guest['companyName'] ??
                                        'Unknown Company';
                                    String contactNum =
                                        guest['contactNum'] ?? 'No Contact';
                                    String emailAdd =
                                        guest['emailAdd'] ?? 'No Email';
                                    String initialLetter = getInitial(fullName);

                                    return Container(
                                      height: screenWidth /
                                          17, // Increased height for the additional content
                                      child: Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                screenWidth / 160),
                                          ),
                                          color: Colors.blue.shade50,
                                          child: ListTile(
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: textWithTooltip(
                                                    fullName,
                                                    TextStyle(
                                                      fontSize:
                                                          screenWidth / 90,
                                                      fontFamily: "B",
                                                    ),
                                                    maxWidth: screenWidth /
                                                        2, // Define max width for name
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    textWithTooltip(
                                                      emailAdd,
                                                      TextStyle(
                                                        fontSize:
                                                            screenWidth / 120,
                                                        fontFamily: "R",
                                                      ),
                                                      maxWidth: screenWidth /
                                                          2, // Define max width for email
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    // Company Name with tooltip and fixed width
                                                    Expanded(
                                                      child: textWithTooltip(
                                                        company,
                                                        TextStyle(
                                                          fontSize:
                                                              screenWidth / 120,
                                                          fontFamily: "R",
                                                        ),
                                                        maxWidth:
                                                            screenWidth / 4,
                                                      ),
                                                    ),

                                                    verticalDivider(
                                                        screenWidth),

                                                    // Contact Number with tooltip and fixed width
                                                    Expanded(
                                                      child: textWithTooltip(
                                                        contactNum,
                                                        TextStyle(
                                                          fontSize:
                                                              screenWidth / 120,
                                                          fontFamily: "R",
                                                        ),
                                                        maxWidth:
                                                            screenWidth / 4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.blue,
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
                                          )),
                                    );
                                  },
                                ),
                              ),

                              // Only show pagination if we have items
                              if (filteredGuests.isNotEmpty) ...[
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
                                            ? Colors.blue
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
                                                              ? Colors.blue
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          border: Border.all(
                                                            color: isCurrentPage
                                                                ? Colors.blue
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
                                            ? Colors.blue
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
                                    'Page $currentPage of $totalPages (${filteredGuests.length} total items)',
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
}
