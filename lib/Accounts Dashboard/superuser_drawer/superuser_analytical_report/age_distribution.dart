import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/superuser_analytical_report/presentation/resources/app_resources.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/superuser_analytical_report/util/extensions/color_extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AgeDistributionChart extends StatefulWidget {
  const AgeDistributionChart({super.key});

  @override
  State<StatefulWidget> createState() => AgeDistributionChartState();
}

class AgeDistributionChartState extends State<AgeDistributionChart> {
  int touchedIndex = -1;
  bool isLoading = true;
  Map<String, int> ageGroupCounts = {};
  final List<String> ageRanges = ['18-25', '26-30', '31-35', '36-40', '41-45', '46-50', '51+'];
  
  @override
  void initState() {
    super.initState();
    fetchAgeDistribution();
  }

  // Calculate age from birthdate
  int calculateAge(String birthDateString) {
    try {
      // Parse the birthdate string (format: MM/dd/yyyy)
      final DateFormat formatter = DateFormat('M/d/yyyy');
      final DateTime birthDate = formatter.parse(birthDateString);
      
      // Calculate the difference in years from current date
      final DateTime currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      
      // Adjust age if birthday hasn't occurred yet this year
      if (currentDate.month < birthDate.month || 
          (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      // Return 0 if there's an error parsing the date
      print('Error calculating age: $e');
      return 0;
    }
  }

  // Get the age group for a given age
  String getAgeGroup(int age) {
    if (age <= 25) return '18-25';
    if (age <= 30) return '26-30';
    if (age <= 35) return '31-35';
    if (age <= 40) return '36-40';
    if (age <= 45) return '41-45';
    if (age <= 50) return '46-50';
    return '51+';
  }

  // Fetch age distribution data from Firestore
  Future<void> fetchAgeDistribution() async {
    try {
      // Initialize age groups with zero counts
      for (String range in ageRanges) {
        ageGroupCounts[range] = 0;
      }

      // Query Firestore for user data
      final QuerySnapshot userSnapshot = 
          await FirebaseFirestore.instance.collection('users').get();
      
      // Process each user's birthdate
      for (var doc in userSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        if (userData.containsKey('birthdate') && userData['birthdate'] != null) {
          final birthdate = userData['birthdate'] as String;
          final age = calculateAge(birthdate);
          
          if (age >= 18) { // Only count adults
            final ageGroup = getAgeGroup(age);
            ageGroupCounts[ageGroup] = (ageGroupCounts[ageGroup] ?? 0) + 1;
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching age distribution: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Employee Age Distribution',
                  style: TextStyle(
                    color: AppColors.contentColorBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : BarChart(
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
    if (ageGroupCounts.isEmpty) return 10;
    return (ageGroupCounts.values.reduce((curr, next) => curr > next ? curr : next) * 1.2);
  }

  // Bar touch data configuration
  BarTouchData get barTouchData => BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String ageRange = ageRanges[group.x];
            return BarTooltipItem(
              '${ageRange}: ${rod.toY.round()} employees',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
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
            reservedSize: 40,
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

  // Bottom titles widget for age ranges
  Widget bottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= ageRanges.length) {
      return const SizedBox.shrink();
    }
    
    final style = TextStyle(
      color: touchedIndex == index ? AppColors.contentColorBlue.darken(20) : AppColors.contentColorBlue,
      fontWeight: touchedIndex == index ? FontWeight.bold : FontWeight.normal,
      fontSize: 12,
    );
    
    final text = ageRanges[index];
    
    return SideTitleWidget(
      meta: meta,
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  // Left titles widget for count values
  Widget leftTitles(double value, TitleMeta meta) {
    if (value == 0) {
      return Container();
    }
    
    const style = TextStyle(
      fontSize: 10,
      color: AppColors.contentColorBlue,
    );
    
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toInt().toString(),
        style: style,
      ),
    );
  }

  // Generate bar groups for the chart
  List<BarChartGroupData> get barGroups {
    return List.generate(
      ageRanges.length,
      (index) {
        final ageRange = ageRanges[index];
        final count = ageGroupCounts[ageRange] ?? 0;
        
        // Create gradient for the bars
        final LinearGradient barGradient = LinearGradient(
          colors: [
            AppColors.contentColorBlue.withOpacity(0.7),
            AppColors.contentColorCyan,
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              gradient: touchedIndex == index ? null : barGradient,
              color: touchedIndex == index ? AppColors.contentColorPink : null,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
          showingTooltipIndicators: touchedIndex == index ? [0] : [],
        );
      },
    );
  }
}