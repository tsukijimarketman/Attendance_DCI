import 'dart:ui';
import 'package:attendance_app/Animation/text_reveal.dart';
import 'package:attendance_app/Auth/Persistent.dart';
import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/encryption/encryption_helper.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode firstNameFocusNode = FocusNode();
  FocusNode lastNameFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // this is all the variables that are used in the login page
  bool isLoading = false;
  bool isLogin = true;
  Color color1 = Colors.white;
  Color color2 = Colors.blueAccent;
  bool islocked = true;
  Icon icon = Icon(Icons.lock);
  bool isChecked = false;

  // This is the controller for the password field
  // This is the controller for the email field
  // This is the controller for the first name field
  // This is the controller for the last name field
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  String passwordError = ""; // To hold the error message for password

  // This is the function that will clear the text fields after the user has Sign In
  void _clearFields() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    passwordController.clear();
  }

  bool isForgotPassword = false;

  // this is for animations
  late AnimationController controllerLogo;
  late Animation<double> _textRevealcontrollerLogo;
  late Animation<double> _textOpacitycontrollerLogo;
  late AnimationController controllerHeading;
  late Animation<double> _textRevealcontrollerHeading;
  late Animation<double> _textOpacitycontrollerHeading;
  late AnimationController controllerSignin;
  late Animation<double> _textRevealcontrollerSignin;
  late Animation<double> _textOpacitycontrollerSignin;

  // this is all for the animation of the text field
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
      if (mounted) controllerLogo.forward();
    });
    Future.delayed(Duration(milliseconds: 1600), () {
      if (mounted) controllerHeading.forward();
    });
    Future.delayed(Duration(milliseconds: 1700), () {
      if (mounted) controllerSignin.forward();
    });
  }

  // Clean up resources when widget is disposed
  @override
  void dispose() {
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    firstNameFocusNode.dispose();
    lastNameFocusNode.dispose();

    // Dispose all animation controllers
    controllerLogo.dispose();
    controllerHeading.dispose();
    controllerSignin.dispose();

    // Dispose all text controllers
    passwordController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();

    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (isLogin) {
        handleSignIn(); // Trigger sign in if on login page
      } else if (isForgotPassword) {
        handlePasswordReset(); // Trigger password reset if on forgot password page
      } else {
        _validator(); // Trigger registration if on register page
      }
    }
  }

  // Password validation logic
  bool validatePassword(String password) {
    String pattern =
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[_!@#$%^&*(),.?":{}|<>]).{8,16}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(password);
  }

  // This is the function that will show the loading animation when the user clicks on the button
  void showLoading() {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
  }

  // This is the function that will hide the loading animation when the user clicks on the button
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
        return RawKeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKey: _handleKeyEvent,
          child: Scaffold(
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
                                  "assets/rmvbg.png",
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
                      isForgotPassword
                          ? ForgotPassword()
                          : (isLogin ? SignIn() : Register()),
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
        child: Form(
          key: _formKey,
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
                  focusNode: emailFocusNode,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(passwordFocusNode),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width / 100,
              ),
              Container(
                height: MediaQuery.of(context).size.width / 28,
                width: MediaQuery.of(context).size.width / 3.5,
                child: AnimatedTextField(
                  label: "Password",
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: handleSignIn, // Trigger sign in on Enter
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
                  // this will trigger the HandleSignIn function when the user clicks on the button
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
              RichText(
                  text: TextSpan(
                text: 'By signing in, you agree to our ',
                style: TextStyle(color: Colors.white, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (await canLaunch(url)) {
                          await launch(url,
                              webOnlyWindowName:
                                  '_blank'); // open new tab on web
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Could not open Privacy Policy')),
                          );
                        }
                      },
                  ),
                  TextSpan(text: '.'),
                ],
              )).showCursorOnHover,
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
                  ).showCursorOnHover.moveUpOnHover,
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        // Clear any error messages
                        passwordError = "";
                        // Clear password field
                        passwordController.clear();
                        // Switch to forgot password screen
                        isForgotPassword = true;
                        isLogin = false;
                      });
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: MediaQuery.of(context).size.width / 85,
                        fontFamily: "R",
                      ),
                    ),
                  ).showCursorOnHover.moveUpOnHover,
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // This is the function that will handle the sign in process
  // It will check if the email and password are correct and if they are registered to the google firebase auth,
  // it will navigate to the home page
  Future<void> handleSignIn() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Check if email or password is empty before proceeding
    if (email.isEmpty || password.isEmpty) {
      _showDialog('Required Fields',
          'Please enter both email and password to sign in.');
      return;
    }

    showLoading();

    try {
      // Step 1: Check status in Firestore first (BEFORE signing in)
      final QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDocs.docs.isEmpty) {
        hideLoading();
        _showDialog('Login Failed', 'No user record found with this email.');
        return;
      }

      final userData = userDocs.docs.first.data() as Map<String, dynamic>?;
      final status = userData?['status']?.toString()?.toLowerCase();

      if (status != 'active') {
        hideLoading();
        _showDialog(
          'Access Denied',
          'Your account is not active. Please contact the administrator.',
        );
        return;
      }

      // Check if email and password are not empty
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Check if the user is not null after login
      if (userCredential.user != null) {
        // First hide loading before any operations that might cause navigation
        hideLoading();

        // Log the user in and log audit trail
        // Important: We don't need to await this since we're about to navigate
        // This prevents setState being called after navigation
        logAuditTrail("User Logged In", "User with email $email logged in.")
            .catchError((error) {
          // Silent error handling since we're already navigating
          print("Error logging audit trail: $error");
        });

        // Navigate to the home page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AuthPersistent()),
          );
        }
      } else {
        // If user is null, show an error message
        hideLoading();
        _showDialog('Login Failed', 'Wrong Password. Please try again.');
      }
      // Handle specific Firebase authentication errors
    } on FirebaseAuthException catch (e) {
      // Hide loading animation
      hideLoading();

      // Show user-friendly error messages using dialog instead of setting passwordError
      if (e.code == 'user-not-found') {
        _showDialog('Login Failed', 'No user found with this email.');
      } else if (e.code == 'wrong-password') {
        _showDialog('Login Failed', 'Incorrect password. Please try again.');
      } else {
        _showDialog('Login Failed', 'Incorrect password. Please try again.');
      }
    } catch (e) {
      // Handle any unexpected errors and ensure loading is hidden
      hideLoading();
      _showDialog('Error', 'An unexpected error occurred. Please try again.');
    }
  }

// Function to validate sign up form
  void _validator() {
    if (!mounted) return;

    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Check if any fields are empty
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showDialog('Empty Fields', 'Please fill in all required fields.');
      return;
    }

    // Only check password validation if all fields are filled
    if (!validatePassword(password)) {
      _showDialog('Invalid Password',
          'Password must contain at least one uppercase letter, one lowercase letter, one number, one special character, and be between 8-16 characters long.');
      return;
    }

    // All validations passed, proceed with user registration
    _storePendingUser();
  }

  Future<void> handlePasswordReset() async {
    String email = emailController.text.trim();

    // Check if email is empty
    if (email.isEmpty) {
      _showDialog('Email Required',
          'Please enter your email address to reset your password.');
      return;
    }

    // Show loading animation
    showLoading();

    try {
      // Check if the email exists in the database first
      final QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDocs.docs.isEmpty) {
        hideLoading();
        _showDialog(
            'Email Not Found', 'No account exists with this email address.');
        return;
      }

      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Hide loading and show success dialog
      hideLoading();
      _showDialog('Reset Link Sent',
          'A password reset link has been sent to $email. Please check your inbox and follow the instructions to reset your password.');

      // Log the password reset request in audit trail
      logAuditTrail("Password Reset Requested",
              "Password reset requested for email $email.")
          .catchError((error) {
        print("Error logging audit trail: $error");
      });

      // Clear the email field
      emailController.clear();
    } on FirebaseAuthException catch (e) {
      hideLoading();

      // Handle specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        _showDialog(
            'Email Not Found', 'No account exists with this email address.');
      } else {
        _showDialog('Error',
            'An error occurred while sending the reset link. Please try again later.');
      }
    } catch (e) {
      hideLoading();
      _showDialog('Error', 'An unexpected error occurred. Please try again.');
    }
  }

  Widget ForgotPassword() {
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  "Forgot Password",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width / 40,
                      fontFamily: "B"),
                ),
                SizedBox(height: MediaQuery.of(context).size.width / 300),
                Text(
                  "Enter your email to receive a password reset link",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width / 65,
                      fontFamily: "R"),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.width / 50),
            Container(
              width: MediaQuery.of(context).size.width / 3.5,
              height: MediaQuery.of(context).size.width / 28,
              child: AnimatedTextField(
                label: "Email",
                suffix: Icon(Icons.email),
                readOnly: false,
                obscureText: false,
                controller: emailController,
                focusNode: emailFocusNode,
                textInputAction: TextInputAction.done,
                onEditingComplete: handlePasswordReset,
              ),
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
                onTap: handlePasswordReset,
                child: Container(
                  width: MediaQuery.of(context).size.width / 3.5,
                  decoration: BoxDecoration(
                      color: color2,
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width / 80)),
                  height: MediaQuery.of(context).size.width / 28,
                  child: Center(
                    child: Text(
                      "Reset Password",
                      style: TextStyle(
                          color: color1,
                          fontSize: MediaQuery.of(context).size.width / 55,
                          fontFamily: "M"),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.width / 70),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Remember your password? ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width / 85,
                    fontFamily: "R",
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Set to login screen
                      isForgotPassword = false;
                      isLogin = true;
                      // Clear any error messages
                      passwordError = "";
                    });
                  },
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: MediaQuery.of(context).size.width / 85,
                      fontFamily: "R",
                    ),
                  ),
                ).showCursorOnHover.moveUpOnHover,
              ],
            ),
          ],
        ),
      ),
    );
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
      child: Form(
        key: _formKey,
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
                      focusNode: firstNameFocusNode,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context)
                          .requestFocus(lastNameFocusNode),
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
                      focusNode: lastNameFocusNode,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(emailFocusNode),
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
                  focusNode: emailFocusNode,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(passwordFocusNode),
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
                focusNode: passwordFocusNode,
                textInputAction: TextInputAction.done,
                onEditingComplete: _validator, // Trigger registration on Enter
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
                // Modified onTap function for Sign Up button with loading animation
                onTap: () async {
                  if (!mounted) return;
                  setState(() {
                    showLoading(); // Show the loading animation when clicked
                  });

                  // Add a small delay so the loading animation is visible
                  await Future.delayed(Duration(milliseconds: 300));

                  if (!mounted) return;
                  setState(() {
                    hideLoading(); // Hide the loading animation
                  });

                  // Call validator which now checks empty fields first
                  _validator();
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
      ),
    );
  }

  // This is the function that will store the user in the database
  Future<void> _storePendingUser() async {
    if (!mounted) return;

    try {
      String email = emailController.text.trim();

      // **Step 1: Check if email already exists in Firestore**
      QuerySnapshot existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (!mounted) return;

      // Check if the email already exists in the database
      // If it does, show an error message and return
      if (existingUser.docs.isNotEmpty) {
        // **Email already exists, show error**
        _showDialog('Email Already in Use', 'Pick another email address.');
        _clearFields();
        return;
      }

      // **Step 2: Encrypt password and store the new user**
      String encryptedPassword =
          EncryptionHelper.encryptPassword(passwordController.text.trim());

      // Store the new user in Firestore with status 'pending'
      await FirebaseFirestore.instance.collection('users').add({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': email,
        'password': encryptedPassword,
        'status': 'pending',
        'isDeleted': false,
      });

      if (!mounted) return;

      // **Step 3: Show success message and clear fields**
      _showDialog('Pending Approval',
          'Your account request has been sent for approval.');
      _clearFields();
    } catch (error) {
      if (!mounted) return;

      // **Step 4: Handle errors gracefully**
      _showDialog('Error', error.toString());
    }
  }

  // This is will show the dialog
  void _showDialog(String title, String message) {
    if (!mounted) return;

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
                      Icons.info_outline,
                      color: Color(0xFF0e2643),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      title,
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
