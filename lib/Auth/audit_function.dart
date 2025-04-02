import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

Future<String> getIPAddress() async {
  try {
    final response = await http.get(Uri.parse('https://api64.ipify.org'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "Unknown IP";
    }
  } catch (e) {
    return "Unknown IP";
  }
}

Future<void> logAuditTrail(String action, String details) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // Ensure user is logged in

  // Query Firestore to get the user document by UID
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('uid', isEqualTo: user.uid)
      .limit(1)
      .get();

  String fullName = "Unknown User";
  String role = "user"; // Default role if not found

  if (querySnapshot.docs.isNotEmpty) {
    var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
    fullName =
        "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();
    role = userData.containsKey('roles') ? userData['roles'] : "user"; // Check if 'roles' exists
  }

  String ipAddress = await getIPAddress(); // Fetch IP address

  await FirebaseFirestore.instance.collection('audit_logs').add({
    'userId': user.uid,
    'fullName': fullName,
    'role': role, // ✅ Added role field
    'action': action,
    'timestamp': FieldValue.serverTimestamp(),
    'details': details,
    'ipAddress': ipAddress, // Store user's IP address
  });
}

Future<List<Map<String, dynamic>>> getAuditLogsByName(String name) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('audit_logs')
        .orderBy('fullName') // Ensure Firestore index on fullName
        .get();

    // Convert Firestore docs to a List
    List<Map<String, dynamic>> logs = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Filter manually to support "contains" search (case-insensitive)
    List<Map<String, dynamic>> filteredLogs = logs.where((log) {
      String fullName = log['fullName'].toString().toLowerCase();
      return fullName.contains(name.toLowerCase());
    }).toList();

    return filteredLogs;
  } catch (e) {
    print("❌ Error fetching audit logs: $e");
    return [];
  }
}

