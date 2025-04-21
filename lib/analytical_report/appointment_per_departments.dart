import 'dart:async';
import 'package:attendance_app/analytical_report/presentation/resources/app_resources.dart';
import 'package:attendance_app/analytical_report/util/extensions/color_extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentsPerDepartmentChart extends StatefulWidget {
  const AppointmentsPerDepartmentChart({super.key});

  @override
  State<StatefulWidget> createState() => AppointmentsPerDepartmentChartState();
}

class AppointmentsPerDepartmentChartState extends State<AppointmentsPerDepartmentChart> {
  final Color barColor = Color.fromARGB(255, 11, 55, 99);
  int touchedIndex = -1;
  
  // Department data will be loaded from Firestore
  Map<String, int> departmentAppointments = {};
  bool isLoading = true;
  String error = '';
  
  // Stream subscription for Firestore updates
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;

  // List of all departments to show, even if they have 0 appointments
  final List<String> allDepartments = [
    'QMS', 'IQA', 'PMD', 'HRA', 'BD', 'ACCT', 'ITO', 'ADM', 
    'TID', 'PI', 'LC', 'CA', 'CS', 'CPD'
  ];

  // Mapping between full department names and abbreviations
  final Map<String, String> departmentAbbreviations = {
    'Quality Management System': 'QMS',
    'Internal Quality Audit': 'IQA',
    'Project Management Department': 'PMD',
    'Human Resources Admin': 'HRA',
    'Business Development': 'BD',
    'Accounting': 'ACCT',
    'IT Operations': 'ITO',
    'Admin Operations': 'ADM',
    'Technology & Innovations': 'TID',
    'Project Implementation': 'PI',
    'Legal and Compliance': 'LC',
    'Corporate Affairs': 'CA',
    'Customer Service': 'CS',
    'Corporate Planning & Development': 'CPD',
  };

  // Tooltip for showing department full names when needed
  final Map<String, String> departmentFullNames = {
    'QMS': 'Quality Management System',
    'IQA': 'Internal Quality Audit',
    'PMD': 'Project Management Department',
    'HRA': 'Human Resources Admin',
    'BD': 'Business Development',
    'ACCT': 'Accounting',
    'ITO': 'IT Operations',
    'ADM': 'Admin Operations',
    'TID': 'Technology & Innovations',
    'PI': 'Project Implementation',
    'LC': 'Legal and Compliance',
    'CA': 'Corporate Affairs',
    'CS': 'Customer Service',
    'CPD': 'Corporate Planning & Development',
  };

  @override
  void initState() {
    super.initState();
    subscribeToAppointments();
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  // Subscribe to Firestore updates
  void subscribeToAppointments() {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      _appointmentsSubscription = FirebaseFirestore.instance
          .collection('appointment')
          .snapshots()
          .listen((snapshot) {
        processAppointmentData(snapshot);
      }, onError: (e) {
        setState(() {
          error = 'Error: $e';
          isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        error = 'Failed to subscribe: $e';
        isLoading = false;
      });
    }
  }

  // Process appointment data and update the state
  void processAppointmentData(QuerySnapshot snapshot) {
    try {
      // Initialize counters for all departments with zero
      Map<String, int> counts = {};
      for (String dept in allDepartments) {
        counts[dept] = 0;
      }
      
      // Count appointments by department
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String? department = data['department'] as String?;
        
        if (department != null && department.isNotEmpty) {
          // Convert full department name to abbreviation if needed
          String deptAbbrev = departmentAbbreviations[department] ?? department;
          
          // Make sure the abbreviation is one of our known departments
          if (allDepartments.contains(deptAbbrev)) {
            counts[deptAbbrev] = (counts[deptAbbrev] ?? 0) + 1;
          }
        }
      }
      
      setState(() {
        departmentAppointments = counts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error processing data: $e';
        isLoading = false;
      });
    }
  }

  // Update touchedIndex without rebuilding the whole widget
  void updateTouchedIndex(int? index) {
    touchedIndex = index ?? -1;
    // This setState is isolated from the data update
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Color(0xFFc0dcf7),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center( 
                child: Text(
                  'Appointments Per Department',
                  style: TextStyle(
                    color: Color.fromARGB(255, 11, 55, 99),
                    fontSize: MediaQuery.of(context).size.width/80,
                    fontFamily: "SB",
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.width/80),
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else
                Expanded(
                  child: BarChart(
                    BarChartData(
                      barTouchData: barTouchData,
                      titlesData: titlesData,
                      borderData: borderData,
                      barGroups: barGroups,
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: horizontalGridLine,
                      ),
                      alignment: BarChartAlignment.spaceAround,
                      maxY: getMaxY(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Get maximum Y value plus some padding
  double getMaxY() {
    if (departmentAppointments.isEmpty) return 10;
    double max = departmentAppointments.values.fold(0, (max, value) => value > max ? value : max).toDouble();
    return max > 0 ? max * 1.2 : 10;
  }

  // Bar touch data configuration - optimized to prevent excessive rebuilds
  BarTouchData get barTouchData => BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String departmentAbbrev = allDepartments[group.x];
            return BarTooltipItem(
              '${departmentFullNames[departmentAbbrev] ?? departmentAbbrev}\n${rod.toY.round()} appointments',
              TextStyle(
                color: Colors.white,
                fontFamily: "B"
              ),
            );
          },
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          if (!event.isInterestedForInteractions ||
              barTouchResponse == null ||
              barTouchResponse.spot == null) {
            if (touchedIndex != -1) {
              updateTouchedIndex(-1);
            }
            return;
          }
          
          int newIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          if (touchedIndex != newIndex) {
            updateTouchedIndex(newIndex);
          }
        },
      );

  // Grid line configuration
  static FlLine horizontalGridLine(double value) {
    return FlLine(
      color: AppColors.borderColor.withOpacity(0.1),
      strokeWidth: 1,
    );
  }

  // Border configuration
  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor.withOpacity(0.2), width: 1),
          left: BorderSide(color: AppColors.borderColor.withOpacity(0.2), width: 1),
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      );

  // Titles configuration
  FlTitlesData get titlesData => FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: bottomTitles,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: leftTitles,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      );

  // Bottom titles widget - display department abbreviations
  Widget bottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= allDepartments.length) {
      return const SizedBox.shrink();
    }
    
    final style = TextStyle(
      color: touchedIndex == index ? Color.fromARGB(255, 11, 55, 99).darken(20) : Color.fromARGB(255, 11, 55, 99),
      fontWeight: touchedIndex == index ? FontWeight.bold : FontWeight.normal,
      fontSize: 10,
    );
    
    final text = allDepartments[index];
    
    return SideTitleWidget(
      meta: meta,
      space: 5,
      child: Transform.rotate(
        angle: 0.5, // Slight angle to make text more readable when crowded
        child: Text(
          text,
          style: style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Left titles widget
  Widget leftTitles(double value, TitleMeta meta) {
    if (value % 5 != 0) {
      return Container();
    }
    
    final style = TextStyle(
      fontSize: MediaQuery.of(context).size.width/120,
      color: Color.fromARGB(255, 11, 55, 99),
    );
    
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toInt().toString(),
        style: style,
      ),
    );
  }

  // Generate bar groups
  List<BarChartGroupData> get barGroups {
    return List.generate(
      allDepartments.length,
      (index) {
        final deptAbbrev = allDepartments[index];
        final count = departmentAppointments[deptAbbrev] ?? 0;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: touchedIndex == index 
                  ? Color.fromARGB(255, 11, 55, 99) 
                  : Color.fromARGB(255, 11, 55, 99).withOpacity(0.7),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}