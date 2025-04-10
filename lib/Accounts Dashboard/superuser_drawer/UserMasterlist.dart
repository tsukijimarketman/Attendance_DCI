import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Masterlist extends StatefulWidget {
  const Masterlist({super.key});

  @override
  State<Masterlist> createState() => _MasterlistState();
}

class _MasterlistState extends State<Masterlist> {
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    String fullName = "$first_name $last_name".trim(); // Generate fullName

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            GridView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              children: [
                buildStatusCard("Internal Users Account", "User", fullName),
                buildStatusCard("Manager Account", "Manager", fullName),
                buildStatusCard(
                    "Department Head Account", "DepartmentHead", fullName),
                buildStatusCard("Admin Account", "Admin", fullName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusCard(String title, String roles, String fullName) {
    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Divider(thickness: 1, color: Colors.black),
              Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('status', isEqualTo: 'active')
                              .where('roles',
                                  isEqualTo: roles) // Filter by role here
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(child: Text("No records"));
                            }

                            var userDocs = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: userDocs.length,
                              itemBuilder: (context, index) {
                                var data = userDocs[index].data()
                                    as Map<String, dynamic>;
                                String name =
                                    "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}"
                                        .trim();
                                String email = data['email'] ?? 'No email';
                                String department = data['department'] ?? 'N/A';

                                return Card(
                                  color: Colors.grey.shade200,
                                  elevation: 2,
                                  child: ListTile(
                                    title: Text(name,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(email),
                                        Text("Department: $department"),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ))
            ])));
  }
}
