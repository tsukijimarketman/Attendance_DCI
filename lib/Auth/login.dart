import 'dart:ui';

import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/department_head_dashboard.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/manager_dashoard.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/super_user_dashboard.dart';
import 'package:attendance_app/Animation/text_reveal.dart';
import 'package:attendance_app/Auth/Persistent.dart';
import 'package:attendance_app/Auth/audit_function.dart';
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

class _LoginState extends State<Login> with TickerProviderStateMixin {
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

  void _clearFields() {
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
      passwordController.clear();
    }

  late AnimationController controllerLogo;
  late Animation<double> _textRevealcontrollerLogo;
  late Animation<double> _textOpacitycontrollerLogo;
  late AnimationController controllerHeading;
  late Animation<double> _textRevealcontrollerHeading;
  late Animation<double> _textOpacitycontrollerHeading;
  late AnimationController controllerSignin;
  late Animation<double> _textRevealcontrollerSignin;
  late Animation<double> _textOpacitycontrollerSignin;

  @override
  void initState() {
    controllerLogo = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
      reverseDuration: Duration(milliseconds: 375),
    );
    _textRevealcontrollerLogo = Tween<double>(begin: 100, end: 0).animate(
        CurvedAnimation(
            parent: controllerLogo,
            curve: Interval(0.0, 0.3, curve: Curves.fastEaseInToSlowEaseOut)));
    _textOpacitycontrollerLogo = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: controllerLogo,
            curve: Interval(0.0, 0.3, curve: Curves.easeOut)));
    controllerHeading = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
      reverseDuration: Duration(milliseconds: 375),
    );
    _textRevealcontrollerHeading = Tween<double>(begin: 100, end: 0).animate(
        CurvedAnimation(
            parent: controllerHeading,
            curve: Interval(0.0, 0.3, curve: Curves.fastEaseInToSlowEaseOut)));
    _textOpacitycontrollerHeading = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: controllerHeading,
            curve: Interval(0.0, 0.3, curve: Curves.easeOut)));
    controllerSignin = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
      reverseDuration: Duration(milliseconds: 375),
    );
    _textRevealcontrollerSignin = Tween<double>(begin: 100, end: 0).animate(
        CurvedAnimation(
            parent: controllerSignin,
            curve: Interval(0.0, 0.3, curve: Curves.fastEaseInToSlowEaseOut)));
    _textOpacitycontrollerSignin = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: controllerSignin,
            curve: Interval(0.0, 0.3, curve: Curves.easeOut)));

    super.initState();
    Future.delayed(Duration(milliseconds: 1000), () {
      controllerLogo.forward();
    });
    Future.delayed(Duration(milliseconds: 1600), () {
      controllerHeading.forward();
    });
    Future.delayed(Duration(milliseconds: 1700),(){
      controllerSignin.forward();
    });
  }

  // Password validation logic
  bool validatePassword(String password) {
    String pattern =
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[_!@#$%^&*(),.?":{}|<>]).{8,16}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(password);
  }

  void showLoading() {
     if (!mounted) return;
    setState(() {
      isLoading = true;
    });
  }

  void hideLoading() {
  if (!mounted) return;
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
                        image: AssetImage("assets/bgl.jpg"),
                        fit: BoxFit.cover)),
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
                      padding: EdgeInsets.all(width / 25),
                      decoration: BoxDecoration(
                          border: Border(
                              right: BorderSide(
                                  color: Color(0xFF002428), width: 2))),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextReveal(
                            maxHeight: width / 6,
                            textController: controllerLogo,
                            textRevealAnimation: _textRevealcontrollerLogo,
                            textOpacityAnimation: _textOpacitycontrollerLogo,
                            child: Container(
                              child: Image.asset(
                                "assets/dciSplash.png",
                                height: width / 5.8,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: width / 120,
                          ),
                          FadeTransition(
                            opacity: _textOpacitycontrollerHeading,
                            child: Text(
                              "Appointment System",
                              style: TextStyle(
                                  color: Color(0xFF002428),
                                  fontSize: width / 35,
                                  fontFamily: "BL"),
                            ),
                          ),
                          SizedBox(
                            height: width / 120,
                          ),
                          FadeTransition(
                            opacity: _textOpacitycontrollerHeading,
                            child: Text(
                              "Track schedules, record attendance, and manage appointments, all in one place.",
                              style: TextStyle(
                                  color: Color(0xFF002428),
                                  fontSize: width / 60,
                                  fontFamily: "R"),
                            ),
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
                          'assets/lda.json',
                          width: width / 6,
                          height: width / 6,
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

  Widget SignIn() {
    return FadeTransition(
      opacity: _textOpacitycontrollerSignin,
      child: Container(
        width: MediaQuery.of(context).size.width / 2.23,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            color: Color(0xFF002428),
            borderRadius: BorderRadius.only(
                topRight:
                    Radius.circular(MediaQuery.of(context).size.width / 30),
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
                      icon =
                          islocked ? Icon(Icons.lock) : Icon(Icons.lock_open);
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
                onTap: handleSignIn,
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
      ),
    );
  }

 Future<void> handleSignIn() async {
  String email = emailController.text.trim();
  String password = passwordController.text.trim();
  showLoading();

  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    if (userCredential.user != null) {
      print("User logged in: ${userCredential.user!.email}");
      await logAuditTrail("User Logged In", "User with email $email logged in.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPersistent()),
      );
    } else {
      throw FirebaseAuthException(
        code: "null-user",
        message: "User is null after login.",
      );
    }
  } on FirebaseAuthException catch (e) {
    hideLoading();
    setState(() {
      if (e.code == 'user-not-found') {
        passwordError = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        passwordError = "Incorrect password.";
      } else {
        passwordError = "Authentication failed: ${e.message}";
      }
    });
  } catch (e) {
    hideLoading();
    setState(() {
      passwordError = "An unexpected error occurred: ${e.toString()}";
    });
  }
}

  Widget Register() {
    return Container(
      width: MediaQuery.of(context).size.width / 2.23,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(MediaQuery.of(context).size.width / 30),
            bottomRight:
                Radius.circular(MediaQuery.of(context).size.width / 30)),
        color: Color(0xFF002428),
      ),
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
                  showLoading(); // Show the loading animation when clicked
                });

                if (validatePassword(password)) {
                  // Simulate some delay to show the loading animation
                  await Future.delayed(Duration(seconds: 2));

                  setState(() {
                    hideLoading(); // Hide the loading animation when finished
                  });

                  // Proceed with registration logic here
                  _validator();
                } else {
                  setState(() {
                    hideLoading(); // Hide the loading animation on error
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
    String email = emailController.text.trim();

    // **Step 1: Check if email already exists in Firestore**
    QuerySnapshot existingUser = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (existingUser.docs.isNotEmpty) {
      // **Email already exists, show error**
      _showDialog('Email Already in Use', 'Pick another email address.');
      _clearFields();
      return;
    }

    // **Step 2: Encrypt password and store the new user**
    String encryptedPassword = EncryptionHelper.encryptPassword(passwordController.text.trim());

    await FirebaseFirestore.instance.collection('users').add({
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'email': email,
      'password': encryptedPassword,
      'status': 'pending',
      'isDeleted': false,
    });

    _showDialog('Pending Approval', 'Your account request has been sent for approval.');
    _clearFields();
  } catch (error) {
    _showDialog('Error', error.toString());
  }
}

  void _showDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
                child: Text('OK'), onPressed: () => Navigator.pop(context))
          ]),
    );
  }
}
