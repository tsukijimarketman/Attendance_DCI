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

  // The initState method is called when the widget is initialized. It sets the isLoading flag to false,
// indicating that the initial loading state has been completed. This helps manage the state of the widget
// as it is loaded into the UI.
  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  // The fetchUsersGroupedByDepartmentOnly function retrieves the list of active users from the Firestore 
// "users" collection. It queries users where the 'status' field is equal to 'active' and groups them 
// by their respective departments. The data is then organized in a map where the keys are department names 
// and the values are lists of user data (each user represented as a map). If a user's department is 
// missing or undefined, it is categorized under "Unknown Department". The function returns the grouped data 
// as a map of department names to lists of user data, which can be used for further processing or displaying 
// in the UI.
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
      // This FutureBuilder listens for the result of the fetchUsersGroupedByDepartmentOnly function, 
// which fetches and groups active users by their department. It handles different states: while waiting 
// for the data, it shows a loading indicator. Once the data is fetched, it checks if the data exists 
// and if it's empty. If no active users are found, a message is displayed. Upon receiving the grouped data, 
// the FutureBuilder extracts the department entries and prepares them for further use, such as displaying 
// the data in a UI widget. This ensures the UI reflects the latest available data, updating automatically 
// once the fetch operation completes.
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