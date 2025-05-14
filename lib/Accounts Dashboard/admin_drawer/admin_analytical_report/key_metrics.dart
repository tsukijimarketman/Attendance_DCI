import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KeyMetrics extends StatefulWidget {
  const KeyMetrics({super.key});

  @override
  State<KeyMetrics> createState() => _KeyMetricsState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class _KeyMetricsState extends State<KeyMetrics> {
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').where('status', isEqualTo: 'active').where('isDeleted', isEqualTo: false).snapshots();
  }


  Stream<QuerySnapshot> getAppointmentsStream() {
    return _firestore.collection('appointment').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Total Users Card with StreamBuilder
        StreamBuilder<QuerySnapshot>(
          stream: getUsersStream(),
          builder: (context, snapshot) {
            // Check connection state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildLoadingUserCard(width);
            }
        
            // Check for errors
            if (snapshot.hasError) {
              return buildErrorUserCard(width);
            }
        
            // Get the total count of users
            int totalUsers = snapshot.data?.docs.length ?? 0;
        
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
                    "Total Active Users",
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
                        totalUsers
                            .toString(), // Display the actual count here
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
                      "Total Appointments",
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
              );
            }
        
            // Check for errors
            if (snapshot.hasError) {
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Appointments",
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
              );
            }
        
            // Get the total count of appointments
            int totalAppointments = snapshot.data?.docs.length ?? 0;
        
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
                    "Total Appointments",
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
                        totalAppointments
                            .toString(), // Display the actual count here
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
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total Active Users",
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
  );
}

// Helper method for error state
Widget buildErrorUserCard(double width) {
  return Container(
    width: width / 5.6,
    height: width / 9.5,
    padding: EdgeInsets.all(width / 80),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total Active Users",
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
  );
}


