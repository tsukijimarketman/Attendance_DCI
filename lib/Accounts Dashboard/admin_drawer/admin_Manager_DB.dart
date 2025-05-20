import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ManagerDB extends StatefulWidget {
  const ManagerDB({super.key});

  @override
  State<ManagerDB> createState() => _ManagerDBState();
}

class _ManagerDBState extends State<ManagerDB> {
    // The fetchFirestoreData method fetches data from multiple Firestore collections and returns it as a map.
  // It takes an optional 'lastSync' parameter, which is used to filter documents that have been updated after a specific timestamp.
  // The method iterates over a predefined list of collection names (appointment, attendance, audit_logs, categories, clients, and users).
  // For collections like appointment, attendance, and audit_logs, it filters the data based on the 'updatedAt' field to only fetch records
  // that have been modified since the provided lastSync timestamp. 
  // After fetching the data from each collection, the method processes each document by including the document ID and converting 
  // any Timestamp or DateTime fields to ISO8601 string format. Finally, the data is stored in a map, where the keys are collection names 
  // and the values are lists of processed documents, which are then returned.
  Future<Map<String, List<Map<String, dynamic>>>> fetchFirestoreData(
      DateTime? lastSync) async {
    final firestore = FirebaseFirestore.instance;

    List<String> collections = [
      'appointment',
      'attendance',
      'audit_logs',
      'categories',
      'clients',
      'users'
    ];

    Map<String, List<Map<String, dynamic>>> allData = {};

    for (String collectionName in collections) {
      Query query = firestore.collection(collectionName);
      if (lastSync != null &&
          ['appointment', 'attendance', 'audit_logs']
              .contains(collectionName)) {
        query = query.where('updatedAt',
            isGreaterThan: Timestamp.fromDate(lastSync));
      }

      QuerySnapshot snapshot = await query.get();

      allData[collectionName] = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Include the Firestore document ID
        data['id'] = doc.id;

        // Convert all Timestamps or DateTimes to ISO8601 strings
        data.forEach((key, value) {
          if (value is Timestamp) {
            data[key] = value.toDate().toIso8601String();
          } else if (value is DateTime) {
            data[key] = value.toIso8601String();
          }
        });

        return data;
      }).toList();
    }

    return allData;
  }

   // The syncToMongoDB method synchronizes data from Firestore to MongoDB via an API.
  // First, it retrieves the last sync timestamp from a server endpoint ('http://localhost:3000/last-sync'). 
  // If the timestamp is found and valid, it is parsed into a DateTime object; otherwise, the lastSync variable remains null.
  // Next, it calls the fetchFirestoreData method to retrieve the data from Firestore, optionally filtered by the last sync time.
  // The method then determines whether this is the first sync by checking if lastSync is null.
  // After fetching the data, the method sends the data to the server by making a POST request to 'http://localhost:3000/sync'.
  // The request includes whether it's the first sync and the Firestore data in the request body.
  // If the sync is successful (status code 200), a Snackbar with a success message is shown; otherwise, a failure message is displayed.
  Future<void> syncToMongoDB() async {
    final lastSyncRes =
        await http.get(Uri.parse('http://localhost:3000/last-sync'));
    DateTime? lastSync;

    if (lastSyncRes.statusCode == 200) {
      final decoded = jsonDecode(lastSyncRes.body);
      lastSync = decoded['lastSync'] != null
          ? DateTime.parse(decoded['lastSync'])
          : null;
    }

    final firestoreData = await fetchFirestoreData(lastSync);
    final isFirstTime = lastSync == null;

    final syncResponse = await http.post(
      Uri.parse('http://localhost:3000/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'isFirstTime': isFirstTime,
        'collections': firestoreData,
      }),
    );

    if (syncResponse.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync successful!"),));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to sync!"),));
  }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Padding(
        padding: EdgeInsets.all(width / 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Delete & Transfer",
                style: TextStyle(
                    fontSize: width / 30,
                    fontFamily: "BL",
                    color: Color.fromARGB(255, 11, 55, 99))),
            SizedBox.shrink(),
            Text("This will delete all data from Firestore and transfer it to MongoDB.",
                style: TextStyle(
                    fontSize: width / 70,
                    fontFamily: "M",
                    color: Colors.grey.withOpacity(0.7))),
                    Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color.fromARGB(255, 11, 55, 99),
                                        width: 2))),
                          ),
            Container(
              width: 450,
              height: 60,
              margin: EdgeInsets.only(top: width / 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(width / 50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 11, 55, 99),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // This will Triggered the syncToMongoDB it will reset the firestore and backup the data in the MongoDb
                  syncToMongoDB();
                },
                child: Text('Delete & Transfer to MongoDB',style: TextStyle(
                    fontSize: width / 90,
                    fontFamily: "M",
                    color: Colors.white)),
              ),
            ),
          ],
        ));
  }
}
