import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminAudit extends StatefulWidget {
  const AdminAudit({super.key});

  @override
  State<AdminAudit> createState() => _AdminAuditState();
}

class _AdminAuditState extends State<AdminAudit> {
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
          .where("uid", isEqualTo: uid)  // Match UID field
          .limit(1) // Expecting one result
          .get();

      
      if (userQuery.docs.isNotEmpty) {
        var userDoc = userQuery.docs.first; // Get the first document
        String fetchedFullName = "${userDoc["first_name"]} ${userDoc["last_name"]}";
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

Future<List<Map<String, dynamic>>> fetchAuditLogsByUser(String uid, String fullName) async {
  try {
    print("🔎 Fetching logs for: UserID=$uid, FullName=$fullName");

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("audit_logs")
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

  
  @override
  Widget build(BuildContext context) {
    return Expanded(
  child: Padding(
    padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
    child: Container(
      color: Colors.blue.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed Header Row
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
            color: Colors.blue.shade300, // Slightly darker shade for contrast
            child: Row(
              children: [
                Expanded(child: Text("Date & Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Expanded(child: Text("Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Expanded(child: Text("Action", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Expanded(child: Text("Action Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
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

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    var log = logs[index];
                    return Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black12)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(log["timestamp"] != null 
                            ? DateTime.fromMillisecondsSinceEpoch(
                                log["timestamp"].millisecondsSinceEpoch).toString() 
                            : "No Timestamp")),
                          Expanded(child: Text(log["fullName"] ?? "Unknown Name")),
                          Expanded(child: Text(log["action"] ?? "Unknown Action")),
                          Expanded(child: Text(log["details"] ?? "No Details")),
                        ],
                      ),
                    );
                  },
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