import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DepartmentMasterlist extends StatefulWidget {
  const DepartmentMasterlist({super.key});

  @override
  State<DepartmentMasterlist> createState() => _DepartmentMasterlistState();
}

class _DepartmentMasterlistState extends State<DepartmentMasterlist> {
  String userDepartment = '';
  String first_name = '';
  String last_name = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

Future<Map<String, List<Map<String, dynamic>>>> fetchUsersGroupedByDepartmentOnly() async {
  QuerySnapshot userSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('status', isEqualTo: 'active')
      .get();

  Map<String, List<Map<String, dynamic>>> grouped = {};

  for (var doc in userSnapshot.docs) {
    var data = doc.data() as Map<String, dynamic>;
    String department = data['department'] ?? 'Unknown Department';

    if (!grouped.containsKey(department)) {
      grouped[department] = [];
    }

    grouped[department]!.add(data);
  }

  return grouped;
}



@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: fetchUsersGroupedByDepartmentOnly(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No active users found"));
        }

        final grouped = snapshot.data!;
        final departments = grouped.entries.toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          itemCount: departments.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final department = departments[index].key;
            final users = departments[index].value;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(department,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
              Divider(thickness: 1, color: Colors.black),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, userIndex) {
                          final user = users[userIndex];
                          final name =
                              "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
                          final email = user['email'] ?? 'No Email';
                          final role = user['roles'] ?? 'No Role';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Card(
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
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
}