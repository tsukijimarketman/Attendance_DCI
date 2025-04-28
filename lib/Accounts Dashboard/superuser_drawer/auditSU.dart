import 'package:attendance_app/Animation/loader.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AuditSU extends StatefulWidget {
  const AuditSU({super.key});

  @override
  State<AuditSU> createState() => _AuditSUState();
}

class _AuditSUState extends State<AuditSU> {
  Future<List<Map<String, dynamic>>>? _userAuditLogs;
  String? userId;
  String? fullName;
  TextEditingController searchController = TextEditingController();
  TextEditingController _dateFromController = TextEditingController();
  TextEditingController _dateToController = TextEditingController();

  // Add these variables to track filter state
  String? _nameFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // The initState method is called when the widget is first created. It initializes the state and triggers 
// the _fetchUserData function to fetch the currently authenticated user's data. This ensures that the user's 
// information (such as user ID and full name) is retrieved and available as soon as the widget is built, 
// allowing the UI to reflect the user's data promptly. The super.initState() is called to ensure proper 
// initialization of the widget's state before the custom logic is executed.
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // The _fetchUserData function retrieves and processes user data based on the currently authenticated user. 
// First, it checks if a user is logged in by accessing the current user from FirebaseAuth. If a user is authenticated, 
// it fetches the user's data from the Firestore "users" collection by querying with the user's unique UID. 
// If a matching user document is found, it extracts the user's full name by combining their first and last name, 
// then updates the state with the user's ID, full name, and triggers the fetching of the user's audit logs. 
// If no user document is found or if the user is not authenticated, appropriate error messages are shown 
// to the user via snack bars. In case of any errors during the data retrieval process, a generic error message is displayed. 
// This method ensures that user data is fetched and the UI is updated accordingly, while handling potential errors gracefully.
  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection("users")
            .where("uid", isEqualTo: uid)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          var userDoc = userQuery.docs.first;
          String fetchedFullName =
              "${userDoc["first_name"]} ${userDoc["last_name"]}";

          setState(() {
            userId = uid;
            fullName = fetchedFullName;
            _userAuditLogs = fetchAuditLogsByUser(userId!);
          });
        } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ No user document found for UID"))); 
        }
      } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ No authenticated user found."))); }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Improved search method that maintains date filters
  void searchAuditLogs() {
    String searchText = searchController.text.trim();
    setState(() {
      _nameFilter = searchText.isNotEmpty ? searchText : null;
      // Apply all current filters
      _applyAllFilters();
    });
  }

  // Apply all current filters (name, date range)
  void _applyAllFilters() {
    setState(() {
      _userAuditLogs = fetchFilteredAuditLogs();
    });
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      searchController.clear();
      _dateFromController.clear();
      _dateToController.clear();
      _nameFilter = null;
      _dateFrom = null;
      _dateTo = null;

      // Reset to default view
      _userAuditLogs = fetchAuditLogsByUser(userId!);
    });
  }

  // The fetchFilteredAuditLogs function retrieves audit logs with multiple filtering options. 
// First, it fetches the user's role based on their user ID from the "users" collection. If the user is a "Superuser", 
// no additional user-specific filtering is applied, but if the user is not a Superuser, the logs are filtered by their userId. 
// The function then checks if date filters (_dateFrom and _dateTo) are provided, and applies timestamp filtering accordingly, 
// ensuring the logs fall within the specified date range. To ensure that the date range is inclusive of the full end of the day, 
// the 'to' date is adjusted to include the last moment of the day. 
// After fetching the logs, the results are optionally filtered on the client side by the full name (_nameFilter), 
// ensuring that only logs with names matching the filter are returned. The logs are then sorted by timestamp in descending order 
// to show the most recent events first. Any errors encountered during the process are caught and an empty list is returned, 
// allowing for graceful error handling. This method combines multiple filters for a more comprehensive log-fetching process.
  Future<List<Map<String, dynamic>>> fetchFilteredAuditLogs() async {
    try {
      // Fetch user role
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection("users")
          .where("uid", isEqualTo: userId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return [];
      }

      String role = userQuery.docs.first.get("roles");

      Query query = FirebaseFirestore.instance.collection("audit_logs");

      if (role == "Superuser") {
      } else {
        query = query.where("userId", isEqualTo: userId);
      }

      // Apply Date Filtering if selected
      if (_dateFrom != null && _dateTo != null) {
        DateTime toDateEnd =
            _dateTo!.add(Duration(hours: 23, minutes: 59, seconds: 59));
        query = query
            .where("timestamp",
                isGreaterThanOrEqualTo: Timestamp.fromDate(_dateFrom!))
            .where("timestamp",
                isLessThanOrEqualTo: Timestamp.fromDate(toDateEnd));
      }

      query = query.orderBy("timestamp", descending: true);

      QuerySnapshot querySnapshot = await query.get();
      List<Map<String, dynamic>> logs = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Apply name filter if provided (client-side filtering)
      if (_nameFilter != null && _nameFilter!.isNotEmpty) {
        logs = logs.where((log) {
          String fullName = log['fullName'].toString().toLowerCase();
          return fullName.contains(_nameFilter!.toLowerCase());
        }).toList();
      }

      return logs;
    } catch (e) {
      return [];
    }
  } 


// The fetchAuditLogsByUser function retrieves audit logs for a specific user based on their unique user ID (uid). 
// First, it queries the "users" collection to fetch the user's role, and if the user is a "Superuser", 
// no additional filtering is applied. If the user is not a Superuser, the query is filtered by the userId 
// to retrieve only their audit logs. If date filters (fromDate and toDate) are provided, the function further 
// filters the logs by timestamp, ensuring only logs within the specified date range are returned. 
// The logs are sorted by timestamp in descending order to show the most recent activities first. 
// The function catches any errors during the data retrieval process and returns an empty list in case of failure, 
// ensuring that the app handles potential issues gracefully.
  Future<List<Map<String, dynamic>>> fetchAuditLogsByUser(String uid,
      {DateTime? fromDate, DateTime? toDate}) async {
    try {
      // Fetch user role
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection("users")
          .where("uid", isEqualTo: uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return [];
      }

      String role = userQuery.docs.first.get("roles");

      Query query = FirebaseFirestore.instance.collection("audit_logs");

      if (role == "Superuser") {
      } else {
        query = query.where("userId", isEqualTo: uid);
      }

      // Apply Date Filtering if selected
      if (fromDate != null && toDate != null) {
        query = query
            .where("timestamp",
                isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
            .where("timestamp",
                isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      query = query.orderBy("timestamp", descending: true);

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // The 'icon' variable holds the default icon used in the UI, initially set to 'Icons.arrow_drop_down', 
// which may represent a dropdown action. The 'isClicked' boolean tracks whether the dropdown or 
// similar UI element has been clicked or interacted with, defaulting to 'true'. 
  IconData icon = Icons.arrow_drop_down;
  bool isClicked = true;

  
// The '_dateFormat' variable stores a DateFormat instance with the format 'yyyy-MM-dd', 
// used to format and parse dates in a consistent way throughout the application. 
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // The 'filteredResults' variable is a list of DocumentSnapshot objects that holds 
// the filtered data retrieved from Firestore. It is initialized as an empty list, ready to 
// store results that match the user’s criteria or filters.
  List<DocumentSnapshot> filteredResults = [];

  // The _selectDate method is used to allow the user to pick a date from a date picker dialog. 
// It takes two parameters: the context for the date picker and a boolean flag 'isDateFrom' 
// to determine whether the selected date is for the "from" date or the "to" date. 
// The method uses the showDatePicker function to display the date picker with a defined date range 
// (from the year 2000 to 2100), and it initializes with the current date. If the user selects a date, 
// it updates the corresponding date variable (_dateFrom or _dateTo) and updates the associated text controller 
// with the selected date in the 'yyyy-MM-dd' format. The method ensures that the selected date is reflected 
// in both the internal state and the UI.

  Future<void> _selectDate(BuildContext context, bool isDateFrom) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isDateFrom) {
          _dateFrom = pickedDate;
          _dateFromController.text =
              DateFormat('yyyy-MM-dd').format(pickedDate);
        } else {
          _dateTo = pickedDate;
          _dateToController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        }
      });
    }
  }

  // The _filterResults method is used to filter data based on user-provided date ranges. 
// It first checks if both the "from" and "to" date fields are not empty. If either field is empty, 
// the function exits early without applying any filters. When both date fields contain valid inputs, 
// it parses the date strings into DateTime objects using the 'yyyy-MM-dd' format. The method then updates 
// the state with the parsed date values and calls the _applyAllFilters function to apply any additional filters 
// or actions needed based on the selected date range. This method ensures that the user can
  void _filterResults() async {
    if (_dateFromController.text.isEmpty || _dateToController.text.isEmpty) {
      return;
    }

    DateTime fromDate =
        DateFormat('yyyy-MM-dd').parse(_dateFromController.text);
    DateTime toDate = DateFormat('yyyy-MM-dd').parse(_dateToController.text);

    setState(() {
      _dateFrom = fromDate;
      _dateTo = toDate;
      _applyAllFilters();
    });

  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFf2edf3), // Background color
            // Optional rounded corners
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed Header Row
              Container(
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Audit Trail",
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width / 50,
                          color: Color.fromARGB(255, 11, 55, 99),
                          fontFamily: "BL"),
                    ),
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            isClicked = !isClicked;
                            icon = isClicked
                                ? Icons.arrow_drop_down
                                : Icons.arrow_drop_up;
                            print("$isClicked");
                          });
                        },
                        child: Icon(
                          icon,
                          color: Color.fromARGB(255, 11, 55, 99),
                          size: MediaQuery.of(context).size.width / 35,
                        )).showCursorOnHover
                  ],
                ),
              ),

              Offstage(
                offstage: isClicked,
                child: Container(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.width / 80,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Column(
                                children: [
                                  Text("Name",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              7,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              35,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        150),
                                                bottomLeft: Radius.circular(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        150)),
                                          ),
                                          child: TextField(
                                            controller: searchController,
                                            keyboardType: TextInputType.text,
                                            style: TextStyle(
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    110,
                                                color: Colors.black,
                                                fontFamily: "R"),
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.all(
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      120),
                                              hintText: "Enter Name",
                                              hintStyle: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          110,
                                                  color: Colors.grey,
                                                  fontFamily: "R"),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            150),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              10.68,
                                          child: GestureDetector(
                                            // This will triggered the searchAuditLogs
                                            onTap: searchAuditLogs,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  20,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  35,
                                              decoration: BoxDecoration(
                                                color: Color.fromARGB(
                                                    255, 11, 55, 99),
                                                borderRadius: BorderRadius.only(
                                                    topRight: Radius.circular(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            150),
                                                    bottomRight:
                                                        Radius.circular(
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                150)),
                                              ),
                                              child: Icon(Icons.search,
                                                  color: Colors.white),
                                            ).showCursorOnHover,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text("Date From",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 7,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: GestureDetector(
                                  onTap: () =>
                                  // This will triggered the _selectDate
                                      _selectDate(context, true), // Date From

                                  child: AbsorbPointer(
                                    // Prevents manual input while allowing tap detection
                                    child: TextField(
                                      controller: _dateFromController,
                                      readOnly: true,
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Date From",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text("Date To",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 7,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    // This will triggered the _selectDate
                                    _selectDate(context, false);
                                  },
                                  // Date To

                                  child: AbsorbPointer(
                                    // Prevents manual input while allowing tap detection
                                    child: TextField(
                                      // This will Triggered the _dateToCOntroller Method
                                      controller: _dateToController,
                                      readOnly: true,
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Date To",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text("",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              GestureDetector(
                                // This is will Triggered the Filtering Result
                                onTap: _filterResults,
                                child: Container(
                                    width:
                                        MediaQuery.of(context).size.width / 10,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Search",
                                        style: TextStyle(
                                            fontFamily: "B",
                                            color: Colors.white,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                90),
                                      ),
                                    )),
                              ),
                            ],
                          ).showCursorOnHover,
                          Column(
                            children: [
                              Text("",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              GestureDetector(
                                onTap:
                                // This will Triggered the method for Clearing the filters
                                    _clearFilters, // Use the new clear method here
                                child: Container(
                                    width:
                                        MediaQuery.of(context).size.width / 10,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Clear",
                                        style: TextStyle(
                                            fontFamily: "B",
                                            color: Colors.white,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                90),
                                      ),
                                    )),
                              ),
                            ],
                          ).showCursorOnHover,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width / 80,
              ),
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                          MediaQuery.of(context).size.width / 90),
                      topRight: Radius.circular(
                          MediaQuery.of(context).size.width / 90)),
                  color: Color.fromARGB(255, 11, 55, 99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Shadow color
                      spreadRadius: 1, // How much the shadow spreads
                      blurRadius: 6, // Softness of the shadow
                      offset: Offset(3, 3), // Position of the shadow (X, Y)
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: Text("Date & Time",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text("Name",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text("Action",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text("Details",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text("IP Address",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

              // The Expanded widget ensures that the FutureBuilder takes up all available space within the parent widget. 
              // The FutureBuilder listens for the result of the _userAuditLogs future, which fetches a list of audit logs. 
              // It handles various states: while waiting for the data, it displays a custom loading indicator; if there is 
              // an error during data fetching, it shows an error message; and if no data is found or the list is empty, 
              // it informs the user with a message saying "No audit logs found". Once the data is available, the FutureBuilder 
              // displays the audit logs in a list or another appropriate widget. This setup ensures that the UI is responsive 
              // and provides feedback during the data-fetching process, while also displaying the results when available.
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _userAuditLogs,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CustomLoader());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error loading logs"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("No audit logs found"));
                    }

                    List<Map<String, dynamic>> logs = snapshot.data!;

                    return Container(
                      color: Colors.white,
                      child: ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          var log = logs[index];
                          return Container(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width / 40),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.black12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                    child: Text(log["timestamp"] != null
                                        ? DateTime.fromMillisecondsSinceEpoch(
                                                log["timestamp"]
                                                    .millisecondsSinceEpoch)
                                            .toString()
                                        : "No Timestamp")),
                                Expanded(
                                    child: Text(
                                        log["fullName"] ?? "Unknown Name")),
                                Expanded(
                                    child: Text(
                                        log["action"] ?? "Unknown Action")),
                                Expanded(
                                    child:
                                        Text(log["details"] ?? "No Details")),
                                Expanded(
                                    child: Text(log["ipAddress"] ?? "No IP")),
                              ],
                            ),
                          );
                        },
                      ),
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
}
