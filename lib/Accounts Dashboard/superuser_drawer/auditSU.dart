import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AuditSU extends StatefulWidget {
  const AuditSU({super.key});

  @override
  State<AuditSU> createState() => _AuditSUState();
}

class _AuditSUState extends State<AuditSU> {
  Future<List<Map<String, dynamic>>>? _userAuditLogs;
  String? userId;
  String? fullName;

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
            _userAuditLogs = fetchAuditLogsByUser(userId!, fullName!);
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

  Future<List<Map<String, dynamic>>> fetchAuditLogsByUser(
      String uid, String fullName) async {
    try {
      print("🔎 Fetching logs for: UserID=$uid, FullName=$fullName");

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("audit_logs")
          .where("userId", isEqualTo: uid)
          .where("fullName", isEqualTo: fullName)
          .orderBy("timestamp", descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("⚠️ No audit logs found.");
      }

      return querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        print("📝 Log Found: $data");
        return data;
      }).toList();
    } catch (e) {
      print("❌ Error fetching audit logs: $e");
      return [];
    }
  }

  IconData icon = Icons.arrow_drop_down;
  bool isClicked = true;

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
                                            keyboardType: TextInputType.text,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(
                                                      r'[a-zA-Z]')), // Allows only letters
                                            ],
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
                                                  bottomRight: Radius.circular(
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          150)),
                                            ),
                                            child: Icon(Icons.search,
                                                color: Colors.white),
                                          ).showCursorOnHover,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
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
                                child: TextField(
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(
                                        r'[a-zA-Z]')), // Allows only letters
                                  ],
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width /
                                            120),
                                    hintText: "Date From",
                                    hintStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.grey,
                                        fontFamily: "R"),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
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
                                child: TextField(
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(
                                        r'[a-zA-Z]')), // Allows only letters
                                  ],
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width /
                                            120),
                                    hintText: "Date To",
                                    hintStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.grey,
                                        fontFamily: "R"),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
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
                              Container(
                                  width: MediaQuery.of(context).size.width / 10,
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
                              Container(
                                  width: MediaQuery.of(context).size.width / 15,
                                  height:
                                      MediaQuery.of(context).size.width / 35,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.width /
                                            150),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.print,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        "CSV",
                                        style: TextStyle(
                                            fontFamily: "B",
                                            color: Colors.white,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                90),
                                      ),
                                    ],
                                  )),
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
                              Container(
                                  width: MediaQuery.of(context).size.width / 15,
                                  height:
                                      MediaQuery.of(context).size.width / 35,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.width /
                                            150),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Icon(
                                        Icons.print,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        "PDF",
                                        style: TextStyle(
                                            fontFamily: "B",
                                            color: Colors.white,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                90),
                                      ),
                                    ],
                                  )),
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
                      return Center(child: CircularProgressIndicator());
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
