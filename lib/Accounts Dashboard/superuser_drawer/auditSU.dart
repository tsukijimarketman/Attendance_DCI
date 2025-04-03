import 'package:attendance_app/Animation/loader.dart';
import 'package:attendance_app/Auth/audit_function.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

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
          print("✅ Found User Document: ${userDoc.id}, Name: $fetchedFullName");

          setState(() {
            userId = uid;
            fullName = fetchedFullName;
            _userAuditLogs = fetchAuditLogsByUser(userId!);
          });
        } else {
          print("⚠️ No user document found for UID: $uid");
        }
      } else {
        print("⚠️ No authenticated user found.");
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
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
    print("🧹 Cleared all filters");
  }

  // New method that combines all filtering logic
  Future<List<Map<String, dynamic>>> fetchFilteredAuditLogs() async {
    try {
      // Fetch user role
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection("users")
          .where("uid", isEqualTo: userId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("⚠️ No user document found.");
        return [];
      }

      String role = userQuery.docs.first.get("roles");
      print("🔎 User Role: $role");

      Query query = FirebaseFirestore.instance.collection("audit_logs");

      if (role == "Superuser") {
        print("👀 Fetching ALL audit logs for Superuser...");
      } else {
        print("🔒 Fetching logs ONLY for this user...");
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
        print("🔍 Filtering by date range: ${_dateFrom!} to ${toDateEnd}");
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
        print("🔍 Filtering by name: $_nameFilter");
      }

      return logs;
    } catch (e) {
      print("❌ Error fetching filtered audit logs: $e");
      return [];
    }
  }

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
        print("⚠️ No user document found.");
        return [];
      }

      String role = userQuery.docs.first.get("roles");
      print("🔎 User Role: $role");

      Query query = FirebaseFirestore.instance.collection("audit_logs");

      if (role == "Superuser") {
        print("👀 Fetching ALL audit logs for Superuser...");
      } else {
        print("🔒 Fetching logs ONLY for this user...");
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
      print("❌ Error fetching audit logs: $e");
      return [];
    }
  }

  IconData icon = Icons.arrow_drop_down;
  bool isClicked = true;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  List<DocumentSnapshot> filteredResults = [];

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

  void _filterResults() async {
    if (_dateFromController.text.isEmpty || _dateToController.text.isEmpty) {
      print("⚠️ Error: Select both dates before searching.");
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

    print("🔍 Filtering logs from: $fromDate to $toDate");
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
                                    _selectDate(context, false);
                                  },
                                  // Date To

                                  child: AbsorbPointer(
                                    // Prevents manual input while allowing tap detection
                                    child: TextField(
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

              // Scrollable Log List
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
