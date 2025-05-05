import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceTrends extends StatefulWidget {
  final String? status; // Optional status filter
  final int periodsToShow; // Number of periods to display
  
  const AttendanceTrends({
    Key? key,
    this.status,
    this.periodsToShow = 8, // Default to showing 8 periods
  }) : super(key: key);

  @override
  State<AttendanceTrends> createState() => _AttendanceTrendsState();
}

class _AttendanceTrendsState extends State<AttendanceTrends> {
  bool isLoading = true;
  List<Map<String, dynamic>> attendanceData = [];
  bool showAverage = false;
  double averageCount = 0;
  
  // Track currently selected time period
  String _selectedTimePeriod = 'Weekly';
  final List<String> _timePeriods = ['Weekly', 'Monthly', 'Yearly'];
  
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
    setState(() {
      isLoading = true;
    });
    
    try {
      // Calculate the start date based on time period
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedTimePeriod) {
        case 'Weekly':
          startDate = now.subtract(Duration(days: widget.periodsToShow * 7));
          break;
        case 'Monthly':
          // Go back periodsToShow months
          startDate = DateTime(now.year, now.month - widget.periodsToShow, now.day);
          break;
        case 'Yearly':
          // Go back periodsToShow years
          startDate = DateTime(now.year - widget.periodsToShow, now.month, now.day);
          break;
        default:
          startDate = now.subtract(Duration(days: widget.periodsToShow * 7));
      }
      
      // Reference to the attendance collection
      Query query = FirebaseFirestore.instance.collection('appointment');
      
      // Apply date filter to limit the data
      query = query.where('schedule', isGreaterThanOrEqualTo: startDate.toIso8601String());
      
      // Apply status filter if provided
      if (widget.status != null && widget.status!.isNotEmpty) {
        query = query.where('status', isEqualTo: widget.status);
      }
      
      // Get all appointments
      final QuerySnapshot snapshot = await query.get();
      
      // Process data by period
      final Map<String, int> periodCounts = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get the schedule date
        String dateStr = data['schedule'] as String;
        DateTime appointmentDate = DateTime.parse(dateStr);
        
        // Format based on selected time period
        String periodKey;
        
        switch (_selectedTimePeriod) {
          case 'Weekly':
            periodKey = getWeekPeriod(appointmentDate);
            break;
          case 'Monthly':
            periodKey = DateFormat('MMM yyyy').format(appointmentDate);
            break;
          case 'Yearly':
            periodKey = DateFormat('yyyy').format(appointmentDate);
            break;
          default:
            periodKey = getWeekPeriod(appointmentDate);
        }
        
        // Count attendees
        int attendeeCount = 0;
        
        if (data.containsKey('guest') && data['guest'] is List) {
          attendeeCount += (data['guest'] as List).length;
        }
        
        if (data.containsKey('internal_users') && data['internal_users'] is List) {
          attendeeCount += (data['internal_users'] as List).length;
        }
        
        // If no attendees found, count at least 1 (the appointment creator)
        if (attendeeCount == 0) attendeeCount = 1;
        
        // Add to period counts
        periodCounts[periodKey] = (periodCounts[periodKey] ?? 0) + attendeeCount;
      }
      
      // Convert to list
      List<Map<String, dynamic>> result = [];
      periodCounts.forEach((period, count) {
        result.add({
          'period': period,
          'attendees': count,
        });
      });
      
      // Sort by date
      result.sort((a, b) {
        DateTime dateA;
        DateTime dateB;
        
        switch (_selectedTimePeriod) {
          case 'Weekly':
            // Extract date from "Week N MMM yyyy" format
            final regexWeek = RegExp(r'Week \d+ (.+)');
            final matchA = regexWeek.firstMatch(a['period']);
            final matchB = regexWeek.firstMatch(b['period']);
            final dateStrA = matchA?.group(1) ?? '';
            final dateStrB = matchB?.group(1) ?? '';
            
            try {
              dateA = DateFormat('MMM yyyy').parse(dateStrA);
              dateB = DateFormat('MMM yyyy').parse(dateStrB);
              
              // If same month/year, compare by week number
              if (dateA.isAtSameMomentAs(dateB)) {
                final weekA = int.parse(a['period'].split(' ')[1]);
                final weekB = int.parse(b['period'].split(' ')[1]);
                return weekA.compareTo(weekB);
              }
              
              return dateA.compareTo(dateB);
            } catch (e) {
              // Fallback to string comparison if parsing fails
              return a['period'].compareTo(b['period']);
            }
            break;
          case 'Monthly':
            try {
              dateA = DateFormat('MMM yyyy').parse(a['period']);
              dateB = DateFormat('MMM yyyy').parse(b['period']);
            } catch (e) {
              return a['period'].compareTo(b['period']);
            }
            break;
          case 'Yearly':
            try {
              dateA = DateFormat('yyyy').parse(a['period']);
              dateB = DateFormat('yyyy').parse(b['period']);
            } catch (e) {
              return a['period'].compareTo(b['period']);
            }
            break;
          default:
            try {
              dateA = DateFormat('MMM yyyy').parse(a['period']);
              dateB = DateFormat('MMM yyyy').parse(b['period']);
            } catch (e) {
              return a['period'].compareTo(b['period']);
            }
        }
        
        return dateA.compareTo(dateB);
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
        attendanceData = result;
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
                Text(
                  '$_selectedTimePeriod Attendance Trends',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Time period selection dropdown
                    DropdownButton<String>(
                      value: _selectedTimePeriod,
                      dropdownColor: const Color(0xFF2c3e50),
                      style: const TextStyle(color: Colors.white),
                      underline: Container(
                        height: 2,
                        color: Colors.orangeAccent,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTimePeriod = newValue;
                          });
                          fetchAttendanceData();
                        }
                      },
                      items: _timePeriods.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 16),
                    // Average toggle button
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
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (attendanceData.isEmpty)
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
    for (int i = 0; i < attendanceData.length; i++) {
      spots.add(FlSpot(i.toDouble(), attendanceData[i]['attendees'].toDouble()));
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
            reservedSize: getReservedSizeForLabels(),
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < attendanceData.length) {
                final period = attendanceData[value.toInt()]['period'];
                return SideTitleWidget(
                  meta: meta,
                  angle: _selectedTimePeriod == 'Weekly' ? 0.3 : 0,
                  child: Text(
                    _formatLabel(period),
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
      maxX: (attendanceData.length - 1).toDouble(),
      minY: 0,
      maxY: attendanceData.isEmpty 
          ? 10 
          : (attendanceData.map((e) => e['attendees'] as int).reduce((a, b) => a > b ? a : b) + 5)
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
              final String period = attendanceData[index]['period'];
              final int attendees = attendanceData[index]['attendees'];
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
    for (int i = 0; i < attendanceData.length; i++) {
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
            reservedSize: getReservedSizeForLabels(),
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < attendanceData.length) {
                final period = attendanceData[value.toInt()]['period'];
                return SideTitleWidget(
                  meta: meta,
                  angle: _selectedTimePeriod == 'Weekly' ? 0.3 : 0,
                  child: Text(
                    _formatLabel(period),
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
      maxX: (attendanceData.length - 1).toDouble(),
      minY: 0,
      maxY: attendanceData.isEmpty 
          ? 10 
          : (attendanceData.map((e) => e['attendees'] as int).reduce((a, b) => a > b ? a : b) + 5)
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
  
  // Helper function to adjust label appearance based on time period
  String _formatLabel(String label) {
    switch (_selectedTimePeriod) {
      case 'Weekly':
        // For weekly view, extract and format "Week N" and month
        final parts = label.split(' ');
        if (parts.length >= 3) {
          return '${parts[0]} ${parts[1]}\n${parts[2]}';
        }
        return label;
      case 'Monthly':
        // For monthly view, no special formatting needed
        return label;
      case 'Yearly':
        // For yearly view, just show the year
        return label;
      default:
        return label;
    }
  }

  // Adjust the bottom title height based on the selected time period
  double getReservedSizeForLabels() {
    switch (_selectedTimePeriod) {
      case 'Weekly':
        return 60; // More space for weekly labels
      case 'Monthly':
        return 30; // Standard space for monthly labels
      case 'Yearly':
        return 30; // Standard space for yearly labels
      default:
        return 30;
    }
  }
}