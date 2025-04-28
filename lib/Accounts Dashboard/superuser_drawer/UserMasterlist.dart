import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// In this Dart file This is the Masterlist of the user,
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

  // The `initState` method is called once when the widget is inserted into the widget tree. 
// It is used for initializing any data or setting up states before the widget builds for the first time.
// In this case, `isLoading` is explicitly set to `false` during initialization, 
// which means the screen will not show a loading state when it first appears.
// The `super.initState()` call ensures that any initialization logic from the parent class (StatefulWidget) is also executed properly.
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
                buildStatusCard("Super Users", "Superuser", fullName)
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

              // This Expanded widget contains the main body of the screen that displays a list of users.
              // - If `isLoading` is true, a CircularProgressIndicator (loading spinner) is shown at the center of the screen.
              // - If not loading, a StreamBuilder listens to the 'users' collection in Firestore in real-time.
              // - It applies two filters: 
              //    1. Only users whose 'status' field is 'active' 
              //    2. Only users whose 'roles' field matches the provided `roles` variable.
              // - If the Firestore stream is still waiting for data (connection is in waiting state), a loading spinner is displayed.
              // - If there is no data or the documents are empty, a "No records" message is shown.
              // - If data exists, it builds a ListView where each item displays:
              //    - the user's full name (first name + last name),
              //    - their email address,
              //    - and their department information.
              // This ensures a dynamic and real-time updated list of users based on their role and active status.
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
