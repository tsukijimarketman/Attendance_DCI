import 'dart:async';

import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_analytical_report/appointment_status_distribution.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_analytical_report/appointment_trends.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_analytical_report/attendance_trends.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_analytical_report/civil_status.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_analytical_report/gender_distribution.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_analytical_report/role_ristribution.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_analytical_report/age_distribution.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/status/manager_appointment_summary.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:flutter/material.dart' hide ReorderableList;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';

class InternalReports extends StatefulWidget {
  const InternalReports({super.key});

  @override
  State<InternalReports> createState() => _InternalReportsState();
}

// Data class for the report items
class ReportItemData {
  final String title;
  final Widget widget;
  final Key key;
  final bool isHorizontallyReorderable;

  ReportItemData(this.title, this.widget, this.key, {this.isHorizontallyReorderable = false});
}

// Data class for horizontal charts
class HorizontalChartData {
  final Widget widget;
  final Key key;

  HorizontalChartData(this.widget, this.key);
}

class _InternalReportsState extends State<InternalReports> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  
  // List of report items that can be reordered vertically
  late List<ReportItemData> _reportItems;

  // Lists for horizontally reorderable charts
  late List<HorizontalChartData> _departmentStatusCharts;
  late List<HorizontalChartData> _roleAgeCharts;
  late List<HorizontalChartData> _genderCivilStatusCharts;

  @override
  void initState() {
    super.initState();
    // Get current user
    currentUser = _auth.currentUser;
    
    // Initialize horizontal charts
    _initHorizontalCharts();
    
    // Initialize report items
    _initReportItems();
  }
  
  void _initHorizontalCharts() {
    // Department and Status Charts
    _departmentStatusCharts = [
      HorizontalChartData(
        Builder(
          builder: (context) {
            double width = MediaQuery.of(context).size.width;
            return Container(
              width: width / 2.5,
              height: width / 4,
              child: AppointmentStatusPieChart(),
            );
          }
        ),
        ValueKey('status_chart')
      ),
    ];
    
    // Role and Age Charts
    _roleAgeCharts = [
      HorizontalChartData(
        Builder(
          builder: (context) {
            double width = MediaQuery.of(context).size.width;
            return Container(
              width: width / 2.5,
              height: width / 4,
              child: RoleDistributionPieChart(),
            );
          }
        ),
        ValueKey('role_chart')
      ),
      HorizontalChartData(
        Builder(
          builder: (context) {
            double width = MediaQuery.of(context).size.width;
            return Container(
              width: width / 2.5,
              height: width / 4,
              child: AgeDistributionChart(),
            );
          }
        ),
        ValueKey('age_chart')
      ),
    ];
    
    // Gender and Civil Status Charts
    _genderCivilStatusCharts = [
      HorizontalChartData(
        Builder(
          builder: (context) {
            double width = MediaQuery.of(context).size.width;
            return Container(
              width: width / 2.5,
              height: width / 4,
              child: GenderDistributionPieChart(),
            );
          }
        ),
        ValueKey('gender_chart')
      ),
      HorizontalChartData(
        Builder(
          builder: (context) {
            double width = MediaQuery.of(context).size.width;
            return Container(
              width: width / 2.5,
              height: width / 4,
              child: CivilStatusPieChart(),
            );
          }
        ),
        ValueKey('civil_status_chart')
      ),
    ];
  }
  
  void _initReportItems() {
    _reportItems = [
      // Vertical reorderable items
   
      ReportItemData(
        "Appointment Status", 
        ManagerAppointmentStatus(), 
        ValueKey('appointment_status')
      ),
      
    ];
  }

  // Returns index of item with given key for vertical reordering
  int _indexOfKey(Key key) {
    return _reportItems.indexWhere((ReportItemData item) => item.key == key);
  }

  // Handle reordering of vertical items
  bool _reorderCallback(Key item, Key newPosition) {
    int draggingIndex = _indexOfKey(item);
    int newPositionIndex = _indexOfKey(newPosition);

    final draggedItem = _reportItems[draggingIndex];
    setState(() {
      _reportItems.removeAt(draggingIndex);
      _reportItems.insert(newPositionIndex, draggedItem);
    });
    return true;
  }

  void _reorderDone(Key item) {
    // You can add additional logic here after reordering is done
  }
  
  // Handle reordering of horizontal charts
  
  void _reorderHorizontalCharts(String listName, int oldIndex, int newIndex) {
    setState(() {
      if (listName == 'department_status') {
        final item = _departmentStatusCharts.removeAt(oldIndex);
        _departmentStatusCharts.insert(newIndex, item);
      } else if (listName == 'role_age') {
        final item = _roleAgeCharts.removeAt(oldIndex);
        _roleAgeCharts.insert(newIndex, item);
      } else if (listName == 'gender_civil') {
        final item = _genderCivilStatusCharts.removeAt(oldIndex);
        _genderCivilStatusCharts.insert(newIndex, item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        return Scaffold(
          body: Container(
            width: width,
            color: Color(0xFFf2edf3),
            child: ReorderableList(
              onReorder: _reorderCallback,
              onReorderDone: _reorderDone,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: width / 40, vertical: width / 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dashboard",
                              style: TextStyle(
                                  fontSize: width / 37,
                                  fontFamily: "BL",
                                  color: Color.fromARGB(255, 11, 55, 99))),
                          Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color.fromARGB(255, 11, 55, 99),
                                        width: 2))),
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: width / 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return ReportItem(
                            data: _reportItems[index],
                            isFirst: index == 0,
                            isLast: index == _reportItems.length - 1,
                            width: width,
                          );
                        },
                        childCount: _reportItems.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
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

// Widget for horizontally reorderable charts
class HorizontalReorderableCharts extends StatelessWidget {
  final List<HorizontalChartData> charts;
  final Function(String, int, int) onReorder;
  final GlobalKey listKey;
  final String listName;

  const HorizontalReorderableCharts({
    Key? key,
    required this.charts,
    required this.onReorder,
    required this.listKey,
    required this.listName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ReorderableListView.builder(
        key: listKey,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: charts.length,
        itemBuilder: (context, index) {
          final chart = charts[index];
          return HorizontalChartItem(
            key: chart.key,
            child: chart.widget,
          );
        },
        onReorder: (oldIndex, newIndex) {
          // Fix for ReorderableListView's bug where newIndex might be one off
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          onReorder(listName, oldIndex, newIndex);
        },
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(animation.value);
              final double elevation = lerpDouble(0, 6, animValue)!;
              return Material(
                elevation: elevation,
                color: Colors.transparent,
                shadowColor: Colors.black.withOpacity(0.3),
                child: child,
              );
            },
            child: child,
          );
        },
      ),
      height: MediaQuery.of(context).size.width / 3.2,
    );
  }
  
  // Helper function to interpolate between double values
  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

// Horizontal chart item
class HorizontalChartItem extends StatelessWidget {

  final Widget child;

  const HorizontalChartItem({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(right: width/90),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width/120),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(width/120),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportItem extends StatelessWidget {
  const ReportItem({
    Key? key,
    required this.data,
    required this.isFirst,
    required this.isLast,
    required this.width,
  }) : super(key: key);

  final ReportItemData data;
  final bool isFirst;
  final bool isLast;
  final double width;

  Widget _buildChild(BuildContext context, ReorderableItemState state) {
    // Define decoration based on the state
    BoxDecoration decoration;

    if (state == ReorderableItemState.dragProxy ||
        state == ReorderableItemState.dragProxyFinished) {
      // Slightly transparent background while dragging
      decoration = BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      );
    } else {
      bool placeholder = state == ReorderableItemState.placeholder;
      decoration = BoxDecoration(
        color: placeholder ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: placeholder 
            ? [] 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
      );
    }

    // Drag handle widget
    Widget dragHandle = ReorderableListener(
      child: Container(
        padding: EdgeInsets.all(width/120),
        child: Icon(
          Icons.drag_indicator_rounded, 
          color: Color.fromARGB(255, 11, 55, 99),
        ),
      ).showCursorOnHover,
    );

    return Container(
      margin: EdgeInsets.only(bottom: width / 40),
      child: Opacity(
        // Hide content for placeholder
        opacity: state == ReorderableItemState.placeholder ? 0.0 : 1.0,
        child: Container(
          decoration: decoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and drag handle
              Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 11, 55, 99).withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(width/120),
                    topRight: Radius.circular(width/120),
                  ),
                ),
                child: Row(
                  children: [
                    dragHandle,
                    Expanded(
                      child: Text(
                        data.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 11, 55, 99),
                          fontSize: width / 80,  // Customize font size here
                          fontFamily: "B",  // Customize font family here
                        ),
                      ),
                    ),
                    if (data.isHorizontallyReorderable)
                      Container(
                        padding: EdgeInsets.all(width/120),
                        child: Row(
                          children: [
                            Icon(
                              Icons.swap_horiz, 
                              color: Color.fromARGB(255, 11, 55, 99),
                              size: width / 80,
                            ),
                            SizedBox(width: width/160),
                            Text(
                              "Horizontally reorderable",
                              style: TextStyle(
                                color: Color.fromARGB(255, 11, 55, 99),
                                fontSize: width / 100,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Content widget
              Padding(
                padding: EdgeInsets.all(width/100),
                child: data.widget,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(
      key: data.key,
      childBuilder: _buildChild,
    );
  }
}