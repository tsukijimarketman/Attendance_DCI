import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/encryption/encryption_helper.dart';
import 'package:attendance_app/secrets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
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
String? selectedRoles;  // Start as null (no role selected)

  // List to store department names fetched from Firestore
List<Map<String, dynamic>> departmentList = []; // Using dynamic type for flexibility

  // Holds the currently selected department from the dropdown
String? selectedDepartmentId;

  bool _isSendingEmail = false;


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
    QuerySnapshot referencesSnapshot = await FirebaseFirestore.instance
        .collection("references")
        .where('isDeleted', isEqualTo: false)
        .get();

    setState(() {
      departmentList = referencesSnapshot.docs.map((doc) {
        return {
          'deptID': doc["deptID"] as String,  // Treat deptID as a String
          'name': doc["name"] as String,
        };
      }).toList();
    });
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

  void clearDropdowns() {
  setState(() {
    selectedRoles = null;
    selectedDepartmentId = null;
  });
}


  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width / 2.30,
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 40,
          vertical: MediaQuery.of(context).size.width / 180),
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
                style: TextStyle(
                  color: Colors.black,
                  fontSize: MediaQuery.of(context).size.width / 100,
                  fontFamily: "R",
                ),
                decoration: InputDecoration(
                  hintStyle: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 100,
                    color: Colors.black54,
                    fontFamily: "R",
                  ),
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
              height: MediaQuery.of(context).size.width / 3.05,
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
                    return Center(
                        child: Text(
                      "No pending users.",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 100,
                        fontFamily: "R",
                      ),
                    ));
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
                              color: const Color.fromARGB(255, 216, 216, 216)),
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
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                80,
                                            fontFamily: "SB",
                                            color: Colors.black,
                                          )),
                                      subtitle: Text(user["email"],
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                100,
                                            fontFamily: "M",
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
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 100,
                                  fontFamily: "B",
                                ),
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
                          fontSize: MediaQuery.of(context).size.width / 100,
                          fontFamily: "R",
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
  // Updated to match new design style
  void _showDialog(BuildContext context, DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 8.0,
              child: Container(
                height: MediaQuery.of(context).size.width / 4.75,
                width: MediaQuery.of(context).size.width / 3,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF5F9FF)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_ind,
                          color: Color(0xFF0e2643),
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Assign Role",
                          style: TextStyle(
                            fontFamily: "SB",
                            color: Color(0xFF0e2643),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Role Dropdown
                        DropdownButtonFormField<String>(
  value: selectedRoles,
  onChanged: (String? newRole) {
    setState(() {
      selectedRoles = newRole;
    });
  },
  isExpanded: true,
  style: TextStyle(
    fontSize: 16,
    color: Colors.black87,
  ),
  decoration: InputDecoration(
    contentPadding: EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 10,
    ),
    labelText: "Select Role",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  ),
  hint: Text(
    "Select Role",
    style: TextStyle(fontSize: 16, color: Colors.black54),
  ),
  items: rolesMap.keys.map<DropdownMenuItem<String>>((String displayValue) {
    return DropdownMenuItem<String>(
      value: displayValue,
      child: Text(displayValue),
    );
  }).toList(),
),

                          SizedBox(height: 12),

                          // Department Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedDepartmentId,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 10,
                              ),
                              labelText: "Select Department",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: departmentList.map((dept) {
                              return DropdownMenuItem<String>(
      value: dept['deptID'], // Convert deptID to String
                                child: Text(dept['name']!, 
                                    style: TextStyle(fontSize: 16)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedDepartmentId  = newValue;
                              });
                            },
                            hint: Text("Select Department",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 7,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: (){
                              Navigator.pop(context);
                              clearDropdowns();
                              },
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: "R",
                                fontSize:
                                    MediaQuery.of(context).size.width / 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 7,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: _isSendingEmail ? null : () async {
                              // Prevent saving if a department is required but not selected
                      if (selectedRoles == null || selectedRoles!.isEmpty) {
  _showErrorDialog(context, "Please select a role.");
  return;
}


  // Validate department
  if (selectedDepartmentId == null || selectedDepartmentId!.isEmpty) {
    _showErrorDialog(context, "Please select a department.");
    return;
  }
                              

                              // This will close the showDialog Box
                              Navigator.pop(context);
                              // This will trigger the _approveUser and passing the user
  await _approveUser(user);  // wait for approval to finish
                                                            clearDropdowns();

                            },
                            child: Text(
                              "Confirm",
                              style: TextStyle(
                                fontFamily: "R",
                                fontSize:
                                    MediaQuery.of(context).size.width / 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Helper function to show an error dialog with the updated design
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Container(
            width: MediaQuery.of(context).size.width / 4,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Error",
                      style: TextStyle(
                        fontFamily: "SB",
                        color: Color(0xFF0e2643),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "R",
                      fontSize: 16,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width / 7,
                  height: MediaQuery.of(context).size.width / 35,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width / 170),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontFamily: "R",
                        fontSize: MediaQuery.of(context).size.width / 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// This is a showdialog Box for rejecting a registered user with the updated design
  void _showDialogReject(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Container(
            width: MediaQuery.of(context).size.width / 3,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cancel_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Reject User",
                      style: TextStyle(
                        fontFamily: "SB",
                        color: Color(0xFF0e2643),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    "Do you want to reject this user?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "R",
                      fontSize: 16,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 7,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width / 170),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.width / 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 7,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width / 170),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          // This will triggered the _rejectUser and it passing the userID
                          _rejectUser(userId);
                          // This is closing the showdialogbox
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.width / 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendWelcomeEmail(String userEmail, String userName) async {
  setState(() => _isSendingEmail = true);

  try {
    // Create a Dio instance for API request
    final dio = Dio();

    // Get the email template
    String emailBody = _getWelcomeEmailTemplate(userName);

    // Prepare template parameters for EmailJS API
    final Map<String, dynamic> templateParams = {
      'to_email': userEmail,
      'subject': 'Welcome to DBP-DCI - Your Registration is Approved!',
      'message_html': emailBody, // Already processed HTML content
      'user_name': userName,
      'login_link': 'attendance-dci.web.app',
    };

    // Prepare data for EmailJS API
    final Map<String, dynamic> emailJsData = {
      'service_id': AppSecrets.emailJsServiceId,
      'template_id': AppSecrets.emailJsTemplateWelcome,
      'template_params': templateParams,
      'user_id': AppSecrets.emailJsUserId,
    };

    // Send the request to EmailJS API
    final response = await dio.post(
      'https://api.emailjs.com/api/v1.0/email/send',
      data: emailJsData,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
        validateStatus: (status) =>
            status! < 500, // Accept all status codes less than 500
      ),
    );

    if (response.statusCode == 200) {
      // Try to create a record in Firestore for tracking
      try {
        await _firestore.collection('email_logs').add({
          'type': 'welcome_email',
          'recipient': userEmail,
          'sent_at': FieldValue.serverTimestamp(),
          'subject': 'Welcome to DBP-DCI - Your Registration is Approved!',
          'user_name': userName,
          'provider': 'EmailJS',
        });
      } catch (firestoreError) {
        print("Failed to log email: $firestoreError");
      }

      print('Welcome email sent successfully to $userEmail!');
    } else {
      throw Exception(
          'Failed to send email: ${response.statusCode} - ${response.data}');
    }
  } catch (e) {
    // Error handling
    if (e is DioException) {
      // Handle different types of Dio errors
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          print('Connection timeout. Please check your internet connection.');
          break;
        case DioExceptionType.receiveTimeout:
          print('Receive timeout. The server took too long to respond.');
          break;
        case DioExceptionType.connectionError:
          print('Connection error. Please check your internet connection.');
          break;
        default:
          print('Failed to send email: ${e.message}');
          break;
      }
    } else {
      print('Failed to send email: $e');
    }
  } finally {
    setState(() => _isSendingEmail = false);
  }
}

// HTML template for welcome email
String _getWelcomeEmailTemplate(String userName) {
  return '''<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #ffffff;
      color: #333333;
      padding: 20px;
      line-height: 1.6;
    }
    .header {
      background-color: #0e2643;
      padding: 20px;
      text-align: center;
      color: white;
      border-radius: 8px 8px 0 0;
    }
    .content {
      padding: 20px;
      border: 1px solid #e0e0e0;
      border-top: none;
      border-radius: 0 0 8px 8px;
    }
    .button {
      display: inline-block;
      background-color: #8B0000;
      color: white;
      padding: 12px 24px;
      text-decoration: none;
      border-radius: 5px;
      font-weight: bold;
      margin: 20px 0;
    }
    .footer {
      margin-top: 40px;
      font-size: 12px;
      color: #888888;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="header">
    <h2>Welcome to DBP-Data Center Inc.</h2>
  </div>
  <div class="content">
    <p>Dear ${userName},</p>
    
    <p>Your registration has been approved! You can now login and access the Appointment System.</p>
    
    <p>Please use the link below to access the system:</p>
    
    <a href="http://192.168.1.78:8081" class="button" style="display: inline-block; background-color: #8B0000; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0;">Access Appointment System</a>
    
    <p>If you have any questions or need assistance, please don't hesitate to contact our support team.</p>
    
    <p>Best regards,<br>DBP-Data Center Inc. Team</p>
  </div>
  <div class="footer">
    © 2025 DBP-Data Center Inc. All rights reserved.
  </div>
</body>
</html>''';
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
    String name = user["first_name"] ?? "User"; // Get user's name if available, otherwise use "User"
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
        "deptID": selectedDepartmentId,
      });

      await logAuditTrail("User Approved",
          "Super User approved user $email and assigned to department: $selectedDepartmentId with role: ${rolesMap[selectedRoles]}");

      // Send welcome email to the user
      await _sendWelcomeEmail(email, name);

      toastification.show(
        context: context,
        alignment: Alignment.topRight,
        icon: Icon(Icons.check_circle_outline, color: Colors.blue),
        title: Text('User Approved!'),
        description: Text('User approved and welcome email sent successfully!'),
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
