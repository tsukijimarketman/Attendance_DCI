import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isClicked = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height / 2,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 77, 79, 189),
              image: DecorationImage(
                  fit: BoxFit.cover, image: AssetImage("assets/dbp.jpg")),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 4,
            child: Container(
              height: MediaQuery.of(context).size.height / 1.3,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 28, 29, 70),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50))),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.width / 3.5,
            left: MediaQuery.of(context).size.width / 6,
            right: MediaQuery.of(context).size.width / 6,
            child: CircleAvatar(
                radius: MediaQuery.of(context).size.width / 3.8,
                backgroundColor: Colors.white,
                child: Image.asset(
                  "assets/dciSplash.png",
                  height: MediaQuery.of(context).size.width / 3,
                )),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2.5,
            left: MediaQuery.of(context).size.height / 20,
            right: MediaQuery.of(context).size.height / 20,
            child: Container(
              child: Column(
                children: [
                  Text(
                    "Sign In",
                    style: TextStyle(
                        fontFamily: "BL",
                        fontSize: MediaQuery.of(context).size.height / 25,
                        color: Colors.white),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 40,
                  ),
                  Container(
                      height: MediaQuery.of(context).size.height / 13,
                      width: MediaQuery.of(context).size.height / 2.6,
                      child: AnimatedTextField(
                        label: "Email",
                        suffix: Icon(Icons.email),
                        readOnly: false,
                        obscureText: false,
                      )),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 40,
                  ),
                  Container(
                      height: MediaQuery.of(context).size.height / 13,
                      width: MediaQuery.of(context).size.height / 2.6,
                      child: AnimatedTextField(
                        label: "Password",
                        suffix: Icon(Icons.lock),
                        readOnly: false,
                        obscureText: true,
                      )),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 40,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height / 25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Checkbox(
                                  materialTapTargetSize: MaterialTapTargetSize
                                      .shrinkWrap, // Reduces tap target size
                                  visualDensity: VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  value: isClicked,
                                  onChanged: (_) {
                                    setState(() {
                                      if (isClicked == true) {
                                        isClicked = false;
                                      } else if (isClicked == false) {
                                        isClicked = true;
                                      }
                                    });
                                  }),
                              SizedBox(
                                width: MediaQuery.of(context).size.height / 55,
                              ),
                              Container(
                                  child: Text(
                                "Remember Me",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "M",
                                    fontSize:
                                        MediaQuery.of(context).size.height /
                                            70),
                              )),
                            ],
                          ),
                        ),
                        VerticalDivider(),
                        Container(
                            child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                              color: Colors.white,
                              fontFamily: "M",
                              fontSize:
                                  MediaQuery.of(context).size.height / 70),
                        ))
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 40,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.height / 2.6,
                    height: MediaQuery.of(context).size.height / 13,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 77, 79, 189),
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.height / 80)),
                    child: Center(
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: "R",
                            fontSize: MediaQuery.of(context).size.height / 40),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height/12,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Don't have an account?", style: TextStyle(color: Colors.white, fontFamily: "R"),),
                      SizedBox(width: MediaQuery.of(context).size.height/60,),
                      Text("Sign Up Here!", style: TextStyle(color: Colors.white, fontFamily: "B", decoration: TextDecoration.underline, decorationColor: Colors.white),),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
