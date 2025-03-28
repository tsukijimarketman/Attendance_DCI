import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> logAuditTrail(String action, String details) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // Ensure user is logged in

  // Query Firestore to get the user document by email
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('uid', isEqualTo: user.uid) // Search by email
      .limit(1)
      .get();

  String fullName = "Unknown User";
  if (querySnapshot.docs.isNotEmpty) {
    var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
    fullName = "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();
  }

  await FirebaseFirestore.instance.collection('audit_logs').add({
    'userId': user.uid,
    'fullName': fullName, // Store user's full name
    'action': action,
    'timestamp': FieldValue.serverTimestamp(),
    'details': details,
  });
}
