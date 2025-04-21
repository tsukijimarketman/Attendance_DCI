import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GenderDistributionPieChart extends StatefulWidget {
  const GenderDistributionPieChart({super.key});

  @override
  State<GenderDistributionPieChart> createState() => _GenderDistributionPieChartState();
}

class _GenderDistributionPieChartState extends State<GenderDistributionPieChart> {
  int touchedIndex = -1;
  bool isLoading = true;
  String? errorMessage;
  Map<String, int> genderCounts = {
    'Male': 0,
    'Female': 0,
  };
  int totalUsers = 0;
  List<GenderData> genderData = [];

  @override
  void initState() {
    super.initState();
    fetchGenderData();
  }

  Future<void> fetchGenderData() async {
    try {
      // Access Firestore and get users collection
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection.get();

      // Process each user document
      genderCounts = {
        'Male': 0,
        'Female': 0,
      };
      
      int countedUsers = 0;

      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        
        // Check if the sex field exists
        if (userData.containsKey('sex')) {
          final gender = userData['sex'];
          
          if (gender is String) {
            // Only count exact matches for 'Male' or 'Female'
            if (gender == 'Male') {
              genderCounts['Male'] = (genderCounts['Male'] ?? 0) + 1;
              countedUsers++;
            } else if (gender == 'Female') {
              genderCounts['Female'] = (genderCounts['Female'] ?? 0) + 1;
              countedUsers++;
            }
          }
        }
      }

      // Set total as only the counted Male/Female users
      totalUsers = countedUsers;

      // Convert gender counts to percentage-based data for the chart
      genderData = genderCounts.entries.map((entry) {
        final genderName = entry.key;
        final count = entry.value;
        final percentage = totalUsers > 0 ? (count / totalUsers) * 100 : 0.0;
        
        return GenderData(
          gender: genderName,
          count: count,
          percentage: percentage,
        );
      }).toList();

      // Filter out zero counts
      genderData = genderData.where((data) => data.count > 0).toList();

      // Sort by percentage (highest first)
      genderData.sort((a, b) => b.percentage.compareTo(a.percentage));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching gender data: $e';
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

    if (genderData.isEmpty) {
      return const Center(child: Text('No gender data available'));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Column(
        children: [
          Text(
            'Gender Distribution',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width/80,
              fontFamily: "SB",
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
                  children: generateGenderIndicators(),
                ),
              ],
            ),
          ),
          Text(
            'Total Users: $totalUsers',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width/80,
              fontFamily: "B",
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width / 80),
        ],
      ),
    );
  }

  List<Widget> generateGenderIndicators() {
    final List<Widget> indicators = [];
    
    // Define gender-specific colors (only Male and Female)
    final Map<String, Color> genderColors = {
      'Male': Colors.blue,
      'Female': Colors.pink,
    };

    for (var i = 0; i < genderData.length; i++) {
      final data = genderData[i];
      indicators.add(
        Indicator(
          color: genderColors[data.gender]!,
          text: '${data.gender}: ${data.percentage.toStringAsFixed(1)}%',
          isSquare: true,
        ),
      );
      
      if (i < genderData.length - 1) {
        indicators.add(const SizedBox(height: 4));
      }
    }

    return indicators;
  }

  List<PieChartSectionData> showingSections() {
    // Define gender-specific colors (only Male and Female)
    final Map<String, Color> genderColors = {
      'Male': Colors.blue,
      'Female': Colors.pink,
    };
      
    return List.generate(genderData.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? MediaQuery.of(context).size.width/50 : MediaQuery.of(context).size.width/70;
      final radius = isTouched ? MediaQuery.of(context).size.width/17 : MediaQuery.of(context).size.width/20;
      
      return PieChartSectionData(
        color: genderColors[genderData[i].gender]!,
        value: genderData[i].percentage,
        title: '${genderData[i].percentage.toStringAsFixed(1)}%',
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

class GenderData {
  final String gender;
  final int count;
  final double percentage;

  GenderData({
    required this.gender,
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