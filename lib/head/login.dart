import 'dart:ui';

import 'package:attendance_app/Accounts%20Dashboard/admin_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/department_head_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_dashoard.dart';
import 'package:attendance_app/Accounts%20Dashboard/super_user_dashboard.dart';
import 'package:attendance_app/Manager_Dashboard/manager_dash.dart';
import 'package:attendance_app/encryption/encryption_helper.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:lottie/lottie.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isLoading = false;
  bool isLogin = true;
  Color color1 = Colors.white;
  Color color2 = Colors.blueAccent;
  bool islocked = true;
  Icon icon = Icon(Icons.lock);
  bool isChecked = false;

  // Add a text editing controller for the password
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  String passwordError = ""; // To hold the error message for password

  // Password validation logic
  bool validatePassword(String password) {
    String pattern =
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[_!@#$%^&*(),.?":{}|<>]).{8,16}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(password);
  }

  void showLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void hideLoading() {
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double height = constraints.maxHeight;
        double width = constraints.maxWidth;
        return Scaffold(
          body: Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                        image: AssetImage("assets/bgl.jpg"), fit: BoxFit.cover)),
                width: width,
                padding: EdgeInsets.symmetric(
                    horizontal: width / 20, vertical: width / 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: width / 2.23,
                      height: height,
                      decoration: BoxDecoration(
                          border: Border(
                              right: BorderSide(
                                  color: Color(0xFF002428), width: 2))),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                "Appointment System ",
                                style: TextStyle(
                                    color: Color(0xFF002428),
                                    fontSize: width / 30,
                                    fontFamily: "BL"),
                              ),
                              SizedBox(
                                height: width / 80,
                              ),
                              Text(
                                "Track schedules, record attendance, and manage appointments -all in one place.",
                                style: TextStyle(
                                    color: Color(0xFF002428),
                                    fontSize: width / 50,
                                    fontFamily: "M"),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: width / 40,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "dciSplash.png",
                                height: width / 10,
                              ),
                              SizedBox(
                                width: width / 40,
                              ),
                              Image.asset(
                                "dci_logo.png",
                                height: width / 10,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    isLogin ? SignIn() : Register(),
                  ],
                ),
              ),
              if (isLoading)
                Positioned.fill(
                    child: Center(
                  child: Stack(
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                      // Lottie animation centered on the screen
                      Center(
                        child: Lottie.asset(
                          'assets/ld.json',
                          width: width / 4,
                          height: width / 4,
                          repeat: true,
                        ),
                      ),
                    ],
                  ),
                ))
            ],
          ),
        );
      },
    );
  }

  void checkUserRole(User user) async {
    try {
      // Query the users collection where the email matches the authenticated user's email
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid) // Match by email or user.uid
          .get();

      if (userSnapshot.docs.isEmpty) {
        // If no matching user is found, handle the error appropriately
        print("User not found in Firestore");
        return;
      }

      // Assuming you have a single user document matching the email
      DocumentSnapshot userDoc = userSnapshot.docs.first;

      // Get the role from the Firestore document
      String role = userDoc['roles'];

      if (role == "Manager") {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => Manager_Dashboard()));
      } else if (role == "DepartmentHead") {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => Deparment_Head_Dashboard()));
      } else if (role == "Admin") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Admin_Dashboard()));
      } else if (role == "Superuser") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => SuperUserDashboard()));
      } else {
        print("Unknown role");
      }
    } catch (e) {
      print("Error checking user role: $e");
    }
  }

  Widget SignIn() {
    return Container(
      width: MediaQuery.of(context).size.width / 2.23,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          color: Color(0xFF002428),
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(MediaQuery.of(context).size.width / 30),
              bottomRight:
                  Radius.circular(MediaQuery.of(context).size.width / 30))),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width / 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                "Sign In",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width / 35,
                    fontFamily: "B"),
              ),
              Text(
                "Please sign in to your account.",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width / 55,
                    fontFamily: "R"),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width / 50,
          ),
          Container(
              width: MediaQuery.of(context).size.width / 3.5,
              height: MediaQuery.of(context).size.width / 28,
              child: AnimatedTextField(
                label: "Email",
                suffix: Icon(Icons.email),
                readOnly: false,
                obscureText: false,
                controller: emailController,
              )),
          SizedBox(
            height: MediaQuery.of(context).size.width / 100,
          ),
          Container(
            height: MediaQuery.of(context).size.width / 28,
            width: MediaQuery.of(context).size.width / 3.5,
            child: AnimatedTextField(
              label: "Password",
              controller: passwordController,
              suffix: GestureDetector(
                onTap: () {
                  setState(() {
                    islocked = !islocked;
                    icon = islocked ? Icon(Icons.lock) : Icon(Icons.lock_open);
                  });
                },
                child: icon,
              ).showCursorOnHover,
              readOnly: false,
              obscureText: islocked,
            ),
          ),
          if (passwordError.isNotEmpty)
            Text(
              passwordError,
              style: TextStyle(color: Colors.red),
            ),
          SizedBox(
            height: MediaQuery.of(context).size.width / 100,
          ),
          MouseRegion(
            onEnter: (event) {
              setState(() {
                color1 = Colors.white;
                color2 = Color(0xFF2c2d6c);
              });
            },
            onExit: (event) {
              setState(() {
                color1 = Colors.white;
                color2 = Colors.blueAccent;
              });
            },
            child: GestureDetector(
              onTap: () async {
                String email = emailController.text;
                String password = passwordController.text;
                showLoading();
                try {
                  // Attempt login
                  UserCredential userCredential = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                          email: email, password: password);

                  // Call checkUserRole once login is successful
                  checkUserRole(userCredential.user!);
                } on FirebaseAuthException catch (e) {
                  // Check for email not found or wrong password error
                  hideLoading();
                  if (e.code == 'user-not-found') {
                    setState(() {
                      passwordError = "No user found with this email.";
                    });
                  } else if (e.code == 'wrong-password') {
                    setState(() {
                      passwordError = "Incorrect password.";
                    });
                  } else {
                    setState(() {
                      passwordError =
                          "Wrong credentials! Invalid email or password.";
                    });
                  }
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width / 3.5,
                decoration: BoxDecoration(
                    color: color2,
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width / 80)),
                height: MediaQuery.of(context).size.width / 28,
                child: Center(
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                        color: color1,
                        fontSize: MediaQuery.of(context).size.width / 55,
                        fontFamily: "M"),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width / 70,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width / 85,
                  fontFamily: "R",
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    passwordError = "";
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  "Register Now!",
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: MediaQuery.of(context).size.width / 85,
                    fontFamily: "R",
                  ),
                ),
              ).showCursorOnHover.moveUpOnHover
            ],
          )
        ],
      ),
    );
  }

  Widget Register() {
  return Container(
    width: MediaQuery.of(context).size.width / 2.23,
    height: MediaQuery.of(context).size.height,
    color: Color(0xFF002428),
    padding: EdgeInsets.all(MediaQuery.of(context).size.width / 30),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(
              "Sign Up Now!",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width / 35,
                  fontFamily: "B"),
            ),
          ],
        ),
        SizedBox(
          height: MediaQuery.of(context).size.width / 180,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width / 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: MediaQuery.of(context).size.width / 7.4,
                height: MediaQuery.of(context).size.width / 28,
                child: AnimatedTextField(
                  controller: firstNameController,
                  label: "First Name",
                  suffix: null,
                  readOnly: false,
                  obscureText: false,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 88,
              ),
              Container(
                width: MediaQuery.of(context).size.width / 7.4,
                height: MediaQuery.of(context).size.width / 28,
                child: AnimatedTextField(
                  controller: lastNameController,
                  label: "Last Name",
                  suffix: null,
                  readOnly: false,
                  obscureText: false,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.width / 80,
        ),
        Container(
            width: MediaQuery.of(context).size.width / 3.5,
            height: MediaQuery.of(context).size.width / 28,
            child: AnimatedTextField(
              controller: emailController,
              label: "Email",
              suffix: Icon(Icons.email),
              readOnly: false,
              obscureText: false,
            )),
        SizedBox(
          height: MediaQuery.of(context).size.width / 100,
        ),
        Container(
          height: MediaQuery.of(context).size.width / 28,
          width: MediaQuery.of(context).size.width / 3.5,
          child: AnimatedTextField(
            label: "Password",
            controller: passwordController,
            suffix: GestureDetector(
              onTap: () {
                setState(() {
                  islocked = !islocked;
                  icon = islocked ? Icon(Icons.lock) : Icon(Icons.lock_open);
                });
              },
              child: icon,
            ).showCursorOnHover,
            readOnly: false,
            obscureText: islocked,
          ),
        ),
        if (passwordError.isNotEmpty)
          Text(
            passwordError,
            style: TextStyle(color: Colors.red),
          ),
        SizedBox(
          height: MediaQuery.of(context).size.width / 100,
        ),
        MouseRegion(
          onEnter: (event) {
            setState(() {
              color1 = Colors.white;
              color2 = Color(0xFF2c2d6c);
            });
          },
          onExit: (event) {
            setState(() {
              color1 = Colors.white;
              color2 = Colors.blueAccent;
            });
          },
          child: GestureDetector(
            onTap: () async {
              String password = passwordController.text;
              setState(() {
                showLoading();  // Show the loading animation when clicked
              });

              if (validatePassword(password)) {
                // Simulate some delay to show the loading animation
                await Future.delayed(Duration(seconds: 2));

                setState(() {
                  hideLoading();  // Hide the loading animation when finished
                });

                // Proceed with registration logic here
                _validator();
              } else {
                setState(() {
                  hideLoading();  // Hide the loading animation on error
                  passwordError =
                      "Password must contain at least one uppercase letter, one lowercase letter, one number, one special character, and be between 8-16 characters long.";
                });
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width / 3.5,
              decoration: BoxDecoration(
                  color: color2,
                  borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width / 80)),
              height: MediaQuery.of(context).size.width / 28,
              child: Center(
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                      color: color1,
                      fontSize: MediaQuery.of(context).size.width / 55,
                      fontFamily: "M"),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.width / 70,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Have an existing account? ",
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width / 85,
                fontFamily: "R",
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  passwordError = "";
                  isLogin = !isLogin;
                });
              },
              child: Text(
                "Sign In Now!",
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: MediaQuery.of(context).size.width / 85,
                  fontFamily: "R",
                ),
              ),
            ).showCursorOnHover.moveUpOnHover
          ],
        )
      ],
    ),
  );
}


 void _validator() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showDialog('Empty Fields', 'Please fill in all fields.');
      return;
    }
    _storePendingUser();
  }

  Future<void> _storePendingUser() async {
    try {
      String encryptedPassword = EncryptionHelper.encryptPassword(passwordController.text.trim());
      await FirebaseFirestore.instance.collection('users').add({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'password': encryptedPassword,
        'status': 'pending'
      });
      _showDialog('Pending Approval', 'Your account request has been sent for approval.');
    } catch (error) {
      _showDialog('Error', error.toString());
    }
  }

  void _showDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(title: Text(title), content: Text(message), actions: [CupertinoDialogAction(child: Text('OK'), onPressed: () => Navigator.pop(context))]),
    );
  }
}
