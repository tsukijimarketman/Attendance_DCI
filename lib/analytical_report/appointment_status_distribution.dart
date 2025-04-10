import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AppointmentStatusPieChart extends StatefulWidget {
  const AppointmentStatusPieChart({super.key});

  @override
  State<AppointmentStatusPieChart> createState() => _AppointmentStatusPieChartState();
}

class _AppointmentStatusPieChartState extends State<AppointmentStatusPieChart> {
  int touchedIndex = -1;
  bool isLoading = true;
  String? errorMessage;
  Map<String, int> statusCounts = {};
  int totalAppointments = 0;
  List<StatusData> statusData = [];

  @override
  void initState() {
    super.initState();
    fetchStatusData();
  }

  Future<void> fetchStatusData() async {
    try {
      // Access Firestore and get appointments collection
      final appointmentsCollection = FirebaseFirestore.instance.collection('appointment');
      final querySnapshot = await appointmentsCollection.get();

      // Process each appointment document
      statusCounts.clear();
      totalAppointments = querySnapshot.docs.length;

      // Define expected status values for grouping
      final expectedStatuses = ['Scheduled', 'In Progress', 'Completed', 'Cancelled'];
      
      for (var status in expectedStatuses) {
        statusCounts[status] = 0; // Initialize all expected statuses with 0
      }

      for (var doc in querySnapshot.docs) {
        final appointmentData = doc.data();
        
        if (appointmentData.containsKey('status')) {
          final status = appointmentData['status'];
          
          if (status is String) {
            // Standardize status capitalization to match expected values
            String normalizedStatus = status.trim();
            
            // Find the matching expected status (case-insensitive)
            String? matchedStatus = expectedStatuses.firstWhere(
              (expectedStatus) => expectedStatus.toLowerCase() == normalizedStatus.toLowerCase(),
              orElse: () => 'Other',
            );
            
            statusCounts[matchedStatus] = (statusCounts[matchedStatus] ?? 0) + 1;
          }
        } else {
          // Count appointments with no status defined
          statusCounts['Unknown'] = (statusCounts['Unknown'] ?? 0) + 1;
        }
      }

      // Remove statuses with zero count
      statusCounts.removeWhere((key, value) => value == 0);

      // Convert status counts to percentage-based data for the chart
      statusData = statusCounts.entries.map((entry) {
        final statusName = entry.key;
        final count = entry.value;
        final double percentage = totalAppointments > 0 ? (count / totalAppointments) * 100 : 0;
        
        return StatusData(
          status: statusName,
          count: count,
          percentage: percentage,
        );
      }).toList();

      // Sort by percentage (highest first)
      statusData.sort((a, b) => b.percentage.compareTo(a.percentage));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching appointment data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)));
    }

    if (statusData.isEmpty) {
      return const Center(child: Text('No appointment data available'));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Column(
        children: [
          Text(
            'Appointment Status Distribution',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width/80,
              fontFamily: "SB",
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width/80),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: showingSections(),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width/100),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: generateStatusIndicators(),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width/80),
          Text(
            'Total Appointments: $totalAppointments',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width/80,
              fontFamily: "B",
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> generateStatusIndicators() {
    final List<Widget> indicators = [];
    
    // Define specific colors for appointment statuses
    final Map<String, Color> statusColors = {
      'Scheduled': Color(0xFF082649),
      'In Progress': Colors.orange,
      'Completed': Colors.green,
      'Cancelled': Colors.red,
      'Unknown': Colors.grey,
      'Other': Colors.purple,
    };

    for (var i = 0; i < statusData.length; i++) {
      final data = statusData[i];
      indicators.add(
        Indicator(
          color: statusColors[data.status] ?? Colors.teal,
          text: '${data.status}: ${data.percentage.toStringAsFixed(1)}% (${data.count})',
          isSquare: true,
        ),
      );
      
      if (i < statusData.length - 1) {
        indicators.add(const SizedBox(height: 4));
      }
    }

    return indicators;
  }

  List<PieChartSectionData> showingSections() {
    // Define specific colors for appointment statuses
    final Map<String, Color> statusColors = {
      'Scheduled': Color(0xFF082649),
      'In Progress': Colors.orange,
      'Completed': Colors.green,
      'Cancelled': Colors.red,
      'Unknown': Colors.grey,
      'Other': Colors.purple,
    };
      
    return List.generate(statusData.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? MediaQuery.of(context).size.width/50 : MediaQuery.of(context).size.width/70;
      final radius = isTouched ? MediaQuery.of(context).size.width/17 : MediaQuery.of(context).size.width/20;
      
      final Color color = statusColors[statusData[i].status] ?? Colors.teal;
      
      return PieChartSectionData(
        color: color,
        value: statusData[i].percentage,
        title: '${statusData[i].percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    });
  }
}

class StatusData {
  final String status;
  final int count;
  final double percentage;

  StatusData({
    required this.status,
    required this.count,
    required this.percentage,
  });
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });

  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width/90,
            fontFamily: "R",
            color: textColor,
          ),
        )
      ],
    );
  }
}