import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// This function logs user actions to the Firestore database
/// It captures the user's ID, full name, role, action performed, timestamp, details of the action, and IP address.
/// It uses Firebase Authentication to get the current user and Firestore to store the logs.
/// The function also fetches the user's IP address using a public API.

// Function to fetch the user's IP address
Future<String> getIPAddress() async {
  // Using a public API to get the IP address
  try {
    // Make a GET request to the API
    // This API returns the public IP address of the client making the request
    final response = await http.get(Uri.parse('https://api64.ipify.org'));
    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      // Parse the response body to get the IP address
      // The response body is a plain text containing the IP address
      return response.body;
    } else {
      // If the request was not successful, return a default value
      return "Unknown IP";
    }
  } catch (e) {
    // If there was an error (e.g., network issue), return a default value
    return "Unknown IP";
  }
}

// Function to log audit trails
// This function logs user actions to the Firestore database
// It captures the user's ID, full name, role, action performed, timestamp, details of the action, and IP address
Future<void> logAuditTrail(String action, String details) async {
  // Get the current user from Firebase Authentication
  // This user object contains information about the logged-in user, including their UID
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // Ensure user is logged in

  // Query Firestore to get the user document by UID
  // This query fetches the user's document from the 'users' collection where the 'uid' field matches the current user's UID
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('uid', isEqualTo: user.uid)
      .limit(1)
      .get();

  String fullName = "Unknown User";
  String role = "user"; // Default role if not found

  // If the user document is found, extract the full name and role
  // The full name is constructed from the 'first_name' and 'last_name' fields in the user document
  if (querySnapshot.docs.isNotEmpty) {
    var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
    fullName =
        "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();
    role = userData.containsKey('roles')
        ? userData['roles']
        : "user"; // Check if 'roles' exists
  }

  // Fetch the user's IP address using the getIPAddress function
  String ipAddress = await getIPAddress(); // Fetch IP address

  // Log the audit trail to Firestore
  // This adds a new document to the 'audit_logs' collection with the user's ID, full name, role, action, timestamp, details, and IP address
  // The 'timestamp' field is set to the server's current timestamp using FieldValue.serverTimestamp()
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
