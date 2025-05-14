import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentTrendsChart extends StatefulWidget {
  final String? status;
  
  const AppointmentTrendsChart({
    Key? key,
    this.status,
  }) : super(key: key);

  @override
  State<AppointmentTrendsChart> createState() => _AppointmentTrendsChartState();
}

class _AppointmentTrendsChartState extends State<AppointmentTrendsChart> {
  bool isLoading = true;
  List<Map<String, dynamic>> trendData = [];
  bool showAverage = false;
  double averageCount = 0;
  
  // Track currently selected time period
  String _selectedTimePeriod = 'Monthly';
  final List<String> _timePeriods = ['Weekly', 'Monthly', 'Yearly'];
  
  // Colors for the chart
  final List<Color> gradientColors = [
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
  ];

  @override
  void initState() {
    super.initState();
    fetchAppointmentsData();
  }

  Future<void> fetchAppointmentsData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Reference to the appointments collection
      Query query = FirebaseFirestore.instance.collection('appointment');
      
      // Apply status filter if provided
      if (widget.status != null && widget.status!.isNotEmpty) {
        query = query.where('status', isEqualTo: widget.status);
      }
      
      // Get all appointments
      final QuerySnapshot snapshot = await query.get();
      
      // Process data based on selected time period
      final Map<String, int> periodCounts = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get the schedule date (assuming it's stored as a string)
        String dateStr = data['schedule'] as String;
        DateTime appointmentDate = DateTime.parse(dateStr);
        
        // Format based on selected time period
        String periodKey;
        
        switch (_selectedTimePeriod) {
          case 'Weekly':
            // Get the start of the week (Monday)
            final startOfWeek = appointmentDate.subtract(Duration(days: appointmentDate.weekday - 1));
            periodKey = '${DateFormat('MMM d').format(startOfWeek)}';
            break;
          case 'Monthly':
            periodKey = DateFormat('MMM yyyy').format(appointmentDate);
            break;
          case 'Yearly':
            periodKey = DateFormat('yyyy').format(appointmentDate);
            break;
          default:
            periodKey = DateFormat('MMM yyyy').format(appointmentDate);
        }
        
        // Increment the count for this period
        periodCounts[periodKey] = (periodCounts[periodKey] ?? 0) + 1;
      }
      
      // Convert to list
      List<Map<String, dynamic>> result = [];
      periodCounts.forEach((period, count) {
        result.add({
          'period': period,
          'count': count,
        });
      });
      
      // Sort by date
      result.sort((a, b) {
        DateTime dateA;
        DateTime dateB;
        
        switch (_selectedTimePeriod) {
          case 'Weekly':
            // Extract date from "Week of MMM d" format
            final regexWeek = RegExp(r'(.+)');
            final matchA = regexWeek.firstMatch(a['period']);
            final matchB = regexWeek.firstMatch(b['period']);
            final dateStrA = matchA?.group(1) ?? '';
            final dateStrB = matchB?.group(1) ?? '';
            
            try {
              dateA = DateFormat('MMM d').parse(dateStrA);
              dateB = DateFormat('MMM d').parse(dateStrB);
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
          total += item['count'];
        }
        averageCount = total / result.length;
      }
      
      setState(() {
        trendData = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching appointment data: $e');
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
                  '$_selectedTimePeriod Appointments Trend',
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
                        color: Colors.blueAccent,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTimePeriod = newValue;
                          });
                          fetchAppointmentsData();
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
            else if (trendData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No appointment data available',
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
    for (int i = 0; i < trendData.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendData[i]['count'].toDouble()));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
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
              if (value.toInt() >= 0 && value.toInt() < trendData.length) {
                final period = trendData[value.toInt()]['period'];
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
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value == value.roundToDouble()) {
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
      maxX: (trendData.length - 1).toDouble(),
      minY: 0,
      maxY: trendData.isEmpty ? 10 : trendData.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 2,
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
              final String period = trendData[index]['period'];
              final int count = trendData[index]['count'];
              return LineTooltipItem(
                '$period\n$count appointments',
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
    for (int i = 0; i < trendData.length; i++) {
      averageSpots.add(FlSpot(i.toDouble(), averageCount));
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                'Average: ${averageCount.toStringAsFixed(1)}',
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
        horizontalInterval: 1,
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
              if (value.toInt() >= 0 && value.toInt() < trendData.length) {
                final period = trendData[value.toInt()]['period'];
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
              if (value == value.roundToDouble()) {
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
            interval: 1,
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
      maxX: (trendData.length - 1).toDouble(),
      minY: 0,
      maxY: trendData.isEmpty ? 10 : trendData.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 2,
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
        // For weekly view, we might want to show abbreviated weeks
        if (label.length > 12) {
          return label.substring(0, 12) + '...';
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