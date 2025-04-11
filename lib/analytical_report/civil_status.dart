import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CivilStatusPieChart extends StatefulWidget {
  const CivilStatusPieChart({super.key});

  @override
  State<CivilStatusPieChart> createState() => _CivilStatusPieChartState();
}

class _CivilStatusPieChartState extends State<CivilStatusPieChart> {
  int touchedIndex = -1;
  bool isLoading = true;
  String? errorMessage;
  Map<String, int> statusCounts = {};
  int totalUsers = 0;
  List<StatusData> statusData = [];

  @override
  void initState() {
    super.initState();
    fetchCivilStatusData();
  }

  Future<void> fetchCivilStatusData() async {
    try {
      // Access Firestore and get users collection
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection.get();

      // Process each user document
      statusCounts.clear();
      totalUsers = 0; // Will count only users with valid civil status

      // Define expected civil status values
      final expectedStatuses = ['Single', 'Married', 'Divorced', 'Separated'];
      
      for (var status in expectedStatuses) {
        statusCounts[status] = 0; // Initialize all expected statuses with 0
      }

      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        
        if (userData.containsKey('civil_status')) {
          final status = userData['civil_status'];
          
          if (status is String) {
            // Standardize status capitalization to match expected values
            String normalizedStatus = status.trim();
            
            // Find the matching expected status (case-insensitive)
            String? matchedStatus = expectedStatuses.firstWhere(
              (expectedStatus) => expectedStatus.toLowerCase() == normalizedStatus.toLowerCase(),
              orElse: () => 'Other',
            );
            
            statusCounts[matchedStatus] = (statusCounts[matchedStatus] ?? 0) + 1;
            totalUsers++; // Count this user since they have a valid civil status
          }
        } else {
          // Count users with no civil status defined
          statusCounts['Unknown'] = (statusCounts['Unknown'] ?? 0) + 1;
          totalUsers++; // Still count users without a status
        }
      }

      // Remove statuses with zero count
      statusCounts.removeWhere((key, value) => value == 0);

      // Convert status counts to percentage-based data for the chart
      statusData = statusCounts.entries.map((entry) {
        final statusName = entry.key;
        final count = entry.value;
        final double percentage = totalUsers > 0 ? (count / totalUsers) * 100 : 0;
        
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
        errorMessage = 'Error fetching civil status data: $e';
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
      return const Center(child: Text('No civil status data available'));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Column(
        children: [
          Text(
            'Civil Status Distribution',
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
            'Total Users: $totalUsers',
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
    
    // Define specific colors for civil statuses
    final Map<String, Color> statusColors = {
      'Single': Color(0xFF1E88E5),     // Blue
      'Married': Color(0xFF43A047),    // Green
      'Divorced': Color(0xFFE53935),   // Red
      'Separated': Color(0xFFFFB300),  // Amber
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
    // Define specific colors for civil statuses
    final Map<String, Color> statusColors = {
      'Single': Color(0xFF1E88E5),     // Blue
      'Married': Color(0xFF43A047),    // Green
      'Divorced': Color(0xFFE53935),   // Red
      'Separated': Color(0xFFFFB300),  // Amber
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