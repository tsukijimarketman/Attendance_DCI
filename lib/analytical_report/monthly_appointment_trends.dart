import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MonthlyAppointmentTrends extends StatefulWidget {
  final String? status; // Optional status filter
  
  const MonthlyAppointmentTrends({
    Key? key,
    this.status,
  }) : super(key: key);

  @override
  State<MonthlyAppointmentTrends> createState() => _MonthlyAppointmentTrendsState();
}

class _MonthlyAppointmentTrendsState extends State<MonthlyAppointmentTrends> {
  bool isLoading = true;
  List<Map<String, dynamic>> monthlyData = [];
  bool showAverage = false;
  double averageCount = 0;
  
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
    try {
      // Reference to the appointments collection
      Query query = FirebaseFirestore.instance.collection('appointment');
      
      // Apply status filter if provided
      if (widget.status != null && widget.status!.isNotEmpty) {
        query = query.where('status', isEqualTo: widget.status);
      }
      
      // Get all appointments
      final QuerySnapshot snapshot = await query.get();
      
      // Process data by month
      final Map<String, int> monthlyCounts = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get the schedule date (assuming it's stored as a string)
        String dateStr = data['schedule'] as String;
        DateTime appointmentDate = DateTime.parse(dateStr);
        
        // Format the month and year
        String monthYear = DateFormat('MMM yyyy').format(appointmentDate);
        
        // Increment the count for this month
        monthlyCounts[monthYear] = (monthlyCounts[monthYear] ?? 0) + 1;
      }
      
      // Convert to list and sort by date
      List<Map<String, dynamic>> result = [];
      monthlyCounts.forEach((month, count) {
        result.add({
          'month': month,
          'count': count,
        });
      });
      
      // Sort by date
      result.sort((a, b) {
        final DateTime dateA = DateFormat('MMM yyyy').parse(a['month']);
        final DateTime dateB = DateFormat('MMM yyyy').parse(b['month']);
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
        monthlyData = result;
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
                const Text(
                  'Monthly Appointments Trend',
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
            else if (monthlyData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
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
    for (int i = 0; i < monthlyData.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyData[i]['count'].toDouble()));
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
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                final month = monthlyData[value.toInt()]['month'];
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    month,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
      maxX: (monthlyData.length - 1).toDouble(),
      minY: 0,
      maxY: monthlyData.isEmpty ? 10 : monthlyData.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 2,
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
              final String month = monthlyData[index]['month'];
              final int count = monthlyData[index]['count'];
              return LineTooltipItem(
                '$month\n$count appointments',
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
    for (int i = 0; i < monthlyData.length; i++) {
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
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                final month = monthlyData[value.toInt()]['month'];
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    month,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
      maxX: (monthlyData.length - 1).toDouble(),
      minY: 0,
      maxY: monthlyData.isEmpty ? 10 : monthlyData.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 2,
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