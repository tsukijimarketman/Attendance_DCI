import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/encryption/encryption_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String selectedRoles = '---';

  List<String> departmentList = [];
  String? selectedDepartment;

  final Map<String, String> rolesMap = {
    '---': '',
    'Super User': 'Superuser',
    'Manager': 'Manager',
    'Department Head': 'DepartmentHead',
    'Admin': 'Admin',
    'User': 'User'
  };

  @override
  void initState() {
    super.initState();
    _fetchDepartments(); // Fetch departments when the screen loads
  }

  // Function to fetch department references
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder(
        stream: _firestore
            .collection("users")
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No pending users."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var user = snapshot.data!.docs[index];
              return ListTile(
                tileColor: Colors.grey.shade100
                    .withOpacity(0.5), // 50% transparent grey
                hoverColor: Colors.amber,
                title: Text(
                  "${user["first_name"]} ${user["last_name"]}",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400),
                ),
                subtitle: Text(user["email"],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    )),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _showDialog(context, user),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _rejectUser(user.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDialog(BuildContext context, DocumentSnapshot user) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool requiresDepartment = !(selectedRoles == "Super User" || selectedRoles == "Admin");

          return CupertinoAlertDialog(
            title: Text('Assign Role'),
            content: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: selectedRoles, 
                    onChanged: (String? newRole) {
                      setState(() {
                        selectedRoles = newRole!;
                      });
                    },
                    items: rolesMap.keys
                        .map<DropdownMenuItem<String>>((String displayValue) {
                      return DropdownMenuItem<String>(
                        value: displayValue,
                        child: Text(displayValue),
                      );
                    }).toList(),
                  ),
                  
                  // ✅ Show department dropdown only if required
                  if (requiresDepartment)
                    DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                      items: departmentList.map((String department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Text(department, style: TextStyle(fontSize: 18)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDepartment = newValue;
                        });
                      },
                      hint: Text("Select Department",
                          style: TextStyle(fontSize: 18, color: Colors.black54)),
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // ✅ Prevent saving if a department is required but not selected
                  if (requiresDepartment && selectedDepartment == null) {
                    _showErrorDialog(context, "Please select a department.");
                    return;
                  }

                  Navigator.pop(context);
                  _approveUser(user);
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ✅ Helper function to show an error dialog
void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}


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
        password: decryptedPassword,  // Use decrypted password from Firestore
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

     _showMessage("User approved and account created successfully!");

    } finally {
      // Clean up: delete temporary app
      await tempApp.delete();
    }

  } catch (e) {
    _showMessage("Error approving user: ${e.toString()}");
  }
}

  void _rejectUser(String userId) async {
    try {
      // Find the user document by userId
      DocumentSnapshot userSnapshot =
          await _firestore.collection("users").doc(userId).get();

      if (!userSnapshot.exists) {
        _showMessage("User not found!");
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
      await _firestore.collection("users").doc(userId).delete();

      await logAuditTrail("User Rejected",
          "Superuser rejected user registration for email: $email");

      _showMessage("User rejected and removed from the system.");
    } catch (e) {
      _showMessage("Error rejecting user: ${e.toString()}");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
