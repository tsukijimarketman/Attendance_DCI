import 'package:attendance_app/analytical_report/presentation/resources/app_resources.dart';
import 'package:attendance_app/analytical_report/util/extensions/color_extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AppointmentsPerDepartmentChart extends StatefulWidget {
  const AppointmentsPerDepartmentChart({super.key});

  @override
  State<StatefulWidget> createState() => AppointmentsPerDepartmentChartState();
}

class AppointmentsPerDepartmentChartState extends State<AppointmentsPerDepartmentChart> {
  final Color barColor = Color.fromARGB(255, 11, 55, 99);
  int touchedIndex = -1;

  // Mock data - replace with your actual data from Firestore
  final Map<String, int> departmentAppointments = {
    'QMS': 25,
    'IQA': 18,
    'PMD': 32,
    'HRA': 15,
    'BD': 28,
    'ACCT': 20,
    'ITO': 22,
    'ADM': 30,
    'TID': 14,
    'PI': 35,
    'LC': 12,
    'CA': 16,
    'CS': 24,
    'CPD': 19,
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
    return (departmentAppointments.values.reduce((curr, next) => curr > next ? curr : next) * 1.2);
  }

  // Bar touch data configuration
  BarTouchData get barTouchData => BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String departmentName = departmentAppointments.keys.elementAt(group.x);
            return BarTooltipItem(
              '${departmentFullNames[departmentName]}\n${rod.toY.round()} appointments',
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

  // Bottom titles widget
  Widget bottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= departmentAppointments.length) {
      return const SizedBox.shrink();
    }
    
    final style = TextStyle(
      color: touchedIndex == index ? Color.fromARGB(255, 11, 55, 99).darken(20) : Color.fromARGB(255, 11, 55, 99),
      fontWeight: touchedIndex == index ? FontWeight.bold : FontWeight.normal,
      fontSize: 10,
    );
    
    final text = departmentAppointments.keys.elementAt(index);
    
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
      departmentAppointments.length,
      (index) {
        final data = departmentAppointments.entries.elementAt(index);
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data.value.toDouble(),
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