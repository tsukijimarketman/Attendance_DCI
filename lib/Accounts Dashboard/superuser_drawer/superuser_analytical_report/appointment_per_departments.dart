import 'dart:async';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/superuser_analytical_report/presentation/resources/app_resources.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/superuser_analytical_report/util/extensions/color_extensions.dart';
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
  Map<String, String> departmentFullNames = {};
  Map<String, String> departmentIds = {}; // Maps abbreviation to deptID
  
  bool isLoading = true;
  String error = '';
  
  // Stream subscriptions for Firestore updates
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;
  StreamSubscription<QuerySnapshot>? _departmentsSubscription;

  // List of department abbreviations
  List<String> departmentAbbreviations = [];

  @override
  void initState() {
    super.initState();
    // First load departments, then load appointments
    loadDepartments();
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _departmentsSubscription?.cancel();
    super.dispose();
  }

  // Load departments from references collection
  void loadDepartments() {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      _departmentsSubscription = FirebaseFirestore.instance
          .collection('references')
          .snapshots()
          .listen((snapshot) {
        processDepartmentData(snapshot);
      }, onError: (e) {
        setState(() {
          error = 'Error loading departments: $e';
          isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load departments: $e';
        isLoading = false;
      });
    }
  }

  // Process department data from Firestore
  void processDepartmentData(QuerySnapshot snapshot) {
    try {
      Map<String, String> fullNames = {};
      Map<String, String> deptIds = {};
      List<String> abbrevs = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? name = data['name'] as String?;
        final String? deptId = data['deptID'] as String?;
        final bool? isDeleted = data['isDeleted'] as bool?;
        
        // Skip deleted departments or those without names
        if (isDeleted == true || name == null || name.isEmpty || deptId == null) {
          continue;
        }
        
        // Generate abbreviation from the department name
        String abbrev = createAbbreviation(name);
        
        fullNames[abbrev] = name;
        deptIds[abbrev] = deptId;
        abbrevs.add(abbrev);
      }
      
      setState(() {
        departmentFullNames = fullNames;
        departmentIds = deptIds;
        departmentAbbreviations = abbrevs;
        
        // After loading departments, now load appointments
        if (departmentAbbreviations.isNotEmpty) {
          subscribeToAppointments();
        } else {
          isLoading = false;
          error = 'No departments found';
        }
      });
    } catch (e) {
      setState(() {
        error = 'Error processing departments: $e';
        isLoading = false;
      });
    }
  }

  // Create abbreviation from department name (3-4 characters)
  String createAbbreviation(String departmentName) {
    // Split the name into words
    List<String> words = departmentName.split(' ');
    
    if (words.isEmpty) return '';
    
    // For very short names (1-2 words), we might just use the first letters
    if (words.length <= 2) {
      String abbrev = '';
      for (var word in words) {
        if (word.isNotEmpty) {
          abbrev += word[0].toUpperCase();
        }
      }
      
      // If abbreviation is too short, add more letters from the first word
      if (abbrev.length < 3 && words[0].length >= 3) {
        abbrev = words[0].substring(0, 3).toUpperCase();
      }
      
      return abbrev;
    }
    
    // For longer names, take first letter of each main word
    String abbrev = '';
    for (var word in words) {
      // Skip small connecting words for abbreviation
      if (word.toLowerCase() != 'and' && 
          word.toLowerCase() != 'of' && 
          word.toLowerCase() != 'the' &&
          word.isNotEmpty) {
        abbrev += word[0].toUpperCase();
      }
    }
    
    // Ensure abbreviation is 3-4 characters
    if (abbrev.length < 3) {
      // Add more characters from prominent words if needed
      for (var word in words) {
        if (word.length > 1 && abbrev.length < 3) {
          abbrev += word[1].toUpperCase();
        }
      }
    }
    
    // Truncate if too long
    if (abbrev.length > 4) {
      abbrev = abbrev.substring(0, 4);
    }
    
    return abbrev;
  }

  // Subscribe to Firestore appointments
  void subscribeToAppointments() {
    try {
      _appointmentsSubscription = FirebaseFirestore.instance
          .collection('appointment')
          .snapshots()
          .listen((snapshot) {
        processAppointmentData(snapshot);
      }, onError: (e) {
        setState(() {
          error = 'Error loading appointments: $e';
          isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        error = 'Failed to subscribe to appointments: $e';
        isLoading = false;
      });
    }
  }

  // Process appointment data and update the state
  void processAppointmentData(QuerySnapshot snapshot) {
    try {
      // Initialize counters for all departments with zero
      Map<String, int> counts = {};
      for (String dept in departmentAbbreviations) {
        counts[dept] = 0;
      }
      
      // Count appointments by department ID
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String? deptId = data['deptID'] as String?;
        bool counted = false;
        
        // First try to count by department ID - primary method
        if (deptId != null && deptId.isNotEmpty) {
          // Find which department abbreviation matches this deptID
          for (String abbrev in departmentAbbreviations) {
            if (departmentIds[abbrev] == deptId) {
              counts[abbrev] = (counts[abbrev] ?? 0) + 1;
              counted = true;
              break;
            }
          }
        }
        
        // If we couldn't identify by deptID and we haven't counted this appointment yet,
        // try to look at internal users as a fallback only
        if (!counted && data.containsKey('internal_users') && data['internal_users'] is List) {
          // We'll only count the primary department (first one)
          // to avoid duplicate counting of appointments
          List<dynamic> internalUsers = data['internal_users'] as List<dynamic>;
          
          if (internalUsers.isNotEmpty) {
            var firstUser = internalUsers.first;
            if (firstUser is Map<String, dynamic> && firstUser.containsKey('department')) {
              String? departmentName = firstUser['department'] as String?;
              
              if (departmentName != null && departmentName.isNotEmpty) {
                // Find matching department by full name
                for (String abbrev in departmentAbbreviations) {
                  if (departmentFullNames[abbrev] == departmentName) {
                    counts[abbrev] = (counts[abbrev] ?? 0) + 1;
                    break;
                  }
                }
              }
            }
          }
        }
      }
      
      setState(() {
        departmentAppointments = counts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error processing appointments: $e';
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
              else if (departmentAbbreviations.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No departments found',
                      style: TextStyle(color: Colors.grey),
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
            String departmentAbbrev = departmentAbbreviations[group.x];
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
            interval: 1, // Ensure indicators are spaced by 1 unit
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
    if (index < 0 || index >= departmentAbbreviations.length) {
      return const SizedBox.shrink();
    }
    
    final style = TextStyle(
      color: touchedIndex == index ? Color.fromARGB(255, 11, 55, 99).darken(20) : Color.fromARGB(255, 11, 55, 99),
      fontWeight: touchedIndex == index ? FontWeight.bold : FontWeight.normal,
      fontSize: 10,
    );
    
    final text = departmentAbbreviations[index];
    
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
    final maxY = getMaxY();
    if (value > maxY || value < 0) {
      return Container();
    }

    final style = TextStyle(
      fontSize: MediaQuery.of(context).size.width / 120,
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
      departmentAbbreviations.length,
      (index) {
        final deptAbbrev = departmentAbbreviations[index];
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