import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RoleDistributionPieChart extends StatefulWidget {
  const RoleDistributionPieChart({super.key});

  @override
  State<RoleDistributionPieChart> createState() => _RoleDistributionPieChartState();
}

class _RoleDistributionPieChartState extends State<RoleDistributionPieChart> {
  int touchedIndex = -1;
  bool isLoading = true;
  String? errorMessage;
  Map<String, int> roleCounts = {};
  int totalUsers = 0;
  List<RoleData> roleData = [];

  @override
  void initState() {
    super.initState();
    fetchRoleData();
  }

  Future<void> fetchRoleData() async {
    try {
      // Access Firestore and get users collection
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection.get();

      // Process each user document
      roleCounts.clear();
      totalUsers = querySnapshot.docs.length;

      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        
        // Handle the roles field - could be a string, array, map, or not exist
        if (userData.containsKey('roles')) {
          final userRoles = userData['roles'];
          
          if (userRoles is String) {
            // If roles is a single string
            roleCounts[userRoles] = (roleCounts[userRoles] ?? 0) + 1;
          } else if (userRoles is List) {
            // If roles is an array
            for (var role in userRoles) {
              if (role is String) {
                roleCounts[role] = (roleCounts[role] ?? 0) + 1;
              }
            }
          } else if (userRoles is Map) {
            // If roles is a map like {admin: true, user: false}
            userRoles.forEach((role, isActive) {
              if (isActive == true && role is String) {
                roleCounts[role] = (roleCounts[role] ?? 0) + 1;
              }
            });
          }
        } else {
          // Count users with no role defined
          roleCounts['no role'] = (roleCounts['no role'] ?? 0) + 1;
        }
      }

      // Convert role counts to percentage-based data for the chart
      roleData = roleCounts.entries.map((entry) {
        final roleName = entry.key;
        final count = entry.value;
        final percentage = (count / totalUsers) * 100;
        
        return RoleData(
          role: roleName,
          count: count,
          percentage: percentage,
        );
      }).toList();

      // Sort by percentage (highest first)
      roleData.sort((a, b) => b.percentage.compareTo(a.percentage));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching role data: $e';
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

    if (roleData.isEmpty) {
      return const Center(child: Text('No role data available'));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Column(
        children: [
          Text(
            'User Role Distribution',
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
                  children: generateRoleIndicators(),
                ),
              ],
            ),
          ),SizedBox(height: MediaQuery.of(context).size.width/80,),
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

  List<Widget> generateRoleIndicators() {
    final List<Widget> indicators = [];
    
    // Define colors for roles - ensure we have enough
    final List<Color> colors = [
      Colors.blue, 
      Colors.green, 
      Colors.yellow, 
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    for (var i = 0; i < roleData.length; i++) {
      final data = roleData[i];
      indicators.add(
        Indicator(
          color: colors[i % colors.length],
          text: '${data.role}: ${data.percentage.toStringAsFixed(1)}%',
          isSquare: true,
        ),
      );
      
      if (i < roleData.length - 1) {
        indicators.add(const SizedBox(height: 4));
      }
    }

    return indicators;
  }

  List<PieChartSectionData> showingSections() {
    final List<Color> colors = [
      Colors.blue, 
      Colors.green, 
      Colors.yellow, 
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

      
    return List.generate(roleData.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? MediaQuery.of(context).size.width/50 : MediaQuery.of(context).size.width/70;
      final radius = isTouched ? MediaQuery.of(context).size.width/17 : MediaQuery.of(context).size.width/20;
      
      final Color color = colors[i % colors.length];
      
      return PieChartSectionData(
        color: color,
        value: roleData[i].percentage,
        title: '${roleData[i].percentage.toStringAsFixed(1)}%',
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

class RoleData {
  final String role;
  final int count;
  final double percentage;

  RoleData({
    required this.role,
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