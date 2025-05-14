import 'package:attendance_app/hover_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountInfo extends StatefulWidget {
  const AccountInfo({super.key});

  @override
  State<AccountInfo> createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  bool isChangePassword = false;
  String errorMessage = ""; // Holds error message for UI display

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$',
  );

    //It first checks if the old password, new password, and confirm password fields are filled. If any of these fields are empty, it sets an error message. 
// The method then validates the new password using a regular expression to ensure that it meets certain criteria: at least 8 characters long, containing one uppercase letter, 
// one lowercase letter, one number, and one special character. If the new password doesn't match the criteria, an error message is displayed.
// Additionally, the function checks if the new password matches the confirm password field; if they do not match, an error message is displayed.
// If the user has filled all fields correctly, the method proceeds by attempting to reauthenticate the user with the old password using Firebase Authentication. 
// Upon successful reauthentication, the password is updated to the new one. If reauthentication or password update fails, an appropriate error message is shown.
// If the password is successfully updated, the method hides any error messages, disables the change password view, and shows a success message using a SnackBar.
    Future<void> _changePassword() async {
    String oldPassword = oldPasswordController.text.trim();
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorMessage = "All fields are required.";
      });
      return;
    }

    // Validate the new password with regex
    if (!passwordRegex.hasMatch(newPassword)) {
      setState(() {
        errorMessage =
            "Password must be at least 8 characters long, contain one uppercase, one lowercase, one number, and one special character.";
      });
      return;
    }

    // Check if new password matches confirm password
    if (newPassword != confirmPassword) {
      setState(() {
        errorMessage = "New password and confirm password do not match.";
      });
      return;
    }

    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = "User not logged in.";
        });
        return;
      }

      // Reauthenticate the user with the old password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // If re-authentication is successful, update the password
      await user.updatePassword(newPassword);

      setState(() {
        errorMessage = ""; // Hide error message
        isChangePassword = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password successfully updated!"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == "wrong-password") {
          errorMessage = "The old password is incorrect.";
        } else {
          errorMessage = "An error occurred: ${e.message}";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Panel (Email & Change Password Button)
          Container(
            height: MediaQuery.of(context).size.width / 4.2,
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 50),
                Text("Email",
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 90,
                        color: Colors.black,
                        fontFamily: "R")),
                SizedBox(height: MediaQuery.of(context).size.width / 170),
                // This StreamBuilder listens to real-time updates from the "users" collection in Firestore. 
// It filters the documents by the current user's UID, retrieved from Firebase Authentication, 
// and limits the query to a single document (since the UID is unique for each user).
// Whenever there are changes to the "users" collection that match the current user's UID, 
// the StreamBuilder rebuilds the UI with the updated data.
// If the snapshot contains data, the first document is fetched from the snapshot, 
// and the user's email is extracted from the document data. If the email field is not present, 
// it defaults to "N/A". The `email` variable is then available for use in the UI or other logic.
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .where("uid",
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text("No Email Found",
                          style: TextStyle(color: Colors.red));
                    }
                    var userData = snapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                    String email = userData["email"] ?? "N/A";
                    return Container(
                      width: MediaQuery.of(context).size.width / 5.52,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width / 150),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: email),
                        showCursor: false,
                        readOnly: true,
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width / 110,
                            color: Colors.black,
                            fontFamily: "R"),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(
                              MediaQuery.of(context).size.width / 120),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 150),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.width / 80),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isChangePassword = true;
                    });
                  },
                  child: Container(
                      width: MediaQuery.of(context).size.width / 5.52,
                      height: MediaQuery.of(context).size.width / 35,
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 11, 55, 99),
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width / 200)),
                      child: Center(
                          child: Text("Change Password",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "M",
                                  fontSize: 16)))),
                ).showCursorOnHover,
              ],
            ),
          ),

          // Divider
          VerticalDivider(),

          // Change Password Section
          Visibility(
            visible: isChangePassword,
            child: Container(
              height: MediaQuery.of(context).size.width / 4.2,
              child: Column(children: [
                SizedBox(height: MediaQuery.of(context).size.width / 95),
                _buildPasswordField("Old Password", oldPasswordController),
                SizedBox(height: MediaQuery.of(context).size.width / 90),
                _buildPasswordField("New Password", newPasswordController),
                SizedBox(height: MediaQuery.of(context).size.width / 90),
                _buildPasswordField(
                    "Confirm Password", confirmPasswordController),
                SizedBox(height: MediaQuery.of(context).size.width / 80),
                Row(
                  children: [
                    _buildActionButton("Cancel", Colors.red, () {
                      setState(() {
                        isChangePassword = false;
                      });
                    }).showCursorOnHover,
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 70,
                    ),
                    _buildActionButton("Save", Colors.green, _changePassword).showCursorOnHover,
                  ],
                ),
              ]),
            ),
          ),

          // Divider
          VerticalDivider(),

          // Error Message Display
          Container(
            height: MediaQuery.of(context).size.width / 4.2,
            width: MediaQuery.of(context).size.width / 3.4,
            alignment: Alignment.center,
            child: errorMessage.isNotEmpty
                ? Container(
                    width: MediaQuery.of(context).size.width / 4.4,
                    height: MediaQuery.of(context).size.width / 7.4,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width / 70)),
                    child: Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 3.4,
                          height: MediaQuery.of(context).size.width / 20,
                          decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(
                                      MediaQuery.of(context).size.width / 70),
                                  topRight: Radius.circular(
                                      MediaQuery.of(context).size.width / 70))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                  child: Icon(
                                Icons.error,
                                color: Colors.yellow,
                                size: MediaQuery.of(context).size.width / 30,
                              )),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.width / 80,
                        ),
                        Center(
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                                fontFamily: "M",
                                fontSize: 14,
                                color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Helper function to build password fields
  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.width / 90,
                color: Colors.black,
                fontFamily: "R")),
        SizedBox(height: MediaQuery.of(context).size.width / 170),
        Container(
          width: MediaQuery.of(context).size.width / 5.52,
          height: MediaQuery.of(context).size.width / 35,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(MediaQuery.of(context).size.width / 150),
          ),
          child: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.all(MediaQuery.of(context).size.width / 120),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width / 150),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper function to build action buttons
  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
          width: MediaQuery.of(context).size.width / 12,
          height: MediaQuery.of(context).size.width / 35,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10)),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "M",
                    fontSize: MediaQuery.of(context).size.width / 100,
                  )))),
    );
  }
}
