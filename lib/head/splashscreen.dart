import 'package:attendance_app/head/login.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // No async operations should be done here, moving async task to didChangeDependencies
    Future.delayed(Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.white,
      child: Center(
        child: Stack(
          children: [
            
            Center(
              child: Image.asset(
                "assets/dci_logo.png",
                height: screenWidth / 1.2,
              ),
            ),
            Center(child: LottieBuilder.asset("assets/scan.json", height: screenWidth/1.5,))
          ],
        ),
      ),
    );
  }
}
