import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KeyMetrics extends StatefulWidget {
  const KeyMetrics({super.key});

  @override
  State<KeyMetrics> createState() => _KeyMetricsState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class _KeyMetricsState extends State<KeyMetrics> {
  String departmentName = "Loading...";
  String currentUserDeptId = "";
  String currentUserId = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getCurrentUserDepartment();
  }

  // Method to get current user department
  Future<void> getCurrentUserDepartment() async {
    try {
      print("Starting getCurrentUserDepartment()"); // Debug print
      
      // Get current user from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        print("No current user found"); // Debug print
        setState(() {
          isLoading = false;
          departmentName = "Your Department"; // Generic name
        });
        return;
      }
      
      print("Current user ID: ${currentUser.uid}"); // Debug print
      
      // Store the current user ID for later use
      setState(() {
        currentUserId = currentUser.uid;
      });
      
      // ALTERNATIVE APPROACH: Query by uid field instead of document ID
      try {
        final userQuerySnapshot = await _firestore
            .collection('users')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        
        if (userQuerySnapshot.docs.isNotEmpty) {
          final userData = userQuerySnapshot.docs.first.data();
          print("Found user document via uid field query");
          
          // Print all fields for debugging
          print("All user data fields: ${userData.keys.join(', ')}");
          userData.forEach((key, value) {
            print("Field: $key, Value: $value");
          });
          
          final deptId = userData['deptID'] as String?;
          
          print("Retrieved deptID: $deptId"); // Debug print
          
          if (deptId != null && deptId.isNotEmpty) {
            setState(() {
              currentUserDeptId = deptId;
              departmentName = "Department $deptId"; // Just use the ID as part of the name
            });
            return; // Exit if we found it this way
          }
        } else {
          print("No user found via uid field query");
        }
      } catch (e) {
        print("Error querying by uid field: $e");
      }
      
      // Original approach: try getting by document ID
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (userDoc.exists) {
        // Extract the department ID
        final userData = userDoc.data()!; // Use ! since we already checked exists
        
        // Print all fields for debugging
        print("All user data fields: ${userData.keys.join(', ')}");
        userData.forEach((key, value) {
          print("Field: $key, Value: $value");
        });
        
        final deptId = userData['deptID'] as String?;
        
        print("Retrieved deptID: $deptId"); // Debug print
        
        if (deptId != null && deptId.isNotEmpty) {
          setState(() {
            currentUserDeptId = deptId;
            departmentName = "Department $deptId"; // Just use the ID as part of the name
          });
        } else {
          print("No department ID found for user"); // Debug print
          setState(() {
            departmentName = "Your Department";
          });
        }
      } else {
        print("User document does not exist"); // Debug print
        setState(() {
          departmentName = "Your Department";
        });
      }
    } catch (e) {
      print("Error getting department: $e");
      setState(() {
        departmentName = "Your Department";
      });
    } finally {
      // Always set isLoading to false when the operation completes
      print("Finishing getCurrentUserDepartment()"); // Debug print
      setState(() {
        isLoading = false;
      });
    }
  }

  // Updated method to get department-filtered appointments stream
  Stream<QuerySnapshot> getAppointmentsStream() {
    // If we have a department ID, filter by department
    if (currentUserDeptId.isNotEmpty) {
      print("Filtering appointments by deptID: $currentUserDeptId"); // Debug print
      return _firestore
          .collection('appointment')
          .where('deptID', isEqualTo: currentUserDeptId)
          .snapshots();
    } else {
      // Fallback to all appointments if department ID isn't available
      print("No deptID available, showing all appointments"); // Debug print
      return _firestore.collection('appointment').snapshots();
    }
  }

  Stream<QuerySnapshot> getUsersInDepartmentStream() {
    // If we have a department ID, filter by both status and department
    if (currentUserDeptId.isNotEmpty) {
      print("Querying for deptID: $currentUserDeptId"); // Debug print
      return _firestore
          .collection('users')
          .where('status', isEqualTo: 'active')
          .where('deptID', isEqualTo: currentUserDeptId)
          .where('isDeleted', isEqualTo: false) // Add this filter for active users only
          .snapshots();
    } else {
      // Fallback to just active users if department ID isn't available
      return _firestore
          .collection('users')
          .where('status', isEqualTo: 'active')
          .where('isDeleted', isEqualTo: false)
          .snapshots();
    }
  }
  
  // Get the current authenticated user
  User? get currentAuthUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: getUsersInDepartmentStream(),
          builder: (context, snapshot) {
            // Show loading state only until we have both department info and user data
            if (isLoading) {
              return buildLoadingUserCard(width);
            }
            
            // Check connection state separately
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildLoadingUserCard(width);
            }
        
            // Check for errors
            if (snapshot.hasError) {
              return buildErrorUserCard(width);
            }
        
            // Get the total count of users in department, excluding current user
            int totalUsers = 0;
            if (snapshot.hasData) {
              // For debugging only
              print("Total docs returned: ${snapshot.data!.docs.length}");
              snapshot.data!.docs.forEach((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                print("User ID: ${doc.id}, deptID: ${data['deptID']}, status: ${data['status']}");
              });
              
              // Count only users with:
              // 1. The same department ID as current user
              // 2. Not the current user
              // 3. Status is active
              totalUsers = snapshot.data!.docs
                  .where((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return doc.id != currentUserId && 
                           data['deptID'] == currentUserDeptId &&
                           data['status'] == 'active';
                  })
                  .length;
              
              // Should be 3 in your case (4 total - 1 current user)
              print("Current user ID: $currentUserId");
              print("Current dept ID: $currentUserDeptId");
              print("Calculated total users in dept: $totalUsers");
            }
        
            return Container(
              width: width / 5.6,
              height: width / 9.5,
              padding: EdgeInsets.all(width / 80),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4), // X, Y
                  ),
                ],
                color: Colors.white,
                borderRadius: BorderRadius.circular(width / 120),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Users in Department",
                    style: TextStyle(
                      fontSize: width / 80,
                      fontFamily: "SB",
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.groups_2_rounded,
                        color: Color(0xFF0354A1),
                        size: width / 17,
                      ),
                      SizedBox(width: width / 80),
                      Text(
                        totalUsers.toString(),
                        style: TextStyle(
                          fontSize: width / 40,
                          fontFamily: "SB",
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ).moveUpOnHover;
          },
        ),
        
        StreamBuilder<QuerySnapshot>(
          stream: getAppointmentsStream(),
          builder: (context, snapshot) {
            // Check connection state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildLoadingAppointmentCard(width);
            }
        
            // Check for errors
            if (snapshot.hasError) {
              return buildErrorAppointmentCard(width);
            }
        
            // Get the total count of appointments in the user's department
            int totalAppointments = 0;
            if (snapshot.hasData) {
              // For debugging only
              print("Total appointment docs returned: ${snapshot.data!.docs.length}");
              snapshot.data!.docs.forEach((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                print("Appointment ID: ${doc.id}, deptID: ${data['deptID']}");
              });
              
              // Count appointments for this department
              totalAppointments = snapshot.data!.docs.length;
              
              print("Total appointments for deptID $currentUserDeptId: $totalAppointments");
            }
        
            return Container(
              width: width / 5.6,
              height: width / 9.5,
              padding: EdgeInsets.all(width / 80),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4), // X, Y
                  ),
                ],
                borderRadius: BorderRadius.circular(width / 120),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Appointments",
                    style: TextStyle(
                      fontSize: width / 80,
                      fontFamily: "SB",
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF0354A1),
                        size: width / 17,
                      ),
                      SizedBox(width: width / 80),
                      Text(
                        totalAppointments.toString(),
                        style: TextStyle(
                          fontSize: width / 40,
                          fontFamily: "SB",
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ).moveUpOnHover;
          },
        ),
      ],
    );
  }
}

// Helper method for loading state
Widget buildLoadingUserCard(double width) {
  return Container(
    width: width / 5.6,
    height: width / 9.5,
    padding: EdgeInsets.all(width / 80),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(width / 120),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(0, 4), // X, Y
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Users in Department",
          style: TextStyle(
            fontSize: width / 80,
            fontFamily: "SB",
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              Icons.groups_2_rounded,
              color: Color(0xFF0354A1),
              size: width / 17,
            ),
            SizedBox(width: width / 80),
            SizedBox(
              width: width / 15,
              height: width / 40,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.grey,
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        )
      ],
    ),
  ).moveUpOnHover;
}

// Helper method for error state
Widget buildErrorUserCard(double width) {
  return Container(
    width: width / 5.6,
    height: width / 9.5,
    padding: EdgeInsets.all(width / 80),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(width / 120),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(0, 4), // X, Y
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Users in Department",
          style: TextStyle(
            fontSize: width / 80,
            fontFamily: "SB",
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              Icons.groups_2_rounded,
              color: Color(0xFF0354A1),
              size: width / 17,
            ),
            SizedBox(width: width / 80),
            Text(
              "Error",
              style: TextStyle(
                fontSize: width / 40,
                fontFamily: "SB",
                color: Colors.black,
              ),
            ),
          ],
        )
      ],
    ),
  ).moveUpOnHover;
}

// Helper methods for appointments
Widget buildLoadingAppointmentCard(double width) {
  return Container(
    width: width / 5.6,
    height: width / 9.5,
    padding: EdgeInsets.all(width / 80),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(0, 4), // X, Y
        ),
      ],
      borderRadius: BorderRadius.circular(width / 120),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Appointments",
          style: TextStyle(
            fontSize: width / 80,
            fontFamily: "SB",
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF0354A1),
              size: width / 17,
            ),
            SizedBox(width: width / 80),
            SizedBox(
              width: width / 15,
              height: width / 40,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.grey,
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        )
      ],
    ),
  ).moveUpOnHover;
}

Widget buildErrorAppointmentCard(double width) {
  return Container(
    width: width / 5.6,
    height: width / 9.5,
    padding: EdgeInsets.all(width / 80),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(0, 4), // X, Y
        ),
      ],
      borderRadius: BorderRadius.circular(width / 120),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Appointments",
          style: TextStyle(
            fontSize: width / 80,
            fontFamily: "SB",
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF0354A1),
              size: width / 17,
            ),
            SizedBox(width: width / 80),
            Text(
              "Error",
              style: TextStyle(
                fontSize: width / 40,
                fontFamily: "SB",
                color: Colors.black,
              ),
            ),
          ],
        )
      ],
    ),
  ).moveUpOnHover;
}