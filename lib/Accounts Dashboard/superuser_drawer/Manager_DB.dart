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
      print('Sync successful!');
    } else {
      print('Failed to sync!');
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
