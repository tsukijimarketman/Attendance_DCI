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
  if (querySnapshot.docs.isNotEmpty) {
    var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
    fullName = "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();
  }

  String ipAddress = await getIPAddress(); // Fetch IP address

  await FirebaseFirestore.instance.collection('audit_logs').add({
    'userId': user.uid,
    'fullName': fullName,
    'action': action,
    'timestamp': FieldValue.serverTimestamp(),
    'details': details,
    'ipAddress': ipAddress, // Store user's IP address
  });
}
