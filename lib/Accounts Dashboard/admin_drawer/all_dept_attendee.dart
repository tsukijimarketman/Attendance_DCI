import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllDeptAttendee extends StatelessWidget {
  final String selectedAgenda;
  const AllDeptAttendee({
    required this.selectedAgenda,
    super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendees for: $selectedAgenda")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('agenda', isEqualTo: selectedAgenda)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No attendees found for this agenda"));
          }

          var attendees = snapshot.data!.docs;

          return Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey[300], // Light gray background for header
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Contact Number', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Contact Number', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

              // Divider
              const Divider(height: 1, thickness: 1),

              // Attendee List
              Expanded(
                child: ListView.builder(
                  itemCount: attendees.length,
                  itemBuilder: (context, index) {
                    var data = attendees[index].data() as Map<String, dynamic>;
                    String name = data['name'] ?? 'Unknown';
                    String email = data['email_address'] ?? 'Unknown';
                    String contact = data['contact_num'] ?? 'Unknown';
                    String dept = data['department'] ?? 'Unknown';

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(name)),
                          Expanded(child: Text(email)),
                          Expanded(child: Text(contact)),
                          Expanded(child: Text(dept)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
