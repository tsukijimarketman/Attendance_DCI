import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/encryption/encryption_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'dart:async';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  Timer? _debounce;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Holds the currently selected role from the dropdown (default is '---')
  String selectedRoles = '---';

  // List to store department names fetched from Firestore
  List<String> departmentList = [];

  // Holds the currently selected department from the dropdown
  String? selectedDepartment;

  // Search and pagination variables
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<DocumentSnapshot> _allUsers = [];
  List<DocumentSnapshot> _filteredUsers = [];
  bool _isLoading = true;

  // Map that defines the display name of roles and their corresponding internal role identifiers
// Used to map the human-readable role names to the backend-recognized role keys
  final Map<String, String> rolesMap = {
    '---': '',
    'Super User': 'Superuser',
    'Manager': 'Manager',
    'Department Head': 'DepartmentHead',
    'Admin': 'Admin',
    'User': 'User'
  };

  // The initState method is called once when the widget is first inserted into the widget tree.
// Inside it, we call _fetchDepartments() to immediately fetch and prepare the list of departments
// from Firestore as soon as the screen loads, ensuring the dropdowns or selections are populated early.
  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel the previous timer if it's still active
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Set a new timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchText = _searchController.text;
        _filterUsers();
        _currentPage = 1; // Reset to first page when search changes
      });
    });
  }

  void _filterUsers() {
    if (_searchText.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((user) {
        String fullName = "${user["first_name"]} ${user["last_name"]}";
        String email = user["email"];
        return fullName.toLowerCase().contains(_searchText.toLowerCase()) ||
            email.toLowerCase().contains(_searchText.toLowerCase());
      }).toList();
    }
  }

  // This function fetches the list of available departments from Firestore.
// It first looks inside the 'categories' collection to find the document where 'name' is 'Department'.
// Then, it accesses the 'references' subcollection under that department document.
// It filters out any references that are marked as deleted ('isDeleted' == false).
// Finally, it extracts the names of the departments and updates the local 'departmentList' state.
// If any error occurs during this process, it prints an error message to the console.
  Future<void> _fetchDepartments() async {
    try {
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection("categories")
          .where("name", isEqualTo: "Department")
          .get();

      if (categorySnapshot.docs.isNotEmpty) {
        String departmentCategoryId = categorySnapshot.docs.first.id;

        QuerySnapshot referencesSnapshot = await FirebaseFirestore.instance
            .collection("categories")
            .doc(departmentCategoryId)
            .collection("references")
            .where('isDeleted', isEqualTo: false)
            .get();

        setState(() {
          departmentList = referencesSnapshot.docs
              .map((doc) => doc["name"] as String)
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching departments: $e");
    }
  }

  List<DocumentSnapshot> _getCurrentPageItems() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredUsers.length) {
      return [];
    }

    if (endIndex > _filteredUsers.length) {
      return _filteredUsers.sublist(startIndex);
    }

    return _filteredUsers.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    return (_filteredUsers.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width / 2.30,
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 40),
      child: Column(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User Management",
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 41,
                    fontFamily: "BL",
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 11, 55, 99))),
            Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: Color.fromARGB(255, 11, 55, 99), width: 2))),
            ),
            // Search bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width / 2.95,
              child: StreamBuilder(
                stream: _firestore
                    .collection("users")
                    .where("status", isEqualTo: "pending")
                    .where("isDeleted", isEqualTo: false)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No pending users."));
                  }

                  // Update all users when the data changes
                  _allUsers = snapshot.data!.docs;
                  if (_searchText.isEmpty) {
                    _filteredUsers = _allUsers;
                  } else {
                    _filterUsers();
                  }

                  final currentPageItems = _getCurrentPageItems();

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(5),
                            color: const Color.fromARGB(255, 216, 216, 216)
                          ),
                          padding: EdgeInsets.all(8),
                          child: ListView.builder(
                            itemCount: currentPageItems.length,
                            itemBuilder: (context, index) {
                              var user = currentPageItems[index];
                              return Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: ListTile(
                                      tileColor: index % 2 == 0
                                          ? Colors.grey.shade50
                                          : Colors.white,
                                      title: Text(
                                        "${user["first_name"]} ${user["last_name"]}",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text(user["email"],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          )),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                                Icons.check_circle_outline,
                                                color: Colors.green),
                                            onPressed: () =>
                                                _showDialog(context, user),
                                            tooltip: 'Approve User',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.cancel_outlined,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _showDialogReject(user.id),
                                            tooltip: 'Reject User',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (index < currentPageItems.length - 1)
                                    Divider(
                                      color: Colors.black26,
                                        height: 1,
                                        thickness: 1,
                                        indent: 16,
                                        endIndent: 16),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      // Pagination controls
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.first_page),
                              onPressed: _currentPage > 1
                                  ? () => setState(() => _currentPage = 1)
                                  : null,
                              tooltip: 'First Page',
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: _currentPage > 1
                                  ? () => setState(() => _currentPage--)
                                  : null,
                              tooltip: 'Previous Page',
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Page $_currentPage of $_totalPages',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed: _currentPage < _totalPages
                                  ? () => setState(() => _currentPage++)
                                  : null,
                              tooltip: 'Next Page',
                            ),
                            IconButton(
                              icon: Icon(Icons.last_page),
                              onPressed: _currentPage < _totalPages
                                  ? () =>
                                      setState(() => _currentPage = _totalPages)
                                  : null,
                              tooltip: 'Last Page',
                            ),
                          ],
                        ),
                      ),

                      // Display item count information
                      Text(
                        'Showing ${_getCurrentPageItems().length} of ${_filteredUsers.length} pending users',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ]),
    );
  }

  // This is a showdialog box where if you click the Check Icon it will open this and it will show two DropDown
  // in the Dropdown you can select what kind role you will give to the registered user
  // and the other Dropdown is for the Department
  // if you click the cancel it will close the showdialog box
  // if you click the confirm it will triggered the method for _approveUsers
  void _showDialog(BuildContext context, DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Text(
                'Assign Role',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              content: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: selectedRoles,
                        onChanged: (String? newRole) {
                          setState(() {
                            selectedRoles = newRole!;
                          });
                        },
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        items: rolesMap.keys.map<DropdownMenuItem<String>>(
                            (String displayValue) {
                          return DropdownMenuItem<String>(
                            value: displayValue,
                            child: Text(displayValue),
                          );
                        }).toList(),
                      ),
                    ),

                    // Show department dropdown only if required
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: selectedDepartment,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        items: departmentList.map((String department) {
                          return DropdownMenuItem<String>(
                            value: department,
                            child: Text(department,
                                style: TextStyle(fontSize: 18)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedDepartment = newValue;
                          });
                        },
                        hint: Text("Select Department",
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () =>
                            // this will close the showdialog box
                            Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        )),
                    ElevatedButton(
                        onPressed: () {
                          // Prevent saving if a department is required but not selected
                          if (selectedDepartment == null) {
                            _showErrorDialog(
                                context, "Please select a department.");
                            return;
                          }

                          // this will close the showDialog Box
                          Navigator.pop(context);
                          // This will triggered the _approveUser and passing the user
                          _approveUser(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ))
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper function to show an error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () =>
                  // This will close the ShowErrorDialog
                  Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // This is a showdialog Box for rejecting a registere user
  void _showDialogReject(String userId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Reject this User?'),
            content: Text('Do you want to reject this user?'),
            actions: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton(
                  onPressed: () =>
                      // This will close the ShowDialogBox
                      Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // This will triggered the _rejectUser and it passing the userID
                    _rejectUser(userId);
                    // This is closing the showdialogbox
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ])
            ],
          );
        });
  }

  // This function handles the approval process for a pending user registration.
// It performs the following steps:
// 1. Retrieves the user's email and encrypted password from the Firestore document.
// 2. Decrypts the password using a helper function.
// 3. Initializes a temporary Firebase app instance to create a new user account without affecting the current admin session.
// 4. Creates a new user in Firebase Authentication using the decrypted credentials.
// 5. Updates the Firestore document with the new user's UID, sets their status to 'active', assigns the selected role and department, and removes the password field for security.
// 6. Logs the approval action in the audit trail.
// 7. Displays a success toast notification to inform the admin of the successful operation.
// 8. Ensures cleanup by deleting the temporary Firebase app instance, regardless of success or failure.
// If any errors occur during this process, an error toast notification is displayed to inform the admin.
  Future<void> _approveUser(DocumentSnapshot user) async {
    try {
      String email = user["email"];
      String encryptedPassword = user["password"];

      // Decrypt password before using it
      String decryptedPassword =
          EncryptionHelper.decryptPassword(encryptedPassword);

      final options = Firebase.app().options;
      final tempAppName = 'tempApp-${DateTime.now().millisecondsSinceEpoch}';

      // Initialize a temporary Firebase app
      final tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: FirebaseOptions(
          apiKey: options.apiKey,
          appId: options.appId,
          messagingSenderId: options.messagingSenderId,
          projectId: options.projectId,
          authDomain: options.authDomain,
          storageBucket: options.storageBucket,
        ),
      );
      // Create a new user in the temporary app
      try {
        final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

        final userCredential = await tempAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: decryptedPassword, // Use decrypted password from Firestore
        );

        String newUid = userCredential.user!.uid;

        // Sign out from the temporary auth instance
        await tempAuth.signOut();

        // Update Firestore record
        await _firestore.collection("users").doc(user.id).update({
          "uid": newUid,
          "status": "active",
          "password": FieldValue.delete(), // Remove password for security
          "roles": rolesMap[selectedRoles],
          "department": selectedDepartment,
        });

        await logAuditTrail("User Approved",
            "Super User approved user $email and assigned to department: $selectedDepartment with role: ${rolesMap[selectedRoles]}");

        toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.check_circle_outline, color: Colors.blue),
          title: Text('User Approved!'),
          description: Text('User approved and account created successfully!'),
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      } finally {
        // Clean up: delete temporary app
        await tempApp.delete();
      }
    } catch (e) {
      toastification.show(
        context: context,
        alignment: Alignment.topRight,
        icon: Icon(Icons.error, color: Colors.red),
        title: Text('Error approving!'),
        description: Text('Error approving user: ${e.toString()}'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
      );
      return;
    }
  }

  // This function handles rejecting a user from the system.
  // Steps:
  // 1. Fetch the user document from Firestore using the provided userId.
  // 2. If the user document does not exist, show an error notification.
  // 3. If the user exists, retrieve their email from the document.
  // 4. Check if the email is linked to any sign-in methods (registered in Firebase Authentication).
  // 5. If the user is found in Firebase Auth and matches the email, delete the user from Firebase Authentication.
  // 6. Instead of fully deleting from Firestore, mark the user document as "deleted"
  //    by setting "isDeleted" to true and recording the "deletedAt" timestamp (soft delete).
  // 7. Log the rejection action in the audit trail for record-keeping.
  // 8. Show a toast notification indicating the user has been rejected.
  // 9. If any error occurs during the process, show an error toast message.
  void _rejectUser(String userId) async {
    try {
      // Find the user document by userId
      DocumentSnapshot userSnapshot =
          await _firestore.collection("users").doc(userId).get();

      if (!userSnapshot.exists) {
        toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('User not found!'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }

      String email = userSnapshot["email"]; // Get email from Firestore

      // Find user in Firebase Auth
      List<String> signInMethods =
          await _auth.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        // Get the Firebase user by email
        User? firebaseUser = _auth.currentUser;

        if (firebaseUser != null && firebaseUser.email == email) {
          await firebaseUser.delete(); // Delete from Firebase Auth
        }
      }

      // Delete from Firestore
      await _firestore.collection("users").doc(userId).update({
        "isDeleted": true, // Mark user as deleted
        "deletedAt": FieldValue
            .serverTimestamp(), // Optionally track when the user was marked as deleted
      });

      await logAuditTrail("User Rejected",
          "Superuser rejected user registration for email: $email");

      toastification.show(
        context: context,
        alignment: Alignment.topRight,
        icon: Icon(Icons.error, color: Colors.red),
        title: Text('User Rejected!'),
        description:
            Text('User has been rejected and removed from the system.'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
      );
      return;
    } catch (e) {
      toastification.show(
        context: context,
        alignment: Alignment.topRight,
        icon: Icon(Icons.error, color: Colors.red),
        title: Text('Error rejecting!'),
        description: Text('Error rejecting user: ${e.toString()}'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
      );
      return;
    }
  }
}
