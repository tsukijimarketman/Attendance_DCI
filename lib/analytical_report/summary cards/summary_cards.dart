import 'package:flutter/material.dart';

class SummaryCards extends StatefulWidget {
  const SummaryCards({super.key});

  @override
  State<SummaryCards> createState() => _SummaryCardsState();
}

class _SummaryCardsState extends State<SummaryCards> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          SizedBox(height: width / 40),
          Container(
            width: width / 1.535,
            height: width / 3.5,
            padding: EdgeInsets.all(width / 80),
            decoration: BoxDecoration(
              color: Color(0xFFBADDFB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Appointments",
                  style: TextStyle(
                    fontSize: width / 80,
                    fontFamily: "SB",
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
