import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WeeklyAttendanceTrends extends StatefulWidget {
  final String? status; // Optional status filter
  final int weeksToShow; // Number of weeks to display
  
  const WeeklyAttendanceTrends({
    Key? key,
    this.status,
    this.weeksToShow = 8, // Default to showing 8 weeks
  }) : super(key: key);

  @override
  State<WeeklyAttendanceTrends> createState() => _WeeklyAttendanceTrendsState();
}

class _WeeklyAttendanceTrendsState extends State<WeeklyAttendanceTrends> {
  bool isLoading = true;
  List<Map<String, dynamic>> weeklyData = [];
  bool showAverage = false;
  double averageCount = 0;
  
  // Colors for the chart
  final List<Color> gradientColors = [
    const Color(0xFFFF9800), // Orange
    const Color(0xFFF44336), // Red
  ];

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  // Helper function to get week number and year from a date
  String getWeekPeriod(DateTime date) {
    // Calculate the first day of the year
    final firstDayOfYear = DateTime(date.year, 1, 1);
    
    // Calculate days since first day of the year
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    
    // Calculate week number (add 1 because weeks are 1-indexed)
    final weekNumber = ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
    
    return 'Week $weekNumber ${DateFormat('MMM yyyy').format(date)}';
  }

  Future<void> fetchAttendanceData() async {
    try {
      // Calculate the start date (N weeks ago)
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: widget.weeksToShow * 7));
      
      // Reference to the attendance collection
      // Note: Adjust the collection path if your attendance data is structured differently
      Query query = FirebaseFirestore.instance.collection('appointment');
      
      // Apply date filter to limit the data
      query = query.where('schedule', isGreaterThanOrEqualTo: startDate.toIso8601String());
      
      // Apply status filter if provided
      if (widget.status != null && widget.status!.isNotEmpty) {
        query = query.where('status', isEqualTo: widget.status);
      }
      
      // Get all appointments
      final QuerySnapshot snapshot = await query.get();
      
      // Process data by week
      final Map<String, int> weeklyCounts = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get the schedule date
        String dateStr = data['schedule'] as String;
        DateTime appointmentDate = DateTime.parse(dateStr);
        
        // Format the week and year
        String weekPeriod = getWeekPeriod(appointmentDate);
        
        // Count attendees (assuming a 'guest' array field exists)
        int attendeeCount = 0;
        
        if (data.containsKey('guest') && data['guest'] is List) {
          attendeeCount += (data['guest'] as List).length;
        }
        
        if (data.containsKey('internal_users') && data['internal_users'] is List) {
          attendeeCount += (data['internal_users'] as List).length;
        }
        
        // If no attendees found, count at least 1 (the appointment creator)
        if (attendeeCount == 0) attendeeCount = 1;
        
        // Add to weekly counts
        weeklyCounts[weekPeriod] = (weeklyCounts[weekPeriod] ?? 0) + attendeeCount;
      }
      
      // Convert to list and sort by date
      List<Map<String, dynamic>> result = [];
      weeklyCounts.forEach((week, count) {
        result.add({
          'period': week,
          'attendees': count,
        });
      });
      
      // Sort by week period
      result.sort((a, b) {
        // Extract the week number and month/year
        final RegExp regExp = RegExp(r'Week (\d+) (.+)');
        final aMatch = regExp.firstMatch(a['period']);
        final bMatch = regExp.firstMatch(b['period']);
        
        if (aMatch == null || bMatch == null) return 0;
        
        final aWeekNum = int.parse(aMatch.group(1)!);
        final bWeekNum = int.parse(bMatch.group(1)!);
        
        final aDate = DateFormat('MMM yyyy').parse(aMatch.group(2)!);
        final bDate = DateFormat('MMM yyyy').parse(bMatch.group(2)!);
        
        // First compare by date
        final dateComparison = aDate.compareTo(bDate);
        if (dateComparison != 0) return dateComparison;
        
        // If same month/year, compare by week number
        return aWeekNum.compareTo(bWeekNum);
      });
      
      // Calculate average
      if (result.isNotEmpty) {
        double total = 0;
        for (var item in result) {
          total += item['attendees'];
        }
        averageCount = total / result.length;
      }
      
      setState(() {
        weeklyData = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching attendance data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF232d37),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Attendance Trends',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAverage = !showAverage;
                    });
                  },
                  child: Text(
                    'Show ${showAverage ? 'Trend' : 'Average'}',
                    style: TextStyle(
                      color: showAverage ? Colors.white.withOpacity(0.5) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (weeklyData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No attendance data available',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 18,
                    left: 12,
                    top: 24,
                    bottom: 12,
                  ),
                  child: LineChart(
                    showAverage ? averageData() : mainData(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  LineChartData mainData() {
    // Convert data to spots
    final List<FlSpot> spots = [];
    for (int i = 0; i < weeklyData.length; i++) {
      spots.add(FlSpot(i.toDouble(), weeklyData[i]['attendees'].toDouble()));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5, // Show grid line every 5 attendees
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                final String period = weeklyData[value.toInt()]['period'];
                // Extract just the week number and month
                final parts = period.split(' ');
                if (parts.length >= 3) {
                  final simplifiedPeriod = '${parts[0]} ${parts[1]}\n${parts[2]}';
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      simplifiedPeriod,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    period,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5, // Show numbers every 5 attendees
            getTitlesWidget: (value, meta) {
              if (value % 5 == 0) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.left,
                );
              }
              return const SizedBox();
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: (weeklyData.length - 1).toDouble(),
      minY: 0,
      maxY: weeklyData.isEmpty 
          ? 10 
          : (weeklyData.map((e) => e['attendees'] as int).reduce((a, b) => a > b ? a : b) + 5)
              .toDouble().ceilToDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: gradientColors[0],
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final int index = touchedSpot.x.toInt();
              final String period = weeklyData[index]['period'];
              final int attendees = weeklyData[index]['attendees'];
              return LineTooltipItem(
                '$period\n$attendees attendees',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  LineChartData averageData() {
    // Create spots for average line
    final List<FlSpot> averageSpots = [];
    for (int i = 0; i < weeklyData.length; i++) {
      averageSpots.add(FlSpot(i.toDouble(), averageCount));
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                'Average: ${averageCount.toStringAsFixed(1)} attendees',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        verticalInterval: 1,
        horizontalInterval: 5,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                final String period = weeklyData[value.toInt()]['period'];
                // Extract just the week number and month
                final parts = period.split(' ');
                if (parts.length >= 3) {
                  final simplifiedPeriod = '${parts[0]} ${parts[1]}\n${parts[2]}';
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      simplifiedPeriod,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    period,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox();
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value % 5 == 0) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.left,
                );
              }
              return const SizedBox();
            },
            reservedSize: 42,
            interval: 5,
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: (weeklyData.length - 1).toDouble(),
      minY: 0,
      maxY: weeklyData.isEmpty 
          ? 10 
          : (weeklyData.map((e) => e['attendees'] as int).reduce((a, b) => a > b ? a : b) + 5)
              .toDouble().ceilToDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: averageSpots,
          isCurved: false,
          gradient: LinearGradient(
            colors: [
              Colors.amber,
              Colors.amber,
            ],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          dashArray: [6, 4],
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      ],
    );
  }
}