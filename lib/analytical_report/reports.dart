import 'package:attendance_app/analytical_report/summary%20cards/summary_cards.dart';
import 'package:flutter/material.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        return Scaffold(
          body: SingleChildScrollView(
            child: Container(
              width: width,
              padding: EdgeInsets.all(width / 40),
              color: Color(0xFFf2edf3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dashboard",
                      style: TextStyle(
                          fontSize: width / 37,
                          fontFamily: "BL",
                          color: Color.fromARGB(255, 11, 55, 99))),
                  SizedBox.shrink(),
                  Text("View and analyze reports of attendance and other data",
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
                  SizedBox(
                    height: width / 70,
                  ),
                  Text("Summary Cards",
                      style: TextStyle(
                          fontSize: width / 55,
                          fontFamily: "SB",
                          color: Colors.black)),
                  SizedBox(height: width / 120),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: width / 4.6,
                        height: width / 9.5,
                        padding: EdgeInsets.all(width / 80),
                        decoration: BoxDecoration(
                          color: Color(0xFF7dc2fc),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Users",
                              style: TextStyle(
                                fontSize: width / 80,
                                fontFamily: "SB",
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.groups_2_rounded,
                                  color: Color(0xFF0354A1),
                                  size: width / 17,
                                ),
                                SizedBox(width: width / 80),
                                Text(
                                  "1000",
                                  style: TextStyle(
                                    fontSize: width / 40,
                                    fontFamily: "SB",
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Container(
                        width: width / 4.6,
                        height: width / 9.5,
                        padding: EdgeInsets.all(width / 80),
                        decoration: BoxDecoration(
                          color: Color(0xFF7dc2fc),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pending Approvals",
                              style: TextStyle(
                                fontSize: width / 80,
                                fontFamily: "SB",
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  Icons.pending_actions_rounded,
                                  color: Color(0xFF0354A1),
                                  size: width / 17,
                                ),
                                SizedBox(width: width / 80),
                                Text(
                                  "1000",
                                  style: TextStyle(
                                    fontSize: width / 40,
                                    fontFamily: "SB",
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Container(
                        width: width / 4.6,
                        height: width / 9.5,
                        padding: EdgeInsets.all(width / 80),
                        decoration: BoxDecoration(
                          color: Color(0xFF7dc2fc),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Attendance Rate",
                              style: TextStyle(
                                fontSize: width / 80,
                                fontFamily: "SB",
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF0354A1),
                                  size: width / 17,
                                ),
                                SizedBox(width: width / 80),
                                Text(
                                  "100%",
                                  style: TextStyle(
                                    fontSize: width / 40,
                                    fontFamily: "SB",
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: width / 4.6,
                        height: width / 9.5,
                        padding: EdgeInsets.all(width / 80),
                        decoration: BoxDecoration(
                          color: Color(0xFF7dc2fc),
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
                                  "100",
                                  style: TextStyle(
                                    fontSize: width / 40,
                                    fontFamily: "SB",
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: width / 40),
                  Container(
                    width: width,
                    height: width / 3.5,
                    padding: EdgeInsets.all(width / 50),
                    decoration: BoxDecoration(
                      color: Color(0xFFBADDFB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Appointment Summary",
                          style: TextStyle(
                            fontSize: width / 80,
                            fontFamily: "SB",
                          ),
                        ),
                        SizedBox(height: width / 80),
                        Container(
                          width: width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: width / 5.6,
                                height: width / 9.5,
                                padding: EdgeInsets.all(width / 80),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Appointments",
                                      style: TextStyle(
                                        fontSize: width / 80,
                                        fontFamily: "SB",
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          color: Color(0xFF0354A1),
                                          size: width / 17,
                                        ),
                                        SizedBox(width: width / 80),
                                        Text(
                                          "100",
                                          style: TextStyle(
                                            fontSize: width / 40,
                                            fontFamily: "SB",
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: width / 5.6,
                                height: width / 9.5,
                                padding: EdgeInsets.all(width / 80),
                                decoration: BoxDecoration(
                                  color: Color(0xFF7dc2fc),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Appointments",
                                      style: TextStyle(
                                        fontSize: width / 80,
                                        fontFamily: "SB",
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          color: Color(0xFF0354A1),
                                          size: width / 17,
                                        ),
                                        SizedBox(width: width / 80),
                                        Text(
                                          "100",
                                          style: TextStyle(
                                            fontSize: width / 40,
                                            fontFamily: "SB",
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: width / 5.6,
                                height: width / 9.5,
                                padding: EdgeInsets.all(width / 80),
                                decoration: BoxDecoration(
                                  color: Color(0xFF7dc2fc),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Appointments",
                                      style: TextStyle(
                                        fontSize: width / 80,
                                        fontFamily: "SB",
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          color: Color(0xFF0354A1),
                                          size: width / 17,
                                        ),
                                        SizedBox(width: width / 80),
                                        Text(
                                          "100",
                                          style: TextStyle(
                                            fontSize: width / 40,
                                            fontFamily: "SB",
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: width / 5.6,
                                height: width / 9.5,
                                padding: EdgeInsets.all(width / 80),
                                decoration: BoxDecoration(
                                  color: Color(0xFF7dc2fc),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Appointments",
                                      style: TextStyle(
                                        fontSize: width / 80,
                                        fontFamily: "SB",
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          color: Color(0xFF0354A1),
                                          size: width / 17,
                                        ),
                                        SizedBox(width: width / 80),
                                        Text(
                                          "100",
                                          style: TextStyle(
                                            fontSize: width / 40,
                                            fontFamily: "SB",
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
